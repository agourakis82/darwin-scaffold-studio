"""
Image Loading Module

Load microCT/SEM images from various formats (TIFF, NIfTI, DICOM).
"""

module ImageLoader

using Images
using FileIO

# Conditional NIfTI import
const NIFTI_AVAILABLE = try
    using NIfTI
    true
catch
    false
end

"""
    load_image(path::String) -> Array{Float64, 3}

Load 3D image from file.

Supports: TIFF, NIfTI, DICOM (via Images.jl)
"""
function load_image(path::String)::Array{Float64, 3}
    ext = lowercase(splitext(path)[2])
    
    if ext == ".nii" || ext == ".nii.gz"
        if !NIFTI_AVAILABLE
            error("NIfTI.jl not available. Install with: using Pkg; Pkg.add(\"NIfTI\")")
        end
        nii = NIfTI.niread(path)
        return Float64.(nii.raw)
    elseif ext == ".tif" || ext == ".tiff"
        img = load(path)
        # Convert to 3D array
        if ndims(img) == 3
            return Float64.(channelview(img))
        elseif ndims(img) == 2
            # Single slice - expand to 3D
            return reshape(Float64.(channelview(img)), size(img)..., 1)
        else
            error("Unsupported image dimensions: ", ndims(img))
        end
    else
        # Try Images.jl generic loader
        img = load(path)
        if ndims(img) == 3
            return Float64.(channelview(img))
        else
            error("Unsupported format or dimensions: ", ext, ", dims: ", ndims(img))
        end
    end
end

"""
    load_image_stack(directory::String, pattern::String="*.tif") -> Array{Float64, 3}

Load 3D image from stack of 2D images.
"""
function load_image_stack(directory::String, pattern::String="*.tif")::Array{Float64, 3}
    files = sort([f for f in readdir(directory) if occursin(pattern, f)])
    
    if isempty(files)
        error("No files found matching pattern: ", pattern)
    end
    
    # Load first image to get dimensions
    first_img = load(joinpath(directory, files[1]))
    h, w = size(first_img)
    n_slices = length(files)
    
    # Allocate 3D array
    stack = Array{Float64, 3}(undef, h, w, n_slices)
    
    # Load all slices
    for (i, file) in enumerate(files)
        img = load(joinpath(directory, file))
        stack[:, :, i] = Float64.(channelview(img))
    end
    
    return stack
end

end # module ImageLoader

