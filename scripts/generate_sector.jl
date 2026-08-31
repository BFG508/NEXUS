#!/usr/bin/env julia
# ASTRA — reproducible procedural galactic sector generation.
# Usage: julia --project=. scripts/generate_sector.jl [N_STARS] [--seed N]

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using Random
using Statistics
using astra

function parse_cli(args)
    n_stars = 20
    seed = 42
    positional_seen = false
    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--seed"
            i == length(args) && throw(ArgumentError("--seed requires an integer value"))
            i += 1
            seed = parse(Int, args[i])
        elseif startswith(arg, "--seed=")
            seed = parse(Int, split(arg, "=", limit=2)[2])
        elseif startswith(arg, "--")
            throw(ArgumentError("Unknown option: $arg"))
        elseif !positional_seen
            n_stars = parse(Int, arg)
            positional_seen = true
        else
            throw(ArgumentError("Unexpected positional argument: $arg"))
        end
        i += 1
    end
    n_stars > 0 || throw(ArgumentError("N_STARS must be greater than zero"))
    return (n_stars=n_stars, seed=seed)
end

cfg = parse_cli(ARGS)
Random.seed!(cfg.seed)

project_dir = normpath(joinpath(@__DIR__, ".."))
export_dir = joinpath(project_dir, "exports")
mkpath(export_dir)

println("\n🌌 ASTRA — Galactic Sector Generator")
println("═" ^ 50)
println("Generating $(cfg.n_stars) stellar systems with seed $(cfg.seed)...\n")

systems = [generate_system(generate_star()) for _ in 1:cfg.n_stars]

for (i, sys) in enumerate(systems)
    println("─── System $i ───")
    println(system_summary(sys))
    println()
end

println("\n📊 Spectral Class Distribution")
println("═" ^ 40)
class_counts = Dict{SpectralClass, Int}()
for sys in systems
    class_counts[sys.star.spectral_class] = get(class_counts, sys.star.spectral_class, 0) + 1
end
for sc in instances(SpectralClass)
    count = get(class_counts, sc, 0)
    bar = "█" ^ count
    pct = round(100.0 * count / cfg.n_stars; digits=1)
    println("  $(rpad(string(sc), 8)) │ $(rpad(bar, 20)) $count ($pct%)")
end

masses = [sys.star.mass_solar for sys in systems]
println("\n📈 Mass Statistics (M☉)")
println("  Min:    $(round(minimum(masses); digits=4))")
println("  Max:    $(round(maximum(masses); digits=4))")
println("  Mean:   $(round(mean(masses); digits=4))")
println("  Median: $(round(median(masses); digits=4))")

println("\n🎨 Rendering orbital map for System 1...")
plot_system(systems[1]; filename=joinpath(export_dir, "system_1_map.svg"))

println("\n✅ Sector generation complete.\n")
