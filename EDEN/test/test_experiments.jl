@testset "Ensembles and invasion analysis" begin
    params = SimulationParameters(population_size = 20, carrying_capacity = 20, seed = 1)
    ensemble = run_ensemble(params; generations = 2, seeds = 1:3)
    summary = summarize_ensemble(ensemble; metrics = (:cooperation_rate, :population_size))
    @test nrow(summary) == 3
    @test all(summary.replicates .== 3)
    @test :cooperation_rate_ci95_low in propertynames(summary)

    invasion = InvasionParameters(mutant_fraction = 0.10, generations = 2)
    results = run_invasion_experiment(
        params;
        invasion = invasion,
        seeds = 1:2,
        residents = (Egoist,),
        invaders = (Altruist,),
    )
    @test nrow(results) == 2
    invasion_summary = summarize_invasions(results)
    @test nrow(invasion_summary) == 1
    @test 0.0 <= invasion_summary.growth_probability[1] <= 1.0
end
