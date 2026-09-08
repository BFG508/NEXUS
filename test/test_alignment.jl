@testset "Orthogonal alignment" begin
    vocab = ["anchor_a", "anchor_b", "concept"]
    reference_vectors = [1.0 0.0; 0.0 1.0; 1 / sqrt(2) 1 / sqrt(2)]
    angle = 0.7
    rotation = [cos(angle) -sin(angle); sin(angle) cos(angle)]
    target_vectors = reference_vectors * rotation

    reference = EmbeddingSpace(vocab, Dict(term => i for (i, term) in enumerate(vocab)), reference_vectors)
    target = EmbeddingSpace(vocab, Dict(term => i for (i, term) in enumerate(vocab)), target_vectors)

    aligned, anchors = align_to_reference(
        reference,
        target;
        minimum_anchors = 2,
        excluded = Set(["concept"]),
    )
    @test length(anchors) == 2
    @test aligned.vectors ≈ reference_vectors atol = 1e-10

    concept = ConceptDefinition("concept", "Concept", [["concept"]])
    @test semantic_shift(reference, aligned, concept) ≈ 0.0 atol = 1e-10
end

@testset "Semantic shift uses shared aliases only" begin
    reference = EmbeddingSpace(
        ["shared", "reference_only"],
        Dict("shared" => 1, "reference_only" => 2),
        [1.0 0.0; 0.0 1.0],
    )
    target = EmbeddingSpace(
        ["shared", "target_only"],
        Dict("shared" => 1, "target_only" => 2),
        [1.0 0.0; 0.0 -1.0],
    )
    concept = ConceptDefinition(
        "concept",
        "Concept",
        [["shared"], ["reference_only"], ["target_only"]],
    )
    @test semantic_shift(reference, target, concept) ≈ 0.0 atol = 1e-12

    no_shared = ConceptDefinition(
        "no_shared",
        "No shared alias",
        [["reference_only"], ["target_only"]],
    )
    @test isnan(semantic_shift(reference, target, no_shared))
end

@testset "Alignment safeguards" begin
    reference = EmbeddingSpace(
        ["a", "b", "c"],
        Dict("a" => 1, "b" => 2, "c" => 3),
        [1.0 0.0; 0.0 1.0; 1.0 1.0],
    )
    target = EmbeddingSpace(
        ["a", "b", "c"],
        Dict("a" => 1, "b" => 2, "c" => 3),
        [0.0 1.0; -1.0 0.0; -1.0 1.0],
    )
    @test_throws InsufficientAnchorsError align_to_reference(
        reference,
        target;
        minimum_anchors = 4,
    )

    degenerate = [1.0 0.0; 2.0 0.0; 3.0 0.0]
    @test_throws DegenerateAlignmentError orthogonal_procrustes(
        degenerate,
        degenerate;
        normalize_rows = true,
    )
end
