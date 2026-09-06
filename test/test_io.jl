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


@testset "Group metadata consistency" begin
    function fixture(id, label, period, language)
        metadata = CorpusEntry(
            id, "g", label, period, "Work", "Author", 1900, 1900,
            language, language, "", "edition", "prose", "source", "license", "", "",
        )
        return LoadedDocument(metadata, "text", ["text"])
    end
    @test validate_group_consistency(Dict("g" => [fixture("a", "Group", "P", "en"), fixture("b", "Group", "P", "en")]))
    @test_throws ErrorException validate_group_consistency(Dict("g" => [fixture("a", "Group", "P", "en"), fixture("b", "Other", "P", "en")]))
    @test_throws ErrorException validate_group_consistency(Dict("g" => [fixture("a", "Group", "P", "en"), fixture("b", "Group", "Q", "en")]))
    @test_throws ErrorException validate_group_consistency(Dict("g" => [fixture("a", "Group", "P", "en"), fixture("b", "Group", "P", "es")]))
end
