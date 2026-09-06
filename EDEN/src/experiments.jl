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
            _, model = run_simulation(local_params; generations = invasion.generations)
            final_fraction = doctrine_fraction(model, invader)
            push!(rows, (
                resident = string(resident),
                invader = string(invader),
                seed = Int(seed),
                initial_fraction = invasion.mutant_fraction,
                final_fraction = final_fraction,
                grew = final_fraction > invasion.mutant_fraction + invasion.growth_tolerance,
                fixed = final_fraction >= invasion.fixation_threshold,
                extinct = final_fraction == 0.0,
                final_population = nagents(model),
            ))
        end
    end
    return DataFrame(rows)
end

"""Aggregate controlled invasion experiments into pairwise probabilities."""
function summarize_invasions(results::DataFrame)
    required = (:resident, :invader, :grew, :fixed, :extinct, :final_fraction)
    all(name -> name in propertynames(results), required) || throw(ArgumentError("results is not an invasion-results table."))
    groups = groupby(results, [:resident, :invader])
    rows = NamedTuple[]
    for group in groups
        push!(rows, (
            resident = first(group.resident),
            invader = first(group.invader),
            replicates = nrow(group),
            growth_probability = mean(Float64.(group.grew)),
            fixation_probability = mean(Float64.(group.fixed)),
            extinction_probability = mean(Float64.(group.extinct)),
            mean_final_fraction = mean(group.final_fraction),
            std_final_fraction = nrow(group) > 1 ? std(group.final_fraction) : 0.0,
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

"""Return empirical ESS candidates whose invaders rarely grow in controlled tests."""
function empirical_ess_candidates(summary::DataFrame; max_growth_probability::Float64 = 0.05)
    0.0 <= max_growth_probability <= 1.0 || throw(ArgumentError("max_growth_probability must lie in [0, 1]."))
    candidates = String[]
    for resident in string.(collect(instances(Doctrine)))
        rows = summary[summary.resident .== resident, :]
        nrow(rows) == 0 && continue
        maximum(rows.growth_probability) <= max_growth_probability && push!(candidates, resident)
    end
    return candidates
end
