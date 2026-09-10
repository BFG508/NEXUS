use std::env;
use std::path::{Path, PathBuf};
use std::process;

use aegis::error::AegisError;
use aegis::fault_tree::FaultTreeNode;
use aegis::io::config;
use aegis::io::report::{monte_carlo_json, AnalysisReport};
use aegis::markov::Ctmc;
use aegis::monte_carlo::simulate_mission;
use aegis::io::write_text;

fn main() {
    if let Err(error) = run() {
        eprintln!("AEGIS error: {error}");
        process::exit(1);
    }
}

fn run() -> Result<(), AegisError> {
    let args = env::args().skip(1).collect::<Vec<_>>();
    let command = args.first().map(String::as_str).unwrap_or("help");
    match command {
        "help" | "--help" | "-h" => {
            print_help();
            Ok(())
        }
        "version" | "--version" | "-V" => {
            println!("{}", aegis::VERSION);
            Ok(())
        }
        "validate" => command_validate(&args[1..]),
        "analyze" => command_analyze(&args[1..]),
        "monte-carlo" => command_monte_carlo(&args[1..]),
        "demo" => command_demo(),
        other => Err(AegisError::InvalidInput(format!(
            "unknown command '{other}'; run 'aegis help'"
        ))),
    }
}

fn command_validate(args: &[String]) -> Result<(), AegisError> {
    if args.len() != 1 {
        return Err(AegisError::InvalidInput(
            "usage: aegis validate <config.toml|config.json>".to_string(),
        ));
    }
    let config = config::load(&args[0])?;
    config.validate()?;
    println!("valid: {} ({} components)", config.system.name, config.system.components.len());
    Ok(())
}

fn command_analyze(args: &[String]) -> Result<(), AegisError> {
    if args.is_empty() {
        return Err(AegisError::InvalidInput(
            "usage: aegis analyze <config> [--output PATH]".to_string(),
        ));
    }
    let config = config::load(&args[0])?;
    let output = parse_output_option(&args[1..])?;
    let report = AnalysisReport::from_config(&config)?;
    emit(&report.to_json_pretty(), output.as_deref())
}

fn command_monte_carlo(args: &[String]) -> Result<(), AegisError> {
    if args.is_empty() {
        return Err(AegisError::InvalidInput(
            "usage: aegis monte-carlo <config> [--runs N] [--seed N] [--output PATH]".to_string(),
        ));
    }
    let config = config::load(&args[0])?;
    let mut runs = config.monte_carlo_runs;
    let mut seed = config.seed;
    let mut output = None::<PathBuf>;
    let mut index = 1;
    while index < args.len() {
        match args[index].as_str() {
            "--runs" => {
                index += 1;
                let value = args.get(index).ok_or_else(|| {
                    AegisError::InvalidInput("--runs requires an integer".to_string())
                })?;
                runs = value.parse::<u64>().map_err(|_| {
                    AegisError::InvalidInput("--runs requires a positive integer".to_string())
                })?;
            }
            "--seed" => {
                index += 1;
                let value = args.get(index).ok_or_else(|| {
                    AegisError::InvalidInput("--seed requires an integer".to_string())
                })?;
                seed = value.parse::<u64>().map_err(|_| {
                    AegisError::InvalidInput("--seed requires a non-negative integer".to_string())
                })?;
            }
            "--output" => {
                index += 1;
                let value = args.get(index).ok_or_else(|| {
                    AegisError::InvalidInput("--output requires a path".to_string())
                })?;
                output = Some(PathBuf::from(value));
            }
            other => {
                return Err(AegisError::InvalidInput(format!(
                    "unknown monte-carlo option '{other}'"
                )))
            }
        }
        index += 1;
    }
    let analytic = config.system.reliability(config.mission_hours)?;
    let summary = simulate_mission(&config.system, config.mission_hours, runs, seed)?;
    let json = monte_carlo_json(&config, &summary, analytic);
    emit(&json, output.as_deref())
}

fn command_demo() -> Result<(), AegisError> {
    let fault_tree = FaultTreeNode::Or(vec![
        FaultTreeNode::BasicEvent {
            id: "power_bus".to_string(),
            probability: 0.01,
        },
        FaultTreeNode::And(vec![
            FaultTreeNode::BasicEvent {
                id: "computer_a".to_string(),
                probability: 0.02,
            },
            FaultTreeNode::BasicEvent {
                id: "computer_b".to_string(),
                probability: 0.02,
            },
        ]),
    ]);
    let lambda = 1.0e-4;
    let mu = 1.0e-2;
    let markov = Ctmc::new(vec![vec![-lambda, lambda], vec![mu, -mu]])?;
    let steady = markov.steady_state(1.0e-12, 200_000)?;
    println!("fault_tree_top_probability={:.8}", fault_tree.evaluate()?);
    println!("markov_operational_steady_state={:.8}", steady[0]);
    Ok(())
}

fn parse_output_option(args: &[String]) -> Result<Option<PathBuf>, AegisError> {
    if args.is_empty() {
        return Ok(None);
    }
    if args.len() == 2 && args[0] == "--output" {
        return Ok(Some(PathBuf::from(&args[1])));
    }
    Err(AegisError::InvalidInput(
        "usage: aegis analyze <config> [--output PATH]".to_string(),
    ))
}

fn emit(text: &str, output: Option<&Path>) -> Result<(), AegisError> {
    if let Some(path) = output {
        write_text(path, text)?;
        println!("{}", path.display());
    } else {
        print!("{text}");
    }
    Ok(())
}

fn print_help() {
    println!("AEGIS {}", aegis::VERSION);
    println!("Reliability, availability and survivability analysis engine");
    println!();
    println!("USAGE:");
    println!("  aegis version");
    println!("  aegis validate <config.toml|config.json>");
    println!("  aegis analyze <config> [--output PATH]");
    println!("  aegis monte-carlo <config> [--runs N] [--seed N] [--output PATH]");
    println!("  aegis demo");
}
