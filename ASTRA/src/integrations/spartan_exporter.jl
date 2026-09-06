using UUIDs

# ══════════════════════════════════════════════════════════════════════
#  spartan_exporter.jl — Integration for SPARTAN
# ══════════════════════════════════════════════════════════════════════

"""
    export_to_spartan(systems::Vector{System}, filename::String="spartan_import.txt")

Exports generated aerospace assets for advanced civilizations into a
strict 28-byte records for SPARTAN's explicit import queue.
"""
function export_to_spartan(systems::Vector{System}, filename::String="spartan_import.txt")
    node_types = ["HUB", "PROBE", "RELAY", "SATELLITE", "STATION", "CRUISER", "FRIGATE"]
    records = String[]
    
    for sys in systems
        for p in sys.planets
            civ = infer_civilization(sys.star, p)
            if !isnothing(civ)
                # Determine number of assets based on tech level
                n_assets = 0
                if occursin("Spacefaring", civ.tech_level) || occursin("Post-Biological", civ.tech_level)
                    n_assets = rand(20:50)
                elseif occursin("Information", civ.tech_level) || occursin("Atomic", civ.tech_level)
                    n_assets = rand(2:10)
                else
                    continue # Primitive civs don't have orbital assets
                end
                
                for _ in 1:n_assets
                    node_type = rpad(rand(node_types), 10)[1:10]
                    # 10-byte low-collision integration ID: AST- + 6 UUID hex chars.
                    node_id = "AST-" * replace(string(uuid4()), "-" => "")[1:6]
                    
                    integrity = rand() > 0.3 ? 100 : rand(30:99)
                    delta_v = rand(10000:99999)
                    
                    # Format strictly to 28 bytes
                    integrity_str = lpad(integrity, 3, '0')[1:3]
                    deltav_str = lpad(delta_v, 5, '0')[1:5]
                    
                    record = "$(node_type)$(node_id)$(integrity_str)$(deltav_str)\n"
                    push!(records, record)
                end
            end
        end
    end
    
    if isempty(records)
        println("⚠️  No advanced civilizations found to generate SPARTAN assets.")
        return
    end
    
    mkpath(dirname(abspath(filename)))
    open(filename, "a") do io
        for rec in records
            print(io, rec)
        end
    end
    println("✅ Exported $(length(records)) orbital assets to SPARTAN format: $filename")
end
