@testset "Edge cases and explicit failures" begin
    @test isempty(tokenize(""))
    @test concept_frequency(Vector{Vector{String}}(), ConceptDefinition("x", "X", [["x"]])) == 0.0

    @test cosine_similarity([1.0, 0.0], [1.0, 0.0]) == 1.0
    @test cosine_similarity([1.0, 0.0], [-1.0, 0.0]) == -1.0
    @test isnan(cosine_similarity([0.0, 0.0], [1.0, 0.0]))
    @test_throws DimensionMismatch cosine_similarity([1.0], [1.0, 2.0])

    @test_throws ArgumentError build_embedding(["a", "b"]; dimension = 0)
    @test_throws ArgumentError orthogonal_procrustes(zeros(2, 0), zeros(2, 0))

    empty_space = build_embedding(String[])
    @test isempty(empty_space.vocab)
    @test size(empty_space.vectors) == (0, 0)
end
