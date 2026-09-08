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

@testset "Semantic bootstrap reports support" begin
    reference = [repeat(["anchor_a", "anchor_b", "anchor_c", "anchor_d", "care"], 30)]
    target = [repeat(["anchor_a", "anchor_b", "anchor_c", "anchor_d", "care"], 30)]
    concept = ConceptDefinition("care", "Care", [["care"]])
    result = bootstrap_semantic_shift(
        reference,
        target,
        concept;
        window = 2,
        maximum_vocabulary = 20,
        dimension = 2,
        minimum_anchors = 2,
        anchor_maximum_frequency_ratio = 2.0,
        replicates = 4,
        block_size = 10,
        minimum_valid_replicates = 2,
        minimum_valid_fraction = 0.5,
        seed = 7,
    )
    @test result.requested_replicates == 4
    @test result.minimum_required == 2
    @test result.sufficient
    @test result.valid_replicates >= 2
    @test isfinite(result.lower)
    @test isfinite(result.upper)
end
