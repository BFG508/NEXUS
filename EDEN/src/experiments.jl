Base.@kwdef struct InvasionParameters
    mutant_fraction::Float64 = 0.02
    generations::Int = 500
    fixation_threshold::Float64 = 0.95
    growth_tolerance::Float64 = 1e-9
end

function _doctrine_fraction_tuple(resident::Doctrine, invader::Doctrine, mutant_fraction::Float64)
    resident == invader && throw(ArgumentError("resident and invader doctrines must differ."))
    0.0 < mutant_fraction < 1.0 || throw(ArgumentError("mutant_fraction must lie in (0, 1)."))
    fractions = zeros(Float64, 4)
    fractions[Int(resident)] = 1.0 - mutant_fraction
    fractions[Int(invader)] = mutant_fraction
    return Tuple(fractions)
end

function _doctrine_fraction_column(doctrine::Doctrine)
    doctrine == Egoist && return :egoist_fraction
    doctrine == Altruist && return :altruist_fraction
    doctrine == Utilitarian && return :utilitarian_fraction
    return :reciprocal_fraction
end

"""Run controlled resident-invader experiments across doctrines and seeds."""
function run_invasion_experiment(
    params::SimulationParameters = SimulationParameters();
    invasion::InvasionParameters = InvasionParameters(),
    seeds = 1:20,
    residents = instances(Doctrine),
    invaders = instances(Doctrine),
)
    invasion.generations >= 1 || throw(ArgumentError("invasion.generations must be positive."))
    0.0 < invasion.fixation_threshold <= 1.0 || throw(ArgumentError("fixation_threshold must lie in (0, 1]."))
    rows = NamedTuple[]

    for resident in residents, invader in invaders
        resident == invader && continue
        fractions = _doctrine_fraction_tuple(resident, invader, invasion.mutant_fraction)
        for seed in seeds
            local_params = replace_parameters(
                params;
                initial_doctrine_fractions = fractions,
                seed = Int(seed),
            )
            metrics, model = run_simulation(local_params; generations = invasion.generations)
            fraction_column = _doctrine_fraction_column(invader)
            initial_population = Int(metrics.population_size[1])
            initial_fraction = Float64(metrics[1, fraction_column])
            initial_count = round(Int, initial_population * initial_fraction)
            final_population = nagents(model)
            final_count = doctrine_count(model, invader)
            final_fraction = final_population == 0 ? 0.0 : final_count / final_population
            frequency_growth = final_fraction - initial_fraction
            absolute_growth = final_count - initial_count
            push!(rows, (
                resident = string(resident),
                invader = string(invader),
                seed = Int(seed),
                initial_population = initial_population,
                final_population = final_population,
                initial_count = initial_count,
                final_count = final_count,
                initial_fraction = initial_fraction,
                final_fraction = final_fraction,
                frequency_growth = frequency_growth,
                absolute_growth = absolute_growth,
                grew = frequency_growth > invasion.growth_tolerance,
                grew_absolute = absolute_growth > 0,
                fixed = final_fraction >= invasion.fixation_threshold,
                extinct = final_count == 0,
            ))
        end
    end
    return DataFrame(rows)
end

"""Aggregate controlled invasion experiments into pairwise probabilities and uncertainty."""
function summarize_invasions(results::DataFrame)
    required = (:resident, :invader, :grew, :fixed, :extinct, :final_fraction)
    all(name -> name in propertynames(results), required) || throw(ArgumentError("results is not an invasion-results table."))
    groups = groupby(results, [:resident, :invader])
    rows = NamedTuple[]
    for group in groups
        replicates = nrow(group)
        growth_successes = count(identity, group.grew)
        growth_ci_low, growth_ci_high = wilson_interval(growth_successes, replicates)
        absolute_probability = :grew_absolute in propertynames(group) ? mean(Float64.(group.grew_absolute)) : NaN
        push!(rows, (
            resident = first(group.resident),
            invader = first(group.invader),
            replicates = replicates,
            growth_probability = mean(Float64.(group.grew)),
            growth_ci_low = growth_ci_low,
            growth_ci_high = growth_ci_high,
            absolute_growth_probability = absolute_probability,
            fixation_probability = mean(Float64.(group.fixed)),
            extinction_probability = mean(Float64.(group.extinct)),
            mean_final_fraction = mean(group.final_fraction),
            std_final_fraction = replicates > 1 ? std(group.final_fraction) : 0.0,
            mean_frequency_growth = :frequency_growth in propertynames(group) ? mean(group.frequency_growth) : NaN,
            mean_absolute_growth = :absolute_growth in propertynames(group) ? mean(Float64.(group.absolute_growth)) : NaN,
        ))
    end
    return DataFrame(rows)
end

"""Return a doctrine-by-doctrine matrix of empirical invader growth probabilities."""
function invasibility_matrix(summary::DataFrame)
    doctrines = collect(instances(Doctrine))
    names = string.(doctrines)
    matrix = fill(NaN, length(doctrines), length(doctrines))
    for row in eachrow(summary)
        resident_index = findfirst(==(row.resident), names)
        invader_index = findfirst(==(row.invader), names)
        isnothing(resident_index) && continue
        isnothing(invader_index) && continue
        matrix[resident_index, invader_index] = row.growth_probability
    end
    return matrix
end

"""
Return empirical ESS candidates whose complete invader set is bounded below the
growth threshold.

By default the upper Wilson confidence bound is used, so a point estimate of
zero growth with only a few replicates is not enough to label a resident an ESS
candidate.
"""
function empirical_ess_candidates(
    summary::DataFrame;
    max_growth_probability::Float64 = 0.05,
    require_complete::Bool = true,
    use_upper_confidence_bound::Bool = true,
)
    0.0 <= max_growth_probability <= 1.0 || throw(ArgumentError("max_growth_probability must lie in [0, 1]."))
    required_columns = (:resident, :invader, :growth_probability)
    all(name -> name in propertynames(summary), required_columns) || throw(ArgumentError("summary is missing invasion columns."))
    use_upper_confidence_bound && !(:growth_ci_high in propertynames(summary)) && throw(
        ArgumentError("growth_ci_high is required when use_upper_confidence_bound=true."),
    )

    doctrine_names = string.(collect(instances(Doctrine)))
    candidates = String[]
    for resident in doctrine_names
        rows = summary[summary.resident .== resident, :]
        nrow(rows) == 0 && continue
        expected_invaders = Set(filter(!=(resident), doctrine_names))
        observed_invaders = Set(String.(rows.invader))
        require_complete && observed_invaders != expected_invaders && continue
        metric = use_upper_confidence_bound ? Float64.(rows.growth_ci_high) : Float64.(rows.growth_probability)
        all(isfinite, metric) || continue
        maximum(metric) <= max_growth_probability && push!(candidates, resident)
    end
    return candidates
end

"""Diagnostic table explaining why each doctrine does or does not satisfy the empirical ESS rule."""
function empirical_ess_diagnostics(
    summary::DataFrame;
    max_growth_probability::Float64 = 0.05,
)
    doctrine_names = string.(collect(instances(Doctrine)))
    rows = NamedTuple[]
    for resident in doctrine_names
        subset = summary[summary.resident .== resident, :]
        expected = Set(filter(!=(resident), doctrine_names))
        observed = Set(String.(subset.invader))
        complete = observed == expected
        worst_upper = nrow(subset) > 0 && :growth_ci_high in propertynames(subset) ? maximum(Float64.(subset.growth_ci_high)) : NaN
        push!(rows, (
            resident = resident,
            complete = complete,
            tested_invaders = length(observed),
            expected_invaders = length(expected),
            worst_growth_upper_bound = worst_upper,
            candidate = complete && isfinite(worst_upper) && worst_upper <= max_growth_probability,
        ))
    end
    return DataFrame(rows)
end
