using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using EDEN

function main()
    game = PrisonersDilemma()
    matrix = prisoners_dilemma_matrix(game)
    history = simulate_replicator([0.5, 0.5], matrix; dt = 0.01, steps = 2_000)
    validation = validate_binary_abm_against_replicator(game)

    println("Final replicator state: ", history[end, :])
    println("ABM/replicator directional validation: ", validation)
end

main()
