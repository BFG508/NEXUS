using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using CSV
using EDEN

function main()
    params = SimulationParameters(
        population_size = 500,
        carrying_capacity = 500,
        update_mode = SynchronousUpdate,
        evolution_mode = CulturalEvolution,
    )
    ensemble = run_ensemble(params; generations = 1_000, seeds = 1:50)
    summary = summarize_ensemble(ensemble)

    output_dir = joinpath(@__DIR__, "..", "results")
    mkpath(output_dir)
    CSV.write(joinpath(output_dir, "uncertainty_raw.csv"), ensemble)
    CSV.write(joinpath(output_dir, "uncertainty_summary.csv"), summary)
    println(joinpath(output_dir, "uncertainty_summary.csv"))
end

main()
