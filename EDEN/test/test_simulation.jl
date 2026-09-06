@testset "Simulation and metrics" begin
    @test_throws ArgumentError build_model(SimulationParameters(population_size = 1))
    @test_throws ArgumentError build_model(SimulationParameters(population_size = 10, carrying_capacity = 9))

    params = SimulationParameters(population_size = 40, carrying_capacity = 40, seed = 7, interactions_per_agent = 4)
    model = build_model(params)
    @test nagents(model) == 40
    @test all(length(agent.memory_ids) == params.memory_capacity for agent in allagents(model))

    step!(model, 1)
    metrics = collect_metrics(model)
    fractions = metrics.egoist_fraction + metrics.altruist_fraction + metrics.utilitarian_fraction + metrics.reciprocal_fraction
    @test isapprox(fractions, 1.0; atol = 1e-12)
    @test 0.0 <= metrics.cooperation_rate <= 1.0
    @test metrics.mean_energy >= 0.0

    output, _ = run_simulation(params; generations = 10)
    @test nrow(output) == 11

    spatial_params = SimulationParameters(
        population_size = 30,
        carrying_capacity = 30,
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

@testset "Energy bookkeeping" begin
    params = SimulationParameters(
        population_size = 2,
        carrying_capacity = 2,
        initial_energy = 10.0,
        initial_doctrine_fractions = (0.0, 1.0, 0.0, 0.0),
        payoff_to_energy = 0.5,
        metabolic_cost = 0.2,
        mutation_rate = 0.0,
        doctrine_mutation_rate = 0.0,
        seed = 8,
    )
    model = build_model(params)
    for agent in allagents(model)
        agent.genome = EthicalGenome(1.0, 0.0, 1.0, 0.0)
    end
    a = model[1]
    b = model[2]
    EDEN.apply_interaction!(a, b, model)
    @test isapprox(a.energy, 11.3; atol = 1e-12)
    @test isapprox(b.energy, 11.3; atol = 1e-12)
    @test a.interaction_count == 1
    @test b.interaction_count == 1
end
