using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using CSV
using EDEN

function main()
    params = SimulationParameters(
        population_size = 400,
        carrying_capacity = 400,
        spatial = true,
        grid_size = (40, 40),
        neighborhood_radius = 2,
        move_agents = true,
        update_mode = SynchronousUpdate,
        evolution_mode = CulturalEvolution,
        seed = 42,
    )
    metrics, _ = run_simulation(params; generations = 1_000)

    output_dir = joinpath(@__DIR__, "..", "results")
    mkpath(output_dir)
    output_file = joinpath(output_dir, "spatial_seed_42.csv")
    CSV.write(output_file, metrics)
    println(output_file)
end

main()
