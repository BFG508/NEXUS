use crate::error::AegisError;
use crate::models::LifetimeModel;
use crate::reliability::availability;

#[derive(Debug, Clone, PartialEq)]
pub struct Component {
    pub id: String,
    pub lifetime: LifetimeModel,
    pub repair_rate_per_hour: Option<f64>,
}

impl Component {
    pub fn validate(&self) -> Result<(), AegisError> {
        if self.id.trim().is_empty() {
            return Err(AegisError::InvalidInput(
                "component id cannot be empty".to_string(),
            ));
        }
        self.lifetime.validate()?;
        if let Some(rate) = self.repair_rate_per_hour {
            if !rate.is_finite() || rate < 0.0 {
                return Err(AegisError::InvalidInput(format!(
                    "component {} has invalid repair rate",
                    self.id
                )));
            }
        }
        Ok(())
    }

    pub fn reliability(&self, time_hours: f64) -> Result<f64, AegisError> {
        self.lifetime.reliability(time_hours)
    }

    pub fn mttf_hours(&self) -> Result<f64, AegisError> {
        self.lifetime.mttf_hours()
    }

    pub fn steady_state_availability(&self) -> Result<Option<f64>, AegisError> {
        match (&self.lifetime, self.repair_rate_per_hour) {
            (
                LifetimeModel::Exponential {
                    failure_rate_per_hour,
                },
                Some(repair_rate),
            ) => Ok(Some(availability::steady_state(
                *failure_rate_per_hour,
                repair_rate,
            )?)),
            _ => Ok(None),
        }
    }
}
