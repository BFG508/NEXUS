
function build_document_term_matrix(
    documents::Vector{LoadedDocument};
    stopwords::Set{String} = Set{String}(),
    minimum_count::Int = 1,
    maximum_vocabulary::Int = 5000,
)
    token_sequences = [document.tokens for document in documents]
    terms = vocabulary(
        token_sequences;
        minimum_count = minimum_count,
        maximum_vocabulary = maximum_vocabulary,
        stopwords = stopwords,
    )
    index = Dict(term => i for (i, term) in enumerate(terms))
    matrix = zeros(Float64, length(documents), length(terms))
    for (row, document) in enumerate(documents)
        for token in document.tokens
            column = get(index, token, 0)
            column == 0 || (matrix[row, column] += 1.0)
        end
    end
    return matrix, terms
end

function tfidf_matrix(dtm::AbstractMatrix{<:Real})
    n_documents, n_terms = size(dtm)
    n_documents == 0 && return zeros(Float64, size(dtm))
    tfidf = zeros(Float64, size(dtm))
    row_totals = vec(sum(dtm; dims = 2))
    for column in 1:n_terms
        document_frequency = count(value -> value > 0, view(dtm, :, column))
        inverse_document_frequency = log((1 + n_documents) / (1 + document_frequency)) + 1.0
        for row in 1:n_documents
            term_frequency = row_totals[row] > 0 ? dtm[row, column] / row_totals[row] : 0.0
            tfidf[row, column] = term_frequency * inverse_document_frequency
        end
    end
    return tfidf
end

function cooccurrence_matrix(
    token_sequences::Vector{Vector{String}};
    window::Int = 4,
    minimum_count::Int = 1,
    maximum_vocabulary::Int = 2000,
    distance_weighted::Bool = true,
)
    window >= 1 || throw(ArgumentError("window must be at least 1"))
    terms = vocabulary(
        token_sequences;
        minimum_count = minimum_count,
        maximum_vocabulary = maximum_vocabulary,
    )
    index = Dict(term => i for (i, term) in enumerate(terms))
    matrix = zeros(Float64, length(terms), length(terms))

    for tokens in token_sequences
        for center_position in eachindex(tokens)
            center_index = get(index, tokens[center_position], 0)
            center_index == 0 && continue
            left = max(firstindex(tokens), center_position - window)
            right = min(lastindex(tokens), center_position + window)
            for context_position in left:right
                context_position == center_position && continue
                context_index = get(index, tokens[context_position], 0)
                context_index == 0 && continue
                distance = abs(context_position - center_position)
                weight = distance_weighted ? inv(Float64(distance)) : 1.0
                matrix[center_index, context_index] += weight
            end
        end
    end
    return matrix, terms
end

function cooccurrence_matrix(tokens::Vector{String}; kwargs...)
    return cooccurrence_matrix([tokens]; kwargs...)
end

function ppmi_matrix(cooccurrence::AbstractMatrix{<:Real})
    matrix = Float64.(cooccurrence)
    total = sum(matrix)
    total <= 0 && return zeros(Float64, size(matrix))
    row_sums = vec(sum(matrix; dims = 2))
    column_sums = vec(sum(matrix; dims = 1))
    result = zeros(Float64, size(matrix))
    for row in axes(matrix, 1), column in axes(matrix, 2)
        value = matrix[row, column]
        value <= 0 && continue
        denominator = row_sums[row] * column_sums[column]
        denominator <= 0 && continue
        pmi = log2(value * total / denominator)
        result[row, column] = max(pmi, 0.0)
    end
    return result
end

function concept_ppmi_associations(
    token_sequences::Vector{Vector{String}},
    concept::ConceptDefinition;
    window::Int = 4,
    minimum_count::Int = 1,
    maximum_vocabulary::Int = 2000,
    distance_weighted::Bool = true,
    limit::Int = 15,
)
    cooccurrence, vocab = cooccurrence_matrix(
        token_sequences;
        window = window,
        minimum_count = minimum_count,
        maximum_vocabulary = maximum_vocabulary,
        distance_weighted = distance_weighted,
    )
    isempty(vocab) && return Tuple{String,Float64}[]
    ppmi = ppmi_matrix(cooccurrence)
    index = Dict(term => i for (i, term) in enumerate(vocab))
    rows = [index[token] for token in concept_tokens(concept) if haskey(index, token)]
    isempty(rows) && return Tuple{String,Float64}[]
    association = vec(mean(ppmi[rows, :]; dims = 1))
    excluded = Set(concept_tokens(concept))
    candidates = Tuple{String,Float64}[]
    for (column, token) in enumerate(vocab)
        token in excluded && continue
        score = association[column]
        score > 0 && isfinite(score) && push!(candidates, (token, score))
    end
    sort!(candidates; by = item -> (-item[2], item[1]))
    return candidates[1:min(limit, length(candidates))]
end

function concept_ppmi_associations(tokens::Vector{String}, concept::ConceptDefinition; kwargs...)
    return concept_ppmi_associations([tokens], concept; kwargs...)
end

