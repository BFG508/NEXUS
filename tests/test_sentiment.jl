@testset "Contextual valence and negation" begin
    concept = ConceptDefinition("compassion", "Compassion", [["compassion"]])
    lexicon = Dict("harm" => -0.8, "care" => 0.8)
    negations = Set(["not"])

    positive = contextual_valence(
        ["compassion", "with", "care"],
        concept,
        lexicon,
        negations;
        window = 3,
        negation_window = 2,
    )
    @test positive.mean ≈ 0.8

    negated = contextual_valence(
        ["compassion", "does", "not", "harm"],
        concept,
        lexicon,
        negations;
        window = 4,
        negation_window = 2,
    )
    @test negated.mean ≈ 0.8
end
