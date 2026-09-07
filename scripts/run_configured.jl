#!/usr/bin/env julia
using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))
using EDEN
using CSV
using TOML

length(ARGS) >= 1 || error("Usage: julia --project=. scripts/run_configured.jl CONFIG.toml [OUTPUT.csv]")
config_path = abspath(ARGS[1])
output_path = length(ARGS) >= 2 ? abspath(ARGS[2]) : joinpath(dirname(config_path), "eden_metrics.csv")
config = TOML.parsefile(config_path)
sim = get(config, "simulation", Dict{String,Any}())
fractions = get(config, "initial_doctrine_fractions", Dict{String,Any}())
required = ("Egoist", "Altruist", "Utilitarian", "StrictReciprocal")
all(haskey(fractions, name) for name in required) || error("initial_doctrine_fractions must define all four EDEN doctrines")

params = SimulationParameters(
    population_size = Int(get(sim, "population_size", 500)),
    initial_doctrine_fractions = Tuple(Float64(fractions[name]) for name in required),
    selection_intensity = Float64(get(sim, "selection_intensity", 1.0)),
    mutation_rate = Float64(get(sim, "mutation_rate", 0.002)),
    doctrine_mutation_rate = Float64(get(sim, "doctrine_mutation_rate", 0.0005)),
    interactions_per_agent = Int(get(sim, "interactions_per_agent", 8)),
    memory_capacity = Int(get(sim, "memory_capacity", 32)),
    seed = Int(get(sim, "seed", 42)),
)

generations = Int(get(sim, "generations", 500))
metrics, _ = run_simulation(params; generations = generations)
mkpath(dirname(output_path))
CSV.write(output_path, metrics)
println(output_path)
