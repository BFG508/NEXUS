
function _xml_escape(value::AbstractString)
    text = replace(String(value), '&' => "&amp;")
    text = replace(text, '<' => "&lt;")
    text = replace(text, '>' => "&gt;")
    text = replace(text, '"' => "&quot;")
    return replace(text, '\'' => "&apos;")
end

function _scale_values(values::AbstractVector{<:Real}, low::Float64, high::Float64)
    isempty(values) && return Float64[]
    minimum_value = minimum(values)
    maximum_value = maximum(values)
    if maximum_value == minimum_value
        return fill((low + high) / 2, length(values))
    end
    return [
        low + (Float64(value) - minimum_value) / (maximum_value - minimum_value) * (high - low)
        for value in values
    ]
end

function pca_coordinates(vectors::AbstractMatrix{<:Real})
    n_rows, n_columns = size(vectors)
    n_rows == 0 && return zeros(Float64, 0, 2)
    n_columns == 0 && return zeros(Float64, n_rows, 2)
    matrix = Matrix{Float64}(vectors)
    centered = matrix .- mean(matrix; dims = 1)
    factorization = svd(centered)
    dimensions = min(2, length(factorization.S))
    coordinates = factorization.U[:, 1:dimensions] * Diagonal(factorization.S[1:dimensions])
    if dimensions == 1
        return hcat(coordinates, zeros(n_rows))
    end
    return Matrix{Float64}(coordinates)
end

function save_scatter_svg(
    path::AbstractString,
    coordinates::AbstractMatrix{<:Real},
    labels::Vector{String};
    title::String = "Semantic map (PCA)",
    width::Int = 1000,
    height::Int = 700,
)
    size(coordinates, 1) == length(labels) || throw(DimensionMismatch("Labels and points differ."))
    mkpath(dirname(path))
    margin = 70.0
    x_pixels = _scale_values(view(coordinates, :, 1), margin, width - margin)
    y_pixels = _scale_values(view(coordinates, :, 2), height - margin, margin)

    open(path, "w") do io
        println(io, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$width\" height=\"$height\" viewBox=\"0 0 $width $height\">")
        println(io, "<rect width=\"100%\" height=\"100%\" fill=\"white\"/>")
        println(io, "<text x=\"$(width / 2)\" y=\"34\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"22\" font-weight=\"600\">$(_xml_escape(title))</text>")
        println(io, "<line x1=\"$margin\" y1=\"$(height - margin)\" x2=\"$(width - margin)\" y2=\"$(height - margin)\" stroke=\"#888\"/>")
        println(io, "<line x1=\"$margin\" y1=\"$margin\" x2=\"$margin\" y2=\"$(height - margin)\" stroke=\"#888\"/>")
        for index in eachindex(labels)
            x = x_pixels[index]
            y = y_pixels[index]
            println(io, "<circle cx=\"$x\" cy=\"$y\" r=\"4\" fill=\"#235789\"/>")
            println(io, "<text x=\"$(x + 7)\" y=\"$(y - 7)\" font-family=\"sans-serif\" font-size=\"12\">$(_xml_escape(labels[index]))</text>")
        end
        println(io, "<text x=\"$(width / 2)\" y=\"$(height - 18)\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"13\">PC1</text>")
        println(io, "<text x=\"18\" y=\"$(height / 2)\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"13\" transform=\"rotate(-90 18 $(height / 2))\">PC2</text>")
        println(io, "</svg>")
    end
    return path
end

function save_bar_svg(
    path::AbstractString,
    labels::Vector{String},
    values::Vector{Float64};
    title::String = "Concept frequencies",
    width::Int = 1200,
    height::Int = 700,
)
    length(labels) == length(values) || throw(DimensionMismatch("Labels and values differ."))
    mkpath(dirname(path))
    margin_left = 80.0
    margin_bottom = 180.0
    plot_width = width - margin_left - 40
    plot_height = height - 70 - margin_bottom
    maximum_value = isempty(values) ? 1.0 : max(maximum(values), eps(Float64))
    bar_width = isempty(values) ? 0.0 : plot_width / max(length(values), 1) * 0.72
    spacing = isempty(values) ? 0.0 : plot_width / max(length(values), 1)

    open(path, "w") do io
        println(io, "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"$width\" height=\"$height\" viewBox=\"0 0 $width $height\">")
        println(io, "<rect width=\"100%\" height=\"100%\" fill=\"white\"/>")
        println(io, "<text x=\"$(width / 2)\" y=\"34\" text-anchor=\"middle\" font-family=\"sans-serif\" font-size=\"22\" font-weight=\"600\">$(_xml_escape(title))</text>")
        baseline = height - margin_bottom
        println(io, "<line x1=\"$margin_left\" y1=\"$baseline\" x2=\"$(width - 40)\" y2=\"$baseline\" stroke=\"#888\"/>")
        for index in eachindex(values)
            bar_height = values[index] / maximum_value * plot_height
            x = margin_left + (index - 0.5) * spacing - bar_width / 2
            y = baseline - bar_height
            println(io, "<rect x=\"$x\" y=\"$y\" width=\"$bar_width\" height=\"$bar_height\" fill=\"#2f6f4e\"/>")
            label_x = x + bar_width / 2
            println(io, "<text x=\"$label_x\" y=\"$(baseline + 15)\" font-family=\"sans-serif\" font-size=\"11\" text-anchor=\"end\" transform=\"rotate(-55 $label_x $(baseline + 15))\">$(_xml_escape(labels[index]))</text>")
        end
        println(io, "</svg>")
    end
    return path
end
