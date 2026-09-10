use crate::error::AegisError;
use crate::io::config::AnalysisConfig;
use crate::io::json::escape_string;
use crate::monte_carlo::MonteCarloSummary;
use crate::VERSION;

#[derive(Debug, Clone, PartialEq)]
pub struct ComponentReport {
    pub id: String,
    pub distribution: String,
    pub reliability: f64,
    pub mttf_hours: f64,
    pub steady_state_availability: Option<f64>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct AnalysisReport {
    pub system_name: String,
    pub mission_hours: f64,
    pub architecture: String,
    pub system_reliability: f64,
    pub system_steady_state_availability: Option<f64>,
    pub components: Vec<ComponentReport>,
}

impl AnalysisReport {
    pub fn from_config(config: &AnalysisConfig) -> Result<Self, AegisError> {
        config.validate()?;
        let system_reliability = config.system.reliability(config.mission_hours)?;
        let system_steady_state_availability = config.system.steady_state_availability()?;
        let mut components = Vec::with_capacity(config.system.components.len());
        for component in &config.system.components {
            components.push(ComponentReport {
                id: component.id.clone(),
                distribution: component.lifetime.kind().to_string(),
                reliability: component.reliability(config.mission_hours)?,
                mttf_hours: component.mttf_hours()?,
                steady_state_availability: component.steady_state_availability()?,
            });
        }
        Ok(Self {
            system_name: config.system.name.clone(),
            mission_hours: config.mission_hours,
            architecture: config.system.architecture.label(),
            system_reliability,
            system_steady_state_availability,
            components,
        })
    }

    pub fn to_json_pretty(&self) -> String {
        let mut out = String::new();
        out.push_str("{\n");
        out.push_str("  \"schema\": \"aegis.analysis.v1\",\n");
        out.push_str(&format!("  \"aegis_version\": {},\n", escape_string(VERSION)));
        out.push_str(&format!("  \"system_name\": {},\n", escape_string(&self.system_name)));
        out.push_str(&format!("  \"mission_hours\": {:.17},\n", self.mission_hours));
        out.push_str(&format!("  \"architecture\": {},\n", escape_string(&self.architecture)));
        out.push_str(&format!("  \"system_reliability\": {:.17},\n", self.system_reliability));
        out.push_str("  \"system_steady_state_availability\": ");
        push_optional_number(&mut out, self.system_steady_state_availability);
        out.push_str(",\n  \"components\": [\n");
        for (index, component) in self.components.iter().enumerate() {
            out.push_str("    {\n");
            out.push_str(&format!("      \"id\": {},\n", escape_string(&component.id)));
            out.push_str(&format!("      \"distribution\": {},\n", escape_string(&component.distribution)));
            out.push_str(&format!("      \"reliability\": {:.17},\n", component.reliability));
            out.push_str(&format!("      \"mttf_hours\": {:.17},\n", component.mttf_hours));
            out.push_str("      \"steady_state_availability\": ");
            push_optional_number(&mut out, component.steady_state_availability);
            out.push_str("\n    }");
            if index + 1 != self.components.len() {
                out.push(',');
            }
            out.push('\n');
        }
        out.push_str("  ]\n}\n");
        out
    }
}

pub fn monte_carlo_json(
    config: &AnalysisConfig,
    summary: &MonteCarloSummary,
    analytic_reliability: f64,
) -> String {
    format!(
        concat!(
            "{{\n",
            "  \"schema\": \"aegis.monte_carlo.v1\",\n",
            "  \"aegis_version\": {},\n",
            "  \"system_name\": {},\n",
            "  \"mission_hours\": {:.17},\n",
            "  \"architecture\": {},\n",
            "  \"runs\": {},\n",
            "  \"survived\": {},\n",
            "  \"seed\": {},\n",
            "  \"survival_probability\": {:.17},\n",
            "  \"standard_error\": {:.17},\n",
            "  \"ci95_lower\": {:.17},\n",
            "  \"ci95_upper\": {:.17},\n",
            "  \"analytic_reliability\": {:.17}\n",
            "}}\n"
        ),
        escape_string(VERSION),
        escape_string(&config.system.name),
        config.mission_hours,
        escape_string(&config.system.architecture.label()),
        summary.runs,
        summary.survived,
        summary.seed,
        summary.probability,
        summary.standard_error,
        summary.ci95_lower,
        summary.ci95_upper,
        analytic_reliability,
    )
}

fn push_optional_number(output: &mut String, value: Option<f64>) {
    match value {
        Some(number) => output.push_str(&format!("{number:.17}")),
        None => output.push_str("null"),
    }
}
