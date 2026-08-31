# ══════════════════════════════════════════════════════════════════════
#  planets.jl — Planetary Generation & Habitable Zone Thermodynamics
# ══════════════════════════════════════════════════════════════════════
#
#  Implements planetary generation, orbital placement, habitable zone
#  calculations, and surface temperature estimations via energy balance.
# ══════════════════════════════════════════════════════════════════════

"""
    Planet

Immutable structure representing a planet with physical, orbital, and
thermodynamic properties.

# Fields
- `name::String`
- `mass::typeof(1.0u"kg")`
- `radius::typeof(1.0u"m")`
- `semimajor_axis::typeof(1.0u"m")`
- `eccentricity::Float64`
- `albedo::Float64`
- `greenhouse_heating::typeof(1.0u"K")`
- `surface_temperature::typeof(1.0u"K")`
- `is_tidally_locked::Bool`
"""
struct Planet
    name::String
    mass::typeof(1.0u"kg")
    radius::typeof(1.0u"m")
    semimajor_axis::typeof(1.0u"m")
    eccentricity::Float64
    albedo::Float64
    greenhouse_heating::typeof(1.0u"K")
    surface_temperature::typeof(1.0u"K")
    is_tidally_locked::Bool
    geology::Geology
end

"""
    System

A star and its orbiting planets.
"""
struct System
    star::Star
    planets::Vector{Planet}
end

# ══════════════════════════════════════════════════════════════════════
#  HABITABLE ZONE & THERMODYNAMICS
# ══════════════════════════════════════════════════════════════════════

"""
    habitable_zone_boundaries(star::Star)

Calculate the inner, optimal, and outer edges of the habitable zone
in Astronomical Units (AU), based on a simple square-root scaling
of the star's solar luminosity.

Returns a tuple: `(inner_au, optimal_au, outer_au)`
"""
function habitable_zone_boundaries(star::Star)
    l_solar = star.luminosity_solar
    inner = 0.95 * sqrt(l_solar)
    optimal = 1.0 * sqrt(l_solar)
    outer = 1.37 * sqrt(l_solar)
    
    return (inner, optimal, outer)
end

"""
    equilibrium_temperature(star::Star, semimajor_axis::typeof(1.0u"m"), albedo::Float64)

Calculate the equilibrium temperature of a planet assuming rapid rotation
and efficient heat redistribution.
"""
function equilibrium_temperature(star::Star, semimajor_axis::typeof(1.0u"m"), albedo::Float64)
    # T_eq = T_star * sqrt(R_star / (2 * a)) * (1 - A)^0.25
    t_star = star.temperature
    r_star = star.radius
    a = semimajor_axis
    
    t_eq = t_star * sqrt(r_star / (2.0 * a)) * (1.0 - albedo)^0.25
    return t_eq
end

"""
    check_tidal_locking(star::Star, semimajor_axis::typeof(1.0u"m"))

A simplified heuristic for tidal locking: planets very close to their
parent star (e.g. inside the habitable zone of an M-dwarf) become
tidally locked due to gravitational gradients.
"""
function check_tidal_locking(star::Star, semimajor_axis::typeof(1.0u"m"))
    # Approximation: locking radius proportional to mass_star^(1/3) * time^(1/6)
    # For a typical system age, we can set an empirical threshold.
    # Often, planets around red dwarfs in the HZ are tidally locked.
    locking_threshold = 0.4 * (star.mass_solar)^(1/3) * AU
    return semimajor_axis <= locking_threshold
end

# ══════════════════════════════════════════════════════════════════════
#  PROCEDURAL GENERATION
# ══════════════════════════════════════════════════════════════════════

"""
    generate_planet(star::Star, index::Int; in_hz::Bool=false)

Generate a single planet orbiting the given star. If `in_hz` is true,
the planet's orbit is forced into the star's habitable zone.
"""
function generate_planet(star::Star, index::Int; in_hz::Bool=false)
    name = "$(star.name) $(Char('b' + index - 1))"
    
    # Mass and radius (Earth-like rocky planets for now)
    mass_earth_ratio = rand(Uniform(0.1, 5.0))
    mass = mass_earth_ratio * M_EARTH
    
    # Simple mass-radius relation for rocky worlds: R ∝ M^0.27
    radius_earth_ratio = mass_earth_ratio^0.27
    radius = radius_earth_ratio * R_EARTH
    
    if in_hz
        hz_inner, hz_opt, hz_outer = habitable_zone_boundaries(star)
        a_au = rand(Uniform(hz_inner, hz_outer))
    else
        # Random placement between 0.1 and 5.0 AU scaled by star mass
        a_au = rand(Uniform(0.1, 5.0)) * sqrt(star.mass_solar)
    end
    
    semimajor_axis = a_au * AU
    eccentricity = rand(Exponential(0.05))
    eccentricity = clamp(eccentricity, 0.0, 0.4) # Keep it stable
    
    albedo = rand(Uniform(0.15, 0.45))
    
    # Calculate temperatures
    t_eq = equilibrium_temperature(star, semimajor_axis, albedo)
    
    # Greenhouse effect: scale randomly, more for heavier planets
    greenhouse = rand(Uniform(10.0, 40.0)) * (mass_earth_ratio^0.5) * 1.0u"K"
    t_surf = t_eq + greenhouse
    
    is_locked = check_tidal_locking(star, semimajor_axis)
    
    geo = generate_geology(mass, radius, t_surf)
    
    Planet(
        name,
        mass,
        radius,
        semimajor_axis,
        eccentricity,
        albedo,
        greenhouse,
        t_surf,
        is_locked,
        geo
    )
end

"""
    generate_system(star::Star; num_planets::Union{Int, Nothing}=nothing)

Generate a complete planetary system around a star.
"""
function generate_system(star::Star; num_planets::Union{Int, Nothing}=nothing)
    n = isnothing(num_planets) ? rand(0:8) : num_planets
    
    planets = Planet[]
    for i in 1:n
        # 20% chance to force a planet into the HZ
        in_hz = rand() < 0.20
        push!(planets, generate_planet(star, i; in_hz=in_hz))
    end
    
    # Sort planets by distance from star
    sort!(planets, by = p -> p.semimajor_axis)
    
    # Reassign letters based on sorted order
    for (i, p) in enumerate(planets)
        new_name = "$(star.name) $(Char('b' + i - 1))"
        planets[i] = Planet(new_name, p.mass, p.radius, p.semimajor_axis, p.eccentricity, p.albedo, p.greenhouse_heating, p.surface_temperature, p.is_tidally_locked, p.geology)
    end
    
    System(star, planets)
end

# ══════════════════════════════════════════════════════════════════════
#  DISPLAY & INTROSPECTION
# ══════════════════════════════════════════════════════════════════════

"""
    planet_summary(planet::Planet)
"""
function planet_summary(planet::Planet)
    mass_e = round(ustrip(planet.mass) / ustrip(M_EARTH); digits=2)
    rad_e = round(ustrip(planet.radius) / ustrip(R_EARTH); digits=2)
    a_au = round(ustrip(planet.semimajor_axis) / ustrip(AU); digits=3)
    t_surf = round(ustrip(planet.surface_temperature); digits=0)
    
    lock_str = planet.is_tidally_locked ? "Yes" : "No"
    
    lines = [
        "  🌍 $(rpad(planet.name, 38))",
        "  ├─ Orbit: $(a_au) AU (e=$(round(planet.eccentricity; digits=3)))",
        "  ├─ Mass:  $(mass_e) M⊕  │  Radius: $(rad_e) R⊕",
        "  ├─ Temp:  $(Int(t_surf)) K   │  Tidally Locked: $(lock_str)",
        "  └─ " * geology_summary(planet.geology)
    ]
    
    join(lines, "\n")
end

"""
    system_summary(sys::System)
"""
function system_summary(sys::System)
    lines = [star_summary(sys.star)]
    if isempty(sys.planets)
        push!(lines, "\n  [No planetary bodies detected]")
    else
        push!(lines, "\n  Planetary System ($(length(sys.planets)) bodies):")
        for p in sys.planets
            push!(lines, planet_summary(p))
            civ = infer_civilization(sys.star, p)
            if !isnothing(civ)
                push!(lines, civilization_summary(civ))
            end
            push!(lines, "")
        end
    end
    join(lines, "\n")
end

function Base.show(io::IO, p::Planet)
    a_au = round(ustrip(p.semimajor_axis) / ustrip(AU); digits=2)
    t_surf = Int(round(ustrip(p.surface_temperature)))
    print(io, "Planet(\"$(p.name)\", $(a_au) AU, T=$(t_surf) K)")
end

function Base.show(io::IO, sys::System)
    print(io, "System($(sys.star.name), $(length(sys.planets)) planets)")
end
