@testset "Numerical regression and invariants" begin
    dtm = [2.0 0.0; 1.0 1.0]
    tfidf = tfidf_matrix(dtm)
    expected_idf_second = log(3 / 2) + 1.0
    @test tfidf[1, 1] ≈ 1.0 atol = 1e-12
    @test tfidf[1, 2] == 0.0
    @test tfidf[2, 1] ≈ 0.5 atol = 1e-12
    @test tfidf[2, 2] ≈ 0.5 * expected_idf_second atol = 1e-12

    cooccurrence, _ = ETHOS.cooccurrence_matrix(
        [["a", "b", "a"], ["b", "c"]];
        window = 1,
        distance_weighted = false,
    )
    ppmi = ppmi_matrix(cooccurrence)
    @test all(isfinite, ppmi)
    @test all(ppmi .>= 0.0)

    source = [1.0 0.0; 0.0 1.0; 1.0 1.0]
    theta = 0.31
    rotation = [cos(theta) -sin(theta); sin(theta) cos(theta)]
    target = source * rotation
    transform = orthogonal_procrustes(target, source)
    @test transform' * transform ≈ [1.0 0.0; 0.0 1.0] atol = 1e-10
    @test target * transform ≈ source atol = 1e-10

    @test -1.0 <= cosine_similarity([1.0, 0.0], [1.0, 1.0]) <= 1.0
end
