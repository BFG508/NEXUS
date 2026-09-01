"""Return the continuous-time replicator right-hand side for a population state."""
function replicator_rhs(x::AbstractVector{<:Real}, payoff_matrix::AbstractMatrix{<:Real})
    n = length(x)
    size(payoff_matrix) == (n, n) || throw(DimensionMismatch("payoff_matrix must be square and match x."))
    state = Float64.(x)
    fitness = payoff_matrix * state
    mean_fitness = sum(state .* fitness)
    return state .* (fitness .- mean_fitness)
end

"""Advance a replicator system by one explicit Euler step and renormalize to the simplex."""
function replicator_step(x::AbstractVector{<:Real}, payoff_matrix::AbstractMatrix{<:Real}, dt::Real)
    dt > 0 || throw(ArgumentError("dt must be positive."))
    next_state = Float64.(x) .+ Float64(dt) .* replicator_rhs(x, payoff_matrix)
    next_state .= max.(next_state, 0.0)
    total = sum(next_state)
    total > 0.0 || throw(DomainError(next_state, "Replicator state left the probability simplex."))
    next_state ./= total
    return next_state
end

"""Simulate a replicator system and return a matrix whose rows are time samples."""
function simulate_replicator(
    x0::AbstractVector{<:Real},
    payoff_matrix::AbstractMatrix{<:Real};
    dt::Real = 0.01,
    steps::Int = 1_000,
)
    steps >= 0 || throw(ArgumentError("steps must be non-negative."))
    x = Float64.(x0)
    all(value -> value >= 0.0, x) || throw(ArgumentError("x0 must be non-negative."))
    sum(x) > 0.0 || throw(ArgumentError("x0 must contain positive mass."))
    x ./= sum(x)

    history = Matrix{Float64}(undef, steps + 1, length(x))
    history[1, :] .= x
    for k in 1:steps
        x = replicator_step(x, payoff_matrix, dt)
        history[k + 1, :] .= x
    end
    return history
end
