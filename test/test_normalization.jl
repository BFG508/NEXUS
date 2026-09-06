@testset "Normalization and tokenization" begin
    text = "  DUTY—Mercy\tAND\rCompassion.  Don't fear. “Soul”  "
    normalized = normalize_text(text)
    @test occursin("duty mercy", normalized)
    @test occursin("don't fear", normalized)
    @test tokenize(text) == ["duty", "mercy", "and", "compassion", "don't", "fear", "soul"]
    @test tokenize("a bb ccc"; minimum_length = 2) == ["bb", "ccc"]
end
