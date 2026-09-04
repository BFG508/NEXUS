module ETHOS

using Dates
using LinearAlgebra
using Printf
using Random
using SHA
using Statistics
using TOML

include("types.jl")
include("io.jl")
include("normalization.jl")
include("concepts.jl")
include("frequencies.jl")
include("matrices.jl")
include("embeddings.jl")
include("alignment.jl")
include("sentiment.jl")
include("statistics.jl")
include("visualization.jl")
include("reporting.jl")
include("pipeline.jl")

export AnalysisConfig,
       ConceptDefinition,
       CorpusEntry,
       EmbeddingSpace,
       LoadedDocument,
       align_to_reference,
       bootstrap_frequency,
       bootstrap_semantic_shift,
       build_document_term_matrix,
       build_embedding,
       concept_count,
       concept_frequency,
       concept_ppmi_associations,
       frequency_matched_shift_control,
       concept_vector,
       contextual_valence,
       cosine_similarity,
       load_analysis_config,
       load_concepts,
       load_corpus,
       load_corpus_manifest,
       validate_manifest,
       validate_config,
       normalize_text,
       orthogonal_procrustes,
       ppmi_matrix,
       run_pipeline,
       semantic_shift,
       tokenize,
       tfidf_matrix

end
