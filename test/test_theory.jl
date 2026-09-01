@testset "Replicator dynamics" begin
    matrix = prisoners_dilemma_matrix()
    rhs = replicator_rhs([0.5, 0.5], matrix)
    @test isapprox(sum(rhs), 0.0; atol = 1e-12)

    next_state = replicator_step([0.5, 0.5], matrix, 0.01)
    @test all(next_state .>= 0.0)
    @test isapprox(sum(next_state), 1.0; atol = 1e-12)

    history = simulate_replicator([0.9, 0.1], matrix; dt = 0.01, steps = 50)
    @test size(history) == (51, 2)
    @test all(abs.(sum(history; dims = 2) .- 1.0) .< 1e-10)
end
