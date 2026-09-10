use std::collections::BTreeMap;
use std::fs;
use std::path::Path;

use crate::error::AegisError;
use crate::io::json::{self, JsonValue};
use crate::models::{Architecture, Component, LifetimeModel, System};

#[derive(Debug, Clone, PartialEq)]
pub struct AnalysisConfig {
    pub system: System,
    pub mission_hours: f64,
    pub monte_carlo_runs: u64,
    pub seed: u64,
}

impl AnalysisConfig {
    pub fn validate(&self) -> Result<(), AegisError> {
        self.system.validate()?;
        if !self.mission_hours.is_finite() || self.mission_hours < 0.0 {
            return Err(AegisError::InvalidInput(
                "mission_hours must be finite and non-negative".to_string(),
            ));
        }
        if self.monte_carlo_runs == 0 {
            return Err(AegisError::InvalidInput(
                "monte_carlo_runs must be positive".to_string(),
            ));
        }
        Ok(())
    }
}

pub fn load(path: impl AsRef<Path>) -> Result<AnalysisConfig, AegisError> {
    let path = path.as_ref();
    let text = fs::read_to_string(path)?;
    match path.extension().and_then(|ext| ext.to_str()).map(|ext| ext.to_ascii_lowercase()) {
        Some(ext) if ext == "json" => parse_json_config(&text),
        Some(ext) if ext == "toml" => parse_toml_config(&text),
        _ => {
            let trimmed = text.trim_start();
            if trimmed.starts_with('{') {
                parse_json_config(&text)
            } else {
                parse_toml_config(&text)
            }
        }
    }
}

pub fn parse_json_config(text: &str) -> Result<AnalysisConfig, AegisError> {
    let root = match json::parse(text)? {
        JsonValue::Object(value) => value,
        _ => return Err(AegisError::Parse("configuration root must be a JSON object".to_string())),
    };

    let name = required_string(&root, "name")?;
    let mission_hours = required_number(&root, "mission_hours")?;
    let architecture_name = required_string(&root, "architecture")?;
    let minimum_operational = optional_u64(&root, "minimum_operational")?.map(|v| v as usize);
    let monte_carlo_runs = optional_u64(&root, "monte_carlo_runs")?.unwrap_or(10_000);
    let seed = optional_u64(&root, "seed")?.unwrap_or(42);
    let architecture = architecture_from_fields(&architecture_name, minimum_operational)?;

    let components_value = root
        .get("components")
        .ok_or_else(|| AegisError::Parse("missing JSON field 'components'".to_string()))?;
    let components_array = match components_value {
        JsonValue::Array(value) => value,
        _ => return Err(AegisError::Parse("'components' must be a JSON array".to_string())),
    };
    let mut components = Vec::with_capacity(components_array.len());
    for (index, value) in components_array.iter().enumerate() {
        let object = match value {
            JsonValue::Object(value) => value,
            _ => return Err(AegisError::Parse(format!("component {index} must be a JSON object"))),
        };
        components.push(component_from_json(object, index)?);
    }

    let config = AnalysisConfig {
        system: System {
            name,
            architecture,
            components,
        },
        mission_hours,
        monte_carlo_runs,
        seed,
    };
    config.validate()?;
    Ok(config)
}

pub fn parse_toml_config(text: &str) -> Result<AnalysisConfig, AegisError> {
    let mut root = BTreeMap::<String, String>::new();
    let mut component_maps = Vec::<BTreeMap<String, String>>::new();
    let mut current_component: Option<BTreeMap<String, String>> = None;

    for (line_number, raw_line) in text.lines().enumerate() {
        let line = strip_comment(raw_line).trim();
        if line.is_empty() {
            continue;
        }
        if line == "[[components]]" {
            if let Some(component) = current_component.take() {
                component_maps.push(component);
            }
            current_component = Some(BTreeMap::new());
            continue;
        }
        if line.starts_with('[') {
            return Err(AegisError::Parse(format!(
                "unsupported TOML table at line {}: {line}",
                line_number + 1
            )));
        }
        let (key, value) = line.split_once('=').ok_or_else(|| {
            AegisError::Parse(format!("expected key = value at line {}", line_number + 1))
        })?;
        let key = key.trim().to_string();
        let value = value.trim().to_string();
        if key.is_empty() || value.is_empty() {
            return Err(AegisError::Parse(format!(
                "empty key or value at line {}",
                line_number + 1
            )));
        }
        if let Some(component) = current_component.as_mut() {
            component.insert(key, value);
        } else {
            root.insert(key, value);
        }
    }
    if let Some(component) = current_component.take() {
        component_maps.push(component);
    }

    let name = toml_required_string(&root, "name")?;
    let mission_hours = toml_required_f64(&root, "mission_hours")?;
    let architecture_name = toml_required_string(&root, "architecture")?;
    let minimum_operational = toml_optional_u64(&root, "minimum_operational")?.map(|v| v as usize);
    let monte_carlo_runs = toml_optional_u64(&root, "monte_carlo_runs")?.unwrap_or(10_000);
    let seed = toml_optional_u64(&root, "seed")?.unwrap_or(42);
    let architecture = architecture_from_fields(&architecture_name, minimum_operational)?;

    let mut components = Vec::with_capacity(component_maps.len());
    for (index, values) in component_maps.iter().enumerate() {
        components.push(component_from_toml(values, index)?);
    }

    let config = AnalysisConfig {
        system: System { name, architecture, components },
        mission_hours,
        monte_carlo_runs,
        seed,
    };
    config.validate()?;
    Ok(config)
}

fn component_from_json(
    object: &BTreeMap<String, JsonValue>,
    index: usize,
) -> Result<Component, AegisError> {
    let id = required_string(object, "id")?;
    let distribution = required_string(object, "distribution")?;
    let repair_rate_per_hour = optional_number(object, "repair_rate_per_hour")?;
    let lifetime = match distribution.as_str() {
        "exponential" => LifetimeModel::Exponential {
            failure_rate_per_hour: required_number(object, "failure_rate_per_hour")?,
        },
        "weibull" => LifetimeModel::Weibull {
            shape: required_number(object, "shape")?,
            scale_hours: required_number(object, "scale_hours")?,
        },
        other => {
            return Err(AegisError::Parse(format!(
                "component {index} has unsupported distribution '{other}'"
            )))
        }
    };
    Ok(Component { id, lifetime, repair_rate_per_hour })
}

fn component_from_toml(
    values: &BTreeMap<String, String>,
    index: usize,
) -> Result<Component, AegisError> {
    let id = toml_required_string(values, "id")?;
    let distribution = toml_required_string(values, "distribution")?;
    let repair_rate_per_hour = toml_optional_f64(values, "repair_rate_per_hour")?;
    let lifetime = match distribution.as_str() {
        "exponential" => LifetimeModel::Exponential {
            failure_rate_per_hour: toml_required_f64(values, "failure_rate_per_hour")?,
        },
        "weibull" => LifetimeModel::Weibull {
            shape: toml_required_f64(values, "shape")?,
            scale_hours: toml_required_f64(values, "scale_hours")?,
        },
        other => {
            return Err(AegisError::Parse(format!(
                "component {index} has unsupported distribution '{other}'"
            )))
        }
    };
    Ok(Component { id, lifetime, repair_rate_per_hour })
}

fn architecture_from_fields(name: &str, minimum_operational: Option<usize>) -> Result<Architecture, AegisError> {
    match name {
        "series" => Ok(Architecture::Series),
        "parallel" => Ok(Architecture::Parallel),
        "k_out_of_n" => Ok(Architecture::KOutOfN {
            minimum_operational: minimum_operational.ok_or_else(|| {
                AegisError::Parse("k_out_of_n requires minimum_operational".to_string())
            })?,
        }),
        other => Err(AegisError::Parse(format!(
            "unsupported architecture '{other}'"
        ))),
    }
}

fn required_string(object: &BTreeMap<String, JsonValue>, key: &str) -> Result<String, AegisError> {
    match object.get(key) {
        Some(JsonValue::String(value)) => Ok(value.clone()),
        Some(_) => Err(AegisError::Parse(format!("JSON field '{key}' must be a string"))),
        None => Err(AegisError::Parse(format!("missing JSON field '{key}'"))),
    }
}

fn required_number(object: &BTreeMap<String, JsonValue>, key: &str) -> Result<f64, AegisError> {
    match object.get(key) {
        Some(JsonValue::Number(value)) => Ok(*value),
        Some(_) => Err(AegisError::Parse(format!("JSON field '{key}' must be a number"))),
        None => Err(AegisError::Parse(format!("missing JSON field '{key}'"))),
    }
}

fn optional_number(object: &BTreeMap<String, JsonValue>, key: &str) -> Result<Option<f64>, AegisError> {
    match object.get(key) {
        Some(JsonValue::Number(value)) => Ok(Some(*value)),
        Some(JsonValue::Null) | None => Ok(None),
        Some(_) => Err(AegisError::Parse(format!("JSON field '{key}' must be a number or null"))),
    }
}

fn optional_u64(object: &BTreeMap<String, JsonValue>, key: &str) -> Result<Option<u64>, AegisError> {
    let value = match object.get(key) {
        Some(JsonValue::Number(value)) => *value,
        Some(JsonValue::Null) | None => return Ok(None),
        Some(_) => return Err(AegisError::Parse(format!("JSON field '{key}' must be an integer"))),
    };
    if value < 0.0 || value.fract() != 0.0 || value > u64::MAX as f64 {
        return Err(AegisError::Parse(format!("JSON field '{key}' must be a non-negative integer")));
    }
    Ok(Some(value as u64))
}

fn toml_required_string(values: &BTreeMap<String, String>, key: &str) -> Result<String, AegisError> {
    let raw = values.get(key).ok_or_else(|| AegisError::Parse(format!("missing TOML key '{key}'")))?;
    parse_toml_string(raw).ok_or_else(|| AegisError::Parse(format!("TOML key '{key}' must be a quoted string")))
}

fn toml_required_f64(values: &BTreeMap<String, String>, key: &str) -> Result<f64, AegisError> {
    let raw = values.get(key).ok_or_else(|| AegisError::Parse(format!("missing TOML key '{key}'")))?;
    parse_f64(raw, key)
}

fn toml_optional_f64(values: &BTreeMap<String, String>, key: &str) -> Result<Option<f64>, AegisError> {
    values.get(key).map(|raw| parse_f64(raw, key)).transpose()
}

fn toml_optional_u64(values: &BTreeMap<String, String>, key: &str) -> Result<Option<u64>, AegisError> {
    values
        .get(key)
        .map(|raw| {
            raw.replace('_', "")
                .parse::<u64>()
                .map_err(|_| AegisError::Parse(format!("TOML key '{key}' must be a non-negative integer")))
        })
        .transpose()
}

fn parse_toml_string(raw: &str) -> Option<String> {
    let trimmed = raw.trim();
    if trimmed.len() >= 2 && trimmed.starts_with('"') && trimmed.ends_with('"') {
        Some(trimmed[1..trimmed.len() - 1].replace("\\\"", "\"").replace("\\\\", "\\"))
    } else {
        None
    }
}

fn parse_f64(raw: &str, key: &str) -> Result<f64, AegisError> {
    let cleaned = raw.replace('_', "");
    let value = cleaned
        .parse::<f64>()
        .map_err(|_| AegisError::Parse(format!("TOML key '{key}' must be numeric")))?;
    if !value.is_finite() {
        return Err(AegisError::Parse(format!("TOML key '{key}' must be finite")));
    }
    Ok(value)
}

fn strip_comment(line: &str) -> &str {
    let mut quoted = false;
    let mut escaped = false;
    for (index, ch) in line.char_indices() {
        if escaped {
            escaped = false;
            continue;
        }
        if ch == '\\' && quoted {
            escaped = true;
            continue;
        }
        if ch == '"' {
            quoted = !quoted;
        } else if ch == '#' && !quoted {
            return &line[..index];
        }
    }
    line
}
