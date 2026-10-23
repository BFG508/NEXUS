use crate::error::AegisError;

#[derive(Debug, Clone, PartialEq)]
pub struct Ctmc {
    generator: Vec<Vec<f64>>,
}

impl Ctmc {
    pub fn new(generator: Vec<Vec<f64>>) -> Result<Self, AegisError> {
        validate_generator(&generator)?;
        Ok(Self { generator })
    }

    pub fn state_count(&self) -> usize {
        self.generator.len()
    }

    pub fn transient(
        &self,
        initial: &[f64],
        time: f64,
        tolerance: f64,
        max_terms: usize,
    ) -> Result<Vec<f64>, AegisError> {
        validate_distribution(initial, self.state_count())?;
        if !time.is_finite() || time < 0.0 {
            return Err(AegisError::InvalidInput(
                "Markov time must be finite and non-negative".to_string(),
            ));
        }
        if !tolerance.is_finite() || tolerance <= 0.0 || tolerance >= 1.0 {
            return Err(AegisError::InvalidInput(
                "Markov tolerance must be in (0, 1)".to_string(),
            ));
        }
        if max_terms == 0 {
            return Err(AegisError::InvalidInput(
                "Markov max_terms must be positive".to_string(),
            ));
        }
        if time == 0.0 {
            return Ok(initial.to_vec());
        }

        let max_exit = self
            .generator
            .iter()
            .enumerate()
            .map(|(i, row)| -row[i])
            .fold(0.0_f64, f64::max);
        if max_exit == 0.0 {
            return Ok(initial.to_vec());
        }
        let q = max_exit * 1.01;
        let p = uniformized_transition(&self.generator, q);
        let qt = q * time;

        let mut term_vector = initial.to_vec();
        let mut weight = (-qt).exp();
        let mut cumulative_weight = weight;
        let mut result = term_vector.iter().map(|v| v * weight).collect::<Vec<_>>();

        for n in 1..=max_terms {
            term_vector = multiply_row_vector(&term_vector, &p);
            weight *= qt / n as f64;
            cumulative_weight += weight;
            for (target, value) in result.iter_mut().zip(term_vector.iter()) {
                *target += weight * value;
            }
            if 1.0 - cumulative_weight <= tolerance {
                normalize(&mut result);
                return Ok(result);
            }
        }

        Err(AegisError::InvalidInput(format!(
            "Markov uniformization did not converge within {max_terms} terms"
        )))
    }

    pub fn steady_state(&self, tolerance: f64, max_iterations: usize) -> Result<Vec<f64>, AegisError> {
        if !tolerance.is_finite() || tolerance <= 0.0 || tolerance >= 1.0 {
            return Err(AegisError::InvalidInput(
                "Markov tolerance must be in (0, 1)".to_string(),
            ));
        }
        if max_iterations == 0 {
            return Err(AegisError::InvalidInput(
                "Markov max_iterations must be positive".to_string(),
            ));
        }

        let max_exit = self
            .generator
            .iter()
            .enumerate()
            .map(|(i, row)| -row[i])
            .fold(0.0_f64, f64::max);
        if max_exit == 0.0 {
            return Ok(vec![1.0 / self.state_count() as f64; self.state_count()]);
        }
        let q = max_exit * 1.01;
        let p = uniformized_transition(&self.generator, q);
        let mut current = vec![1.0 / self.state_count() as f64; self.state_count()];

        for _ in 0..max_iterations {
            let mut next = multiply_row_vector(&current, &p);
            normalize(&mut next);
            let delta: f64 = current
                .iter()
                .zip(next.iter())
                .map(|(a, b)| (a - b).abs())
                .sum();
            if delta <= tolerance {
                return Ok(next);
            }
            current = next;
        }

        Err(AegisError::InvalidInput(format!(
            "Markov steady-state iteration did not converge within {max_iterations} iterations"
        )))
    }
}

fn validate_generator(generator: &[Vec<f64>]) -> Result<(), AegisError> {
    if generator.is_empty() {
        return Err(AegisError::InvalidInput(
            "Markov generator cannot be empty".to_string(),
        ));
    }
    let n = generator.len();
    for (i, row) in generator.iter().enumerate() {
        if row.len() != n {
            return Err(AegisError::InvalidInput(
                "Markov generator must be square".to_string(),
            ));
        }
        let mut sum = 0.0;
        for (j, &value) in row.iter().enumerate() {
            if !value.is_finite() {
                return Err(AegisError::InvalidInput(
                    "Markov generator values must be finite".to_string(),
                ));
            }
            if i != j && value < 0.0 {
                return Err(AegisError::InvalidInput(
                    "Markov off-diagonal rates must be non-negative".to_string(),
                ));
            }
            if i == j && value > 1.0e-14 {
                return Err(AegisError::InvalidInput(
                    "Markov diagonal values must be non-positive".to_string(),
                ));
            }
            sum += value;
        }
        let scale = row.iter().map(|v| v.abs()).sum::<f64>().max(1.0);
        if sum.abs() > 1.0e-10 * scale {
            return Err(AegisError::InvalidInput(format!(
                "Markov generator row {i} does not sum to zero"
            )));
        }
    }
    Ok(())
}

fn validate_distribution(values: &[f64], expected: usize) -> Result<(), AegisError> {
    if values.len() != expected {
        return Err(AegisError::InvalidInput(format!(
            "initial distribution length must be {expected}"
        )));
    }
    let mut sum = 0.0;
    for &value in values {
        if !value.is_finite() || value < 0.0 || value > 1.0 {
            return Err(AegisError::InvalidInput(
                "initial probabilities must be finite and in [0, 1]".to_string(),
            ));
        }
        sum += value;
    }
    if (sum - 1.0).abs() > 1.0e-10 {
        return Err(AegisError::InvalidInput(
            "initial distribution must sum to one".to_string(),
        ));
    }
    Ok(())
}

fn uniformized_transition(generator: &[Vec<f64>], q: f64) -> Vec<Vec<f64>> {
    let n = generator.len();
    let mut p = vec![vec![0.0; n]; n];
    for i in 0..n {
        for j in 0..n {
            p[i][j] = generator[i][j] / q;
            if i == j {
                p[i][j] += 1.0;
            }
        }
    }
    p
}

fn multiply_row_vector(vector: &[f64], matrix: &[Vec<f64>]) -> Vec<f64> {
    let n = vector.len();
    let mut output = vec![0.0; n];
    for i in 0..n {
        for j in 0..n {
            output[j] += vector[i] * matrix[i][j];
        }
    }
    output
}

fn normalize(values: &mut [f64]) {
    let sum: f64 = values.iter().sum();
    if sum > 0.0 {
        for value in values {
            *value /= sum;
        }
    }
}
