use crate::error::AegisError;

pub fn reliability(failure_rate: f64, time: f64) -> Result<f64, AegisError> {
    if !failure_rate.is_finite() || failure_rate < 0.0 {
        return Err(AegisError::InvalidInput(
            "failure rate must be finite and non-negative".to_string(),
        ));
    }
    if !time.is_finite() || time < 0.0 {
        return Err(AegisError::InvalidInput(
            "time must be finite and non-negative".to_string(),
        ));
    }
    Ok((-failure_rate * time).exp())
}

pub fn mttf(failure_rate: f64) -> Result<f64, AegisError> {
    if !failure_rate.is_finite() || failure_rate <= 0.0 {
        return Err(AegisError::InvalidInput(
            "failure rate must be finite and strictly positive for finite MTTF".to_string(),
        ));
    }
    Ok(1.0 / failure_rate)
}
