"""Metadata describing one source document in a corpus."""
struct CorpusEntry
    id::String
    group::String
    label::String
    period::String
    work::String
    author::String
    year::Int
    original_year::Int
    language::String
    original_language::String
    translator::String
    edition::String
    genre::String
    source::String
    license::String
    path::String
    sha256::String
end

"""A source document paired with its normalized token sequence."""
struct LoadedDocument
    metadata::CorpusEntry
    raw_text::String
    tokens::Vector{String}
end

"""A concept represented by one or more lexical aliases, including phrases."""
struct ConceptDefinition
    id::String
    label::String
    aliases::Vector{Vector{String}}
end

"""A dense vector space with row-wise token vectors."""
struct EmbeddingSpace
    vocab::Vector{String}
    index::Dict{String,Int}
    vectors::Matrix{Float64}
end

"""An explicit semantic comparison from one corpus group to another."""
struct ComparisonSpec
    reference::String
    target::String
end

"""Expected alignment failure caused by too few usable anchors."""
struct InsufficientAnchorsError <: Exception
    found::Int
    required::Int
    dimension::Int
end

function Base.showerror(io::IO, error::InsufficientAnchorsError)
    print(
        io,
        "Insufficient shared anchors: $(error.found) found, $(error.required) required " *
        "for an embedding dimension of $(error.dimension).",
    )
end

"""Expected alignment failure caused by a rank-deficient anchor geometry."""
struct DegenerateAlignmentError <: Exception
    rank::Int
    required_rank::Int
end

function Base.showerror(io::IO, error::DegenerateAlignmentError)
    print(
        io,
        "Degenerate alignment geometry: anchor rank $(error.rank), " *
        "required rank $(error.required_rank).",
    )
end

"""Resolved pipeline settings loaded from TOML."""
struct AnalysisConfig
    root::String
    corpora_path::String
    concepts_path::String
    stopwords_path::String
    valence_path::String
    results_dir::String
    require_checksums::Bool
    require_translator_for_translation::Bool
    minimum_token_length::Int
    remove_stopwords_for_dtm::Bool
    frequency_scale::Float64
    cooccurrence_window::Int
    distance_weighted::Bool
    embedding_window::Int
    embedding_minimum_count::Int
    embedding_maximum_vocabulary::Int
    embedding_dimension::Int
    minimum_anchors::Int
    anchor_minimum_frequency::Int
    anchor_maximum_frequency_ratio::Float64
    anchor_maximum_count::Int
    control_frequency_ratio::Float64
    maximum_controls::Int
    minimum_controls::Int
    sentiment_window::Int
    negation_window::Int
    frequency_bootstrap_replicates::Int
    semantic_bootstrap_replicates::Int
    semantic_bootstrap_maximum_vocabulary::Int
    bootstrap_block_size::Int
    minimum_valid_bootstrap_replicates::Int
    minimum_valid_bootstrap_fraction::Float64
    confidence_level::Float64
    random_seed::Int
    maximum_labels::Int
    comparisons::Vector{ComparisonSpec}
end
