struct StrategyState
    doctrine::Doctrine
    genome::EthicalGenome
end

"""Return the probability that a learner imitates a role model under the Fermi rule."""
@inline function fermi_probability(learner_fitness::Real, role_model_fitness::Real, beta::Real)
    delta = Float64(role_model_fitness) - Float64(learner_fitness)
    x = clamp(Float64(beta) * delta, -700.0, 700.0)
    return 1.0 / (1.0 + exp(-x))
end

@inline strategy_state(agent) = StrategyState(agent.doctrine_tag, agent.genome)

@inline function apply_strategy_state!(agent, state::StrategyState)
    agent.doctrine_tag = state.doctrine
    agent.genome = state.genome
    return nothing
end

@inline function copy_strategy!(learner, role_model)
    learner.doctrine_tag = role_model.doctrine_tag
    learner.genome = role_model.genome
    return nothing
end

function _mutated_genome(genome::EthicalGenome, doctrine::Doctrine, sigma::Float64, rng::AbstractRNG)
    values = (
        genome.base_cooperation + sigma * randn(rng),
        genome.reciprocity + sigma * randn(rng),
        genome.other_regard + sigma * randn(rng),
        genome.forgiveness + sigma * randn(rng),
    )
    mutated = EthicalGenome(clamp(values[1], 0.0, 1.0), clamp(values[2], 0.0, 1.0), clamp(values[3], 0.0, 1.0), clamp(values[4], 0.0, 1.0))
    return project_genome(doctrine, mutated)
end

function mutate_strategy_state(state::StrategyState, model, rng::AbstractRNG)
    doctrine = state.doctrine
    genome = state.genome

    if rand(rng) < model.doctrine_mutation_rate
        doctrines = instances(Doctrine)
        current = Int(doctrine)
        offset = rand(rng, 1:(length(doctrines) - 1))
        doctrine = doctrines[mod1(current + offset, length(doctrines))]
        genome = default_genome(doctrine)
    end

    if rand(rng) < model.mutation_rate
        genome = _mutated_genome(genome, doctrine, model.mutation_sigma, rng)
    else
        genome = project_genome(doctrine, genome)
    end

    return StrategyState(doctrine, genome)
end

function mutate_strategy!(agent, model, rng::AbstractRNG)
    apply_strategy_state!(agent, mutate_strategy_state(strategy_state(agent), model, rng))
    return nothing
end

function asynchronous_evolutionary_update!(model)
    rng = abmrng(model)
    ids = collect(allids(model))
    shuffle!(rng, ids)

    for learner_id in ids
        hasid(model, learner_id) || continue
        learner = model[learner_id]
        role_model = select_partner(model, learner)

        if !isnothing(role_model)
            p_imitation = fermi_probability(learner.fitness, role_model.fitness, model.selection_intensity)
            rand(rng) < p_imitation && copy_strategy!(learner, role_model)
        end
        mutate_strategy!(learner, model, rng)
    end
    return nothing
end

function synchronous_evolutionary_update!(model)
    rng = abmrng(model)
    ids = collect(allids(model))
    snapshots = Dict(id => strategy_state(model[id]) for id in ids)
    proposals = Dict{Int,StrategyState}()

    shuffle!(rng, ids)
    for learner_id in ids
        learner = model[learner_id]
        next_state = snapshots[learner_id]
        role_model = select_partner(model, learner)

        if !isnothing(role_model)
            p_imitation = fermi_probability(learner.fitness, role_model.fitness, model.selection_intensity)
            if rand(rng) < p_imitation
                next_state = snapshots[role_model.id]
            end
        end
        proposals[learner_id] = mutate_strategy_state(next_state, model, rng)
    end

    for (id, state) in proposals
        hasid(model, id) && apply_strategy_state!(model[id], state)
    end
    return nothing
end

function evolutionary_update!(model)
    model.evolution_mode == BiologicalEvolution && return nothing
    if model.update_mode == SynchronousUpdate
        return synchronous_evolutionary_update!(model)
    end
    return asynchronous_evolutionary_update!(model)
end
