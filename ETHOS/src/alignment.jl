function _row_normalized(matrix::AbstractMatrix{<:Real})
    values = Matrix{Float64}(matrix)
    normalized = similar(values)
    for row in axes(values, 1)
        row_norm = norm(view(values, row, :))
        row_norm > 0 || throw(DegenerateAlignmentError(0, size(values, 2)))
        normalized[row, :] .= values[row, :] ./ row_norm
    end
    return normalized
end

function _numerical_rank(matrix::AbstractMatrix{<:Real})
    values = Matrix{Float64}(matrix)
    isempty(values) && return 0
    singular_values = svdvals(values)
    isempty(singular_values) && return 0
    tolerance = maximum(size(values)) * eps(Float64) * maximum(singular_values)
    return count(>(tolerance), singular_values)
end

"""Return rank diagnostics for an anchor matrix pair."""
function alignment_diagnostics(source::AbstractMatrix{<:Real}, target::AbstractMatrix{<:Real})
    size(source) == size(target) || throw(DimensionMismatch("Source and target must match."))
    dimension = size(source, 2)
    source_rank = _numerical_rank(source)
    target_rank = _numerical_rank(target)
    return (
        anchors = size(source, 1),
        dimension = dimension,
        source_rank = source_rank,
        target_rank = target_rank,
        full_rank = min(source_rank, target_rank) >= dimension,
    )
end

"""Solve the orthogonal Procrustes transform that maps `source` rows to `target` rows."""
function orthogonal_procrustes(
    source::AbstractMatrix{<:Real},
    target::AbstractMatrix{<:Real};
    normalize_rows::Bool = false,
)
    size(source) == size(target) || throw(DimensionMismatch("Source and target must match."))
    size(source, 1) >= 2 || throw(ArgumentError("At least two anchors are required."))
    size(source, 2) >= 1 || throw(ArgumentError("Embedding dimension must be positive."))
    source_values = normalize_rows ? _row_normalized(source) : Matrix{Float64}(source)
    target_values = normalize_rows ? _row_normalized(target) : Matrix{Float64}(target)
    diagnostics = alignment_diagnostics(source_values, target_values)
    diagnostics.full_rank || throw(
        DegenerateAlignmentError(
            min(diagnostics.source_rank, diagnostics.target_rank),
            diagnostics.dimension,
        ),
    )
    cross_covariance = source_values' * target_values
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
Select frequency-stable shared alignment anchors.

Candidate anchors must be observed at least `minimum_frequency` times in both
corpora. Extremely unbalanced terms are excluded using the ratio between the
larger and smaller corpus count. Candidates are ordered by frequency balance
and then by support, which makes the selection deterministic.
"""
function select_alignment_anchors(
    reference::EmbeddingSpace,
    target::EmbeddingSpace,
    reference_sequences::Vector{Vector{String}},
    target_sequences::Vector{Vector{String}};
    excluded::Set{String} = Set{String}(),
    minimum_frequency::Int = 1,
    maximum_frequency_ratio::Float64 = 6.0,
    maximum_anchors::Int = 0,
)
    minimum_frequency >= 1 || throw(ArgumentError("minimum_frequency must be positive"))
    maximum_frequency_ratio >= 1.0 || throw(ArgumentError("maximum_frequency_ratio must be at least 1"))
    maximum_anchors >= 0 || throw(ArgumentError("maximum_anchors must be non-negative"))

    reference_counts = token_counts(reference_sequences)
    target_counts = token_counts(target_sequences)
    candidates = Tuple{String,Float64,Int}[]
    for token in shared_vocabulary(reference, target; excluded = excluded)
        reference_count = get(reference_counts, token, 0)
        target_count = get(target_counts, token, 0)
        min(reference_count, target_count) >= minimum_frequency || continue
        ratio = max(reference_count, target_count) / max(min(reference_count, target_count), 1)
        ratio <= maximum_frequency_ratio || continue
        imbalance = abs(log(reference_count / target_count))
        support = min(reference_count, target_count)
        push!(candidates, (token, imbalance, support))
    end
    sort!(candidates; by = item -> (item[2], -item[3], item[1]))
    if maximum_anchors > 0
        candidates = candidates[1:min(maximum_anchors, length(candidates))]
    end
    return [item[1] for item in candidates]
end

function _anchor_matrix(space::EmbeddingSpace, anchors::Vector{String})
    isempty(anchors) && return zeros(0, size(space.vectors, 2))
    matrix = Matrix{Float64}(undef, length(anchors), size(space.vectors, 2))
    for (row, token) in enumerate(anchors)
        matrix[row, :] .= space.vectors[space.index[token], :]
    end
    return matrix
end

"""
Align `target` into the coordinate system of `reference` using shared anchor tokens.

The alignment requires at least as many independent anchors as embedding
dimensions, verifies numerical rank, and row-normalizes anchor vectors before
the Procrustes fit so high-norm terms do not dominate the rotation.
"""
function align_to_reference(
    reference::EmbeddingSpace,
    target::EmbeddingSpace;
    minimum_anchors::Int = 8,
    excluded::Set{String} = Set{String}(),
    anchors::Union{Nothing,Vector{String}} = nothing,
)
    size(reference.vectors, 2) == size(target.vectors, 2) || throw(
        DimensionMismatch("Embedding dimensions must match before alignment."),
    )
    dimension = size(reference.vectors, 2)
    selected = anchors === nothing ? shared_vocabulary(reference, target; excluded = excluded) : copy(anchors)
    selected = [term for term in selected if haskey(reference.index, term) && haskey(target.index, term) && !(term in excluded)]
    required = max(minimum_anchors, dimension)
    length(selected) >= required || throw(InsufficientAnchorsError(length(selected), required, dimension))

    reference_matrix = _anchor_matrix(reference, selected)
    target_matrix = _anchor_matrix(target, selected)
    diagnostics = alignment_diagnostics(_row_normalized(target_matrix), _row_normalized(reference_matrix))
    diagnostics.full_rank || throw(
        DegenerateAlignmentError(min(diagnostics.source_rank, diagnostics.target_rank), dimension),
    )
    transform = orthogonal_procrustes(
        target_matrix,
        reference_matrix;
        normalize_rows = true,
    )
    aligned_vectors = target.vectors * transform
    return EmbeddingSpace(target.vocab, copy(target.index), Matrix{Float64}(aligned_vectors)), selected
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
    reference_sequences::Vector{Vector{String}},
    target_sequences::Vector{Vector{String}},
    concept::ConceptDefinition;
    excluded::Set{String} = Set{String}(),
    frequency_ratio::Float64 = 3.0,
    maximum_controls::Int = 30,
    minimum_controls::Int = 5,
)
    frequency_ratio >= 1.0 || throw(ArgumentError("frequency_ratio must be at least 1"))
    maximum_controls >= 1 || throw(ArgumentError("maximum_controls must be positive"))
    reference_counts = token_counts(reference_sequences)
    target_counts = token_counts(target_sequences)
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

function frequency_matched_shift_control(
    reference::EmbeddingSpace,
    aligned_target::EmbeddingSpace,
    reference_tokens::Vector{String},
    target_tokens::Vector{String},
    concept::ConceptDefinition;
    kwargs...
)
    return frequency_matched_shift_control(
        reference,
        aligned_target,
        [reference_tokens],
        [target_tokens],
        concept;
        kwargs...
    )
end
