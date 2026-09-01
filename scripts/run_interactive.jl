using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using Agents
using EDEN
using GLMakie

function doctrine_color(agent)
    agent.doctrine_tag == Egoist && return "#d1495b"
    agent.doctrine_tag == Altruist && return "#2a9d8f"
    agent.doctrine_tag == Utilitarian && return "#3a86ff"
    return "#8338ec"
end

function main()
    GLMakie.activate!()
    params = SimulationParameters(
        population_size = 400,
        spatial = true,
        grid_size = (40, 40),
        neighborhood_radius = 2,
        move_agents = true,
        seed = 42,
    )
    model = build_model(params)

    fig, _, _ = abmplot(
        model;
        agent_color = doctrine_color,
        agent_size = 8,
        add_controls = true,
        dt = 1:10,
        axis = (title = "EDEN spatial evolutionary dynamics",),
    )
    screen = GLMakie.Screen()
    display(screen, fig)
    wait(screen)
end

main()
