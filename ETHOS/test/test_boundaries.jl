@testset "Document boundaries are semantic boundaries" begin
    phrase = ConceptDefinition("bridge", "Bridge", [["alpha", "beta"]])
    sequences = [["alpha"], ["beta"]]
    @test concept_count(sequences, phrase) == 0
    @test concept_frequency(sequences, phrase; scale = 100.0) == 0.0

    cooccurrence, vocab = ETHOS.cooccurrence_matrix(sequences; window = 2, distance_weighted = false)
    index = Dict(term => i for (i, term) in enumerate(vocab))
    @test cooccurrence[index["alpha"], index["beta"]] == 0.0
    @test cooccurrence[index["beta"], index["alpha"]] == 0.0

    concept = ConceptDefinition("target", "Target", [["target"]])
    result = contextual_valence(
        [["target"], ["good"]],
        concept,
        Dict("good" => 1.0),
        Set{String}();
        window = 3,
    )
    @test isnan(result.mean)
    @test result.contexts == 0
end

@testset "Boundary-aware bootstrap is reproducible" begin
    sequences = [repeat(["care", "duty", "life"], 8), repeat(["care", "justice"], 8)]
    concept = ConceptDefinition("duty", "Duty", [["duty"]])
    first_run = bootstrap_frequency(sequences, concept; replicates = 8, block_size = 6, seed = 77)
    second_run = bootstrap_frequency(sequences, concept; replicates = 8, block_size = 6, seed = 77)
    @test first_run == second_run
end
