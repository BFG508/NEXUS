
function _is_negated(
    tokens::Vector{String},
    position::Int,
    negations::Set{String},
    negation_window::Int,
)
    left = max(1, position - negation_window)
    position <= 1 && return false
    return any(token -> token in negations, tokens[left:(position - 1)])
end

"""
Estimate transparent contextual valence around concept mentions.

This is deliberately a lexicon-based descriptive metric, not a claim that moral or
philosophical meaning can be reduced to generic sentiment classification.
"""
function contextual_valence(
    tokens::Vector{String},
    concept::ConceptDefinition,
    lexicon::Dict{String,Float64},
    negations::Set{String};
    window::Int = 7,
    negation_window::Int = 3,
)
    spans = concept_spans(tokens, concept)
    isempty(spans) && return (mean = NaN, contexts = 0, scored_tokens = 0)
    context_scores = Float64[]
    total_scored_tokens = 0

    for (start_index, stop_index) in spans
        left = max(1, start_index - window)
        right = min(length(tokens), stop_index + window)
        scores = Float64[]
        for position in left:right
            start_index <= position <= stop_index && continue
            token = tokens[position]
            haskey(lexicon, token) || continue
            score = lexicon[token]
            _is_negated(tokens, position, negations, negation_window) && (score = -score)
            push!(scores, score)
        end
        if !isempty(scores)
            push!(context_scores, mean(scores))
            total_scored_tokens += length(scores)
        end
    end

    return (
        mean = isempty(context_scores) ? NaN : mean(context_scores),
        contexts = length(context_scores),
        scored_tokens = total_scored_tokens,
    )
end


function contextual_valence(
    token_sequences::Vector{Vector{String}},
    concept::ConceptDefinition,
    lexicon::Dict{String,Float64},
    negations::Set{String};
    window::Int = 7,
    negation_window::Int = 3,
)
    weighted_sum = 0.0
    total_contexts = 0
    total_scored_tokens = 0
    for tokens in token_sequences
        result = contextual_valence(
            tokens,
            concept,
            lexicon,
            negations;
            window = window,
            negation_window = negation_window,
        )
        if result.contexts > 0 && isfinite(result.mean)
            weighted_sum += result.mean * result.contexts
            total_contexts += result.contexts
        end
        total_scored_tokens += result.scored_tokens
    end
    return (
        mean = total_contexts == 0 ? NaN : weighted_sum / total_contexts,
        contexts = total_contexts,
        scored_tokens = total_scored_tokens,
    )
end
