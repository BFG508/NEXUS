use std::collections::HashSet;

use crate::error::AegisError;
use crate::models::{Architecture, Component};

#[derive(Debug, Clone, PartialEq)]
pub struct System {
    pub name: String,
    pub architecture: Architecture,
    pub components: Vec<Component>,
}

impl System {
    pub fn validate(&self) -> Result<(), AegisError> {
        if self.name.trim().is_empty() {
            return Err(AegisError::InvalidInput(
                "system name cannot be empty".to_string(),
            ));
        }
        if self.components.is_empty() {
            return Err(AegisError::InvalidInput(
                "system must contain at least one component".to_string(),
            ));
        }
        let mut ids = HashSet::new();
        for component in &self.components {
            component.validate()?;
            if !ids.insert(component.id.as_str()) {
                return Err(AegisError::InvalidInput(format!(
                    "duplicate component id: {}",
                    component.id
                )));
            }
        }
        if let Architecture::KOutOfN { minimum_operational } = &self.architecture {
            if *minimum_operational == 0 || *minimum_operational > self.components.len() {
                return Err(AegisError::InvalidInput(format!(
                    "minimum_operational must be in 1..={}",
                    self.components.len()
                )));
            }
        }
        Ok(())
    }

    pub fn reliability(&self, time_hours: f64) -> Result<f64, AegisError> {
        self.validate()?;
        let values = self
            .components
            .iter()
            .map(|component| component.reliability(time_hours))
            .collect::<Result<Vec<_>, _>>()?;
        self.architecture.probability(&values)
    }

    pub fn steady_state_availability(&self) -> Result<Option<f64>, AegisError> {
        self.validate()?;
        let mut values = Vec::with_capacity(self.components.len());
        for component in &self.components {
            match component.steady_state_availability()? {
                Some(value) => values.push(value),
                None => return Ok(None),
            }
        }
        Ok(Some(self.architecture.probability(&values)?))
    }
}
