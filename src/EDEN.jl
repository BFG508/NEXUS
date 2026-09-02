module EDEN

using Agents
using DataFrames
using Random
using Statistics

include("games.jl")
include("agents.jl")
include("strategies.jl")
include("environment.jl")
include("evolution.jl")
include("biology.jl")
include("metrics.jl")
include("theory.jl")
include("simulation.jl")
include("experiments.jl")
include("validation.jl")

export Action,
       Cooperate,
       Defect,
       Doctrine,
       Egoist,
       Altruist,
       Utilitarian,
       StrictReciprocal,
       EvolutionMode,
       CulturalEvolution,
       BiologicalEvolution,
       HybridEvolution,
       UpdateMode,
       AsynchronousUpdate,
       SynchronousUpdate,
       EthicalGenome,
       PrisonersDilemma,
       SimulationParameters,
       InvasionParameters,
       EDENAgent,
       SpatialEDENAgent,
       build_model,
       generation_step!,
       run_simulation,
       run_ensemble,
       summarize_ensemble,
       run_invasion_experiment,
       summarize_invasions,
       invasibility_matrix,
       empirical_ess_candidates,
       collect_metrics,
       strategy_action,
       cooperation_probability,
       remember!,
       remembered_action,
       fermi_probability,
       prisoners_dilemma_matrix,
       replicator_rhs,
       replicator_step,
       simulate_replicator,
       validate_binary_abm_against_replicator,
       replace_parameters

end
