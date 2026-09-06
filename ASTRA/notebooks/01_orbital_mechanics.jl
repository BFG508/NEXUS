# ══════════════════════════════════════════════════════════════════════
#  01_orbital_mechanics.jl — Interactive Exploration Notebook
# ══════════════════════════════════════════════════════════════════════
#
#  This notebook is designed for use with Pluto.jl or as a regular
#  Julia script to interactively explore the stellar physics engine.
#
#  Topics:
#   1. Main-sequence scaling relations (M-L, M-R, M-T)
#   2. Spectral classification boundaries
#   3. Initial Mass Function (IMF) sampling
#   4. Habitable Zone computation (Phase 2)
# ══════════════════════════════════════════════════════════════════════

using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using astra
using Plots

# ──────────────────────────────────────────────────────────
#  Section 1: Mass-Luminosity Relation Visualization
# ──────────────────────────────────────────────────────────

println("📐 Plotting Mass-Luminosity relation for main-sequence stars...\n")

# Generate a logarithmic mass grid from 0.08 to 100 M☉
masses = 10 .^ range(log10(0.08), log10(100.0), length=500)
luminosities = [astra.mass_to_luminosity(m) for m in masses]

p1 = plot(masses, luminosities;
    xscale=:log10, yscale=:log10,
    xlabel="Mass (M☉)", ylabel="Luminosity (L☉)",
    title="Main-Sequence Mass-Luminosity Relation",
    linewidth=2, legend=false,
    grid=true, minorgrid=true
)

# Mark the Sun
scatter!(p1, [1.0], [1.0]; markersize=8, color=:gold, label="Sun ☉")

savefig(p1, joinpath(@__DIR__, "..", "mass_luminosity.png"))
println("✅ Plot saved to mass_luminosity.png")

# ──────────────────────────────────────────────────────────
#  Section 2: IMF Sampling — Generate 10000 Stars
# ──────────────────────────────────────────────────────────

println("\n📊 Sampling 10,000 stars from the IMF...")

sample_stars = [generate_star() for _ in 1:10_000]
sample_masses = [s.mass_solar for s in sample_stars]

p2 = histogram(log10.(sample_masses);
    bins=80, xlabel="log₁₀(M/M☉)", ylabel="Count",
    title="Initial Mass Function — 10k Sample",
    fillcolor=:steelblue, linecolor=:white,
    legend=false
)

savefig(p2, joinpath(@__DIR__, "..", "imf_histogram.png"))
println("✅ IMF histogram saved to imf_histogram.png")
