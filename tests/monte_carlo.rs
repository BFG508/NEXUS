use aegis::models::{Architecture, Component, LifetimeModel, System};
use aegis::monte_carlo::simulate_mission;

fn system() -> System {
    System {
        name: "single".to_string(),
        architecture: Architecture::Series,
        components: vec![Component {
            id: "c".to_string(),
            lifetime: LifetimeModel::Exponential { failure_rate_per_hour: 1e-3 },
            repair_rate_per_hour: None,
        }],
    }
}

#[test]
fn fixed_seed_is_reproducible() {
    let first = simulate_mission(&system(), 1000.0, 20_000, 7).unwrap();
    let second = simulate_mission(&system(), 1000.0, 20_000, 7).unwrap();
    assert_eq!(first, second);
}

#[test]
fn monte_carlo_agrees_with_analytic_within_sampling_tolerance() {
    let system = system();
    let analytic = system.reliability(1000.0).unwrap();
    let result = simulate_mission(&system, 1000.0, 100_000, 123).unwrap();
    assert!((result.probability - analytic).abs() < 0.01);
    assert!(result.ci95_lower <= result.probability);
    assert!(result.probability <= result.ci95_upper);
}
