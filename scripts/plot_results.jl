using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using CSV
using CairoMakie
using DataFrames

function main()
    input_file = length(ARGS) >= 1 ? ARGS[1] : joinpath(@__DIR__, "..", "results", "simulation_seed_42.csv")
    data = CSV.read(input_file, DataFrame)

    fig = Figure(size = (1100, 900))
    ax1 = Axis(fig[1, 1], xlabel = "Generation", ylabel = "Population fraction", title = "Doctrine frequencies")
    lines!(ax1, data.generation, data.egoist_fraction, label = "Egoist")
    lines!(ax1, data.generation, data.altruist_fraction, label = "Altruist")
    lines!(ax1, data.generation, data.utilitarian_fraction, label = "Utilitarian")
    lines!(ax1, data.generation, data.reciprocal_fraction, label = "Strict reciprocal")
    axislegend(ax1, position = :rb)

    ax2 = Axis(fig[2, 1], xlabel = "Generation", ylabel = "Rate", title = "Realized cooperation")
    lines!(ax2, data.generation, data.cooperation_rate)
    ylims!(ax2, 0, 1)

    ax3 = Axis(fig[3, 1], xlabel = "Generation", ylabel = "Population", title = "Population dynamics")
    lines!(ax3, data.generation, data.population_size)

    output_file = replace(input_file, r"\.csv$" => "_summary.png")
    save(output_file, fig)
    println(output_file)
end

main()
