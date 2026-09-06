@testset "Matrix baselines" begin
    metadata = CorpusEntry(
        "d1", "g", "G", "P", "W", "A", 1, 1, "en", "en", "", "", "", "", "", "", "",
    )
    document = LoadedDocument(metadata, "alpha beta alpha", ["alpha", "beta", "alpha"])
    dtm, terms = build_document_term_matrix([document])
    @test size(dtm, 1) == 1
    @test sum(dtm) == 3
    @test Set(terms) == Set(["alpha", "beta"])

    weighted = tfidf_matrix(dtm)
    @test size(weighted) == size(dtm)
    @test all(weighted .>= 0)

    cooccurrence, vocab = ETHOS.cooccurrence_matrix(
        ["alpha", "beta", "alpha", "gamma"];
        window = 2,
    )
    @test size(cooccurrence, 1) == length(vocab)
    ppmi = ppmi_matrix(cooccurrence)
    @test all(ppmi .>= 0)
end
