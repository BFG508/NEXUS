"""
    Astra

Astrophysical Stochastic Terrain Rendering Architect.

A physics-informed procedural generation engine for stellar systems,
habitable-environment proxies, and speculative civilizations. Combines
astrophysics (spectral classification, habitable zone thermodynamics,
atmospheric models) with sociological inference to build richly detailed
galactic sectors.

# Submodules
- `stars.jl`       — Spectral classification, luminosity, and main-sequence physics.
- `planets.jl`     — Orbital mechanics, atmospheric thermodynamics, habitability.
- `culture_gen.jl` — Belief-system inference from planetary boundary conditions.

# Quick Start
```julia
using Astra

# Generate a random main-sequence star
star = generate_star()

# Generate an orbital system around it
system = generate_system(star)

# Inspect habitability
for planet in system.planets
    println(planet.name, " → T_surface = ", planet.surface_temperature)
end
```
"""
module astra

# ──────────────────────────────────────────────────────────
#  Dependencies
# ──────────────────────────────────────────────────────────
using Unitful
using Unitful: @u_str
using Distributions
using DataFrames

# ──────────────────────────────────────────────────────────
#  Physical Constants (SI / CGS where convenient)
# ──────────────────────────────────────────────────────────

"""Solar mass in kilograms."""
const M_SUN  = 1.989e30u"kg"

"""Solar luminosity in watts."""
const L_SUN  = 3.828e26u"W"

"""Solar radius in meters."""
const R_SUN  = 6.957e8u"m"

"""Solar effective temperature in Kelvin."""
const T_SUN  = 5778.0u"K"

"""Stefan-Boltzmann constant in SI."""
const SIGMA  = 5.670374419e-8u"W*m^-2*K^-4"

"""Astronomical Unit in meters."""
const AU     = 1.496e11u"m"

"""Earth mass in kilograms."""
const M_EARTH = 5.972e24u"kg"

"""Earth radius in meters."""
const R_EARTH = 6.371e6u"m"

# ──────────────────────────────────────────────────────────
#  Submodule Includes
# ──────────────────────────────────────────────────────────
include("stars.jl")
include("geology.jl")
include("planets.jl")
include("culture_generator.jl")
include("ui_render.jl")

# ──────────────────────────────────────────────────────────
#  Integrations
# ──────────────────────────────────────────────────────────
include("integrations/scale_exporter.jl")
include("integrations/gaia_exporter.jl")
include("integrations/spartan_exporter.jl")
include("integrations/levi_exporter.jl")

# ──────────────────────────────────────────────────────────
#  Public API Exports
# ──────────────────────────────────────────────────────────
export Star, SpectralClass, Planet, System, Civilization, Geology
export generate_star, spectral_class, star_summary, generate_system, planet_summary, system_summary, infer_civilization, civilization_summary, generate_geology, geology_summary, plot_system, export_to_scale, export_to_gaia, export_to_spartan, export_to_levi

end # module astra
