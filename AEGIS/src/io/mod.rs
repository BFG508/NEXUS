pub mod config;
pub mod json;
pub mod report;

use std::fs;
use std::path::Path;

use crate::error::AegisError;

pub fn write_text(path: impl AsRef<Path>, text: &str) -> Result<(), AegisError> {
    let path = path.as_ref();
    if let Some(parent) = path.parent() {
        if !parent.as_os_str().is_empty() {
            fs::create_dir_all(parent)?;
        }
    }
    fs::write(path, text)?;
    Ok(())
}
