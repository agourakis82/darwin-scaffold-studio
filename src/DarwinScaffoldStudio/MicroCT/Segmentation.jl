"""
Segmentation Module

3D segmentation for scaffold analysis.
"""

module Segmentation

using Images
using ImageSegmentation
using ImageMorphology
using Statistics
using StatsBase: fit, Histogram

"""
    segment_scaffold(image::Array{Float64, 3}, method::String="otsu") -> Array{Bool, 3}

Segment scaffold from microCT image.

# Arguments
- `image`: 3D preprocessed image
- `method`: Segmentation method ("otsu", "adaptive", "manual")

# Returns
- Binary 3D array (true = solid, false = pore)
"""
function segment_scaffold(
    image::Array{Float64, 3},
    method::String="otsu"
)::Array{Bool, 3}
    if method == "otsu"
        return segment_otsu(image)
    elseif method == "adaptive"
        return segment_adaptive(image)
    else
        error("Unknown segmentation method: ", method)
    end
end

"""
    segment_otsu(image::Array{Float64, 3}) -> Array{Bool, 3}

Otsu thresholding (per slice).
"""
function segment_otsu(image::Array{Float64, 3})::Array{Bool, 3}
    dims = size(image)
    binary = Array{Bool, 3}(undef, dims)

    for k in 1:dims[3]
        slice = image[:, :, k]
        # Otsu threshold
        threshold = compute_otsu_threshold(slice)
        binary[:, :, k] = slice .> threshold
    end

    return binary
end

"""
    compute_otsu_threshold(image::Array{Float64, 2}) -> Float64

Compute Otsu threshold for 2D image.
"""
function compute_otsu_threshold(image::Array{Float64, 2})::Float64
    # Histogram
    hist = fit(Histogram, vec(image), nbins=256, closed=:left)
    counts = hist.weights
    edges = hist.edges[1]

    if sum(counts) == 0
        return 0.5
    end

    # Normalize
    p = counts ./ sum(counts)

    # Otsu algorithm
    best_threshold = 0.0
    best_variance = 0.0

    for t in 1:length(p)
        w0 = sum(p[1:t])
        w1 = sum(p[t+1:end])

        if w0 == 0 || w1 == 0
            continue
        end

        mu0 = sum((1:t) .* p[1:t]) / w0
        mu1 = sum((t+1:length(p)) .* p[t+1:end]) / w1

        variance = w0 * w1 * (mu0 - mu1)^2

        if variance > best_variance
            best_variance = variance
            best_threshold = edges[t]
        end
    end

    return best_threshold
end

"""
    segment_adaptive(image::Array{Float64, 3}, window_size::Int=50) -> Array{Bool, 3}

Adaptive thresholding.
"""
function segment_adaptive(
    image::Array{Float64, 3},
    window_size::Int=50
)::Array{Bool, 3}
    dims = size(image)
    binary = Array{Bool, 3}(undef, dims)

    for k in 1:dims[3]
        slice = image[:, :, k]
        binary[:, :, k] = adaptive_threshold(slice, window_size)
    end

    return binary
end

"""
    adaptive_threshold(image::Array{Float64, 2}, window_size::Int) -> Array{Bool, 2}

Adaptive threshold per window.
"""
function adaptive_threshold(
    image::Array{Float64, 2},
    window_size::Int
)::Array{Bool, 2}
    h, w = size(image)
    binary = Array{Bool, 2}(undef, h, w)

    for i in 1:h, j in 1:w
        # Local window
        i_min = max(1, i - window_size ÷ 2)
        i_max = min(h, i + window_size ÷ 2)
        j_min = max(1, j - window_size ÷ 2)
        j_max = min(w, j + window_size ÷ 2)

        window = image[i_min:i_max, j_min:j_max]
        local_threshold = mean(window) - 0.1 * std(window)

        binary[i, j] = image[i, j] > local_threshold
    end

    return binary
end

end # module Segmentation
