function _add_offspring!(model, parent, child_state::StrategyState)
    memory_ids, memory_actions = _fresh_memory(model.memory_capacity)
    kwargs = (
        energy = model.reproduction_cost,
        payoff = 0.0,
        fitness = 0.0,
        genome = child_state.genome,
        doctrine_tag = child_state.doctrine,
        memory_ids = memory_ids,
        memory_actions = memory_actions,
        memory_cursor = 0,
        last_action = Cooperate,
        interaction_count = 0,
        birth_generation = model.generation + 1,
        parent_id = parent.id,
    )

    if model.spatial
        return add_agent!(parent.pos, model; kwargs...)
    end
    return add_agent!(model; kwargs...)
end

"""Apply energy-based mortality and reproduction for biological or hybrid evolution."""
function biological_turnover!(model)
    model.evolution_mode == CulturalEvolution && return nothing
    state = abmproperties(model)

    death_ids = Int[]
    for agent in allagents(model)
        agent.energy <= model.death_energy && push!(death_ids, agent.id)
    end
    for id in death_ids
        hasid(model, id) || continue
        remove_agent!(id, model)
        state.deaths_this_generation += 1
    end

    nagents(model) == 0 && return nothing
    vacancies = model.carrying_capacity - nagents(model)
    vacancies <= 0 && return nothing

    rng = abmrng(model)
    parent_ids = [agent.id for agent in allagents(model) if agent.energy >= model.reproduction_energy]
    shuffle!(rng, parent_ids)

    for parent_id in parent_ids
        vacancies <= 0 && break
        hasid(model, parent_id) || continue
        parent = model[parent_id]
        parent.energy >= model.reproduction_energy || continue
        rand(rng) < model.reproduction_probability || continue

        child_state = mutate_strategy_state(strategy_state(parent), model, rng)
        parent.energy -= model.reproduction_cost
        _add_offspring!(model, parent, child_state)
        state.births_this_generation += 1
        vacancies -= 1
    end
    return nothing
end
