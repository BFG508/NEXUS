@enum Doctrine::UInt8 begin
    Egoist = 1
    Altruist = 2
    Utilitarian = 3
    StrictReciprocal = 4
end

@enum EvolutionMode::UInt8 begin
    CulturalEvolution = 1
    BiologicalEvolution = 2
    HybridEvolution = 3
end

@enum UpdateMode::UInt8 begin
    AsynchronousUpdate = 1
    SynchronousUpdate = 2
end

const MEMORY_UNKNOWN = UInt8(0)
const MEMORY_DEFECT = UInt8(1)
const MEMORY_COOPERATE = UInt8(2)

struct EthicalGenome
    base_cooperation::Float64
    reciprocity::Float64
    other_regard::Float64
    forgiveness::Float64

    function EthicalGenome(
        base_cooperation::Real,
        reciprocity::Real,
        other_regard::Real,
        forgiveness::Real,
    )
        values = Float64.((base_cooperation, reciprocity, other_regard, forgiveness))
        all(x -> 0.0 <= x <= 1.0, values) || throw(ArgumentError("EthicalGenome traits must lie in [0, 1]."))
        return new(values...)
    end
end

@agent struct EDENAgent(NoSpaceAgent)
    energy::Float64
    payoff::Float64
    fitness::Float64
    genome::EthicalGenome
    doctrine_tag::Doctrine
    memory_ids::Vector{Int}
    memory_actions::Vector{UInt8}
    memory_cursor::Int
    last_action::Action
    interaction_count::Int
    birth_generation::Int
    parent_id::Int
end

@agent struct SpatialEDENAgent(GridAgent{2})
    energy::Float64
    payoff::Float64
    fitness::Float64
    genome::EthicalGenome
    doctrine_tag::Doctrine
    memory_ids::Vector{Int}
    memory_actions::Vector{UInt8}
    memory_cursor::Int
    last_action::Action
    interaction_count::Int
    birth_generation::Int
    parent_id::Int
end

"""Return the default continuous ethical genome associated with a doctrine."""
@inline function default_genome(doctrine::Doctrine)
    doctrine == Egoist && return EthicalGenome(0.02, 0.05, 0.05, 0.02)
    doctrine == Altruist && return EthicalGenome(0.98, 0.20, 0.90, 0.70)
    doctrine == Utilitarian && return EthicalGenome(0.70, 0.25, 0.95, 0.50)
    return EthicalGenome(0.95, 1.00, 0.35, 0.05)
end

@inline function _fresh_memory(capacity::Int)
    return fill(0, capacity), fill(MEMORY_UNKNOWN, capacity)
end

"""Project a continuous genome into the admissible region of a doctrine."""
function project_genome(doctrine::Doctrine, genome::EthicalGenome)
    b = genome.base_cooperation
    r = genome.reciprocity
    o = genome.other_regard
    f = genome.forgiveness

    if doctrine == Egoist
        b = clamp(b, 0.0, 0.25)
        o = clamp(o, 0.0, 0.30)
    elseif doctrine == Altruist
        b = clamp(b, 0.75, 1.0)
        o = clamp(o, 0.50, 1.0)
    elseif doctrine == Utilitarian
        o = clamp(o, 0.50, 1.0)
    elseif doctrine == StrictReciprocal
        r = clamp(r, 0.75, 1.0)
    end

    return EthicalGenome(clamp(b, 0.0, 1.0), clamp(r, 0.0, 1.0), clamp(o, 0.0, 1.0), clamp(f, 0.0, 1.0))
end

"""Store the most recent observed action using bounded per-agent memory."""
function remember!(agent, opponent_id::Int, action::Action)
    capacity = length(agent.memory_ids)
    capacity == 0 && return nothing
    code = action == Cooperate ? MEMORY_COOPERATE : MEMORY_DEFECT

    @inbounds for i in eachindex(agent.memory_ids)
        if agent.memory_ids[i] == opponent_id
            agent.memory_actions[i] = code
            return nothing
        end
    end

    next_index = mod1(agent.memory_cursor + 1, capacity)
    @inbounds begin
        agent.memory_ids[next_index] = opponent_id
        agent.memory_actions[next_index] = code
    end
    agent.memory_cursor = next_index
    return nothing
end

"""Return the remembered action for an opponent, or `nothing` when unknown."""
function remembered_action(agent, opponent_id::Int)
    @inbounds for i in eachindex(agent.memory_ids)
        if agent.memory_ids[i] == opponent_id
            code = agent.memory_actions[i]
            code == MEMORY_UNKNOWN && return nothing
            return code == MEMORY_COOPERATE ? Cooperate : Defect
        end
    end
    return nothing
end
