using Test
using Agents
using DataFrames
using EDEN
using Random

@testset "EDEN v0.2" begin
    include("test_games.jl")
    include("test_agents.jl")
    include("test_strategies.jl")
    include("test_evolution.jl")
    include("test_biology.jl")
    include("test_theory.jl")
    include("test_simulation.jl")
    include("test_experiments.jl")
end
