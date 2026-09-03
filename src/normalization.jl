"""
Normalize text without destroying lexical information needed by downstream tasks.

The function lowercases, standardizes apostrophes/dashes, removes control characters,
and collapses whitespace. It intentionally does not remove stop words or accents.
"""
function normalize_text(text::AbstractString)
    normalized = lowercase(String(text))
    normalized = replace(
        normalized,
        '\r' => ' ',
        '\t' => ' ',
        '’' => '\'',
        '‘' => '\'',
        '—' => ' ',
        '–' => ' ',
        '−' => ' ',
    )
    normalized = replace(normalized, r"[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]" => " ")
    normalized = replace(normalized, r"\s+" => " ")
    return strip(normalized)
end

"""Tokenize letters, combining marks, apostrophized words, and simple numbers."""
function tokenize(text::AbstractString; minimum_length::Int = 1)
    minimum_length >= 1 || throw(ArgumentError("minimum_length must be at least 1"))
    normalized = normalize_text(text)
    pattern = r"[\p{L}\p{M}]+(?:'[\p{L}\p{M}]+)*|\p{N}+(?:[\.,]\p{N}+)*"
    tokens = String[]
    for match_result in eachmatch(pattern, normalized)
        token = String(match_result.match)
        length(token) >= minimum_length && push!(tokens, token)
    end
    return tokens
end

function filter_stopwords(tokens::Vector{String}, stopwords::Set{String})
    return [token for token in tokens if !(token in stopwords)]
end

function load_corpus(entries::Vector{CorpusEntry}; minimum_token_length::Int = 1)
    documents = LoadedDocument[]
    for entry in entries
        isfile(entry.path) || error("Corpus file not found: $(entry.path)")
        validate_checksum(entry)
        raw_text = read(entry.path, String)
        tokens = tokenize(raw_text; minimum_length = minimum_token_length)
        push!(documents, LoadedDocument(entry, raw_text, tokens))
    end
    return documents
end

function grouped_documents(documents::Vector{LoadedDocument})
    groups = Dict{String,Vector{LoadedDocument}}()
    for document in documents
        push!(get!(groups, document.metadata.group, LoadedDocument[]), document)
    end
    return groups
end

function grouped_tokens(documents::Vector{LoadedDocument})
    groups = Dict{String,Vector{String}}()
    for (group, group_documents) in grouped_documents(documents)
        groups[group] = reduce(vcat, (document.tokens for document in group_documents); init = String[])
    end
    return groups
end
