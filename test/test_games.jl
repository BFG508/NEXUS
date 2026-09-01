@testset "Prisoner's Dilemma" begin
    game = PrisonersDilemma(5, 3, 1, 0)
    @test EDEN.game_payoff(game, Cooperate, Cooperate) == (3.0, 3.0)
    @test EDEN.game_payoff(game, Cooperate, Defect) == (0.0, 5.0)
    @test EDEN.game_payoff(game, Defect, Cooperate) == (5.0, 0.0)
    @test EDEN.game_payoff(game, Defect, Defect) == (1.0, 1.0)
    @test prisoners_dilemma_matrix(game) == [3.0 0.0; 5.0 1.0]
    @test_throws ArgumentError PrisonersDilemma(3, 5, 1, 0)
end
