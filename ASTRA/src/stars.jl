# ══════════════════════════════════════════════════════════════════════
#  stars.jl — Main-Sequence Stellar Generation
# ══════════════════════════════════════════════════════════════════════
#
#  Implements the Morgan-Keenan (MK) spectral classification system
#  and main-sequence mass–luminosity / mass–radius / mass–temperature
#  scaling relations for procedural star generation.
#
#  References:
#   • Habets & Heintze (1981) — Mass-luminosity relation
#   • Demircan & Kahraman (1991) — Mass-radius relation
#   • Eker et al. (2018) — Updated calibrations
#   • Carroll & Ostlie, "Modern Stellar Astrophysics" (2017)
# ══════════════════════════════════════════════════════════════════════

# ──────────────────────────────────────────────────────────
#  Spectral Classification Enum
# ──────────────────────────────────────────────────────────

"""
    SpectralClass

Morgan-Keenan spectral classification for main-sequence stars.
The mnemonic "Oh Be A Fine Girl/Guy, Kiss Me" encodes the temperature
sequence from hottest (O) to coolest (M).

| Class | T_eff Range (K) | Color          | Mass Range (M☉) |
|-------|-----------------|----------------|------------------|
| O     | 30 000 – 50 000 | Blue           | 16 – 150+        |
| B     | 10 000 – 30 000 | Blue-white     | 2.1 – 16         |
| A     | 7 500 – 10 000  | White          | 1.4 – 2.1        |
| F     | 6 000 – 7 500   | Yellow-white   | 1.04 – 1.4       |
| G     | 5 200 – 6 000   | Yellow         | 0.8 – 1.04       |
| K     | 3 700 – 5 200   | Orange         | 0.45 – 0.8       |
| M     | 2 400 – 3 700   | Red            | 0.08 – 0.45      |
"""
@enum SpectralClass begin
    O_CLASS
    B_CLASS
    A_CLASS
    F_CLASS
    G_CLASS
    K_CLASS
    M_CLASS
end


# ──────────────────────────────────────────────────────────
#  Star Data Structure
# ──────────────────────────────────────────────────────────

"""
    Star

Immutable structure representing a main-sequence star with physically
consistent properties derived from its mass.

# Fields
- `name::String`                — Procedurally generated designation.
- `mass::typeof(1.0u"kg")`      — Stellar mass [kg] (Unitful).
- `luminosity::typeof(1.0u"W")` — Bolometric luminosity [W].
- `radius::typeof(1.0u"m")`     — Photospheric radius [m].
- `temperature::typeof(1.0u"K")`— Effective surface temperature [K].
- `spectral_class::SpectralClass` — MK spectral type.
- `mass_solar::Float64`         — Mass expressed in solar masses (dimensionless).
- `luminosity_solar::Float64`   — Luminosity in solar luminosities (dimensionless).
- `radius_solar::Float64`       — Radius in solar radii (dimensionless).
"""
struct Star
    name::String
    mass::typeof(1.0u"kg")
    luminosity::typeof(1.0u"W")
    radius::typeof(1.0u"m")
    temperature::typeof(1.0u"K")
    spectral_class::SpectralClass
    mass_solar::Float64
    luminosity_solar::Float64
    radius_solar::Float64
end


# ══════════════════════════════════════════════════════════════════════
#  PHYSICS ENGINE — Main-Sequence Scaling Relations
# ══════════════════════════════════════════════════════════════════════

"""
    mass_to_luminosity(M_ratio::Float64) → Float64

Compute the luminosity ratio L/L☉ from the mass ratio M/M☉ using
a piecewise power-law fit to the main-sequence mass–luminosity
relation (Eker et al. 2018; Duric 2004).

The relation is split into four regimes:
  • M < 0.43 M☉  →  L ∝ M^2.3   (fully convective low-mass stars)
  • 0.43 ≤ M < 2  →  L ∝ M^4.0  (solar-type, radiative core)
  • 2 ≤ M < 55    →  L ∝ M^3.5  (intermediate/massive stars)
  • M ≥ 55        →  L ∝ M^1.0  (Eddington-limited super-giants)
"""
function mass_to_luminosity(mass_ratio)
    if mass_ratio < 0.43
        # Fully convective regime
        0.23 * mass_ratio^2.3
    elseif mass_ratio < 2.0
        # Solar-type main-sequence
        mass_ratio^4.0
    elseif mass_ratio < 55.0
        # Upper main-sequence (CNO cycle dominated)
        1.4 * mass_ratio^3.5
    else
        # Eddington limit regime
        32000.0 * mass_ratio
    end
end


"""
    mass_to_radius(M_ratio::Float64) → Float64

Compute the radius ratio R/R☉ from the mass ratio M/M☉ using
a piecewise approximation to the mass–radius relation for
main-sequence stars (Demircan & Kahraman 1991).

  • M < 1.0 M☉  →  R ∝ M^0.8
  • M ≥ 1.0 M☉  →  R ∝ M^0.57
"""
function mass_to_radius(mass_ratio)
    if mass_ratio < 1.0
        mass_ratio^0.8
    else
        mass_ratio^0.57
    end
end


"""
    luminosity_radius_to_temperature(L_ratio::Float64, R_ratio::Float64) → Float64

Derive the effective surface temperature T_eff [K] from the
Stefan-Boltzmann law:

    L = 4π R² σ T⁴

Solving for T in solar units:

    T/T☉ = (L/L☉)^(1/4) / (R/R☉)^(1/2)
"""
function luminosity_radius_to_temperature(lum_ratio, rad_ratio)
    t_ratio = (lum_ratio^0.25) / (rad_ratio^0.5)
    t_ratio * ustrip(T_SUN)  # Returns temperature in Kelvin (scalar)
end


"""
    spectral_class(T_eff::Float64) → SpectralClass

Classify a star into the Morgan-Keenan spectral system based on
its effective surface temperature [K].
"""
function spectral_class(t_eff)
    if t_eff >= 30_000.0
        O_CLASS
    elseif t_eff >= 10_000.0
        B_CLASS
    elseif t_eff >= 7_500.0
        A_CLASS
    elseif t_eff >= 6_000.0
        F_CLASS
    elseif t_eff >= 5_200.0
        G_CLASS
    elseif t_eff >= 3_700.0
        K_CLASS
    else
        M_CLASS
    end
end


# ══════════════════════════════════════════════════════════════════════
#  PROCEDURAL GENERATION
# ══════════════════════════════════════════════════════════════════════

"""
    _generate_star_name() → String

Generate a procedural star designation following the format:
    `<Greek-letter prefix> <3-letter constellation code>-<numeric ID>`

Example: `α CYG-4921`
"""
function _generate_star_name()
    prefixes = ["α", "β", "γ", "δ", "ε", "ζ", "η", "θ", "ι", "κ",
                 "λ", "μ", "ν", "ξ", "ο", "π", "ρ", "σ", "τ", "υ",
                 "φ", "χ", "ψ", "ω"]
    constellations = ["CYG", "ORI", "CEN", "VEL", "LYR", "AQL", "SCO",
                      "SGR", "LEO", "PEG", "AND", "CAS", "DRA", "UMA",
                      "AUR", "GEM", "TAU", "CAR", "PUP", "CRU", "LUP",
                      "ARA", "PAV", "TUC", "PHE", "GRU", "ERI", "COL",
                      "PIC", "VOL", "HOR", "RET", "CAE", "MEN", "OCT"]

    prefix  = rand(prefixes)
    constel = rand(constellations)
    id      = rand(1000:9999)
    "$prefix $constel-$id"
end


"""
    generate_star(; mass_solar::Union{Float64, Nothing}=nothing,
                    name::Union{String, Nothing}=nothing) → Star

Generate a physically consistent main-sequence star.

If `mass_solar` is not provided, the mass is drawn from a Salpeter-like
Initial Mass Function (IMF) approximated as a truncated log-normal
distribution:
  • μ = log(0.5)  (peak near 0.5 M☉, consistent with the field star MF)
  • σ = 0.6
  • Truncated to [0.08, 150] M☉

This provides a convenient truncated log-normal population proxy in which
low-mass stars dominate. It is an exploratory generator, not a Salpeter,
Kroupa, or Chabrier IMF implementation.

# Keyword Arguments
- `mass_solar::Float64` — Override mass in solar masses.
- `name::String`        — Override the procedural name.

# Returns
A fully populated `Star` struct with self-consistent physical properties.

# Example
```julia
star = generate_star()                    # Random mass from IMF
star = generate_star(mass_solar=1.0)      # Sol-like star
star = generate_star(name="Proxima")      # Custom name
```
"""
function generate_star(; mass_solar=nothing, name=nothing)

    # ── Step 1: Determine stellar mass ──────────────────────
    if isnothing(mass_solar)
        # Exploratory truncated log-normal stellar-mass proxy.
        # Peak near 0.5 M☉; this is not a Salpeter/Kroupa/Chabrier IMF.
        raw_dist = LogNormal(log(0.5), 0.6)
        truncated_dist = truncated(raw_dist, 0.08, 150.0)
        mass_solar = rand(truncated_dist)
    end

    # Validate physical bounds
    if !(0.08 ≤ mass_solar ≤ 150.0)
        throw(ArgumentError("Stellar mass must be in [0.08, 150.0] M☉. Got: $mass_solar"))
    end

    # ── Step 2: Compute derived quantities ──────────────────
    lum_ratio = mass_to_luminosity(mass_solar)
    rad_ratio = mass_to_radius(mass_solar)
    t_eff   = luminosity_radius_to_temperature(lum_ratio, rad_ratio)
    sp_class = spectral_class(t_eff)

    # ── Step 3: Convert to SI with Unitful ──────────────────
    mass_si        = mass_solar * M_SUN
    luminosity_si  = lum_ratio * L_SUN
    radius_si      = rad_ratio * R_SUN

    # ── Step 4: Assemble Star struct ────────────────────────
    star_name = isnothing(name) ? _generate_star_name() : name

    Star(
        star_name,
        mass_si,
        luminosity_si,
        radius_si,
        t_eff * 1.0u"K",
        sp_class,
        mass_solar,
        lum_ratio,
        rad_ratio
    )
end


# ══════════════════════════════════════════════════════════════════════
#  DISPLAY & INTROSPECTION
# ══════════════════════════════════════════════════════════════════════

"""
    _spectral_color(sc::SpectralClass) → String

Return a human-readable color string for the given spectral class.
"""
function _spectral_color(sc::SpectralClass)
    color_map = Dict(
        O_CLASS => "Blue",
        B_CLASS => "Blue-White",
        A_CLASS => "White",
        F_CLASS => "Yellow-White",
        G_CLASS => "Yellow",
        K_CLASS => "Orange",
        M_CLASS => "Red"
    )
    get(color_map, sc, "Unknown")
end


"""
    _spectral_label(sc::SpectralClass) → String

Return a clean single-character label for the spectral class.
"""
function _spectral_label(sc::SpectralClass)
    label_map = Dict(
        O_CLASS => "O",
        B_CLASS => "B",
        A_CLASS => "A",
        F_CLASS => "F",
        G_CLASS => "G",
        K_CLASS => "K",
        M_CLASS => "M"
    )
    get(label_map, sc, "?")
end


"""
    star_summary(star::Star) → String

Return a formatted multi-line summary of a star's physical properties,
suitable for terminal output or logging.

# Example Output
```
╔══════════════════════════════════════════╗
║  ★  α ORI-3847                          ║
║  Spectral Class: G (Yellow)             ║
╠══════════════════════════════════════════╣
║  Mass          1.02 M☉                  ║
║  Luminosity    1.08 L☉                  ║
║  Radius        1.02 R☉                  ║
║  Temperature   5823 K                   ║
╚══════════════════════════════════════════╝
```
"""
function star_summary(star::Star)
    sp_label = _spectral_label(star.spectral_class)
    sp_color = _spectral_color(star.spectral_class)
    t_val    = round(ustrip(star.temperature); digits=0)

    lines = [
        "╔══════════════════════════════════════════════╗",
        "║  ★  $(rpad(star.name, 38))  ║",
        "║  Spectral Class: $(rpad("$sp_label ($sp_color)", 26))  ║",
        "╠══════════════════════════════════════════════╣",
        "║  Mass          $(rpad("$(round(star.mass_solar; digits=4)) M☉", 27))  ║",
        "║  Luminosity    $(rpad("$(round(star.luminosity_solar; digits=4)) L☉", 27))  ║",
        "║  Radius        $(rpad("$(round(star.radius_solar; digits=4)) R☉", 27))  ║",
        "║  Temperature   $(rpad("$(Int(t_val)) K", 27))  ║",
        "╚══════════════════════════════════════════════╝"
    ]
    join(lines, "\n")
end


"""
    Base.show(io::IO, star::Star)

Custom pretty-printing for Star objects in the REPL.
"""
function Base.show(io::IO, star::Star)
    sp = _spectral_label(star.spectral_class)
    print(io, "Star(\"$(star.name)\", $(round(star.mass_solar; digits=3)) M☉, " *
              "Class $sp, T=$(Int(round(ustrip(star.temperature)))) K)")
end
