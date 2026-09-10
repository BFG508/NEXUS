use std::fmt;
use std::io;

#[derive(Debug)]
pub enum AegisError {
    InvalidInput(String),
    Parse(String),
    Io(io::Error),
}

impl fmt::Display for AegisError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::InvalidInput(message) => write!(f, "invalid input: {message}"),
            Self::Parse(message) => write!(f, "parse error: {message}"),
            Self::Io(error) => write!(f, "I/O error: {error}"),
        }
    }
}

impl std::error::Error for AegisError {}

impl From<io::Error> for AegisError {
    fn from(value: io::Error) -> Self {
        Self::Io(value)
    }
}
