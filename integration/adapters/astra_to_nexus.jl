#!/usr/bin/env julia
# Generate one ASTRA system and export nexus.stellar_system.v1.

using Pkg
const NEXUS_ROOT = normpath(joinpath(@__DIR__, "..", ".."))
Pkg.activate(joinpath(NEXUS_ROOT, "ASTRA"))

using JSON
using Random
using Unitful
using astra

function contract_for_system(system::System, seed::Int)
    star = system.star
    planets = Any[]
    for planet in system.planets
        a_au = ustrip(planet.semimajor_axis) / ustrip(astra.AU)
        period_days = sqrt(a_au^3 / star.mass_solar) * 365.25
        equilibrium_k = ustrip(astra.equilibrium_temperature(star, planet.semimajor_axis, planet.albedo))
        push!(planets, Dict(
            "id" => planet.name,
            "mass_earth" => ustrip(planet.mass) / ustrip(astra.M_EARTH),
            "radius_earth" => ustrip(planet.radius) / ustrip(astra.R_EARTH),
            "semimajor_axis_au" => a_au,
            "eccentricity" => planet.eccentricity,
            "equilibrium_temp_k" => equilibrium_k,
            "surface_temp_k" => ustrip(planet.surface_temperature),
            "orbital_period_days" => period_days,
        ))
    end
    return Dict(
        "schema" => "nexus.stellar_system.v1",
        "producer" => Dict("project" => "ASTRA", "version" => "0.1.0"),
        "payload" => Dict(
            "system_id" => star.name,
            "seed" => seed,
            "star" => Dict(
                "name" => star.name,
                "mass_solar" => star.mass_solar,
                "radius_solar" => star.radius_solar,
                "luminosity_solar" => star.luminosity_solar,
                "temperature_k" => ustrip(star.temperature),
                "spectral_class" => string(star.spectral_class),
            ),
            "planets" => planets,
        ),
    )
end

seed = length(ARGS) >= 1 ? parse(Int, ARGS[1]) : 42
output = length(ARGS) >= 2 ? abspath(ARGS[2]) : joinpath(NEXUS_ROOT, "integration", "generated", "stellar_system.json")
Random.seed!(seed)
system = generate_system(generate_star())
mkpath(dirname(output))
open(output, "w") do io
    JSON.print(io, contract_for_system(system, seed), 4)
end
println(output)
