use std::time::Instant;

use aegis::models::{Architecture, Component, LifetimeModel, System};
use aegis::monte_carlo::simulate_mission;

fn main() {
    let system = System {
        name: "benchmark".to_string(),
        architecture: Architecture::KOutOfN { minimum_operational: 2 },
        components: (0..4)
            .map(|index| Component {
                id: format!("c{index}"),
                lifetime: LifetimeModel::Exponential {
                    failure_rate_per_hour: 1.0e-5 * (index as f64 + 1.0),
                },
                repair_rate_per_hour: None,
            })
            .collect(),
    };

    let runs = 250_000;
    let start = Instant::now();
    let result = simulate_mission(&system, 5_000.0, runs, 42).expect("benchmark simulation");
    let elapsed = start.elapsed();
    println!("runs={runs}");
    println!("probability={:.8}", result.probability);
    println!("elapsed_seconds={:.6}", elapsed.as_secs_f64());
    println!("runs_per_second={:.0}", runs as f64 / elapsed.as_secs_f64());
}
