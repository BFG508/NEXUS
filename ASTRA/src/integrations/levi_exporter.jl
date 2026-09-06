# ══════════════════════════════════════════════════════════════════════
#  levi_exporter.jl — Integration for LEVI
# ══════════════════════════════════════════════════════════════════════

using CSV
using DataFrames
using Unitful

"""
    export_to_levi(sys::System, filename::String="astra_orbits.csv")

Exports planetary orbital elements (semi-major axis, eccentricity, stellar μ)
for LEVI's compatibility adapter. LEVI constructs approximate state vectors
from these elements before solving transfers.
"""
function export_to_levi(sys::System, filename::String="astra_orbits.csv")
    if isempty(sys.planets)
        println("⚠️  No planets to export to LEVI.")
        return
    end

    names = String[]
    a_km = Float64[]
    e_vals = Float64[]
    mu_star = Float64[]

    mu = 1.32712440018e11  # Sun's GM in km³/s² (scaled by mass ratio)
    mu_scaled = mu * sys.star.mass_solar

    for p in sys.planets
        push!(names, p.name)
        push!(a_km, ustrip(p.semimajor_axis) / 1000.0)  # m → km
        push!(e_vals, p.eccentricity)
        push!(mu_star, mu_scaled)
    end

    df = DataFrame(
        planet_name = names,
        semimajor_axis_km = a_km,
        eccentricity = e_vals,
        mu_km3_s2 = mu_star
    )

    mkpath(dirname(abspath(filename)))
    CSV.write(filename, df)
    println("✅ Exported $(nrow(df)) planetary orbits to LEVI format: $filename")
end
