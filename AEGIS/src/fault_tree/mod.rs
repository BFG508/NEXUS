use crate::error::AegisError;
use std::collections::HashSet;

#[derive(Debug, Clone, PartialEq)]
pub enum FaultTreeNode {
    BasicEvent { id: String, probability: f64 },
    And(Vec<FaultTreeNode>),
    Or(Vec<FaultTreeNode>),
}

impl FaultTreeNode {
    pub fn evaluate(&self) -> Result<f64, AegisError> {
        self.evaluate_unique(&mut HashSet::new())
    }

    fn evaluate_unique<'a>(&'a self, events: &mut HashSet<&'a str>) -> Result<f64, AegisError> {
        match self {
            Self::BasicEvent { id, probability } => {
                if id.trim().is_empty() {
                    return Err(AegisError::InvalidInput(
                        "fault-tree event id cannot be empty".to_string(),
                    ));
                }
                validate_probability(*probability)?;
                if !events.insert(id.as_str()) {
                    return Err(AegisError::InvalidInput(format!(
                        "repeated fault-tree event {id:?} violates the independent-event model"
                    )));
                }
                Ok(*probability)
            }
            Self::And(children) => {
                if children.is_empty() {
                    return Err(AegisError::InvalidInput(
                        "AND gate must have at least one child".to_string(),
                    ));
                }
                let mut result = 1.0;
                for child in children {
                    result *= child.evaluate_unique(events)?;
                }
                Ok(result)
            }
            Self::Or(children) => {
                if children.is_empty() {
                    return Err(AegisError::InvalidInput(
                        "OR gate must have at least one child".to_string(),
                    ));
                }
                let mut complement = 1.0;
                for child in children {
                    complement *= 1.0 - child.evaluate_unique(events)?;
                }
                Ok(1.0 - complement)
            }
        }
    }
}

fn validate_probability(probability: f64) -> Result<(), AegisError> {
    if !probability.is_finite() || !(0.0..=1.0).contains(&probability) {
        return Err(AegisError::InvalidInput(
            "fault-tree probabilities must be finite and in [0, 1]".to_string(),
        ));
    }
    Ok(())
}
