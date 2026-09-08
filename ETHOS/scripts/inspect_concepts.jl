import Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using ETHOS

config_path = isempty(ARGS) ? joinpath(@__DIR__, "..", "config", "pipeline.toml") : ARGS[1]
config = load_analysis_config(config_path)
concepts = load_concepts(config.concepts_path)
entries = load_corpus_manifest(config.corpora_path; root = config.root)
documents = load_corpus(entries; minimum_token_length = config.minimum_token_length)

for concept in concepts
    println("$(concept.label) [$(concept.id)]")
    for document in documents
        count = concept_count(document.tokens, concept)
        count > 0 && println("  $(document.metadata.id): $count")
    end
end
