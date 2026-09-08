function resolve_from_root(root::AbstractString, path::AbstractString)
    isabspath(path) ? normpath(path) : normpath(joinpath(root, path))
end

function _comparison_specs(data::Dict{String,Any})
    specs = ComparisonSpec[]
    for item in get(data, "comparisons", Any[])
        haskey(item, "reference") || throw(ArgumentError("Comparison is missing 'reference'."))
        haskey(item, "target") || throw(ArgumentError("Comparison is missing 'target'."))
        push!(specs, ComparisonSpec(String(item["reference"]), String(item["target"])))
    end
    return specs
end

function load_analysis_config(path::AbstractString)
    config_path = abspath(path)
    config_dir = dirname(config_path)
    data = TOML.parsefile(config_path)

    project = data["project"]
    root_setting = String(get(project, "root", "."))
    root = resolve_from_root(config_dir, root_setting)
    provenance = data["provenance"]
    preprocessing = data["preprocessing"]
    frequency = data["frequency"]
    cooccurrence = data["cooccurrence"]
    embeddings = data["embeddings"]
    alignment = get(data, "alignment", Dict{String,Any}())
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
        Int(get(alignment, "minimum_frequency", 1)),
        Float64(get(alignment, "maximum_frequency_ratio", 6.0)),
        Int(get(alignment, "maximum_anchors", 0)),
        Float64(controls["frequency_ratio"]),
        Int(controls["maximum_controls"]),
        Int(controls["minimum_controls"]),
        Int(sentiment["window"]),
        Int(sentiment["negation_window"]),
        Int(statistics["frequency_bootstrap_replicates"]),
        Int(statistics["semantic_bootstrap_replicates"]),
        Int(statistics["semantic_bootstrap_maximum_vocabulary"]),
        Int(statistics["bootstrap_block_size"]),
        Int(get(statistics, "minimum_valid_bootstrap_replicates", 20)),
        Float64(get(statistics, "minimum_valid_bootstrap_fraction", 0.8)),
        Float64(statistics["confidence_level"]),
        Int(statistics["random_seed"]),
        Int(visualization["maximum_labels"]),
        _comparison_specs(data),
    )
end

const _REQUIRED_DOCUMENT_FIELDS = (
    "id", "group", "label", "period", "work", "author", "year", "original_year",
    "language", "original_language", "edition", "source", "license", "path",
)

function _validate_document_dict(item::Dict{String,Any}, index::Int)
    for field in _REQUIRED_DOCUMENT_FIELDS
        haskey(item, field) || throw(ArgumentError("Corpus document #$index is missing required field '$field'."))
        if field ∉ ("year", "original_year") && isempty(strip(String(item[field])))
            throw(ArgumentError("Corpus document #$index has an empty required field '$field'."))
        end
    end
    for field in ("year", "original_year")
        item[field] isa Integer || throw(ArgumentError("Corpus document #$index field '$field' must be an integer."))
    end
    return true
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
        String(item["edition"]),
        String(get(item, "genre", "")),
        String(item["source"]),
        String(item["license"]),
        resolve_from_root(root, String(item["path"])),
        lowercase(String(get(item, "sha256", ""))),
    )
end

function load_corpus_manifest(path::AbstractString; root::Union{Nothing,AbstractString} = nothing)
    manifest_path = abspath(path)
    data = TOML.parsefile(manifest_path)
    manifest_root = if root === nothing
        basename(dirname(manifest_path)) == "config" ? dirname(dirname(manifest_path)) : dirname(manifest_path)
    else
        abspath(String(root))
    end
    raw_documents = get(data, "documents", Any[])
    entries = CorpusEntry[]
    for (index, raw_item) in enumerate(raw_documents)
        item = Dict{String,Any}(raw_item)
        _validate_document_dict(item, index)
        push!(entries, _entry_from_dict(item, manifest_root))
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

function _canonical_single_token(term::AbstractString, source::AbstractString)
    tokens = tokenize(term)
    length(tokens) == 1 || throw(ArgumentError("$source entry must normalize to exactly one token: $(repr(term))"))
    return only(tokens)
end

function load_stopwords(path::AbstractString)
    words = Set{String}()
    for line in eachline(path)
        stripped = strip(line)
        isempty(stripped) || startswith(stripped, "#") || push!(
            words,
            _canonical_single_token(stripped, "Stopword"),
        )
    end
    return words
end

function load_valence_lexicon(path::AbstractString)
    data = TOML.parsefile(path)
    scores = Dict{String,Float64}()
    for (term, value) in data["scores"]
        scores[_canonical_single_token(String(term), "Valence lexicon")] = Float64(value)
    end
    negations = Set(
        _canonical_single_token(String(term), "Negation lexicon")
        for term in data["negations"]["terms"]
    )
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
        text = isfinite(value) ? @sprintf("%.17g", value) : string(value)
    else
        text = string(value)
    end
    if occursin(',', text) || occursin('"', text) || occursin('\n', text)
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
        isempty(strip(entry.id)) && error("Corpus documents must have a non-empty ID.")
        isempty(strip(entry.group)) && error("Document $(entry.id) is missing a group.")
        isempty(strip(entry.label)) && error("Document $(entry.id) is missing a group label.")
        isempty(strip(entry.period)) && error("Document $(entry.id) is missing a period.")
        isempty(strip(entry.work)) && error("Document $(entry.id) is missing a work title.")
        isempty(strip(entry.author)) && error("Document $(entry.id) is missing an author.")
        isempty(strip(entry.edition)) && error("Document $(entry.id) is missing edition information.")
        isempty(strip(entry.language)) && error("Document $(entry.id) is missing an analysis language.")
        isempty(strip(entry.original_language)) && error("Document $(entry.id) is missing an original language.")
        isempty(strip(entry.path)) && error("Document $(entry.id) is missing a path.")
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

function validate_group_consistency(groups::Dict{String,Vector{LoadedDocument}})
    for (group, documents) in groups
        isempty(documents) && error("Corpus group $group does not contain documents.")
        labels = unique([document.metadata.label for document in documents])
        periods = unique([document.metadata.period for document in documents])
        languages = unique([document.metadata.language for document in documents])
        length(labels) == 1 || error("Corpus group $group contains inconsistent labels: $(join(sort!(collect(labels)), ", ")).")
        length(periods) == 1 || error("Corpus group $group contains inconsistent periods: $(join(sort!(collect(periods)), ", ")).")
        length(languages) == 1 || error("Corpus group $group contains inconsistent analysis languages: $(join(sort!(collect(languages)), ", ")).")
    end
    return true
end

function group_analysis_language(groups::Dict{String,Vector{LoadedDocument}}, group::String)
    haskey(groups, group) || throw(ArgumentError("Unknown corpus group '$group'."))
    languages = unique(document.metadata.language for document in groups[group])
    length(languages) == 1 || throw(ArgumentError("Corpus group '$group' has inconsistent analysis languages."))
    return first(languages)
end

function validate_comparison_languages(
    groups::Dict{String,Vector{LoadedDocument}},
    comparisons::Vector{ComparisonSpec},
)
    for comparison in comparisons
        reference_language = group_analysis_language(groups, comparison.reference)
        target_language = group_analysis_language(groups, comparison.target)
        reference_language == target_language || throw(
            ArgumentError(
                "ETHOS v1.1.0 has no cross-lingual embedding backend: comparison " *
                "$(comparison.reference) [$reference_language] -> $(comparison.target) [$target_language] is invalid.",
            ),
        )
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
    config.minimum_anchors >= config.embedding_dimension || error(
        "minimum_anchors must be at least embedding_dimension to constrain Procrustes alignment.",
    )
    config.anchor_minimum_frequency >= 1 || error("alignment minimum_frequency must be positive.")
    config.anchor_maximum_frequency_ratio >= 1 || error("alignment maximum_frequency_ratio must be at least 1.")
    config.anchor_maximum_count >= 0 || error("alignment maximum_anchors must be non-negative.")
    config.anchor_maximum_count == 0 || config.anchor_maximum_count >= config.minimum_anchors || error(
        "alignment maximum_anchors must be zero (unlimited) or at least minimum_anchors.",
    )
    config.control_frequency_ratio >= 1 || error("control_frequency_ratio must be at least 1.")
    config.maximum_controls >= 1 || error("maximum_controls must be positive.")
    config.minimum_controls >= 1 || error("minimum_controls must be positive.")
    config.minimum_controls <= config.maximum_controls || error("minimum_controls cannot exceed maximum_controls.")
    config.sentiment_window >= 0 || error("sentiment_window must be non-negative.")
    config.negation_window >= 0 || error("negation_window must be non-negative.")
    config.frequency_bootstrap_replicates >= 1 || error("frequency_bootstrap_replicates must be positive.")
    config.semantic_bootstrap_replicates >= 1 || error("semantic_bootstrap_replicates must be positive.")
    config.semantic_bootstrap_maximum_vocabulary >= 2 || error("semantic_bootstrap_maximum_vocabulary must be at least 2.")
    config.bootstrap_block_size >= 1 || error("bootstrap_block_size must be positive.")
    config.minimum_valid_bootstrap_replicates >= 1 || error("minimum_valid_bootstrap_replicates must be positive.")
    0 < config.minimum_valid_bootstrap_fraction <= 1 || error("minimum_valid_bootstrap_fraction must lie in (0, 1].")
    0 < config.confidence_level < 1 || error("confidence_level must lie strictly in (0, 1).")
    config.maximum_labels >= 1 || error("maximum_labels must be positive.")
    return true
end
