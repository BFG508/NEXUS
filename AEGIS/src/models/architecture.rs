use crate::error::AegisError;
use crate::reliability::system::{k_out_of_n, parallel, series};

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Architecture {
    Series,
    Parallel,
    KOutOfN { minimum_operational: usize },
}

impl Architecture {
    pub fn probability(&self, probabilities: &[f64]) -> Result<f64, AegisError> {
        match self {
            Self::Series => series(probabilities),
            Self::Parallel => parallel(probabilities),
            Self::KOutOfN { minimum_operational } => {
                k_out_of_n(probabilities, *minimum_operational)
            }
        }
    }

    pub fn is_operational(&self, operational: &[bool]) -> Result<bool, AegisError> {
        if operational.is_empty() {
            return Err(AegisError::InvalidInput(
                "architecture requires at least one component".to_string(),
            ));
        }
        let count = operational.iter().filter(|state| **state).count();
        Ok(match self {
            Self::Series => count == operational.len(),
            Self::Parallel => count >= 1,
            Self::KOutOfN { minimum_operational } => {
                if *minimum_operational == 0 || *minimum_operational > operational.len() {
                    return Err(AegisError::InvalidInput(format!(
                        "minimum_operational must be in 1..={}",
                        operational.len()
                    )));
                }
                count >= *minimum_operational
            }
        })
    }

    pub fn label(&self) -> String {
        match self {
            Self::Series => "series".to_string(),
            Self::Parallel => "parallel".to_string(),
            Self::KOutOfN { minimum_operational } => format!("{minimum_operational}-out-of-n"),
        }
    }
}
