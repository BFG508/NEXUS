use aegis::models::{Architecture, Component, LifetimeModel, System};
use aegis::reliability::{availability, exponential, system, weibull};

fn close(a: f64, b: f64, tolerance: f64) {
    assert!((a - b).abs() <= tolerance, "{a} != {b}");
}

#[test]
fn exponential_matches_closed_form() {
    close(exponential::reliability(0.001, 1000.0).unwrap(), (-1.0_f64).exp(), 1e-14);
    close(exponential::mttf(0.001).unwrap(), 1000.0, 1e-12);
}

#[test]
fn weibull_shape_one_reduces_to_exponential() {
    close(weibull::reliability(1.0, 1000.0, 500.0).unwrap(), (-0.5_f64).exp(), 1e-14);
    close(weibull::mttf(1.0, 1000.0).unwrap(), 1000.0, 1e-9);
}

#[test]
fn system_architectures_are_correct() {
    let values = [0.9, 0.8, 0.7];
    close(system::series(&values).unwrap(), 0.504, 1e-14);
    close(system::parallel(&values).unwrap(), 0.994, 1e-14);
    // Exactly 2 or 3 working: 0.9*0.8*0.3 + 0.9*0.2*0.7 + 0.1*0.8*0.7 + 0.9*0.8*0.7
    close(system::k_out_of_n(&values, 2).unwrap(), 0.902, 1e-14);
}

#[test]
fn repairable_availability_matches_two_state_result() {
    close(availability::steady_state(1e-4, 1e-2).unwrap(), 1e-2 / 1.01e-2, 1e-14);
}

#[test]
fn mixed_distribution_system_reports_no_steady_state_availability() {
    let system = System {
        name: "mixed".to_string(),
        architecture: Architecture::Series,
        components: vec![
            Component {
                id: "a".to_string(),
                lifetime: LifetimeModel::Exponential { failure_rate_per_hour: 1e-5 },
                repair_rate_per_hour: Some(1e-2),
            },
            Component {
                id: "b".to_string(),
                lifetime: LifetimeModel::Weibull { shape: 1.5, scale_hours: 100_000.0 },
                repair_rate_per_hour: None,
            },
        ],
    };
    assert_eq!(system.steady_state_availability().unwrap(), None);
}
