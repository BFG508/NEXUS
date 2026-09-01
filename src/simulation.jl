"""Run a complete simulation and return metrics plus the final model."""
function run_simulation(
    params::SimulationParameters = SimulationParameters();
    generations::Int = 1_000,
)
    generations >= 0 || throw(ArgumentError("generations must be non-negative."))
    model = build_model(params)
    metrics = DataFrame([collect_metrics(model)])

    for _ in 1:generations
        step!(model, 1)
        push!(metrics, collect_metrics(model))
    end
    return metrics, model
end

"""Run independent stochastic replicas using an explicit collection of seeds."""
function run_ensemble(
    params::SimulationParameters = SimulationParameters();
    generations::Int = 1_000,
    seeds = 1:20,
)
    outputs = DataFrame[]
    for seed in seeds
        seeded_params = SimulationParameters(
            population_size = params.population_size,
            initial_energy = params.initial_energy,
            initial_doctrine_fractions = params.initial_doctrine_fractions,
            selection_intensity = params.selection_intensity,
            mutation_rate = params.mutation_rate,
            mutation_sigma = params.mutation_sigma,
            interactions_per_agent = params.interactions_per_agent,
            payoff_to_energy = params.payoff_to_energy,
            metabolic_cost = params.metabolic_cost,
            spatial = params.spatial,
            grid_size = params.grid_size,
            neighborhood_radius = params.neighborhood_radius,
            move_agents = params.move_agents,
            seed = Int(seed),
            game = params.game,
        )
        metrics, _ = run_simulation(seeded_params; generations = generations)
        metrics.seed = fill(Int(seed), nrow(metrics))
        push!(outputs, metrics)
    end
    return isempty(outputs) ? DataFrame() : vcat(outputs...)
end
