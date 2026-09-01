"""Return the probability that a learner imitates a role model under the Fermi rule."""
@inline function fermi_probability(learner_fitness::Real, role_model_fitness::Real, beta::Real)
    delta = Float64(role_model_fitness) - Float64(learner_fitness)
    x = clamp(Float64(beta) * delta, -700.0, 700.0)
    return 1.0 / (1.0 + exp(-x))
end

@inline function copy_strategy!(learner, role_model)
    learner.doctrine_tag = role_model.doctrine_tag
    learner.cooperation_probability = role_model.cooperation_probability
    return nothing
end

function mutate_strategy!(agent, mutation_rate::Float64, mutation_sigma::Float64, rng::AbstractRNG)
    rand(rng) < mutation_rate || return nothing

    doctrines = instances(Doctrine)
    new_doctrine = doctrines[rand(rng, 1:length(doctrines))]
    if new_doctrine == agent.doctrine_tag
        current_index = Int(agent.doctrine_tag)
        new_doctrine = doctrines[mod1(current_index + rand(rng, 1:(length(doctrines) - 1)), length(doctrines))]
    end

    agent.doctrine_tag = new_doctrine
    base = default_cooperation_probability(new_doctrine)
    low, high = doctrine_probability_bounds(new_doctrine)
    agent.cooperation_probability = clamp(base + mutation_sigma * randn(rng), low, high)
    return nothing
end

function evolutionary_update!(model)
    rng = abmrng(model)
    shuffle!(rng, model.activation_order)

    for learner_id in model.activation_order
        learner = model[learner_id]
        role_model = select_partner(model, learner)

        if !isnothing(role_model)
            p_imitation = fermi_probability(
                learner.fitness,
                role_model.fitness,
                model.selection_intensity,
            )
            rand(rng) < p_imitation && copy_strategy!(learner, role_model)
        end

        mutate_strategy!(learner, model.mutation_rate, model.mutation_sigma, rng)
    end
    return nothing
end
