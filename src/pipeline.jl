function _group_order(groups::Dict{String,Vector{LoadedDocument}})
    names = collect(keys(groups))
    sort!(
        names;
        by = group -> minimum(document.metadata.original_year for document in groups[group]),
    )
    return names
end

function _group_labels(groups::Dict{String,Vector{LoadedDocument}})
    return Dict(group => first(documents).metadata.label for (group, documents) in groups)
end

function _group_periods(groups::Dict{String,Vector{LoadedDocument}})
    return Dict(group => first(documents).metadata.period for (group, documents) in groups)
end

function _save_embedding_csv(path::AbstractString, space::EmbeddingSpace)
    header = ["token"; ["dim_$index" for index in 1:size(space.vectors, 2)]]
    rows = (
        tuple(space.vocab[row], (space.vectors[row, column] for column in axes(space.vectors, 2))...)
        for row in axes(space.vectors, 1)
    )
    return write_csv(path, header, rows)
end

function _selected_map_rows(space::EmbeddingSpace, concepts::Vector{ConceptDefinition}, maximum_labels::Int)
    preferred = String[]
    for concept in concepts, token in concept_tokens(concept)
        haskey(space.index, token) && push!(preferred, token)
    end
    for token in space.vocab
        length(preferred) >= maximum_labels && break
        token in preferred || push!(preferred, token)
    end
    return preferred[1:min(maximum_labels, length(preferred))]
end

function _write_run_metadata(
    path::AbstractString,
    config::AnalysisConfig,
    config_path::AbstractString,
    documents::Vector{LoadedDocument},
)
    checksums = Dict(document.metadata.id => file_sha256(document.metadata.path) for document in documents)
    settings = Dict(
        "minimum_token_length" => config.minimum_token_length,
        "remove_stopwords_for_dtm" => config.remove_stopwords_for_dtm,
        "frequency_scale" => config.frequency_scale,
        "cooccurrence_window" => config.cooccurrence_window,
        "distance_weighted" => config.distance_weighted,
        "embedding_window" => config.embedding_window,
        "embedding_minimum_count" => config.embedding_minimum_count,
        "embedding_maximum_vocabulary" => config.embedding_maximum_vocabulary,
        "embedding_dimension" => config.embedding_dimension,
        "minimum_anchors" => config.minimum_anchors,
        "control_frequency_ratio" => config.control_frequency_ratio,
        "maximum_controls" => config.maximum_controls,
        "minimum_controls" => config.minimum_controls,
        "sentiment_window" => config.sentiment_window,
        "negation_window" => config.negation_window,
        "frequency_bootstrap_replicates" => config.frequency_bootstrap_replicates,
        "semantic_bootstrap_replicates" => config.semantic_bootstrap_replicates,
        "semantic_bootstrap_maximum_vocabulary" => config.semantic_bootstrap_maximum_vocabulary,
        "bootstrap_block_size" => config.bootstrap_block_size,
        "confidence_level" => config.confidence_level,
        "random_seed" => config.random_seed,
    )
    metadata = Dict(
        "generated_at" => Dates.format(now(), dateformat"yyyy-mm-ddTHH:MM:SS"),
        "julia_version" => string(VERSION),
        "config_path" => relpath(abspath(config_path), config.root),
        "config_sha256" => file_sha256(abspath(config_path)),
        "corpora_manifest_sha256" => file_sha256(config.corpora_path),
        "concepts_sha256" => file_sha256(config.concepts_path),
        "stopwords_sha256" => file_sha256(config.stopwords_path),
        "valence_lexicon_sha256" => file_sha256(config.valence_path),
        "document_sha256" => checksums,
        "settings" => settings,
    )
    open(path, "w") do io
        TOML.print(io, metadata)
    end
    return path
end

"""Run the complete ETHOS analysis pipeline from a TOML configuration file."""
function run_pipeline(config_path::AbstractString; results_dir_override::Union{Nothing,String} = nothing)
    config = load_analysis_config(config_path)
    validate_config(config)
    results_dir = results_dir_override === nothing ? config.results_dir : abspath(results_dir_override)
    tables_dir = joinpath(results_dir, "tables")
    figures_dir = joinpath(results_dir, "figures")
    embeddings_dir = joinpath(results_dir, "embeddings")
    mkpath.([tables_dir, figures_dir, embeddings_dir])

    entries = load_corpus_manifest(config.corpora_path)
    validate_manifest(
        entries;
        require_checksums = config.require_checksums,
        require_translator_for_translation = config.require_translator_for_translation,
    )
    documents = load_corpus(entries; minimum_token_length = config.minimum_token_length)
    concepts = load_concepts(config.concepts_path)
    stopwords = load_stopwords(config.stopwords_path)
    valence_lexicon, negations = load_valence_lexicon(config.valence_path)

    groups = grouped_documents(documents)
    tokens_by_group = grouped_tokens(documents)
    ordered_groups = _group_order(groups)
    group_labels = _group_labels(groups)
    group_periods = _group_periods(groups)

    write_csv(
        joinpath(tables_dir, "document_metadata.csv"),
        [
            "id", "group", "work", "author", "year", "original_year", "language",
            "original_language", "translator", "edition", "genre", "source", "license",
            "path", "sha256",
        ],
        (
            (
                entry.id, entry.group, entry.work, entry.author, entry.year, entry.original_year,
                entry.language, entry.original_language, entry.translator, entry.edition,
                entry.genre, entry.source, entry.license, relpath(entry.path, config.root),
                file_sha256(entry.path),
            ) for entry in entries
        ),
    )

    corpus_summary_rows = NamedTuple[]
    for group in ordered_groups
        group_documents = groups[group]
        push!(
            corpus_summary_rows,
            (
                group = group,
                documents = length(group_documents),
                tokens = sum(length(document.tokens) for document in group_documents),
                period = group_periods[group],
            ),
        )
    end
    write_csv(
        joinpath(tables_dir, "corpus_summary.csv"),
        ["group", "documents", "tokens", "period"],
        ((row.group, row.documents, row.tokens, row.period) for row in corpus_summary_rows),
    )

    frequency_rows = NamedTuple[]
    for (group_index, group) in enumerate(ordered_groups)
        tokens = tokens_by_group[group]
        for (concept_index, concept) in enumerate(concepts)
            bootstrap = bootstrap_frequency(
                tokens,
                concept;
                scale = config.frequency_scale,
                replicates = config.frequency_bootstrap_replicates,
                block_size = config.bootstrap_block_size,
                confidence_level = config.confidence_level,
                seed = config.random_seed + 1000 * group_index + concept_index,
            )
            push!(
                frequency_rows,
                (
                    group = group,
                    concept = concept.id,
                    label = concept.label,
                    count = concept_count(tokens, concept),
                    frequency = bootstrap.estimate,
                    lower = bootstrap.lower,
                    upper = bootstrap.upper,
                ),
            )
        end
    end
    write_csv(
        joinpath(tables_dir, "concept_frequency.csv"),
        ["group", "concept", "label", "count", "frequency", "ci_lower", "ci_upper"],
        (
            (row.group, row.concept, row.label, row.count, row.frequency, row.lower, row.upper)
            for row in frequency_rows
        ),
    )

    association_rows = NamedTuple[]
    for group in ordered_groups
        tokens = tokens_by_group[group]
        for concept in concepts
            associations = concept_ppmi_associations(
                tokens,
                concept;
                window = config.cooccurrence_window,
                minimum_count = config.embedding_minimum_count,
                maximum_vocabulary = config.embedding_maximum_vocabulary,
                distance_weighted = config.distance_weighted,
                limit = 15,
            )
            for (rank, (term, score)) in enumerate(associations)
                push!(
                    association_rows,
                    (group = group, concept = concept.id, rank = rank, term = term, ppmi = score),
                )
            end
        end
    end
    write_csv(
        joinpath(tables_dir, "concept_ppmi_associations.csv"),
        ["group", "concept", "rank", "term", "ppmi"],
        ((row.group, row.concept, row.rank, row.term, row.ppmi) for row in association_rows),
    )

    valence_rows = NamedTuple[]
    for group in ordered_groups
        tokens = tokens_by_group[group]
        for concept in concepts
            result = contextual_valence(
                tokens,
                concept,
                valence_lexicon,
                negations;
                window = config.sentiment_window,
                negation_window = config.negation_window,
            )
            push!(
                valence_rows,
                (
                    group = group,
                    concept = concept.id,
                    label = concept.label,
                    valence = result.mean,
                    contexts = result.contexts,
                    scored_tokens = result.scored_tokens,
                ),
            )
        end
    end
    write_csv(
        joinpath(tables_dir, "contextual_valence.csv"),
        ["group", "concept", "label", "valence", "contexts", "scored_tokens"],
        (
            (row.group, row.concept, row.label, row.valence, row.contexts, row.scored_tokens)
            for row in valence_rows
        ),
    )

    dtm_stopwords = config.remove_stopwords_for_dtm ? stopwords : Set{String}()
    dtm, terms = build_document_term_matrix(
        documents;
        stopwords = dtm_stopwords,
        minimum_count = 1,
        maximum_vocabulary = config.embedding_maximum_vocabulary,
    )
    tfidf = tfidf_matrix(dtm)
    tfidf_rows = NamedTuple[]
    for row in axes(tfidf, 1)
        order = sortperm(view(tfidf, row, :); rev = true)
        for column in order[1:min(15, length(order))]
            tfidf[row, column] > 0 || continue
            push!(
                tfidf_rows,
                (
                    document = documents[row].metadata.id,
                    term = terms[column],
                    tfidf = tfidf[row, column],
                ),
            )
        end
    end
    write_csv(
        joinpath(tables_dir, "tfidf_top_terms.csv"),
        ["document", "term", "tfidf"],
        ((row.document, row.term, row.tfidf) for row in tfidf_rows),
    )

    spaces = Dict{String,EmbeddingSpace}()
    for group in ordered_groups
        space = build_embedding(
            tokens_by_group[group];
            window = config.embedding_window,
            minimum_count = config.embedding_minimum_count,
            maximum_vocabulary = config.embedding_maximum_vocabulary,
            dimension = config.embedding_dimension,
            distance_weighted = config.distance_weighted,
        )
        spaces[group] = space
        _save_embedding_csv(joinpath(embeddings_dir, "$(group)_embedding.csv"), space)

        map_labels = _selected_map_rows(space, concepts, config.maximum_labels)
        if !isempty(map_labels)
            coordinates = pca_coordinates(space.vectors)
            selected_indices = [space.index[label] for label in map_labels]
            save_scatter_svg(
                joinpath(figures_dir, "semantic_map_$(group).svg"),
                coordinates[selected_indices, :],
                map_labels;
                title = "$(group_labels[group]) — semantic map (PCA)",
            )
        end
    end

    all_concept_tokens = Set{String}()
    for concept in concepts
        union!(all_concept_tokens, Set(concept_tokens(concept)))
    end

    shift_rows = NamedTuple[]
    if length(ordered_groups) >= 2
        for pair_index in 1:(length(ordered_groups) - 1)
            from_group = ordered_groups[pair_index]
            to_group = ordered_groups[pair_index + 1]
            reference_space = spaces[from_group]
            target_space = spaces[to_group]
            common_dimension = min(size(reference_space.vectors, 2), size(target_space.vectors, 2))
            common_dimension >= 1 || continue
            reference_space = truncate_embedding(reference_space, common_dimension)
            target_space = truncate_embedding(target_space, common_dimension)
            aligned_target, anchors = align_to_reference(
                reference_space,
                target_space;
                minimum_anchors = config.minimum_anchors,
                excluded = all_concept_tokens,
            )

            for (concept_index, concept) in enumerate(concepts)
                shift = semantic_shift(reference_space, aligned_target, concept)
                bootstrap = bootstrap_semantic_shift(
                    tokens_by_group[from_group],
                    tokens_by_group[to_group],
                    concept;
                    window = config.embedding_window,
                    minimum_count = config.embedding_minimum_count,
                    maximum_vocabulary = min(
                        config.embedding_maximum_vocabulary,
                        config.semantic_bootstrap_maximum_vocabulary,
                    ),
                    dimension = config.embedding_dimension,
                    minimum_anchors = config.minimum_anchors,
                    distance_weighted = config.distance_weighted,
                    replicates = config.semantic_bootstrap_replicates,
                    block_size = config.bootstrap_block_size,
                    confidence_level = config.confidence_level,
                    seed = config.random_seed + 10_000 * pair_index + concept_index,
                    excluded = all_concept_tokens,
                )
                control = frequency_matched_shift_control(
                    reference_space,
                    aligned_target,
                    tokens_by_group[from_group],
                    tokens_by_group[to_group],
                    concept;
                    excluded = all_concept_tokens,
                    frequency_ratio = config.control_frequency_ratio,
                    maximum_controls = config.maximum_controls,
                    minimum_controls = config.minimum_controls,
                )
                push!(
                    shift_rows,
                    (
                        from_group = from_group,
                        to_group = to_group,
                        concept = concept.id,
                        label = concept.label,
                        shift = shift,
                        lower = bootstrap.lower,
                        upper = bootstrap.upper,
                        anchors = length(anchors),
                        valid_replicates = bootstrap.valid_replicates,
                        control_mean = control.mean,
                        control_std = control.standard_deviation,
                        control_z = control.z_score,
                        controls = control.controls,
                    ),
                )
            end
        end
    end
    write_csv(
        joinpath(tables_dir, "semantic_shift.csv"),
        ["from_group", "to_group", "concept", "label", "shift", "ci_lower", "ci_upper", "anchors", "valid_bootstraps", "control_mean", "control_std", "control_z", "controls"],
        (
            (
                row.from_group,
                row.to_group,
                row.concept,
                row.label,
                row.shift,
                row.lower,
                row.upper,
                row.anchors,
                row.valid_replicates,
                row.control_mean,
                row.control_std,
                row.control_z,
                row.controls,
            ) for row in shift_rows
        ),
    )

    frequency_labels = ["$(row.group): $(row.label)" for row in frequency_rows]
    frequency_values = Float64[row.frequency for row in frequency_rows]
    save_bar_svg(
        joinpath(figures_dir, "concept_frequency.svg"),
        frequency_labels,
        frequency_values;
        title = "Concept frequency per $(Int(round(config.frequency_scale))) tokens",
    )

    report_path = write_markdown_report(
        joinpath(results_dir, "report.md");
        groups = ordered_groups,
        group_labels = group_labels,
        corpus_summary_rows = corpus_summary_rows,
        frequency_rows = frequency_rows,
        valence_rows = valence_rows,
        shift_rows = shift_rows,
        config = config,
    )
    _write_run_metadata(
        joinpath(results_dir, "run_metadata.toml"),
        config,
        config_path,
        documents,
    )

    return (
        report = report_path,
        results_dir = results_dir,
        groups = ordered_groups,
        documents = length(documents),
        concepts = length(concepts),
    )
end
