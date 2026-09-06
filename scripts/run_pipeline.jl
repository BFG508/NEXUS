import Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using ETHOS

config_path = isempty(ARGS) ? joinpath(@__DIR__, "..", "config", "pipeline.toml") : ARGS[1]
result = run_pipeline(config_path)

println("ETHOS pipeline completed.")
println("Documents: $(result.documents)")
println("Concepts: $(result.concepts)")
println("Groups: $(join(result.groups, ", "))")
println("Report: $(result.report)")
