use crate::error::AegisError;

pub fn series(probabilities: &[f64]) -> Result<f64, AegisError> {
    validate_probabilities(probabilities)?;
    Ok(probabilities.iter().copied().product())
}

pub fn parallel(probabilities: &[f64]) -> Result<f64, AegisError> {
    validate_probabilities(probabilities)?;
    Ok(1.0 - probabilities.iter().map(|p| 1.0 - p).product::<f64>())
}

pub fn k_out_of_n(probabilities: &[f64], minimum_operational: usize) -> Result<f64, AegisError> {
    validate_probabilities(probabilities)?;
    let n = probabilities.len();
    if n == 0 {
        return Err(AegisError::InvalidInput(
            "k-out-of-n architecture requires at least one component".to_string(),
        ));
    }
    if minimum_operational == 0 || minimum_operational > n {
        return Err(AegisError::InvalidInput(format!(
            "minimum_operational must be in 1..={n}"
        )));
    }

    // dp[j] = probability of exactly j operational components after the
    // components processed so far. This supports heterogeneous probabilities.
    let mut dp = vec![0.0; n + 1];
    dp[0] = 1.0;
    for &p in probabilities {
        let mut next = vec![0.0; n + 1];
        for j in 0..n {
            if dp[j] == 0.0 {
                continue;
            }
            next[j] += dp[j] * (1.0 - p);
            next[j + 1] += dp[j] * p;
        }
        dp = next;
    }
    Ok(dp[minimum_operational..].iter().sum())
}

pub fn validate_probabilities(probabilities: &[f64]) -> Result<(), AegisError> {
    if probabilities.is_empty() {
        return Err(AegisError::InvalidInput(
            "system architecture requires at least one probability".to_string(),
        ));
    }
    for &p in probabilities {
        if !p.is_finite() || !(0.0..=1.0).contains(&p) {
            return Err(AegisError::InvalidInput(
                "probabilities must be finite and in [0, 1]".to_string(),
            ));
        }
    }
    Ok(())
}
