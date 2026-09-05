
function load_concepts(path::AbstractString)
    data = TOML.parsefile(path)
    raw_concepts = data["concepts"]
    concepts = ConceptDefinition[]
    for concept_id in sort(collect(keys(raw_concepts)))
        item = raw_concepts[concept_id]
        aliases = Vector{Vector{String}}()
        for term in item["terms"]
            phrase = tokenize(String(term))
            isempty(phrase) || push!(aliases, phrase)
        end
        isempty(aliases) && error("Concept $concept_id does not contain valid aliases.")
        push!(
            concepts,
            ConceptDefinition(String(concept_id), String(item["label"]), aliases),
        )
    end
    isempty(concepts) && error("Concept configuration does not contain any concepts.")
    return concepts
end

function _phrase_positions(tokens::Vector{String}, phrase::Vector{String})
    positions = Tuple{Int,Int}[]
    phrase_length = length(phrase)
    phrase_length == 0 && return positions
    length(tokens) < phrase_length && return positions
    for start_index in 1:(length(tokens) - phrase_length + 1)
        stop_index = start_index + phrase_length - 1
        tokens[start_index:stop_index] == phrase && push!(positions, (start_index, stop_index))
    end
    return positions
end

"""
Return non-overlapping concept spans, preferring the longest alias at a shared position.
"""
function concept_spans(tokens::Vector{String}, concept::ConceptDefinition)
    candidates = Tuple{Int,Int}[]
    for alias in concept.aliases
        append!(candidates, _phrase_positions(tokens, alias))
    end
    sort!(candidates; by = span -> (span[1], -(span[2] - span[1] + 1)))
    selected = Tuple{Int,Int}[]
    occupied = falses(length(tokens))
    for (start_index, stop_index) in candidates
        any(occupied[start_index:stop_index]) && continue
        push!(selected, (start_index, stop_index))
        occupied[start_index:stop_index] .= true
    end
    return selected
end

concept_count(tokens::Vector{String}, concept::ConceptDefinition) =
    length(concept_spans(tokens, concept))

function concept_frequency(
    tokens::Vector{String},
    concept::ConceptDefinition;
    scale::Real = 1_000_000.0,
)
    isempty(tokens) && return 0.0
    return concept_count(tokens, concept) / length(tokens) * Float64(scale)
end

function context_windows(
    tokens::Vector{String},
    concept::ConceptDefinition;
    window::Int = 8,
)
    window >= 0 || throw(ArgumentError("window must be non-negative"))
    windows = Vector{Vector{String}}()
    for (start_index, stop_index) in concept_spans(tokens, concept)
        left = max(1, start_index - window)
        right = min(length(tokens), stop_index + window)
        push!(windows, tokens[left:right])
    end
    return windows
end

function concept_tokens(concept::ConceptDefinition)
    result = String[]
    for alias in concept.aliases
        append!(result, alias)
    end
    return unique(result)
end


concept_count(token_sequences::Vector{Vector{String}}, concept::ConceptDefinition) =
    sum(concept_count(tokens, concept) for tokens in token_sequences)

function concept_frequency(
    token_sequences::Vector{Vector{String}},
    concept::ConceptDefinition;
    scale::Real = 1_000_000.0,
)
    total_tokens = sum(length, token_sequences)
    total_tokens == 0 && return 0.0
    return concept_count(token_sequences, concept) / total_tokens * Float64(scale)
end

function context_windows(
    token_sequences::Vector{Vector{String}},
    concept::ConceptDefinition;
    window::Int = 8,
)
    windows = Vector{Vector{String}}()
    for tokens in token_sequences
        append!(windows, context_windows(tokens, concept; window = window))
    end
    return windows
end
