Base.@kwdef struct SimulationParameters
    population_size::Int = 500
    initial_energy::Float64 = 100.0
    initial_doctrine_fractions::NTuple{4,Float64} = (0.25, 0.25, 0.25, 0.25)
    selection_intensity::Float64 = 1.0
    mutation_rate::Float64 = 0.002
    mutation_sigma::Float64 = 0.03
    interactions_per_agent::Int = 8
    payoff_to_energy::Float64 = 0.10
    metabolic_cost::Float64 = 0.20
    spatial::Bool = false
    grid_size::NTuple{2,Int} = (30, 30)
    neighborhood_radius::Int = 1
    move_agents::Bool = true
    seed::Int = 42
    game::PrisonersDilemma = PrisonersDilemma()
end

mutable struct ModelState
    game::PrisonersDilemma
    selection_intensity::Float64
    mutation_rate::Float64
    mutation_sigma::Float64
    interactions_per_agent::Int
    payoff_to_energy::Float64
    metabolic_cost::Float64
    spatial::Bool
    neighborhood_radius::Int
    move_agents::Bool
    generation::Int
    total_cooperations::Int
    total_interactions::Int
    activation_order::Vector{Int}
end

function validate_parameters(params::SimulationParameters)
    params.population_size >= 2 || throw(ArgumentError("population_size must be at least 2."))
    params.initial_energy >= 0.0 || throw(ArgumentError("initial_energy must be non-negative."))
    params.selection_intensity >= 0.0 || throw(ArgumentError("selection_intensity must be non-negative."))
    0.0 <= params.mutation_rate <= 1.0 || throw(ArgumentError("mutation_rate must be in [0, 1]."))
    params.mutation_sigma >= 0.0 || throw(ArgumentError("mutation_sigma must be non-negative."))
    params.interactions_per_agent >= 1 || throw(ArgumentError("interactions_per_agent must be positive."))
    params.payoff_to_energy >= 0.0 || throw(ArgumentError("payoff_to_energy must be non-negative."))
    params.metabolic_cost >= 0.0 || throw(ArgumentError("metabolic_cost must be non-negative."))
    all(x -> x >= 0.0, params.initial_doctrine_fractions) || throw(ArgumentError("initial_doctrine_fractions cannot contain negative values."))
    sum(params.initial_doctrine_fractions) > 0.0 || throw(ArgumentError("initial_doctrine_fractions must contain positive mass."))
    all(x -> x > 0, params.grid_size) || throw(ArgumentError("grid_size dimensions must be positive."))
    params.neighborhood_radius >= 1 || throw(ArgumentError("neighborhood_radius must be positive."))
    return nothing
end

function doctrine_counts(population_size::Int, fractions::NTuple{4,Float64})
    normalized = collect(fractions) ./ sum(fractions)
    raw = normalized .* population_size
    counts = floor.(Int, raw)
    remaining = population_size - sum(counts)
    order = sortperm(raw .- counts; rev = true)
    for i in 1:remaining
        counts[order[i]] += 1
    end
    return counts
end

function make_state(params::SimulationParameters)
    return ModelState(
        params.game,
        params.selection_intensity,
        params.mutation_rate,
        params.mutation_sigma,
        params.interactions_per_agent,
        params.payoff_to_energy,
        params.metabolic_cost,
        params.spatial,
        params.neighborhood_radius,
        params.move_agents,
        0,
        0,
        0,
        collect(1:params.population_size),
    )
end

function add_initial_agents!(model, params::SimulationParameters)
    counts = doctrine_counts(params.population_size, params.initial_doctrine_fractions)
    doctrines = instances(Doctrine)
    memory_length = params.population_size + 1

    for (doctrine, count) in zip(doctrines, counts)
        p = default_cooperation_probability(doctrine)
        for _ in 1:count
            add_agent!(
                model;
                energy = params.initial_energy,
                payoff = 0.0,
                fitness = 0.0,
                cooperation_probability = p,
                doctrine_tag = doctrine,
                memory = fill(MEMORY_UNKNOWN, memory_length),
                last_action = Cooperate,
                interaction_count = 0,
            )
        end
    end
    return model
end

"""Build either a well-mixed model or a two-dimensional local-interaction grid model."""
function build_model(params::SimulationParameters = SimulationParameters())
    validate_parameters(params)
    rng = MersenneTwister(params.seed)
    state = make_state(params)

    if params.spatial
        space = GridSpace(params.grid_size; periodic = true, metric = :chebyshev)
        model = StandardABM(
            SpatialEDENAgent,
            space;
            properties = state,
            model_step! = generation_step!,
            rng = rng,
            container = Vector,
        )
    else
        model = StandardABM(
            EDENAgent;
            properties = state,
            model_step! = generation_step!,
            rng = rng,
            container = Vector,
        )
    end

    add_initial_agents!(model, params)
    return model
end

@inline function select_partner(model, focal)
    if model.spatial
        partner_id = random_nearby_id(focal, model, model.neighborhood_radius)
        return isnothing(partner_id) ? nothing : model[partner_id]
    end

    partner = random_agent(model)
    while partner.id == focal.id
        partner = random_agent(model)
    end
    return partner
end

function reset_generation_accumulators!(model)
    state = abmproperties(model)
    state.total_cooperations = 0
    state.total_interactions = 0
    for agent in allagents(model)
        agent.payoff = 0.0
        agent.fitness = 0.0
        agent.interaction_count = 0
    end
    return nothing
end

function move_spatial_agents!(model)
    model.spatial || return nothing
    model.move_agents || return nothing
    for agent in allagents(model)
        randomwalk!(agent, model, 1; ifempty = false)
    end
    return nothing
end

@inline function apply_interaction!(a, b, model)
    rng = abmrng(model)
    action_a = strategy_action(a, b, model.game, rng)
    action_b = strategy_action(b, a, model.game, rng)
    payoff_a, payoff_b = game_payoff(model.game, action_a, action_b)

    a.payoff += payoff_a
    b.payoff += payoff_b
    a.interaction_count += 1
    b.interaction_count += 1
    a.energy = max(0.0, a.energy + model.payoff_to_energy * payoff_a - model.metabolic_cost)
    b.energy = max(0.0, b.energy + model.payoff_to_energy * payoff_b - model.metabolic_cost)
    a.last_action = action_a
    b.last_action = action_b
    remember!(a, b.id, action_b)
    remember!(b, a.id, action_a)

    state = abmproperties(model)
    state.total_cooperations += (action_a == Cooperate) + (action_b == Cooperate)
    state.total_interactions += 1
    return nothing
end

function play_generation!(model)
    target_interactions = max(1, cld(nagents(model) * model.interactions_per_agent, 2))
    completed = 0
    attempts = 0
    max_attempts = max(10 * target_interactions, 100)

    while completed < target_interactions && attempts < max_attempts
        focal = random_agent(model)
        partner = select_partner(model, focal)
        if !isnothing(partner)
            apply_interaction!(focal, partner, model)
            completed += 1
        end
        attempts += 1
    end
    return nothing
end

function update_fitness!(model)
    for agent in allagents(model)
        agent.fitness = agent.interaction_count == 0 ? 0.0 : agent.payoff / agent.interaction_count
    end
    return nothing
end

"""Advance the ABM by one evolutionary generation."""
function generation_step!(model)
    reset_generation_accumulators!(model)
    move_spatial_agents!(model)
    play_generation!(model)
    update_fitness!(model)
    evolutionary_update!(model)
    abmproperties(model).generation += 1
    return nothing
end
