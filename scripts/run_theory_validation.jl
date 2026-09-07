using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using EDEN

function main()
    result = validate_binary_abm_against_replicator(
        PrisonersDilemma();
        initial_cooperator_fraction = 0.5,
        population_size = 500,
        generations = 10,
        seeds = 1:100,
        selection_intensity = 0.2,
    )
    println(result)
    result.direction_consistent || error("ABM and replicator dynamics disagree in evolutionary direction.")
end

main()
