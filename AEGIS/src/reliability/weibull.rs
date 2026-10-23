use crate::error::AegisError;

pub fn reliability(shape: f64, scale: f64, time: f64) -> Result<f64, AegisError> {
    validate(shape, scale, time)?;
    Ok((-(time / scale).powf(shape)).exp())
}

pub fn mttf(shape: f64, scale: f64) -> Result<f64, AegisError> {
    if !shape.is_finite() || shape <= 0.0 {
        return Err(AegisError::InvalidInput(
            "Weibull shape must be finite and strictly positive".to_string(),
        ));
    }
    if !scale.is_finite() || scale <= 0.0 {
        return Err(AegisError::InvalidInput(
            "Weibull scale must be finite and strictly positive".to_string(),
        ));
    }
    Ok(scale * gamma(1.0 + 1.0 / shape))
}

fn validate(shape: f64, scale: f64, time: f64) -> Result<(), AegisError> {
    if !shape.is_finite() || shape <= 0.0 {
        return Err(AegisError::InvalidInput(
            "Weibull shape must be finite and strictly positive".to_string(),
        ));
    }
    if !scale.is_finite() || scale <= 0.0 {
        return Err(AegisError::InvalidInput(
            "Weibull scale must be finite and strictly positive".to_string(),
        ));
    }
    if !time.is_finite() || time < 0.0 {
        return Err(AegisError::InvalidInput(
            "time must be finite and non-negative".to_string(),
        ));
    }
    Ok(())
}

// Lanczos approximation for positive arguments. The v0.1.0 Weibull MTTF
// calls gamma only for x > 1, but reflection is included for completeness.
fn gamma(z: f64) -> f64 {
    const COEFFS: [f64; 9] = [
        0.999_999_999_999_809_9,
        676.520_368_121_885_1,
        -1_259.139_216_722_402_8,
        771.323_428_777_653_1,
        -176.615_029_162_140_6,
        12.507_343_278_686_905,
        -0.138_571_095_265_720_12,
        9.984_369_578_019_572e-6,
        1.505_632_735_149_311_6e-7,
    ];

    if z < 0.5 {
        std::f64::consts::PI / ((std::f64::consts::PI * z).sin() * gamma(1.0 - z))
    } else {
        let shifted = z - 1.0;
        let mut x = COEFFS[0];
        for (index, coefficient) in COEFFS.iter().enumerate().skip(1) {
            x += coefficient / (shifted + index as f64);
        }
        let t = shifted + 7.5;
        (2.0 * std::f64::consts::PI).sqrt() * t.powf(shifted + 0.5) * (-t).exp() * x
    }
}
