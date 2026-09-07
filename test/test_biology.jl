@testset "Biological evolution" begin
    death_params = SimulationParameters(
        population_size = 4,
        carrying_capacity = 4,
        initial_energy = 0.0,
        payoff_to_energy = 0.0,
        metabolic_cost = 0.0,
        evolution_mode = BiologicalEvolution,
        death_energy = 0.0,
        reproduction_energy = 10.0,
        reproduction_cost = 5.0,
        reproduction_probability = 0.0,
        seed = 3,
    )
    death_model = build_model(death_params)
    step!(death_model, 1)
    @test nagents(death_model) == 0
    @test death_model.deaths_this_generation == 4

    birth_params = SimulationParameters(
        population_size = 2,
        carrying_capacity = 3,
        initial_energy = 200.0,
        payoff_to_energy = 0.0,
        metabolic_cost = 0.0,
        evolution_mode = BiologicalEvolution,
        death_energy = 0.0,
        reproduction_energy = 100.0,
        reproduction_cost = 50.0,
        reproduction_probability = 1.0,
        mutation_rate = 0.0,
        doctrine_mutation_rate = 0.0,
        seed = 4,
    )
    birth_model = build_model(birth_params)
    step!(birth_model, 1)
    @test nagents(birth_model) == 3
    @test birth_model.births_this_generation == 1
    @test any(agent -> agent.parent_id != 0, allagents(birth_model))
end
