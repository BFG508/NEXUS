
function _embedding_index(vocab::Vector{String})
    return Dict(term => i for (i, term) in enumerate(vocab))
end

"""
Build dependency-free word embeddings from a positive-PMI matrix and truncated SVD.

The row representation is `U * sqrt(S)`, which factorizes a symmetric association
matrix while retaining an interpretable connection to the PPMI baseline.
"""
function build_embedding(
    tokens::Vector{String};
    window::Int = 4,
    minimum_count::Int = 1,
    maximum_vocabulary::Int = 2000,
    dimension::Int = 50,
    distance_weighted::Bool = true,
)
    cooccurrence, vocab = cooccurrence_matrix(
        tokens;
        window = window,
        minimum_count = minimum_count,
        maximum_vocabulary = maximum_vocabulary,
        distance_weighted = distance_weighted,
    )
    isempty(vocab) && return EmbeddingSpace(String[], Dict{String,Int}(), zeros(0, 0))
    ppmi = ppmi_matrix(cooccurrence)
    factorization = svd(ppmi)
    rank_limit = min(dimension, length(factorization.S))
    rank_limit >= 1 || return EmbeddingSpace(vocab, _embedding_index(vocab), zeros(length(vocab), 0))
    scales = sqrt.(max.(factorization.S[1:rank_limit], 0.0))
    vectors = factorization.U[:, 1:rank_limit] * Diagonal(scales)
    return EmbeddingSpace(vocab, _embedding_index(vocab), Matrix{Float64}(vectors))
end

function cosine_similarity(a::AbstractVector{<:Real}, b::AbstractVector{<:Real})
    length(a) == length(b) || throw(DimensionMismatch("Vectors must have equal length."))
    denominator = norm(a) * norm(b)
    denominator == 0 && return NaN
    return dot(a, b) / denominator
end

function token_vector(space::EmbeddingSpace, token::AbstractString)
    row = get(space.index, String(token), 0)
    row == 0 && return nothing
    return vec(copy(space.vectors[row, :]))
end

function _alias_vector(space::EmbeddingSpace, alias::Vector{String})
    component_vectors = Vector{Vector{Float64}}()
    for token in alias
        vector = token_vector(space, token)
        vector === nothing && return nothing
        push!(component_vectors, vector)
    end
    isempty(component_vectors) && return nothing
    return vec(mean(hcat(component_vectors...); dims = 2))
end

function concept_vector(space::EmbeddingSpace, concept::ConceptDefinition)
    alias_vectors = Vector{Vector{Float64}}()
    for alias in concept.aliases
        vector = _alias_vector(space, alias)
        vector === nothing || push!(alias_vectors, vector)
    end
    isempty(alias_vectors) && return nothing
    return vec(mean(hcat(alias_vectors...); dims = 2))
end

function nearest_neighbors(space::EmbeddingSpace, token::AbstractString; limit::Int = 10)
    query = token_vector(space, token)
    query === nothing && return Tuple{String,Float64}[]
    scores = Tuple{String,Float64}[]
    for candidate in space.vocab
        candidate == token && continue
        vector = token_vector(space, candidate)
        vector === nothing && continue
        score = cosine_similarity(query, vector)
        isfinite(score) && push!(scores, (candidate, score))
    end
    sort!(scores; by = item -> (-item[2], item[1]))
    return scores[1:min(limit, length(scores))]
end

function truncate_embedding(space::EmbeddingSpace, dimension::Int)
    dimension >= 1 || throw(ArgumentError("dimension must be positive"))
    dimension <= size(space.vectors, 2) || throw(
        DimensionMismatch("Requested dimension exceeds the available embedding rank."),
    )
    return EmbeddingSpace(
        space.vocab,
        copy(space.index),
        Matrix{Float64}(space.vectors[:, 1:dimension]),
    )
end
