@testset "Agents and bounded LRU memory" begin
    @test_throws ArgumentError EthicalGenome(1.2, 0.0, 0.0, 0.0)

    params = SimulationParameters(
        population_size = 4,
        carrying_capacity = 4,
        memory_capacity = 2,
        initial_doctrine_fractions = (0.0, 0.0, 0.0, 1.0),
        seed = 1,
    )
    model = build_model(params)
    a = model[1]

    @test length(a.memory_ids) == 2
    @test remembered_action(a, 2) === nothing
    remember!(a, 2, Cooperate)
    remember!(a, 3, Defect)
    @test remembered_action(a, 2) == Cooperate
    @test remembered_action(a, 3) == Defect

    # Updating agent 2 makes it the most-recent entry; agent 3 is evicted next.
    remember!(a, 2, Defect)
    remember!(a, 4, Cooperate)
    @test remembered_action(a, 2) == Defect
    @test remembered_action(a, 3) === nothing
    @test remembered_action(a, 4) == Cooperate
end
