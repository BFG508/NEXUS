using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using CSV
using EDEN

function main()
    params = SimulationParameters(population_size = 500, carrying_capacity = 500, spatial = false)
    metrics = run_ensemble(params; generations = 1_000, seeds = 1:20)
    summary = summarize_ensemble(metrics)

    output_dir = joinpath(@__DIR__, "..", "results")
    mkpath(output_dir)
    CSV.write(joinpath(output_dir, "ensemble.csv"), metrics)
    CSV.write(joinpath(output_dir, "ensemble_summary.csv"), summary)
    println(joinpath(output_dir, "ensemble_summary.csv"))
end

main()
