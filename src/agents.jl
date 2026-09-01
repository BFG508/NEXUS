@enum Doctrine::UInt8 begin
    Egoist = 1
    Altruist = 2
    Utilitarian = 3
    StrictReciprocal = 4
end

const MEMORY_UNKNOWN = UInt8(0)
const MEMORY_DEFECT = UInt8(1)
const MEMORY_COOPERATE = UInt8(2)

@agent struct EDENAgent(NoSpaceAgent)
    energy::Float64
    payoff::Float64
    fitness::Float64
    cooperation_probability::Float64
    doctrine_tag::Doctrine
    memory::Vector{UInt8}
    last_action::Action
    interaction_count::Int
end

@agent struct SpatialEDENAgent(GridAgent{2})
    energy::Float64
    payoff::Float64
    fitness::Float64
    cooperation_probability::Float64
    doctrine_tag::Doctrine
    memory::Vector{UInt8}
    last_action::Action
    interaction_count::Int
end

"""Return the default cooperation-control parameter for a doctrine."""
@inline function default_cooperation_probability(doctrine::Doctrine)
    doctrine == Egoist && return 0.02
    doctrine == Altruist && return 0.98
    doctrine == Utilitarian && return 0.95
    return 0.98
end

"""Store the most recent observed action for a specific opponent."""
@inline function remember!(agent, opponent_id::Int, action::Action)
    code = action == Cooperate ? MEMORY_COOPERATE : MEMORY_DEFECT
    @inbounds agent.memory[opponent_id + 1] = code
    return nothing
end

"""Return the remembered action for an opponent, or `nothing` when unknown."""
@inline function remembered_action(agent, opponent_id::Int)
    @inbounds code = agent.memory[opponent_id + 1]
    code == MEMORY_UNKNOWN && return nothing
    return code == MEMORY_COOPERATE ? Cooperate : Defect
end

@inline function doctrine_probability_bounds(doctrine::Doctrine)
    doctrine == Egoist && return (0.0, 0.25)
    doctrine == Altruist && return (0.75, 1.0)
    return (0.5, 1.0)
end
