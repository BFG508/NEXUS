use aegis::models::{Architecture, Component, LifetimeModel, System};
use aegis::reliability::{exponential, system, weibull};

#[test]
fn invalid_numeric_inputs_are_rejected() {
    assert!(exponential::reliability(-1.0, 1.0).is_err());
    assert!(exponential::reliability(1.0, -1.0).is_err());
    assert!(weibull::reliability(0.0, 1.0, 1.0).is_err());
    assert!(system::series(&[]).is_err());
    assert!(system::k_out_of_n(&[0.9, 0.8], 0).is_err());
    assert!(system::k_out_of_n(&[0.9, 0.8], 3).is_err());
}

#[test]
fn duplicate_component_ids_are_rejected() {
    let component = Component {
        id: "same".to_string(),
        lifetime: LifetimeModel::Exponential { failure_rate_per_hour: 1e-5 },
        repair_rate_per_hour: None,
    };
    let system = System {
        name: "bad".to_string(),
        architecture: Architecture::Series,
        components: vec![component.clone(), component],
    };
    assert!(system.validate().is_err());
}
