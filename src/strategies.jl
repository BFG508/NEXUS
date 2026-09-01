@inline function _follow_recommendation_probability(agent, recommendation::Action)
    confidence = clamp(agent.cooperation_probability, 0.0, 1.0)
    return recommendation == Cooperate ? confidence : 1.0 - confidence
end

"""Return the conditional probability that an agent cooperates against an opponent."""
function cooperation_probability(agent, opponent, game::PrisonersDilemma)
    doctrine = agent.doctrine_tag

    if doctrine == Egoist || doctrine == Altruist
        return clamp(agent.cooperation_probability, 0.0, 1.0)
    end

    if doctrine == StrictReciprocal
        previous = remembered_action(agent, opponent.id)
        recommendation = isnothing(previous) ? Cooperate : previous
        return _follow_recommendation_probability(agent, recommendation)
    end

    previous = remembered_action(agent, opponent.id)
    q = isnothing(previous) ? 0.5 : (previous == Cooperate ? 1.0 : 0.0)

    welfare_if_cooperate = q * (2.0 * game.reward) + (1.0 - q) * (game.sucker + game.temptation)
    welfare_if_defect = q * (game.temptation + game.sucker) + (1.0 - q) * (2.0 * game.punishment)
    recommendation = welfare_if_cooperate >= welfare_if_defect ? Cooperate : Defect
    return _follow_recommendation_probability(agent, recommendation)
end

"""Sample one action from the doctrine-specific policy."""
@inline function strategy_action(agent, opponent, game::PrisonersDilemma, rng::AbstractRNG)
    p = cooperation_probability(agent, opponent, game)
    return rand(rng) < p ? Cooperate : Defect
end
