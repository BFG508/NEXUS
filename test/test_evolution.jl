@testset "Evolution" begin
    @test fermi_probability(1.0, 1.0, 1.0) == 0.5
    @test fermi_probability(0.0, 1.0, 1.0) > 0.5
    @test fermi_probability(1.0, 0.0, 1.0) < 0.5
    @test fermi_probability(-1000.0, 1000.0, 1000.0) <= 1.0

    for update_mode in (AsynchronousUpdate, SynchronousUpdate)
        params = SimulationParameters(
            population_size = 30,
            carrying_capacity = 30,
            update_mode = update_mode,
            evolution_mode = CulturalEvolution,
            seed = 77,
        )
        a, _ = run_simulation(params; generations = 5)
        b, _ = run_simulation(params; generations = 5)
        @test a == b
        @test all(a.population_size .== 30)
    end
end
