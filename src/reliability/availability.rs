use crate::error::AegisError;

pub fn steady_state(failure_rate: f64, repair_rate: f64) -> Result<f64, AegisError> {
    if !failure_rate.is_finite() || failure_rate < 0.0 {
        return Err(AegisError::InvalidInput(
            "failure rate must be finite and non-negative".to_string(),
        ));
    }
    if !repair_rate.is_finite() || repair_rate < 0.0 {
        return Err(AegisError::InvalidInput(
            "repair rate must be finite and non-negative".to_string(),
        ));
    }
    let denominator = failure_rate + repair_rate;
    if denominator == 0.0 {
        return Ok(1.0);
    }
    Ok(repair_rate / denominator)
}
