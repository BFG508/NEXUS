using Test
using Agents
using DataFrames
using EDEN
using Random

@testset "EDEN" begin
    include("test_games.jl")
    include("test_strategies.jl")
    include("test_theory.jl")
    include("test_simulation.jl")
end
