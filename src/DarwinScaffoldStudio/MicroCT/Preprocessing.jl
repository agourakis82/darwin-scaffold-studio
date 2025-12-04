"""
Image Preprocessing Module

Q1-validated preprocessing pipeline for microCT images.
"""

module Preprocessing

using Images
using ImageFiltering
using ImageMorphology
using Statistics
using LinearAlgebra
using StatsBase

"""
    preprocess_image(image::Array{Float64, 3};
                     denoise::Bool=true,
                     normalize::Bool=true,
                     enhance_contrast::Bool=true) -> Array{Float64, 3}

Preprocess microCT image with Q1-validated pipeline.

# Arguments
- `image`: 3D image array
- `denoise`: Apply denoising (Gaussian filter)
- `normalize`: Normalize intensities to [0, 1]
- `enhance_contrast`: Enhance contrast (histogram equalization)

# Returns
- Preprocessed 3D image array
"""
function preprocess_image(
    image::Array{Float64, 3};
    denoise::Bool=true,
    normalize::Bool=true,
    enhance_contrast::Bool=true
)::Array{Float64, 3}
    processed = copy(image)
    
    # 1. Denoising (Gaussian filter)
    if denoise
        # 3D Gaussian filter
        kernel = ImageFiltering.Kernel.gaussian((1.0, 1.0, 1.0))
        processed = ImageFiltering.imfilter(processed, kernel)
    end
    
    # 2. Normalization
    if normalize
        min_val = minimum(processed)
        max_val = maximum(processed)
        if max_val > min_val
            processed = (processed .- min_val) ./ (max_val - min_val)
        end
    end
    
    # 3. Contrast enhancement (histogram equalization per slice)
    if enhance_contrast
        for k in 1:size(processed, 3)
            slice = processed[:, :, k]
            # Histogram equalization (simplified)
            # Map to [0, 1] and apply power law for contrast
            slice_min = minimum(slice)
            slice_max = maximum(slice)
            if slice_max > slice_min
                slice_norm = (slice .- slice_min) ./ (slice_max - slice_min)
                # Power law: y = x^gamma (gamma < 1 enhances contrast)
                slice = slice_norm .^ 0.7
            end
            processed[:, :, k] = slice
        end
    end
    
    return processed
end

"""
    apply_threshold(image::Array{Float64, 3}, threshold::Float64) -> Array{Bool, 3}

Apply binary threshold to image.

# Arguments
- `image`: 3D image array (normalized to [0, 1])
- `threshold`: Threshold value (0-1)

# Returns
- Binary 3D array (true = solid, false = pore)
"""
function apply_threshold(image::Array{Float64, 3}, threshold::Float64)::Array{Bool, 3}
    return image .> threshold
end

"""
    morphological_operations(binary::Array{Bool, 3};
                            closing::Bool=true,
                            opening::Bool=true,
                            radius::Int=1) -> Array{Bool, 3}

Apply morphological operations to clean binary image.

# Arguments
- `binary`: Binary 3D array
- `closing`: Fill small holes (closing)
- `opening`: Remove small objects (opening)
- `radius`: Structuring element radius

# Returns
- Cleaned binary 3D array
"""
function morphological_operations(
    binary::Array{Bool, 3};
    closing::Bool=true,
    opening::Bool=true,
    radius::Int=1
)::Array{Bool, 3}
    result = copy(binary)
    
    # Create 3D ball structuring element
    se = ImageMorphology.ball(radius)
    
    # Closing (fill holes)
    if closing
        result = ImageMorphology.closing(result, se)
    end
    
    # Opening (remove small objects)
    if opening
        result = ImageMorphology.opening(result, se)
    end
    
    return result
end

end # module Preprocessing

