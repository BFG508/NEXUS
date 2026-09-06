# ══════════════════════════════════════════════════════════════════════
#  culture_gen.jl — Sociological Inference Engine
# ══════════════════════════════════════════════════════════════════════
#
#  Infers hypothetical civilizations, societal archetypes, and belief
#  systems based on the physical boundary conditions of their home
#  planet and star.
# ══════════════════════════════════════════════════════════════════════

"""
    Civilization

Immutable structure representing a hypothetical civilization.
"""
struct Civilization
    name::String
    tech_level::String
    societal_archetype::String
    belief_system::String
    economic_system::String
    conflict_tendency::String
end

# ──────────────────────────────────────────────────────────
#  Generators & Heuristics
# ──────────────────────────────────────────────────────────

function _generate_civ_name(planet_name::String)
    suffixes = ["ans", "ians", "ites", "ese", "i", "oids"]
    base = split(planet_name, " ")[1] # Use the star prefix
    # Simplify the base name to sound like a species
    base = replace(base, r"[^A-Za-z]" => "") 
    base = titlecase(lowercase(base))
    if length(base) < 3
        base = base * "ar"
    end
    "The $(base)$(rand(suffixes))"
end

function _random_tech_level()
    levels = [
        "Stone Age (Hunter-Gatherer)",
        "Bronze/Iron Age (Agricultural)",
        "Medieval / Feudal",
        "Industrial Revolution",
        "Atomic Age",
        "Information Age",
        "Early Spacefaring"
    ]
    # Weight it towards primitive or early tech, as spacefaring is rare
    weights = [0.3, 0.3, 0.2, 0.1, 0.05, 0.03, 0.02]
    levels[rand(Categorical(weights ./ sum(weights)))]
end

"""
    is_habitable(planet::Planet)

Checks if a planet is theoretically capable of supporting carbon-based
life. We define this loosely as surface temperatures between 260 K and 350 K.
"""
function is_habitable(planet::Planet)
    t = ustrip(planet.surface_temperature)
    return 250.0 ≤ t ≤ 360.0
end

"""
    infer_civilization(star::Star, planet::Planet)

Generate a `Civilization` struct using deterministic heuristics based
on the planet's physical properties.
Returns `nothing` if the planet is completely uninhabitable.
"""
function infer_civilization(star::Star, planet::Planet)
    if !is_habitable(planet)
        # Randomly, tiny chance for extremophiles or post-biological entities
        if rand() < 0.01
            tech = "Post-Biological / Mechanized"
            arch = "Extreme Environment Endurers"
            belief = "Mathematical Determinism"
            econ = "Post-Scarcity Energy Grid"
            conflict = "Absolute Zero (Hive Mind)"
            return Civilization(_generate_civ_name(planet.name), tech, arch, belief, econ, conflict)
        end
        return nothing
    end

    tech = _random_tech_level()
    
    # Defaults
    arch = "Temperate Agrarian / City-States"
    belief = "Polytheistic / Animistic"
    conflict = "Moderate (Trade & Tribal border skirmishes)"
    econ = "Barter & Early Fiat"
    
    t_surf = ustrip(planet.surface_temperature)
    
    # ── Rule 1: Geology & Economics ──
    if planet.geology.resource_richness == "Metal-Poor"
        econ = "Bio-Engineered / Scavenger Economy"
        conflict = "High (Wars over rare ore deposits)"
    elseif planet.geology.resource_richness == "Metal-Rich"
        econ = "Hyper-Industrial / Mining Guilds"
    end

    # ── Rule 2: Tidal Locking ──
    if planet.is_tidally_locked
        arch = "Terminator-Line Dwellers (Twilight Zone Hubs)"
        belief = "Dualistic (Eternal Light vs. Eternal Dark Cosmogonies)"
        conflict = "High (Fierce competition over the narrow habitable strip)"
    end
    
    # ── Rule 3: High Eccentricity (Extreme Seasons) ──
    if planet.eccentricity > 0.15
        arch = "Nomadic Migrants / Seasonal Hibernators"
        belief = "Cyclical Rebirth & Apocalyptic Mythologies"
        conflict = "Variable (Peaceful in Spring, Brutal in Winter)"
    end
    
    # ── Rule 4: High Radiation / Hot Stars ──
    if star.spectral_class in (O_CLASS, B_CLASS, A_CLASS, F_CLASS)
        arch = "Subterranean / Cave-Dwellers"
        belief = "Fear of the Sky / Sun as a Wrathful Deity"
        conflict = "Low (Cooperative survival against the environment)"
    end
    
    # ── Rule 5: Marginal Temperatures ──
    if t_surf < 270.0
        arch = "Ice-Desert Scavengers / Tundra Hunters"
        belief = "Animism centered around hearth/fire deities"
    elseif t_surf > 330.0
        arch = "Oasis-Bound / Nocturnal Foragers"
        belief = "Water-worshipping cults / Sun as an adversary"
        conflict = "High (Water Scarcity)"
    end
    
    Civilization(_generate_civ_name(planet.name), tech, arch, belief, econ, conflict)
end

# ══════════════════════════════════════════════════════════════════════
#  DISPLAY
# ══════════════════════════════════════════════════════════════════════

"""
    civilization_summary(civ::Civilization)
"""
function civilization_summary(civ::Civilization)
    lines = [
        "    👁️  Civilization: $(civ.name)",
        "       ├─ Tech Level: $(civ.tech_level)",
        "       ├─ Archetype:  $(civ.societal_archetype)",
        "       ├─ Beliefs:    $(civ.belief_system)",
        "       ├─ Economy:    $(civ.economic_system)",
        "       └─ Conflict:   $(civ.conflict_tendency)"
    ]
    join(lines, "\n")
end
