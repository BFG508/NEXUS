@testset "Manifest validation" begin
    translated_without_translator = CorpusEntry(
        "id",
        "group",
        "label",
        "period",
        "work",
        "author",
        1900,
        1800,
        "en",
        "fr",
        "",
        "edition",
        "prose",
        "source",
        "license",
        "path",
        repeat("a", 64),
    )
    @test_throws ErrorException validate_manifest(
        [translated_without_translator];
        require_checksums = true,
        require_translator_for_translation = true,
    )

    valid = CorpusEntry(
        "id",
        "group",
        "label",
        "period",
        "work",
        "author",
        1900,
        1800,
        "en",
        "fr",
        "translator",
        "edition",
        "prose",
        "source",
        "license",
        "path",
        repeat("a", 64),
    )
    @test validate_manifest(
        [valid];
        require_checksums = true,
        require_translator_for_translation = true,
    )
end
