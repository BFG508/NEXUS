use crate::error::AegisError;
use crate::models::{LifetimeModel, System};

#[derive(Debug, Clone, PartialEq)]
pub struct MonteCarloSummary {
    pub runs: u64,
    pub survived: u64,
    pub seed: u64,
    pub probability: f64,
    pub standard_error: f64,
    pub ci95_lower: f64,
    pub ci95_upper: f64,
}

pub fn simulate_mission(
    system: &System,
    mission_hours: f64,
    runs: u64,
    seed: u64,
) -> Result<MonteCarloSummary, AegisError> {
    system.validate()?;
    if !mission_hours.is_finite() || mission_hours < 0.0 {
        return Err(AegisError::InvalidInput(
            "mission_hours must be finite and non-negative".to_string(),
        ));
    }
    if runs == 0 {
        return Err(AegisError::InvalidInput(
            "Monte Carlo runs must be positive".to_string(),
        ));
    }

    let mut rng = SplitMix64::new(seed);
    let mut survived = 0_u64;
    let mut states = vec![false; system.components.len()];

    for _ in 0..runs {
        for (state, component) in states.iter_mut().zip(system.components.iter()) {
            let failure_time = sample_failure_time(&component.lifetime, &mut rng)?;
            *state = failure_time > mission_hours;
        }
        if system.architecture.is_operational(&states)? {
            survived += 1;
        }
    }

    let probability = survived as f64 / runs as f64;
    let standard_error = (probability * (1.0 - probability) / runs as f64).sqrt();
    let (ci95_lower, ci95_upper) = wilson_interval(survived, runs, 1.959_963_984_540_054);

    Ok(MonteCarloSummary {
        runs,
        survived,
        seed,
        probability,
        standard_error,
        ci95_lower,
        ci95_upper,
    })
}

fn sample_failure_time(model: &LifetimeModel, rng: &mut SplitMix64) -> Result<f64, AegisError> {
    let u = rng.open_unit_interval();
    match model {
        LifetimeModel::Exponential {
            failure_rate_per_hour,
        } => {
            if !failure_rate_per_hour.is_finite() || *failure_rate_per_hour <= 0.0 {
                return Err(AegisError::InvalidInput(
                    "exponential failure rate must be finite and > 0".to_string(),
                ));
            }
            Ok(-u.ln() / failure_rate_per_hour)
        }
        LifetimeModel::Weibull { shape, scale_hours } => {
            if !shape.is_finite() || *shape <= 0.0 || !scale_hours.is_finite() || *scale_hours <= 0.0 {
                return Err(AegisError::InvalidInput(
                    "Weibull shape and scale must be finite and > 0".to_string(),
                ));
            }
            Ok(scale_hours * (-u.ln()).powf(1.0 / shape))
        }
    }
}

fn wilson_interval(successes: u64, trials: u64, z: f64) -> (f64, f64) {
    let n = trials as f64;
    let p = successes as f64 / n;
    let z2 = z * z;
    let denominator = 1.0 + z2 / n;
    let center = (p + z2 / (2.0 * n)) / denominator;
    let half = z * ((p * (1.0 - p) / n + z2 / (4.0 * n * n)).sqrt()) / denominator;
    ((center - half).max(0.0), (center + half).min(1.0))
}

#[derive(Debug, Clone)]
struct SplitMix64 {
    state: u64,
}

impl SplitMix64 {
    fn new(seed: u64) -> Self {
        Self { state: seed }
    }

    fn next_u64(&mut self) -> u64 {
        self.state = self.state.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }

    fn open_unit_interval(&mut self) -> f64 {
        // 53 random bits mapped strictly inside (0, 1), avoiding ln(0).
        let bits = self.next_u64() >> 11;
        (bits as f64 + 0.5) * (1.0 / 9_007_199_254_740_992.0)
    }
}
