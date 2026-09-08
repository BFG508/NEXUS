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

@testset "Cross-language comparisons are rejected" begin
    function language_fixture(id, group, language)
        metadata = CorpusEntry(
            id, group, group, "P", "Work", "Author", 1900, 1900,
            language, language, "", "edition", "prose", "source", "license", "", "",
        )
        return LoadedDocument(metadata, "text", ["text"])
    end
    groups = Dict(
        "english" => [language_fixture("a", "english", "en")],
        "spanish" => [language_fixture("b", "spanish", "es")],
    )
    @test_throws ArgumentError validate_comparison_languages(
        groups,
        [ComparisonSpec("english", "spanish")],
    )
end

@testset "Config root is explicit and portable" begin
    source_root = normpath(joinpath(@__DIR__, ".."))
    mktempdir() do temp_dir
        nested = joinpath(temp_dir, "nested")
        mkpath(nested)
        config_path = joinpath(nested, "portable.toml")
        write(config_path, """
[project]
root = \"$(replace(source_root, "\\" => "\\\\"))\"
corpora = \"config/corpora.toml\"
concepts = \"config/concepts.toml\"
stopwords = \"config/stopwords_en.txt\"
valence_lexicon = \"config/valence_en.toml\"
results_dir = \"results\"
[provenance]
require_checksums = true
require_translator_for_translation = true
[preprocessing]
minimum_token_length = 1
remove_stopwords_for_dtm = true
[frequency]
normalization_scale = 1000.0
[cooccurrence]
window = 2
distance_weighted = true
[embeddings]
window = 2
minimum_count = 1
maximum_vocabulary = 100
dimension = 2
minimum_anchors = 2
[alignment]
minimum_frequency = 1
maximum_frequency_ratio = 6.0
maximum_anchors = 0
[controls]
frequency_ratio = 3.0
maximum_controls = 10
minimum_controls = 2
[sentiment]
window = 3
negation_window = 1
[statistics]
frequency_bootstrap_replicates = 2
semantic_bootstrap_replicates = 2
semantic_bootstrap_maximum_vocabulary = 50
bootstrap_block_size = 5
minimum_valid_bootstrap_replicates = 1
minimum_valid_bootstrap_fraction = 0.5
confidence_level = 0.95
random_seed = 1
[visualization]
maximum_labels = 5
""")
        config = load_analysis_config(config_path)
        @test config.root == source_root
        @test config.corpora_path == joinpath(source_root, "config", "corpora.toml")
        @test validate_config(config)
    end
end
