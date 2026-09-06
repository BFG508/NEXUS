function gini_coefficient(values::AbstractVector{<:Real})
    isempty(values) && return 0.0
    x = sort(Float64.(values))
    total = sum(x)
    total == 0.0 && return 0.0
    n = length(x)
    weighted = 0.0
    @inbounds for i in eachindex(x)
        weighted += i * x[i]
    end
    return (2.0 * weighted) / (n * total) - (n + 1.0) / n
end

@inline doctrine_count(model, doctrine::Doctrine) = count(agent -> agent.doctrine_tag == doctrine, allagents(model))

function doctrine_fraction(model, doctrine::Doctrine)
    n = nagents(model)
    return n == 0 ? 0.0 : doctrine_count(model, doctrine) / n
end

function shannon_diversity(model)
    n = nagents(model)
    n == 0 && return 0.0
    entropy = 0.0
    for doctrine in instances(Doctrine)
        p = doctrine_count(model, doctrine) / n
        p > 0.0 && (entropy -= p * log(p))
    end
    return entropy
end

@inline _safe_mean(values) = isempty(values) ? 0.0 : mean(values)

"""Collect one model-level metrics snapshot as a named tuple."""
function collect_metrics(model)
    n = nagents(model)
    energies = [agent.energy for agent in allagents(model)]
    fitnesses = [agent.fitness for agent in allagents(model)]
    base_cooperation = [agent.genome.base_cooperation for agent in allagents(model)]
    reciprocity = [agent.genome.reciprocity for agent in allagents(model)]
    other_regard = [agent.genome.other_regard for agent in allagents(model)]
    forgiveness = [agent.genome.forgiveness for agent in allagents(model)]
    ages = [max(0, model.generation - agent.birth_generation) for agent in allagents(model)]
    denominator = 2 * model.total_interactions
    cooperation_rate = denominator == 0 ? 0.0 : model.total_cooperations / denominator

    return (
        generation = model.generation,
        population_size = n,
        extinct = n == 0,
        egoist_fraction = doctrine_fraction(model, Egoist),
        altruist_fraction = doctrine_fraction(model, Altruist),
        utilitarian_fraction = doctrine_fraction(model, Utilitarian),
        reciprocal_fraction = doctrine_fraction(model, StrictReciprocal),
        cooperation_rate = cooperation_rate,
        mean_fitness = _safe_mean(fitnesses),
        mean_energy = _safe_mean(energies),
        energy_gini = gini_coefficient(energies),
        strategy_diversity = shannon_diversity(model),
        mean_base_cooperation = _safe_mean(base_cooperation),
        mean_reciprocity = _safe_mean(reciprocity),
        mean_other_regard = _safe_mean(other_regard),
        mean_forgiveness = _safe_mean(forgiveness),
        mean_age = _safe_mean(ages),
        realized_interactions = model.total_interactions,
        births = model.births_this_generation,
        deaths = model.deaths_this_generation,
    )
end
