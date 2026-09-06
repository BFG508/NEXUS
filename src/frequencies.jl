
function token_counts(tokens::Vector{String})
    counts = Dict{String,Int}()
    for token in tokens
        counts[token] = get(counts, token, 0) + 1
    end
    return counts
end

function token_counts(token_sequences::Vector{Vector{String}})
    counts = Dict{String,Int}()
    for tokens in token_sequences, token in tokens
        counts[token] = get(counts, token, 0) + 1
    end
    return counts
end

function normalized_token_frequencies(tokens::Vector{String}; scale::Real = 1_000_000.0)
    counts = token_counts(tokens)
    denominator = max(length(tokens), 1)
    return Dict(token => count / denominator * Float64(scale) for (token, count) in counts)
end

function normalized_token_frequencies(
    token_sequences::Vector{Vector{String}};
    scale::Real = 1_000_000.0,
)
    counts = token_counts(token_sequences)
    denominator = max(sum(length, token_sequences), 1)
    return Dict(token => count / denominator * Float64(scale) for (token, count) in counts)
end

function vocabulary(
    token_sequences::Vector{Vector{String}};
    minimum_count::Int = 1,
    maximum_vocabulary::Int = 5000,
    stopwords::Set{String} = Set{String}(),
)
    minimum_count >= 1 || throw(ArgumentError("minimum_count must be at least 1"))
    maximum_vocabulary >= 1 || throw(ArgumentError("maximum_vocabulary must be positive"))
    counts = Dict{String,Int}()
    for tokens in token_sequences, token in tokens
        token in stopwords && continue
        counts[token] = get(counts, token, 0) + 1
    end
    terms = [term for (term, count) in counts if count >= minimum_count]
    sort!(terms; by = term -> (-counts[term], term))
    return terms[1:min(length(terms), maximum_vocabulary)]
end

function top_terms(tokens::Vector{String}; limit::Int = 20, stopwords::Set{String} = Set{String}())
    counts = token_counts([token for token in tokens if !(token in stopwords)])
    terms = collect(keys(counts))
    sort!(terms; by = term -> (-counts[term], term))
    terms = terms[1:min(limit, length(terms))]
    return [(term, counts[term]) for term in terms]
end


function top_terms(
    token_sequences::Vector{Vector{String}};
    limit::Int = 20,
    stopwords::Set{String} = Set{String}(),
)
    counts = token_counts([[token for token in tokens if !(token in stopwords)] for tokens in token_sequences])
    terms = collect(keys(counts))
    sort!(terms; by = term -> (-counts[term], term))
    terms = terms[1:min(limit, length(terms))]
    return [(term, counts[term]) for term in terms]
end
