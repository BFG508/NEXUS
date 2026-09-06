using Test
using Random
using astra

@testset "ASTRA smoke and physics invariants" begin
    Random.seed!(42)
    sol = generate_star(mass_solar=1.0, name="Sol-test")
    @test sol.mass_solar == 1.0
    @test sol.luminosity_solar ≈ 1.0 atol=1e-12
    @test sol.radius_solar ≈ 1.0 atol=1e-12
    @test sol.spectral_class == astra.G_CLASS

    @test_throws ArgumentError generate_star(mass_solar=0.01)
    @test_throws ArgumentError generate_star(mass_solar=151.0)

    sys = generate_system(sol; num_planets=3)
    @test length(sys.planets) == 3
    @test all(p -> p.semimajor_axis > zero(p.semimajor_axis), sys.planets)
end
