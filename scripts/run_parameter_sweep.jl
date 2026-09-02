using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using CSV
using DataFrames
using EDEN

function main()
    selection_values = (0.1, 0.5, 1.0, 2.0, 5.0)
    mutation_values = (0.0, 0.001, 0.005, 0.01)
    all_results = DataFrame[]

    for beta in selection_values, mutation_rate in mutation_values
        params = SimulationParameters(
            population_size = 500,
            carrying_capacity = 500,
            selection_intensity = beta,
            mutation_rate = mutation_rate,
            spatial = false,
        )
        metrics = run_ensemble(params; generations = 500, seeds = 1:10)
        metrics.selection_intensity = fill(beta, nrow(metrics))
        metrics.mutation_rate = fill(mutation_rate, nrow(metrics))
        push!(all_results, metrics)
    end

    output = vcat(all_results...)
    output_dir = joinpath(@__DIR__, "..", "results")
    mkpath(output_dir)
    output_file = joinpath(output_dir, "parameter_sweep.csv")
    CSV.write(output_file, output)
    println(output_file)
end

main()
