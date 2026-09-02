using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using CSV
using DataFrames
using EDEN

function main()
    params = SimulationParameters(
        population_size = 500,
        carrying_capacity = 500,
        mutation_rate = 0.0,
        doctrine_mutation_rate = 0.0,
        update_mode = SynchronousUpdate,
        evolution_mode = CulturalEvolution,
        seed = 1,
    )
    invasion = InvasionParameters(mutant_fraction = 0.02, generations = 1_000)
    raw = run_invasion_experiment(params; invasion = invasion, seeds = 1:30)
    summary = summarize_invasions(raw)
    matrix = invasibility_matrix(summary)

    output_dir = joinpath(@__DIR__, "..", "results")
    mkpath(output_dir)
    CSV.write(joinpath(output_dir, "invasions_raw.csv"), raw)
    CSV.write(joinpath(output_dir, "invasions_summary.csv"), summary)
    matrix_df = DataFrame(matrix, :auto)
    CSV.write(joinpath(output_dir, "invasibility_matrix.csv"), matrix_df)
    println("Empirical ESS candidates: ", empirical_ess_candidates(summary))
end

main()
