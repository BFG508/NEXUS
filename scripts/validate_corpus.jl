import Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using ETHOS

config_path = isempty(ARGS) ? joinpath(@__DIR__, "..", "config", "pipeline.toml") : ARGS[1]
config = load_analysis_config(config_path)
entries = load_corpus_manifest(config.corpora_path)
validate_manifest(
    entries;
    require_checksums = config.require_checksums,
    require_translator_for_translation = config.require_translator_for_translation,
)
documents = load_corpus(entries; minimum_token_length = config.minimum_token_length)

println("Corpus validation passed.")
for document in documents
    println("- $(document.metadata.id): $(length(document.tokens)) tokens")
end
