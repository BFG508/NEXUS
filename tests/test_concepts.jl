@testset "Concept matching" begin
    concept = ConceptDefinition(
        "soul",
        "Soul",
        [["soul"], ["spirit"], ["inner", "life"]],
    )
    tokens = ["the", "inner", "life", "and", "soul", "and", "spirit"]
    @test concept_count(tokens, concept) == 3
    @test concept_frequency(tokens, concept; scale = 100.0) ≈ 300 / 7
end

@testset "Longest alias preference" begin
    concept = ConceptDefinition("x", "X", [["inner"], ["inner", "life"]])
    @test concept_count(["inner", "life"], concept) == 1
end
