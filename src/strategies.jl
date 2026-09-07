@inline function _blend_probability(base::Float64, recommendation::Action, confidence::Float64)
    target = recommendation == Cooperate ? 1.0 : 0.0
    return clamp((1.0 - confidence) * base + confidence * target, 0.0, 1.0)
end

"""Return the conditional probability that an agent cooperates against an opponent."""
function cooperation_probability(agent, opponent, game::PrisonersDilemma)
    doctrine = agent.doctrine_tag
    genome = agent.genome
    base = genome.base_cooperation

    if doctrine == Egoist || doctrine == Altruist
        return base
    end

    previous = remembered_action(agent, opponent.id)

    if doctrine == StrictReciprocal
        if isnothing(previous)
            return base
        end
        recommendation = previous
        reciprocal = _blend_probability(base, recommendation, genome.reciprocity)
        if recommendation == Defect
            reciprocal = reciprocal * (1.0 - genome.forgiveness) + genome.forgiveness
        end
        return clamp(reciprocal, 0.0, 1.0)
    end

    q = isnothing(previous) ? 0.5 : (previous == Cooperate ? 1.0 : 0.0)
    own_if_cooperate = q * game.reward + (1.0 - q) * game.sucker
    own_if_defect = q * game.temptation + (1.0 - q) * game.punishment
    social_if_cooperate = q * game.reward + (1.0 - q) * game.temptation
    social_if_defect = q * game.sucker + (1.0 - q) * game.punishment

    utility_cooperate = own_if_cooperate + genome.other_regard * social_if_cooperate
    utility_defect = own_if_defect + genome.other_regard * social_if_defect
    recommendation = utility_cooperate >= utility_defect ? Cooperate : Defect
    confidence = clamp(0.5 * genome.other_regard + 0.5 * genome.reciprocity, 0.0, 1.0)
    return _blend_probability(base, recommendation, confidence)
end

"""Sample one action from the doctrine-specific policy."""
@inline function strategy_action(agent, opponent, game::PrisonersDilemma, rng::AbstractRNG)
    p = cooperation_probability(agent, opponent, game)
    return rand(rng) < p ? Cooperate : Defect
end
