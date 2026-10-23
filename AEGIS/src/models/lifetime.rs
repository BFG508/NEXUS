use crate::error::AegisError;
use crate::reliability::{exponential, weibull};

#[derive(Debug, Clone, PartialEq)]
pub enum LifetimeModel {
    Exponential { failure_rate_per_hour: f64 },
    Weibull { shape: f64, scale_hours: f64 },
}

impl LifetimeModel {
    pub fn reliability(&self, time_hours: f64) -> Result<f64, AegisError> {
        match self {
            Self::Exponential { failure_rate_per_hour } => {
                exponential::reliability(*failure_rate_per_hour, time_hours)
            }
            Self::Weibull { shape, scale_hours } => {
                weibull::reliability(*shape, *scale_hours, time_hours)
            }
        }
    }

    pub fn mttf_hours(&self) -> Result<f64, AegisError> {
        match self {
            Self::Exponential { failure_rate_per_hour } => {
                exponential::mttf(*failure_rate_per_hour)
            }
            Self::Weibull { shape, scale_hours } => weibull::mttf(*shape, *scale_hours),
        }
    }

    pub fn validate(&self) -> Result<(), AegisError> {
        match self {
            Self::Exponential { failure_rate_per_hour } => {
                if !failure_rate_per_hour.is_finite() || *failure_rate_per_hour <= 0.0 {
                    return Err(AegisError::InvalidInput(
                        "exponential failure_rate_per_hour must be finite and > 0".to_string(),
                    ));
                }
            }
            Self::Weibull { shape, scale_hours } => {
                if !shape.is_finite() || *shape <= 0.0 {
                    return Err(AegisError::InvalidInput(
                        "Weibull shape must be finite and > 0".to_string(),
                    ));
                }
                if !scale_hours.is_finite() || *scale_hours <= 0.0 {
                    return Err(AegisError::InvalidInput(
                        "Weibull scale_hours must be finite and > 0".to_string(),
                    ));
                }
            }
        }
        Ok(())
    }

    pub fn kind(&self) -> &'static str {
        match self {
            Self::Exponential { .. } => "exponential",
            Self::Weibull { .. } => "weibull",
        }
    }
}
