# This file is intentionally executable as a plain Julia script and can also be
# pasted into a Pluto notebook. It uses only the public SemanticLogos API.

import Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using SemanticLogos

config = load_analysis_config(joinpath(@__DIR__, "..", "config", "pipeline.toml"))
entries = load_corpus_manifest(config.corpora_path)
documents = load_corpus(entries; minimum_token_length = config.minimum_token_length)
concepts = load_concepts(config.concepts_path)

println("Documents: $(length(documents))")
for document in documents
    println("$(document.metadata.id): $(length(document.tokens)) tokens")
end

println("\nConcept occurrences:")
for concept in concepts
    total = sum(concept_count(document.tokens, concept) for document in documents)
    println("$(concept.label): $total")
end
