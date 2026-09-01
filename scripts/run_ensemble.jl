using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using CSV
using EDEN

function main()
    params = SimulationParameters(population_size = 500, spatial = false)
    metrics = run_ensemble(params; generations = 1_000, seeds = 1:20)

    output_dir = joinpath(@__DIR__, "..", "results")
    mkpath(output_dir)
    output_file = joinpath(output_dir, "ensemble.csv")
    CSV.write(output_file, metrics)
    println(output_file)
end

main()
