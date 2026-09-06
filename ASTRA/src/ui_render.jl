# ══════════════════════════════════════════════════════════════════════
#  ui_render.jl — 2D Orbital Map Visualization
# ══════════════════════════════════════════════════════════════════════

using Plots
using Unitful

"""
    plot_system(sys::System; filename::String="orbital_map.svg")

Generates a 2D polar plot of the planetary system, including the star,
the habitable zone (green gradient), and the planets.
"""
function plot_system(sys::System; filename::String="orbital_map.svg")
    # Set up the polar plot
    plt = plot(proj=:polar, legend=false, grid=true, size=(800, 800),
               title="System Map: $(sys.star.name)\nClass: $(sys.star.spectral_class)",
               background_color=:black, foreground_color_grid=:gray40,
               foreground_color_text=:white, foreground_color_border=:gray40)
    
    # Find max distance to scale the plot
    max_a = isempty(sys.planets) ? 5.0 : maximum(p -> ustrip(p.semimajor_axis)/ustrip(AU), sys.planets) * 1.2
    hz_inner, hz_opt, hz_outer = habitable_zone_boundaries(sys.star)
    max_a = max(max_a, hz_outer * 1.2)
    
    # Plot Habitable Zone
    theta = range(0, 2π, length=100)
    plot!(plt, theta, fill(hz_outer, 100), fillrange=fill(hz_inner, 100), 
          color=:green, alpha=0.15, label="Habitable Zone")
    
    plot!(plt, theta, fill(hz_opt, 100), color=:lime, linestyle=:dash, alpha=0.5, label="Optimal HZ")
    
    # Plot Star
    scatter!(plt, [0.0], [0.0], color=:gold, markersize=15, label=sys.star.name)
    
    # Plot Planets
    colors = [:lightblue, :orange, :brown, :red, :cyan, :magenta, :yellow, :white]
    
    for (i, p) in enumerate(sys.planets)
        a_au = ustrip(p.semimajor_axis) / ustrip(AU)
        # Randomize theta for visual spread
        p_theta = rand(Uniform(0, 2π))
        
        c = colors[(i % length(colors)) + 1]
        
        # Draw orbit line
        plot!(plt, theta, fill(a_au, 100), color=c, alpha=0.3, linestyle=:dot)
        
        # Draw planet
        sz = clamp(ustrip(p.radius)/ustrip(R_EARTH) * 4, 3, 10)
        scatter!(plt, [p_theta], [a_au], color=c, markersize=sz)
        
        # Annotate
        annotate!(plt, p_theta + 0.1, a_au * 1.05, text(p.name, 9, :left, :bottom, :white))
    end
    
    # Limits
    ylims!(plt, 0, max_a)
    
    savefig(plt, filename)
    println("✅ 2D Orbital map saved to $filename")
    return plt
end
