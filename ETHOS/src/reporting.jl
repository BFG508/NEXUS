
function _format_metric(value::Real; digits::Int = 4)
    isfinite(value) || return "NA"
    return string(round(Float64(value); digits = digits))
end

function _markdown_table(header::Vector{String}, rows)
    io = IOBuffer()
    println(io, "| " * join(header, " | ") * " |")
    println(io, "| " * join(fill("---", length(header)), " | ") * " |")
    for row in rows
        println(io, "| " * join(row, " | ") * " |")
    end
    return String(take!(io))
end

function write_markdown_report(
    path::AbstractString;
    groups::Vector{String},
    group_labels::Dict{String,String},
    corpus_summary_rows,
    frequency_rows,
    valence_rows,
    shift_rows,
    config::AnalysisConfig,
)
    mkpath(dirname(path))
    open(path, "w") do io
        println(io, "# ETHOS.jl — Analysis report")
        println(io)
        generated_at = Dates.format(now(), dateformat"yyyy-mm-dd HH:MM:SS")
        println(io, "Generated: $generated_at")
        println(io)
        println(io, "## Scope and interpretation")
        println(io)
        println(io, "This report is a reproducible computational description of the configured corpus. ")
        println(io, "It does not by itself establish historical causation, authorial intent, moral value, or philosophical equivalence between corpora.")
        println(io)
        println(io, "Cross-corpus semantic shift is computed in the original embedding space after orthogonal Procrustes alignment. PCA figures are visualization aids only.")
        println(io, "Contextual valence is a transparent lexicon-based descriptor, not a universal sentiment or moral score.")
        println(io)

        println(io, "## Corpus summary")
        println(io)
        summary_table = [
            [string(row.group), string(row.documents), string(row.tokens), string(row.period)]
            for row in corpus_summary_rows
        ]
        print(io, _markdown_table(["Group", "Documents", "Tokens", "Period"], summary_table))
        println(io)

        println(io, "## Concept frequency")
        println(io)
        println(io, "Frequencies are normalized to $(Int(round(config.frequency_scale))) tokens. Confidence intervals use boundary-aware block bootstrap.")
        println(io)
        frequency_table = [
            [
                string(row.group),
                string(row.concept),
                string(row.count),
                _format_metric(row.frequency; digits = 2),
                _format_metric(row.lower; digits = 2),
                _format_metric(row.upper; digits = 2),
            ]
            for row in frequency_rows
        ]
        print(
            io,
            _markdown_table(
                ["Group", "Concept", "Count", "Per scale", "CI low", "CI high"],
                frequency_table,
            ),
        )
        println(io)

        println(io, "## Contextual valence")
        println(io)
        valence_table = [
            [
                string(row.group),
                string(row.concept),
                _format_metric(row.valence; digits = 3),
                string(row.contexts),
                string(row.scored_tokens),
            ]
            for row in valence_rows
        ]
        print(
            io,
            _markdown_table(
                ["Group", "Concept", "Valence", "Scored contexts", "Scored tokens"],
                valence_table,
            ),
        )
        println(io)

        println(io, "## Semantic shift")
        println(io)
        println(io, "Shift is defined as `1 - cosine_similarity` between aligned concept vectors. Larger values indicate greater vector displacement, not necessarily greater philosophical difference.")
        println(io)
        shift_table = [
            [
                string(row.from_group),
                string(row.to_group),
                string(row.concept),
                _format_metric(row.shift; digits = 4),
                _format_metric(row.lower; digits = 4),
                _format_metric(row.upper; digits = 4),
                string(row.anchors),
                string(row.valid_replicates),
                _format_metric(row.control_mean; digits = 4),
                _format_metric(row.control_z; digits = 2),
                string(row.controls),
            ]
            for row in shift_rows
        ]
        print(
            io,
            _markdown_table(
                ["From", "To", "Concept", "Shift", "CI low", "CI high", "Anchors", "Valid bootstraps", "Control mean", "Control z", "Controls"],
                shift_table,
            ),
        )
        println(io)

        println(io, "## Methodological safeguards")
        println(io)
        println(io, "- Corpus provenance and optional SHA-256 validation are defined in `config/corpora.toml`.")
        println(io, "- Concept aliases are explicit and version-controlled in `config/concepts.toml`.")
        println(io, "- Stop-word removal is restricted to the DTM/TF-IDF branch by default.")
        println(io, "- Document boundaries are preserved in aliases, local context, co-occurrence, embeddings and bootstrap.")
        println(io, "- Cross-corpus embeddings are aligned before semantic-distance calculations.")
        println(io, "- Uncertainty is estimated with block bootstrap rather than a single deterministic point estimate.")
        println(io, "- Frequency-matched shared terms provide a descriptive null/control baseline for semantic-shift magnitude.")
        println(io, "- Synthetic example texts are not evidence about real historical periods.")
        println(io)

        println(io, "## Group order")
        println(io)
        for (index, group) in enumerate(groups)
            println(io, "$index. $(get(group_labels, group, group)) (`$group`)")
        end
    end
    return path
end
