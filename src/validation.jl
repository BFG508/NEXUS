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
        mean_abm_change_per_generation = abm_change / max(generations, 1),
        std_abm_change = length(changes) > 1 ? std(changes) : 0.0,
        replicates = length(changes),
        direction_consistent = theoretical_direction == 0 || abm_direction == 0 || theoretical_direction == abm_direction,
    )
end

"""
Run a weak-selection/population-size convergence study between the binary ABM
and the corresponding replicator direction.

The Fermi process and continuous-time replicator equation use different time
scales, so the study reports direction and normalized ABM change rather than
claiming one-to-one trajectory equality.
"""
function validate_abm_replicator_convergence(
    game::PrisonersDilemma = PrisonersDilemma();
    initial_cooperator_fraction::Float64 = 0.5,
    population_sizes = (100, 250, 500),
    selection_intensities = (0.4, 0.2, 0.1, 0.05),
    generations::Int = 3,
    seeds = 1:40,
)
    rows = NamedTuple[]
    for population_size in population_sizes, selection_intensity in selection_intensities
        result = validate_binary_abm_against_replicator(
            game;
            initial_cooperator_fraction = initial_cooperator_fraction,
            population_size = Int(population_size),
            generations = generations,
            seeds = seeds,
            selection_intensity = Float64(selection_intensity),
        )
        push!(rows, (
            population_size = Int(population_size),
            selection_intensity = Float64(selection_intensity),
            theoretical_derivative = result.theoretical_derivative,
            mean_abm_change = result.mean_abm_change,
            mean_abm_change_per_generation = result.mean_abm_change_per_generation,
            std_abm_change = result.std_abm_change,
            replicates = result.replicates,
            direction_consistent = result.direction_consistent,
        ))
    end
    return DataFrame(rows)
end
