"""Compare the direction of a binary pure-strategy ABM with replicator dynamics."""
function validate_binary_abm_against_replicator(
    game::PrisonersDilemma = PrisonersDilemma();
    initial_cooperator_fraction::Float64 = 0.5,
    population_size::Int = 200,
    generations::Int = 5,
    seeds = 1:40,
    selection_intensity::Float64 = 0.2,
)
    0.0 < initial_cooperator_fraction < 1.0 || throw(ArgumentError("initial_cooperator_fraction must lie in (0, 1)."))
    fractions = (1.0 - initial_cooperator_fraction, initial_cooperator_fraction, 0.0, 0.0)
    changes = Float64[]

    for seed in seeds
        params = SimulationParameters(
            population_size = population_size,
            carrying_capacity = population_size,
            initial_doctrine_fractions = fractions,
            selection_intensity = selection_intensity,
            mutation_rate = 0.0,
            doctrine_mutation_rate = 0.0,
            update_mode = SynchronousUpdate,
            evolution_mode = CulturalEvolution,
            seed = Int(seed),
            game = game,
        )
        model = build_model(params)
        for agent in allagents(model)
            if agent.doctrine_tag == Egoist
                agent.genome = EthicalGenome(0.0, 0.0, 0.0, 0.0)
            elseif agent.doctrine_tag == Altruist
                agent.genome = EthicalGenome(1.0, 0.0, 1.0, 0.0)
            end
        end
        initial = doctrine_fraction(model, Altruist)
        for _ in 1:generations
            step!(model, 1)
        end
        push!(changes, doctrine_fraction(model, Altruist) - initial)
    end

    matrix = prisoners_dilemma_matrix(game)
    state = [initial_cooperator_fraction, 1.0 - initial_cooperator_fraction]
    theoretical_change = replicator_rhs(state, matrix)[1]
    abm_change = mean(changes)
    theoretical_direction = sign(theoretical_change)
    abm_direction = sign(abm_change)

    return (
        initial_cooperator_fraction = initial_cooperator_fraction,
        theoretical_derivative = theoretical_change,
        mean_abm_change = abm_change,
        std_abm_change = length(changes) > 1 ? std(changes) : 0.0,
        replicates = length(changes),
        direction_consistent = theoretical_direction == 0 || abm_direction == 0 || theoretical_direction == abm_direction,
    )
end
