function resolve_from_root(root::AbstractString, path::AbstractString)
    isabspath(path) ? normpath(path) : normpath(joinpath(root, path))
end

function load_analysis_config(path::AbstractString)
    config_path = abspath(path)
    root = dirname(dirname(config_path))
    data = TOML.parsefile(config_path)

    project = data["project"]
    provenance = data["provenance"]
    preprocessing = data["preprocessing"]
    frequency = data["frequency"]
    cooccurrence = data["cooccurrence"]
    embeddings = data["embeddings"]
    controls = data["controls"]
    sentiment = data["sentiment"]
    statistics = data["statistics"]
    visualization = data["visualization"]

    return AnalysisConfig(
        root,
        resolve_from_root(root, String(project["corpora"])),
        resolve_from_root(root, String(project["concepts"])),
        resolve_from_root(root, String(project["stopwords"])),
        resolve_from_root(root, String(project["valence_lexicon"])),
        resolve_from_root(root, String(project["results_dir"])),
        Bool(provenance["require_checksums"]),
        Bool(provenance["require_translator_for_translation"]),
        Int(preprocessing["minimum_token_length"]),
        Bool(preprocessing["remove_stopwords_for_dtm"]),
        Float64(frequency["normalization_scale"]),
        Int(cooccurrence["window"]),
        Bool(cooccurrence["distance_weighted"]),
        Int(embeddings["window"]),
        Int(embeddings["minimum_count"]),
        Int(embeddings["maximum_vocabulary"]),
        Int(embeddings["dimension"]),
        Int(embeddings["minimum_anchors"]),
        Float64(controls["frequency_ratio"]),
        Int(controls["maximum_controls"]),
        Int(controls["minimum_controls"]),
        Int(sentiment["window"]),
        Int(sentiment["negation_window"]),
        Int(statistics["frequency_bootstrap_replicates"]),
        Int(statistics["semantic_bootstrap_replicates"]),
        Int(statistics["semantic_bootstrap_maximum_vocabulary"]),
        Int(statistics["bootstrap_block_size"]),
        Float64(statistics["confidence_level"]),
        Int(statistics["random_seed"]),
        Int(visualization["maximum_labels"]),
    )
end

function _entry_from_dict(item::Dict{String,Any}, root::AbstractString)
    return CorpusEntry(
        String(item["id"]),
        String(item["group"]),
        String(item["label"]),
        String(item["period"]),
        String(item["work"]),
        String(item["author"]),
        Int(item["year"]),
        Int(item["original_year"]),
        String(item["language"]),
        String(item["original_language"]),
        String(get(item, "translator", "")),
        String(get(item, "edition", "")),
        String(get(item, "genre", "")),
        String(get(item, "source", "")),
        String(get(item, "license", "")),
        resolve_from_root(root, String(item["path"])),
        lowercase(String(get(item, "sha256", ""))),
    )
end

function load_corpus_manifest(path::AbstractString)
    config_path = abspath(path)
    root = dirname(dirname(config_path))
    data = TOML.parsefile(config_path)
    raw_documents = get(data, "documents", Any[])
    entries = CorpusEntry[]
    for item in raw_documents
        push!(entries, _entry_from_dict(item, root))
    end
    isempty(entries) && error("Corpus manifest does not contain any documents.")
    return entries
end

function file_sha256(path::AbstractString)
    open(path, "r") do io
        return bytes2hex(SHA.sha256(io))
    end
end

function validate_checksum(entry::CorpusEntry)
    isempty(entry.sha256) && return true
    actual = file_sha256(entry.path)
    actual == entry.sha256 || error(
        "Checksum mismatch for $(entry.id): expected $(entry.sha256), got $actual",
    )
    return true
end

function load_stopwords(path::AbstractString)
    words = Set{String}()
    for line in eachline(path)
        word = strip(lowercase(line))
        isempty(word) || startswith(word, "#") || push!(words, word)
    end
    return words
end

function load_valence_lexicon(path::AbstractString)
    data = TOML.parsefile(path)
    scores = Dict{String,Float64}()
    for (term, value) in data["scores"]
        scores[lowercase(String(term))] = Float64(value)
    end
    negations = Set(lowercase.(String.(data["negations"]["terms"])))
    return scores, negations
end

function write_csv(path::AbstractString, header::Vector{String}, rows)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, join(_csv_escape.(header), ','))
        for row in rows
            println(io, join(_csv_escape.(collect(row)), ','))
        end
    end
    return path
end

function _csv_escape(value)
    if value isa AbstractFloat
        text = isfinite(value) ? @sprintf("%.10g", value) : string(value)
    else
        text = string(value)
    end
    if occursin(',', text) || occursin('\"', text) || occursin('\n', text)
        return "\"" * replace(text, "\"" => "\"\"") * "\""
    end
    return text
end

function validate_manifest(
    entries::Vector{CorpusEntry};
    require_checksums::Bool = true,
    require_translator_for_translation::Bool = true,
)
    ids = [entry.id for entry in entries]
    length(unique(ids)) == length(ids) || error("Corpus document IDs must be unique.")
    for entry in entries
        isempty(strip(entry.source)) && error("Document $(entry.id) is missing a source description.")
        isempty(strip(entry.license)) && error("Document $(entry.id) is missing license information.")
        if require_translator_for_translation && entry.language != entry.original_language
            isempty(strip(entry.translator)) && error(
                "Document $(entry.id) is translated but does not identify a translator.",
            )
        end
        if require_checksums && isempty(entry.sha256)
            error("Document $(entry.id) is missing a required SHA-256 checksum.")
        end
        if !isempty(entry.sha256)
            occursin(r"^[0-9a-f]{64}$", entry.sha256) || error(
                "Document $(entry.id) has an invalid SHA-256 value.",
            )
        end
    end
    return true
end

function validate_config(config::AnalysisConfig)
    config.minimum_token_length >= 1 || error("minimum_token_length must be at least 1.")
    config.frequency_scale > 0 || error("frequency_scale must be positive.")
    config.cooccurrence_window >= 1 || error("cooccurrence_window must be at least 1.")
    config.embedding_window >= 1 || error("embedding_window must be at least 1.")
    config.embedding_minimum_count >= 1 || error("embedding_minimum_count must be at least 1.")
    config.embedding_maximum_vocabulary >= 2 || error("embedding_maximum_vocabulary must be at least 2.")
    config.embedding_dimension >= 1 || error("embedding_dimension must be positive.")
    config.minimum_anchors >= 2 || error("minimum_anchors must be at least 2.")
    config.control_frequency_ratio >= 1 || error("control_frequency_ratio must be at least 1.")
    config.maximum_controls >= 1 || error("maximum_controls must be positive.")
    config.minimum_controls >= 1 || error("minimum_controls must be positive.")
    config.minimum_controls <= config.maximum_controls || error(
        "minimum_controls cannot exceed maximum_controls.",
    )
    config.sentiment_window >= 0 || error("sentiment_window must be non-negative.")
    config.negation_window >= 0 || error("negation_window must be non-negative.")
    config.frequency_bootstrap_replicates >= 1 || error(
        "frequency_bootstrap_replicates must be positive.",
    )
    config.semantic_bootstrap_replicates >= 1 || error(
        "semantic_bootstrap_replicates must be positive.",
    )
    config.semantic_bootstrap_maximum_vocabulary >= 2 || error(
        "semantic_bootstrap_maximum_vocabulary must be at least 2.",
    )
    config.bootstrap_block_size >= 1 || error("bootstrap_block_size must be positive.")
    0 < config.confidence_level < 1 || error("confidence_level must lie strictly in (0, 1).")
    config.maximum_labels >= 1 || error("maximum_labels must be positive.")
    return true
end
