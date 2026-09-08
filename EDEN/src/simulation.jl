"""Advance the ABM by one evolutionary generation."""
function generation_step!(model)
    reset_generation_accumulators!(model)
    move_spatial_agents!(model)
    play_generation!(model)
    update_fitness!(model)
    evolutionary_update!(model)
    biological_turnover!(model)
    abmproperties(model).generation += 1
    return nothing
end

"""Create a copy of `SimulationParameters` with selected keyword fields replaced."""
function replace_parameters(params::SimulationParameters; kwargs...)
    base = (
        population_size = params.population_size,
        initial_energy = params.initial_energy,
        initial_doctrine_fractions = params.initial_doctrine_fractions,
        selection_intensity = params.selection_intensity,
        mutation_rate = params.mutation_rate,
        doctrine_mutation_rate = params.doctrine_mutation_rate,
        mutation_sigma = params.mutation_sigma,
        interactions_per_agent = params.interactions_per_agent,
        payoff_to_energy = params.payoff_to_energy,
        metabolic_cost = params.metabolic_cost,
        spatial = params.spatial,
        grid_size = params.grid_size,
        neighborhood_radius = params.neighborhood_radius,
        move_agents = params.move_agents,
        memory_capacity = params.memory_capacity,
        update_mode = params.update_mode,
        evolution_mode = params.evolution_mode,
        death_energy = params.death_energy,
        reproduction_energy = params.reproduction_energy,
        reproduction_cost = params.reproduction_cost,
        reproduction_probability = params.reproduction_probability,
        carrying_capacity = params.carrying_capacity,
        seed = params.seed,
        game = params.game,
    )
    merged = merge(base, (; kwargs...))
    return SimulationParameters(; merged...)
end

"""Run a complete simulation and return metrics plus the final model."""
function run_simulation(
    params::SimulationParameters = SimulationParameters();
    generations::Int = 1_000,
    stop_on_extinction::Bool = true,
)
    generations >= 0 || throw(ArgumentError("generations must be non-negative."))
    model = build_model(params)
    metrics = DataFrame([collect_metrics(model)])

    for _ in 1:generations
        step!(model, 1)
        push!(metrics, collect_metrics(model))
        stop_on_extinction && nagents(model) == 0 && break
    end
    return metrics, model
end

"""Run independent stochastic replicas using an explicit collection of seeds."""
function run_ensemble(
    params::SimulationParameters = SimulationParameters();
    generations::Int = 1_000,
    seeds = 1:20,
    stop_on_extinction::Bool = true,
)
    outputs = DataFrame[]
    for seed in seeds
        seeded_params = replace_parameters(params; seed = Int(seed))
        metrics, _ = run_simulation(seeded_params; generations = generations, stop_on_extinction = stop_on_extinction)
        metrics.seed = fill(Int(seed), nrow(metrics))
        push!(outputs, metrics)
    end
    return isempty(outputs) ? DataFrame() : vcat(outputs...)
end

"""Summarize ensemble uncertainty by generation using Student-t or bootstrap intervals."""
function summarize_ensemble(
    data::DataFrame;
    metrics = (
        :cooperation_rate,
        :egoist_fraction,
        :altruist_fraction,
        :utilitarian_fraction,
        :reciprocal_fraction,
        :mean_energy,
        :population_size,
    ),
    confidence_method::Symbol = :student_t,
    confidence_level::Float64 = 0.95,
    bootstrap_replicates::Int = 2_000,
    seed::Int = 20260906,
)
    :generation in propertynames(data) || throw(ArgumentError("data must contain a generation column."))
    generations = sort(unique(data.generation))
    out = DataFrame(generation = generations)
    out.replicates = [count(==(g), data.generation) for g in generations]

    for (metric_index, metric) in enumerate(metrics)
        metric in propertynames(data) || throw(ArgumentError("Missing metric column: $(metric)."))
        means = Float64[]
        stds = Float64[]
        lowers = Float64[]
        uppers = Float64[]
        for (generation_index, g) in enumerate(generations)
            values = Float64.(data[data.generation .== g, metric])
            interval = mean_confidence_interval(
                values;
                method = confidence_method,
                confidence_level = confidence_level,
                bootstrap_replicates = bootstrap_replicates,
                seed = seed + 10_000 * metric_index + generation_index,
            )
            push!(means, interval.mean)
            push!(stds, interval.standard_deviation)
            push!(lowers, interval.lower)
            push!(uppers, interval.upper)
        end
        out[!, Symbol(metric, :_mean)] = means
        out[!, Symbol(metric, :_std)] = stds
        # Keep the historical ci95 names for the default 95 % level.
        suffix_low = confidence_level == 0.95 ? :_ci95_low : :_ci_low
        suffix_high = confidence_level == 0.95 ? :_ci95_high : :_ci_high
        out[!, Symbol(metric, suffix_low)] = lowers
        out[!, Symbol(metric, suffix_high)] = uppers
    end
    return out
end
