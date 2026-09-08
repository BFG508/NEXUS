const _T95 = (
    12.706, 4.303, 3.182, 2.776, 2.571, 2.447, 2.365, 2.306, 2.262, 2.228,
    2.201, 2.179, 2.160, 2.145, 2.131, 2.120, 2.110, 2.101, 2.093, 2.086,
    2.080, 2.074, 2.069, 2.064, 2.060, 2.056, 2.052, 2.048, 2.045, 2.042,
)

function _t95_critical(df::Int)
    df >= 1 || throw(ArgumentError("degrees of freedom must be positive"))
    df <= length(_T95) && return _T95[df]
    df <= 40 && return 2.021
    df <= 60 && return 2.000
    df <= 120 && return 1.980
    return 1.960
end

function _empirical_quantile(values::Vector{Float64}, probability::Float64)
    isempty(values) && return NaN
    sorted_values = sort(values)
    length(sorted_values) == 1 && return first(sorted_values)
    position = 1 + (length(sorted_values) - 1) * probability
    lower = floor(Int, position)
    upper = ceil(Int, position)
    lower == upper && return sorted_values[lower]
    weight = position - lower
    return sorted_values[lower] * (1 - weight) + sorted_values[upper] * weight
end

"""Confidence interval for an ensemble mean using Student-t or bootstrap resampling."""
function mean_confidence_interval(
    values::AbstractVector{<:Real};
    method::Symbol = :student_t,
    confidence_level::Float64 = 0.95,
    bootstrap_replicates::Int = 2_000,
    seed::Int = 1,
)
    0 < confidence_level < 1 || throw(ArgumentError("confidence_level must lie in (0, 1)"))
    x = Float64.(values)
    isempty(x) && return (mean = NaN, lower = NaN, upper = NaN, standard_deviation = NaN, n = 0)
    mu = mean(x)
    sigma = length(x) > 1 ? std(x) : 0.0
    length(x) == 1 && return (mean = mu, lower = mu, upper = mu, standard_deviation = sigma, n = 1)

    if method == :student_t
        confidence_level == 0.95 || throw(ArgumentError("dependency-free Student-t intervals currently support confidence_level=0.95"))
        critical = _t95_critical(length(x) - 1)
        half_width = critical * sigma / sqrt(length(x))
        return (mean = mu, lower = mu - half_width, upper = mu + half_width, standard_deviation = sigma, n = length(x))
    elseif method == :bootstrap
        bootstrap_replicates >= 100 || throw(ArgumentError("bootstrap_replicates must be at least 100"))
        rng = MersenneTwister(seed)
        means = Vector{Float64}(undef, bootstrap_replicates)
        for replicate in 1:bootstrap_replicates
            means[replicate] = mean(x[rand(rng, eachindex(x), length(x))])
        end
        alpha = 1.0 - confidence_level
        return (
            mean = mu,
            lower = _empirical_quantile(means, alpha / 2),
            upper = _empirical_quantile(means, 1 - alpha / 2),
            standard_deviation = sigma,
            n = length(x),
        )
    end
    throw(ArgumentError("Unknown confidence method: $method"))
end

"""Wilson score interval for a Bernoulli probability at approximately 95% confidence."""
function wilson_interval(successes::Integer, trials::Integer; z::Float64 = 1.96)
    0 <= successes <= trials || throw(ArgumentError("successes must lie in [0, trials]"))
    trials >= 1 || throw(ArgumentError("trials must be positive"))
    p = successes / trials
    denominator = 1 + z^2 / trials
    center = (p + z^2 / (2 * trials)) / denominator
    half_width = z / denominator * sqrt(p * (1 - p) / trials + z^2 / (4 * trials^2))
    return (max(0.0, center - half_width), min(1.0, center + half_width))
end
