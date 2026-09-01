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

function shannon_diversity(model)
    n = nagents(model)
    entropy = 0.0
    for doctrine in instances(Doctrine)
        p = doctrine_count(model, doctrine) / n
        p > 0.0 && (entropy -= p * log(p))
    end
    return entropy
end

"""Collect one model-level metrics snapshot as a named tuple."""
function collect_metrics(model)
    n = nagents(model)
    energies = [agent.energy for agent in allagents(model)]
    fitnesses = [agent.fitness for agent in allagents(model)]
    cooperation_controls = [agent.cooperation_probability for agent in allagents(model)]
    denominator = 2 * model.total_interactions
    cooperation_rate = denominator == 0 ? 0.0 : model.total_cooperations / denominator

    return (
        generation = model.generation,
        egoist_fraction = doctrine_count(model, Egoist) / n,
        altruist_fraction = doctrine_count(model, Altruist) / n,
        utilitarian_fraction = doctrine_count(model, Utilitarian) / n,
        reciprocal_fraction = doctrine_count(model, StrictReciprocal) / n,
        cooperation_rate = cooperation_rate,
        mean_fitness = mean(fitnesses),
        mean_energy = mean(energies),
        energy_gini = gini_coefficient(energies),
        strategy_diversity = shannon_diversity(model),
        mean_cooperation_probability = mean(cooperation_controls),
        realized_interactions = model.total_interactions,
    )
end
