using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using EDEN

function main()
    game = PrisonersDilemma()
    payoff_matrix = prisoners_dilemma_matrix(game)
    x0 = [0.9, 0.1]
    history = simulate_replicator(x0, payoff_matrix; dt = 0.01, steps = 5_000)

    println("Strategy order: cooperate, defect")
    println("Initial state: ", history[1, :])
    println("Final state:   ", history[end, :])
end

main()
