
function _token_blocks(tokens::Vector{String}, block_size::Int)
    block_size >= 1 || throw(ArgumentError("block_size must be positive"))
    blocks = Vector{Vector{String}}()
    for start_index in 1:block_size:length(tokens)
        stop_index = min(length(tokens), start_index + block_size - 1)
        push!(blocks, tokens[start_index:stop_index])
    end
    return blocks
end

function _resample_blocks(rng::AbstractRNG, blocks::Vector{Vector{String}})
    isempty(blocks) && return String[]
    sampled = Vector{String}()
    for _ in eachindex(blocks)
        append!(sampled, blocks[rand(rng, eachindex(blocks))])
    end
    return sampled
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

function bootstrap_frequency(
    tokens::Vector{String},
    concept::ConceptDefinition;
    scale::Float64 = 1_000_000.0,
    replicates::Int = 200,
    block_size::Int = 100,
    confidence_level::Float64 = 0.95,
    seed::Int = 1,
)
    replicates >= 1 || throw(ArgumentError("replicates must be positive"))
    blocks = _token_blocks(tokens, block_size)
    rng = MersenneTwister(seed)
    estimates = Float64[]
    for _ in 1:replicates
        sample = _resample_blocks(rng, blocks)
        push!(estimates, concept_frequency(sample, concept; scale = scale))
    end
    lower, upper = _confidence_interval(estimates, confidence_level)
    return (
        estimate = concept_frequency(tokens, concept; scale = scale),
        lower = lower,
        upper = upper,
        valid_replicates = length(estimates),
    )
end

function bootstrap_semantic_shift(
    reference_tokens::Vector{String},
    target_tokens::Vector{String},
    concept::ConceptDefinition;
    window::Int = 4,
    minimum_count::Int = 1,
    maximum_vocabulary::Int = 2000,
    dimension::Int = 32,
    minimum_anchors::Int = 8,
    distance_weighted::Bool = true,
    replicates::Int = 100,
    block_size::Int = 100,
    confidence_level::Float64 = 0.95,
    seed::Int = 1,
    excluded::Set{String} = Set(concept_tokens(concept)),
)
    reference_blocks = _token_blocks(reference_tokens, block_size)
    target_blocks = _token_blocks(target_tokens, block_size)
    rng = MersenneTwister(seed)
    estimates = Float64[]

    for _ in 1:replicates
        sampled_reference = _resample_blocks(rng, reference_blocks)
        sampled_target = _resample_blocks(rng, target_blocks)
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
        try
            aligned_target, _ = align_to_reference(
                reference_space,
                target_space;
                minimum_anchors = minimum_anchors,
                excluded = excluded,
            )
            estimate = semantic_shift(reference_space, aligned_target, concept)
            isfinite(estimate) && push!(estimates, estimate)
        catch error_value
            if !(error_value isa ErrorException || error_value isa ArgumentError)
                rethrow()
            end
        end
    end

    lower, upper = _confidence_interval(estimates, confidence_level)
    return (lower = lower, upper = upper, valid_replicates = length(estimates))
end
