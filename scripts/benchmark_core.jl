using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using EDEN

function benchmark_case(population_size::Int, spatial::Bool)
    params = SimulationParameters(
        population_size = population_size,
        carrying_capacity = population_size,
        spatial = spatial,
        grid_size = spatial ? (100, 100) : (30, 30),
        interactions_per_agent = 8,
        seed = 42,
    )
    elapsed = @elapsed run_simulation(params; generations = 100)
    agent_generations = population_size * 100
    return (
        population_size = population_size,
        spatial = spatial,
        elapsed_seconds = elapsed,
        agent_generations_per_second = agent_generations / max(elapsed, eps()),
    )
end

function main()
    for population_size in (100, 500, 1_000)
        println(benchmark_case(population_size, false))
    end
    println(benchmark_case(500, true))
end

main()
