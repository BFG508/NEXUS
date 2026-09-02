using Pkg

project = joinpath(@__DIR__, "..")
Pkg.activate(project)
Pkg.resolve()
Pkg.instantiate()
Pkg.precompile()

manifest = joinpath(project, "Manifest.toml")
isfile(manifest) || error("Manifest.toml was not generated.")
println(manifest)
