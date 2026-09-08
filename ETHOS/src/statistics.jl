function _circular_moving_blocks(tokens::Vector{String}, block_size::Int)
    block_size >= 1 || throw(ArgumentError("block_size must be positive"))
    isempty(tokens) && return Vector{Vector{String}}()
    n = length(tokens)
    effective = min(block_size, n)
    blocks = Vector{Vector{String}}(undef, n)
    for start_index in 1:n
        block = Vector{String}(undef, effective)
        for offset in 0:(effective - 1)
            block[offset + 1] = tokens[mod1(start_index + offset, n)]
        end
        blocks[start_index] = block
    end
    return blocks
end

"""
Circular moving-block bootstrap for one document.

The resample has exactly the same token count as the source document and never
creates a context boundary between two different documents.
"""
function _resample_document(rng::AbstractRNG, tokens::Vector{String}, block_size::Int)
    isempty(tokens) && return String[]
    blocks = _circular_moving_blocks(tokens, block_size)
    sample = String[]
    while length(sample) < length(tokens)
        append!(sample, blocks[rand(rng, eachindex(blocks))])
    end
    resize!(sample, length(tokens))
    return sample
end

function _resample_sequences(
    rng::AbstractRNG,
    token_sequences::Vector{Vector{String}},
    block_size::Int,
)
    return [_resample_document(rng, tokens, block_size) for tokens in token_sequences]
end

function _empirical_quantile(values::Vector{Float64}, probability::Float64)
    isempty(values) && return NaN
    0.0 <= probability <= 1.0 || throw(ArgumentError("probability must lie in [0, 1]"))
    sorted_values = sort(values)
    length(sorted_values) == 1 && return first(sorted_values)
    position = 1 + (length(sorted_values) - 1) * probability
    lower_index = floor(Int, position)
    upper_index = ceil(Int, position)
    lower_index == upper_index && return sorted_values[lower_index]
    weight = position - lower_index
    return sorted_values[lower_index] * (1 - weight) + sorted_values[upper_index] * weight
end

function _confidence_interval(values::Vector{Float64}, confidence_level::Float64)
    valid = [value for value in values if isfinite(value)]
    isempty(valid) && return (NaN, NaN)
    alpha = 1.0 - confidence_level
    return (
        _empirical_quantile(valid, alpha / 2),
        _empirical_quantile(valid, 1.0 - alpha / 2),
    )
end

function _minimum_valid_required(
    requested::Int,
    minimum_valid_replicates::Int,
    minimum_valid_fraction::Float64,
)
    minimum_valid_replicates >= 1 || throw(ArgumentError("minimum_valid_replicates must be positive"))
    0.0 < minimum_valid_fraction <= 1.0 || throw(ArgumentError("minimum_valid_fraction must lie in (0, 1]"))
    return min(requested, max(minimum_valid_replicates, ceil(Int, requested * minimum_valid_fraction)))
end

function bootstrap_frequency(
    token_sequences::Vector{Vector{String}},
    concept::ConceptDefinition;
    scale::Float64 = 1_000_000.0,
    replicates::Int = 200,
    block_size::Int = 100,
    confidence_level::Float64 = 0.95,
    seed::Int = 1,
)
    replicates >= 1 || throw(ArgumentError("replicates must be positive"))
    rng = MersenneTwister(seed)
    estimates = Float64[]
    for _ in 1:replicates
        sample = _resample_sequences(rng, token_sequences, block_size)
        push!(estimates, concept_frequency(sample, concept; scale = scale))
    end
    lower, upper = _confidence_interval(estimates, confidence_level)
    return (
        estimate = concept_frequency(token_sequences, concept; scale = scale),
        lower = lower,
        upper = upper,
        valid_replicates = length(estimates),
        requested_replicates = replicates,
        sufficient = true,
    )
end

function bootstrap_frequency(tokens::Vector{String}, concept::ConceptDefinition; kwargs...)
    return bootstrap_frequency([tokens], concept; kwargs...)
end

"""
Bootstrap semantic shifts for multiple concepts while rebuilding each pair of
embedding spaces only once per replicate.

Expected failures caused by insufficient/rank-deficient alignment are counted as
invalid replicates. Unexpected exceptions are never swallowed.
"""
function bootstrap_semantic_shifts(
    reference_sequences::Vector{Vector{String}},
    target_sequences::Vector{Vector{String}},
    concepts::Vector{ConceptDefinition};
    window::Int = 4,
    minimum_count::Int = 1,
    maximum_vocabulary::Int = 2000,
    dimension::Int = 32,
    minimum_anchors::Int = 8,
    anchor_minimum_frequency::Int = 1,
    anchor_maximum_frequency_ratio::Float64 = 6.0,
    anchor_maximum_count::Int = 0,
    distance_weighted::Bool = true,
    replicates::Int = 100,
    block_size::Int = 100,
    confidence_level::Float64 = 0.95,
    seed::Int = 1,
    excluded::Set{String} = Set{String}(),
    minimum_valid_replicates::Int = 20,
    minimum_valid_fraction::Float64 = 0.8,
)
    replicates >= 1 || throw(ArgumentError("replicates must be positive"))
    required_valid = _minimum_valid_required(
        replicates,
        minimum_valid_replicates,
        minimum_valid_fraction,
    )
    rng = MersenneTwister(seed)
    estimates = Dict(concept.id => Float64[] for concept in concepts)
    alignment_valid = 0

    for _ in 1:replicates
        sampled_reference = _resample_sequences(rng, reference_sequences, block_size)
        sampled_target = _resample_sequences(rng, target_sequences, block_size)
        reference_space = build_embedding(
            sampled_reference;
            window = window,
            minimum_count = minimum_count,
            maximum_vocabulary = maximum_vocabulary,
            dimension = dimension,
            distance_weighted = distance_weighted,
        )
        target_space = build_embedding(
            sampled_target;
            window = window,
            minimum_count = minimum_count,
            maximum_vocabulary = maximum_vocabulary,
            dimension = dimension,
            distance_weighted = distance_weighted,
        )
        common_dimension = min(size(reference_space.vectors, 2), size(target_space.vectors, 2))
        common_dimension >= 1 || continue
        reference_space = truncate_embedding(reference_space, common_dimension)
        target_space = truncate_embedding(target_space, common_dimension)

        anchors = select_alignment_anchors(
            reference_space,
            target_space,
            sampled_reference,
            sampled_target;
            excluded = excluded,
            minimum_frequency = anchor_minimum_frequency,
            maximum_frequency_ratio = anchor_maximum_frequency_ratio,
            maximum_anchors = anchor_maximum_count,
        )

        aligned_target = nothing
        try
            aligned_target, _ = align_to_reference(
                reference_space,
                target_space;
                minimum_anchors = minimum_anchors,
                excluded = excluded,
                anchors = anchors,
            )
        catch error_value
            if error_value isa InsufficientAnchorsError || error_value isa DegenerateAlignmentError
                continue
            end
            rethrow()
        end
        alignment_valid += 1

        for concept in concepts
            estimate = semantic_shift(reference_space, aligned_target, concept)
            isfinite(estimate) && push!(estimates[concept.id], estimate)
        end
    end

    results = Dict{String,NamedTuple}()
    for concept in concepts
        values = estimates[concept.id]
        sufficient = length(values) >= required_valid
        lower, upper = sufficient ? _confidence_interval(values, confidence_level) : (NaN, NaN)
        results[concept.id] = (
            lower = lower,
            upper = upper,
            valid_replicates = length(values),
            requested_replicates = replicates,
            minimum_required = required_valid,
            sufficient = sufficient,
            valid_alignments = alignment_valid,
        )
    end
    return results
end

function bootstrap_semantic_shift(
    reference_sequences::Vector{Vector{String}},
    target_sequences::Vector{Vector{String}},
    concept::ConceptDefinition;
    excluded::Set{String} = Set(concept_tokens(concept)),
    kwargs...
)
    results = bootstrap_semantic_shifts(
        reference_sequences,
        target_sequences,
        [concept];
        excluded = excluded,
        kwargs...,
    )
    return results[concept.id]
end

function bootstrap_semantic_shift(
    reference_tokens::Vector{String},
    target_tokens::Vector{String},
    concept::ConceptDefinition;
    kwargs...
)
    return bootstrap_semantic_shift([reference_tokens], [target_tokens], concept; kwargs...)
end
