# ASTRA → SCALE compatibility exporter.
# SCALE GameEntity.attributes are dice expressions, so this adapter exports
# only rollable numeric attributes rather than arbitrary descriptive metadata.

using JSON

function _scale_tech_rank(level::String)
    levels = [
        "Stone Age (Hunter-Gatherer)",
        "Bronze/Iron Age (Agricultural)",
        "Medieval / Feudal",
        "Industrial Revolution",
        "Atomic Age",
        "Information Age",
        "Early Spacefaring",
        "Post-Biological / Mechanized",
    ]
    idx = findfirst(==(level), levels)
    isnothing(idx) ? 1 : idx
end

function _scale_conflict_expression(conflict::String)
    if occursin("Absolute Zero", conflict)
        return "1d1-11"  # deterministic -10 using SCALE's existing grammar
    elseif occursin("High", conflict)
        return "1d1-6"   # deterministic -5
    elseif occursin("Low", conflict)
        return "5"
    else
        return "0"
    end
end

"""
    export_to_scale(systems::Vector{System}, filename::String="entities.json")

Export civilizations as SCALE `GameEntity` objects. Every value inside
`attributes` is a valid SCALE expression. Descriptive ASTRA metadata is not
embedded because SCALE v0.1.0 treats every entity attribute as rollable input.
"""
function export_to_scale(systems::Vector{System}, filename::String="entities.json")
    entities = []
    for sys in systems
        for planet in sys.planets
            civ = infer_civilization(sys.star, planet)
            isnothing(civ) && continue
            push!(entities, Dict(
                "name" => civ.name,
                "attributes" => Dict(
                    "conflict_modifier" => _scale_conflict_expression(civ.conflict_tendency),
                    "tech_rank" => string(_scale_tech_rank(civ.tech_level)),
                ),
            ))
        end
    end

    if isempty(entities)
        println("⚠️  No civilizations found to export to SCALE.")
        return
    end
    mkpath(dirname(abspath(filename)))
    open(filename, "w") do io
        JSON.print(io, entities, 4)
    end
    println("✅ Exported $(length(entities)) SCALE-compatible civilizations: $filename")
end
