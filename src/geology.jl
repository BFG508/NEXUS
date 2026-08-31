# ══════════════════════════════════════════════════════════════════════
#  geology.jl — Geological & Atmospheric Inference Engine
# ══════════════════════════════════════════════════════════════════════

using Unitful

"""
    Geology

Structure representing the geological and atmospheric properties of a planet.
"""
struct Geology
    surface_gravity::typeof(1.0u"m/s^2")
    gravity_g::Float64          # In Earth Gs
    has_tectonics::Bool         # Active plate tectonics
    atmosphere_type::String     # "None", "Thin (CO2/N2)", "Thick (Venusian)", "Earth-like"
    resource_richness::String   # "Metal-Poor", "Standard", "Metal-Rich"
end

const G_CONST = 6.67430e-11u"m^3*kg^-1*s^-2"

"""
    generate_geology(mass::typeof(1.0u"kg"), radius::typeof(1.0u"m"), t_surf::typeof(1.0u"K"))

Infers geology and atmosphere from mass, radius, and temperature.
"""
function generate_geology(mass, radius, t_surf)
    # Surface Gravity g = GM/R²
    g_accel = (G_CONST * mass) / (radius^2)
    g_earth = ustrip(g_accel) / 9.80665
    
    mass_earth = ustrip(mass) / 5.972e24
    
    # Tectonics heuristically require enough mass to retain core heat
    has_tectonics = mass_earth > 0.25
    
    # Simple atmospheric retention logic
    # Depends on escape velocity vs thermal velocity, but we use a heuristic based on mass and temp
    temp = ustrip(t_surf)
    if mass_earth < 0.1 || temp > 1000.0
        atm = "None"
    elseif mass_earth < 0.5
        atm = "Thin (Mars-like)"
    elseif mass_earth > 2.0 && temp > 400.0
        atm = "Thick (Venusian)"
    elseif 250.0 <= temp <= 350.0 && 0.5 <= mass_earth <= 2.5
        atm = "Earth-like (N2/O2)"
    else
        atm = "Dense (CO2/N2/CH4)"
    end
    
    # Resource generation
    rand_val = rand()
    if rand_val < 0.15
        res = "Metal-Poor"
    elseif rand_val > 0.85
        res = "Metal-Rich"
    else
        res = "Standard"
    end
    
    Geology(g_accel, g_earth, has_tectonics, atm, res)
end

function geology_summary(geo::Geology)
    tect = geo.has_tectonics ? "Active" : "Dead"
    "Gravity: $(round(geo.gravity_g; digits=2)) G  │  Tectonics: $tect  │  Atmosphere: $(geo.atmosphere_type)  │  Resources: $(geo.resource_richness)"
end
