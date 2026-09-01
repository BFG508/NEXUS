@testset "Strategies" begin
    game = PrisonersDilemma()
    params = SimulationParameters(population_size = 4, initial_doctrine_fractions = (0.0, 0.0, 0.0, 1.0), seed = 1)
    model = build_model(params)
    a = model[1]
    b = model[2]

    @test remembered_action(a, b.id) === nothing
    @test cooperation_probability(a, b, game) > 0.5

    remember!(a, b.id, Defect)
    @test remembered_action(a, b.id) == Defect
    @test cooperation_probability(a, b, game) < 0.5

    util_params = SimulationParameters(population_size = 4, initial_doctrine_fractions = (0.0, 0.0, 1.0, 0.0), seed = 2)
    util_model = build_model(util_params)
    u = util_model[1]
    v = util_model[2]
    @test cooperation_probability(u, v, game) > 0.5
end
