# ══════════════════════════════════════════════════════════════════════
#  gaia_exporter.jl — Integration for GAIA
# ══════════════════════════════════════════════════════════════════════

using CSV
using DataFrames
using Unitful

"""
    export_to_gaia(systems::Vector{System}, filename::String="astra_payload.csv")

Exports planetary systems into a CSV format mocking the NASA Exoplanet
Archive structure expected by the GAIA Dashboard.
"""
function export_to_gaia(systems::Vector{System}, filename::String="astra_payload.csv")
    pl_name = String[]
    pl_rade = Float64[]
    pl_bmasse = Float64[]
    pl_eqt = Float64[]
    pl_orbper = Float64[]
    hostname = String[]
    st_teff = Float64[]
    st_mass = Float64[]
    st_rad = Float64[]

    for sys in systems
        for p in sys.planets
            push!(pl_name, p.name)
            push!(pl_rade, round(ustrip(p.radius) / ustrip(R_EARTH); digits=3))
            push!(pl_bmasse, round(ustrip(p.mass) / ustrip(M_EARTH); digits=3))
            
            # Use equilibrium temperature (approximate without greenhouse for GAIA to calculate itself)
            t_eq = equilibrium_temperature(sys.star, p.semimajor_axis, p.albedo)
            push!(pl_eqt, round(ustrip(t_eq); digits=1))
            
            # Kepler's Third Law: P^2 = a^3 / M (in solar units and AU = years)
            a_au = ustrip(p.semimajor_axis) / ustrip(AU)
            m_solar = sys.star.mass_solar
            period_years = sqrt((a_au^3) / m_solar)
            period_days = period_years * 365.25
            push!(pl_orbper, round(period_days; digits=2))
            
            push!(hostname, sys.star.name)
            push!(st_teff, round(ustrip(sys.star.temperature); digits=0))
            push!(st_mass, round(sys.star.mass_solar; digits=3))
            push!(st_rad, round(sys.star.radius_solar; digits=3))
        end
    end
    
    if isempty(pl_name)
        println("⚠️  No planets found to export to GAIA.")
        return
    end

    df = DataFrame(
        pl_name = pl_name,
        pl_rade = pl_rade,
        pl_bmasse = pl_bmasse,
        pl_eqt = pl_eqt,
        pl_orbper = pl_orbper,
        hostname = hostname,
        st_teff = st_teff,
        st_mass = st_mass,
        st_rad = st_rad,
        discoverymethod = fill("ASTRA simulation", length(pl_name)),
        disc_year = fill(missing, length(pl_name)),
        sy_dist = fill(missing, length(pl_name))
    )

    mkpath(dirname(abspath(filename)))
    CSV.write(filename, df)
    println("✅ Exported $(nrow(df)) planets to GAIA format: $filename")
end
