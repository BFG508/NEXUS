using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using CSV
using EDEN

function main()
    generations = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 2_000
    population_size = length(ARGS) >= 2 ? parse(Int, ARGS[2]) : 500
    seed = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 42

    params = SimulationParameters(
        population_size = population_size,
        carrying_capacity = population_size,
        initial_energy = 100.0,
        evolution_mode = BiologicalEvolution,
        death_energy = 0.0,
        reproduction_energy = 140.0,
        reproduction_cost = 50.0,
        reproduction_probability = 0.15,
        seed = seed,
    )
    metrics, _ = run_simulation(params; generations = generations)

    output_dir = joinpath(@__DIR__, "..", "results")
    mkpath(output_dir)
    output_file = joinpath(output_dir, "biological_seed_$(seed).csv")
    CSV.write(output_file, metrics)
    println(output_file)
end

main()
