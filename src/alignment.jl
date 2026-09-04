
"""Solve the orthogonal Procrustes transform that maps `source` rows to `target` rows."""
function orthogonal_procrustes(source::AbstractMatrix{<:Real}, target::AbstractMatrix{<:Real})
    size(source) == size(target) || throw(DimensionMismatch("Source and target must match."))
    size(source, 1) >= 2 || throw(ArgumentError("At least two anchors are required."))
    cross_covariance = Matrix{Float64}(source)' * Matrix{Float64}(target)
    factorization = svd(cross_covariance)
    return factorization.U * factorization.Vt
end

function shared_vocabulary(
    reference::EmbeddingSpace,
    target::EmbeddingSpace;
    excluded::Set{String} = Set{String}(),
)
    shared = intersect(Set(reference.vocab), Set(target.vocab))
    return sort([term for term in shared if !(term in excluded)])
end

"""
Align `target` into the coordinate system of `reference` using shared anchor tokens.
"""
function align_to_reference(
    reference::EmbeddingSpace,
    target::EmbeddingSpace;
    minimum_anchors::Int = 8,
    excluded::Set{String} = Set{String}(),
)
    size(reference.vectors, 2) == size(target.vectors, 2) || throw(
        DimensionMismatch("Embedding dimensions must match before alignment."),
    )
    anchors = shared_vocabulary(reference, target; excluded = excluded)
    length(anchors) >= minimum_anchors || error(
        "Insufficient shared anchors: $(length(anchors)) found, $minimum_anchors required.",
    )
    reference_matrix = reduce(vcat, (reference.vectors[reference.index[token], :]' for token in anchors))
    target_matrix = reduce(vcat, (target.vectors[target.index[token], :]' for token in anchors))
    transform = orthogonal_procrustes(target_matrix, reference_matrix)
    aligned_vectors = target.vectors * transform
    return EmbeddingSpace(target.vocab, copy(target.index), Matrix{Float64}(aligned_vectors)), anchors
end

function _shared_concept_vectors(
    reference::EmbeddingSpace,
    aligned_target::EmbeddingSpace,
    concept::ConceptDefinition,
)
    reference_aliases = Vector{Vector{Float64}}()
    target_aliases = Vector{Vector{Float64}}()
    for alias in concept.aliases
        reference_vector = _alias_vector(reference, alias)
        target_vector = _alias_vector(aligned_target, alias)
        if reference_vector !== nothing && target_vector !== nothing
            push!(reference_aliases, reference_vector)
            push!(target_aliases, target_vector)
        end
    end
    isempty(reference_aliases) && return nothing, nothing
    reference_vector = vec(mean(hcat(reference_aliases...); dims = 2))
    target_vector = vec(mean(hcat(target_aliases...); dims = 2))
    return reference_vector, target_vector
end

function semantic_shift(
    reference::EmbeddingSpace,
    aligned_target::EmbeddingSpace,
    concept::ConceptDefinition,
)
    reference_vector, target_vector = _shared_concept_vectors(reference, aligned_target, concept)
    (reference_vector === nothing || target_vector === nothing) && return NaN
    similarity = cosine_similarity(reference_vector, target_vector)
    return isfinite(similarity) ? 1.0 - similarity : NaN
end

function _token_shift(reference::EmbeddingSpace, aligned_target::EmbeddingSpace, token::String)
    reference_vector = token_vector(reference, token)
    target_vector = token_vector(aligned_target, token)
    (reference_vector === nothing || target_vector === nothing) && return NaN
    similarity = cosine_similarity(reference_vector, target_vector)
    return isfinite(similarity) ? 1.0 - similarity : NaN
end

"""
Compare a concept shift with shared non-concept terms of similar corpus frequency.

The result is a descriptive control baseline intended to expose frequency-related
embedding instability. It is not a causal correction for all corpus confounders.
"""
function frequency_matched_shift_control(
    reference::EmbeddingSpace,
    aligned_target::EmbeddingSpace,
    reference_tokens::Vector{String},
    target_tokens::Vector{String},
    concept::ConceptDefinition;
    excluded::Set{String} = Set{String}(),
    frequency_ratio::Float64 = 3.0,
    maximum_controls::Int = 30,
    minimum_controls::Int = 5,
)
    frequency_ratio >= 1.0 || throw(ArgumentError("frequency_ratio must be at least 1"))
    maximum_controls >= 1 || throw(ArgumentError("maximum_controls must be positive"))
    reference_counts = token_counts(reference_tokens)
    target_counts = token_counts(target_tokens)
    concept_terms = [
        term for term in concept_tokens(concept)
        if haskey(reference_counts, term) && haskey(target_counts, term)
    ]
    isempty(concept_terms) && return (
        mean = NaN,
        standard_deviation = NaN,
        z_score = NaN,
        controls = 0,
    )

    reference_frequency = mean(Float64(reference_counts[term]) for term in concept_terms)
    target_frequency = mean(Float64(target_counts[term]) for term in concept_terms)
    target_scale = sqrt(max(reference_frequency * target_frequency, eps(Float64)))

    shared = shared_vocabulary(reference, aligned_target; excluded = excluded)
    candidates = Tuple{String,Float64}[]
    lower_bound = target_scale / frequency_ratio
    upper_bound = target_scale * frequency_ratio
    for token in shared
        haskey(reference_counts, token) || continue
        haskey(target_counts, token) || continue
        comparison_scale = sqrt(Float64(reference_counts[token]) * Float64(target_counts[token]))
        lower_bound <= comparison_scale <= upper_bound || continue
        distance = abs(log((comparison_scale + eps(Float64)) / target_scale))
        push!(candidates, (token, distance))
    end
    sort!(candidates; by = item -> (item[2], item[1]))
    candidates = candidates[1:min(maximum_controls, length(candidates))]

    shifts = Float64[]
    for (token, _) in candidates
        shift = _token_shift(reference, aligned_target, token)
        isfinite(shift) && push!(shifts, shift)
    end
    length(shifts) >= minimum_controls || return (
        mean = isempty(shifts) ? NaN : mean(shifts),
        standard_deviation = length(shifts) >= 2 ? std(shifts) : NaN,
        z_score = NaN,
        controls = length(shifts),
    )

    control_mean = mean(shifts)
    control_standard_deviation = std(shifts)
    concept_value = semantic_shift(reference, aligned_target, concept)
    z_score = if isfinite(concept_value) && control_standard_deviation > 0
        (concept_value - control_mean) / control_standard_deviation
    else
        NaN
    end
    return (
        mean = control_mean,
        standard_deviation = control_standard_deviation,
        z_score = z_score,
        controls = length(shifts),
    )
end
