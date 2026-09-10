use aegis::io::config::{parse_json_config, parse_toml_config};
use aegis::io::report::AnalysisReport;
use aegis::models::Architecture;
use aegis::io::json::{parse, JsonValue};

#[test]
fn json_decodes_surrogate_pairs() {
    assert_eq!(parse(r#""\uD83D\uDE80""#).unwrap(), JsonValue::String("🚀".into()));
    for text in [r#""\uD83D""#, r#""\uDE80""#, r#""\uD83D\u0041""#] {
        assert!(parse(text).is_err());
    }
}

#[test]
fn json_rejects_malformed_numbers_and_whitespace() {
    for text in ["01", "-01", "-.5", "00.5", "\u{000b}1", "1\u{000c}"] {
        assert!(parse(text).is_err(), "accepted {text:?}");
    }
    for text in ["0", "-0", "0.5", "1e+2", " \t\r\n1 "] {
        assert!(parse(text).is_ok(), "rejected {text:?}");
    }
}

const TOML: &str = r#"
name = "demo"
mission_hours = 1000.0
architecture = "k_out_of_n"
minimum_operational = 1
monte_carlo_runs = 2000
seed = 5

[[components]]
id = "a"
distribution = "exponential"
failure_rate_per_hour = 1e-5
repair_rate_per_hour = 1e-2

[[components]]
id = "b"
distribution = "weibull"
shape = 1.2
scale_hours = 90000.0
"#;

const JSON: &str = r#"{
  "name": "demo",
  "mission_hours": 1000.0,
  "architecture": "parallel",
  "monte_carlo_runs": 2000,
  "seed": 5,
  "components": [
    {"id":"a", "distribution":"exponential", "failure_rate_per_hour":1e-5}
  ]
}"#;

#[test]
fn toml_parser_builds_valid_config() {
    let config = parse_toml_config(TOML).unwrap();
    assert_eq!(config.system.components.len(), 2);
    assert_eq!(config.system.architecture, Architecture::KOutOfN { minimum_operational: 1 });
    assert_eq!(config.seed, 5);
}

#[test]
fn json_parser_builds_valid_config() {
    let config = parse_json_config(JSON).unwrap();
    assert_eq!(config.system.components.len(), 1);
    assert_eq!(config.system.architecture, Architecture::Parallel);
}

#[test]
fn report_is_machine_readable_json_shape() {
    let config = parse_toml_config(TOML).unwrap();
    let report = AnalysisReport::from_config(&config).unwrap().to_json_pretty();
    assert!(report.contains("\"schema\": \"aegis.analysis.v1\""));
    assert!(report.contains("\"system_reliability\""));
    assert!(report.contains("\"components\""));
}
