module EDEN

using Agents
using DataFrames
using Random
using Statistics

include("games.jl")
include("agents.jl")
include("strategies.jl")
include("evolution.jl")
include("environment.jl")
include("metrics.jl")
include("theory.jl")
include("simulation.jl")

export Action,
       Cooperate,
       Defect,
       Doctrine,
       Egoist,
       Altruist,
       Utilitarian,
       StrictReciprocal,
       PrisonersDilemma,
       SimulationParameters,
       EDENAgent,
       SpatialEDENAgent,
       build_model,
       generation_step!,
       run_simulation,
       run_ensemble,
       collect_metrics,
       strategy_action,
       cooperation_probability,
       remember!,
       remembered_action,
       fermi_probability,
       prisoners_dilemma_matrix,
       replicator_rhs,
       replicator_step,
       simulate_replicator

end
