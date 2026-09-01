@testset "Simulation" begin
    params = SimulationParameters(population_size = 40, seed = 7, interactions_per_agent = 4)
    model = build_model(params)
    @test nagents(model) == 40
    @test all(length(agent.memory) == 41 for agent in allagents(model))

    step!(model, 1)
    metrics = collect_metrics(model)
    fractions = metrics.egoist_fraction + metrics.altruist_fraction + metrics.utilitarian_fraction + metrics.reciprocal_fraction
    @test isapprox(fractions, 1.0; atol = 1e-12)
    @test 0.0 <= metrics.cooperation_rate <= 1.0
    @test metrics.mean_energy >= 0.0

    a, _ = run_simulation(params; generations = 10)
    b, _ = run_simulation(params; generations = 10)
    @test a == b
    @test nrow(a) == 11

    spatial_params = SimulationParameters(
        population_size = 30,
        spatial = true,
        grid_size = (10, 10),
        neighborhood_radius = 2,
        seed = 9,
    )
    spatial_model = build_model(spatial_params)
    @test nagents(spatial_model) == 30
    step!(spatial_model, 1)
    @test spatial_model.generation == 1
end

@testset "Fermi rule" begin
    @test fermi_probability(1.0, 1.0, 1.0) == 0.5
    @test fermi_probability(0.0, 1.0, 1.0) > 0.5
    @test fermi_probability(1.0, 0.0, 1.0) < 0.5
end
