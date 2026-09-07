@testset "Ensembles and invasion analysis" begin
    params = SimulationParameters(population_size = 20, carrying_capacity = 20, seed = 1)
    ensemble = run_ensemble(params; generations = 2, seeds = 1:3)
    summary = summarize_ensemble(ensemble; metrics = (:cooperation_rate, :population_size))
    @test nrow(summary) == 3
    @test all(summary.replicates .== 3)
    @test :cooperation_rate_ci95_low in propertynames(summary)

    bootstrap_summary = summarize_ensemble(
        ensemble;
        metrics = (:cooperation_rate,),
        confidence_method = :bootstrap,
        bootstrap_replicates = 100,
        seed = 42,
    )
    @test all(bootstrap_summary.cooperation_rate_ci95_low .<= bootstrap_summary.cooperation_rate_ci95_high)

    invasion = InvasionParameters(mutant_fraction = 0.10, generations = 2)
    results = run_invasion_experiment(
        params;
        invasion = invasion,
        seeds = 1:2,
        residents = (Egoist,),
        invaders = (Altruist,),
    )
    @test nrow(results) == 2
    @test all(results.initial_count .>= 0)
    @test :absolute_growth in propertynames(results)
    invasion_summary = summarize_invasions(results)
    @test nrow(invasion_summary) == 1
    @test 0.0 <= invasion_summary.growth_probability[1] <= 1.0
    @test 0.0 <= invasion_summary.growth_ci_low[1] <= invasion_summary.growth_ci_high[1] <= 1.0

    # A partial resident/invader matrix must never be declared an ESS by default.
    @test isempty(empirical_ess_candidates(invasion_summary))
end

@testset "Complete ESS coverage" begin
    names = string.(collect(instances(Doctrine)))
    rows = NamedTuple[]
    for resident in names, invader in names
        resident == invader && continue
        push!(rows, (
            resident = resident,
            invader = invader,
            replicates = 100,
            growth_probability = resident == "Egoist" ? 0.0 : 0.2,
            growth_ci_low = 0.0,
            growth_ci_high = resident == "Egoist" ? 0.04 : 0.30,
        ))
    end
    synthetic = DataFrame(rows)
    @test empirical_ess_candidates(synthetic) == ["Egoist"]
    diagnostics = empirical_ess_diagnostics(synthetic)
    @test all(diagnostics.complete)
end
