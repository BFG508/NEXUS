@testset "Bootstrap frequency" begin
    tokens = repeat(["care", "duty", "care", "life", "justice"], 20)
    concept = ConceptDefinition("duty", "Duty", [["duty"]])
    result = bootstrap_frequency(
        tokens,
        concept;
        scale = 100.0,
        replicates = 10,
        block_size = 10,
        seed = 42,
    )
    @test result.estimate ≈ 20.0
    @test isfinite(result.lower)
    @test isfinite(result.upper)
    @test result.lower <= result.upper
end
