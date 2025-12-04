"""
DataIngestion.jl - Unified data loading for MicroCT, SEM, and synthetic scaffolds

Handles multiple file formats and provides synthetic data generation for testing.
"""

module DataIngestion

using FileIO
using Images
using NIfTI
using Printf

export load_scaffold_data, generate_synthetic_scaffold, detect_file_format

"""
    FileFormat

Supported input file formats.
"""
@enum FileFormat begin
    TIFF_STACK
    NIFTI
    STL
    IMAGE_2D
    SYNTHETIC
    UNKNOWN
end

"""
    detect_file_format(filepath::String) -> FileFormat

Automatically detect the input file format.
"""
function detect_file_format(filepath::String)
    if !isfile(filepath) && !isdir(filepath)
        return UNKNOWN
    end
    
    ext = lowercase(splitext(filepath)[2])
    
    if ext ∈ [".tif", ".tiff"]
        # Check if it's a directory of TIFFs (stack)
        if isdir(filepath)
            return TIFF_STACK
        else
            return IMAGE_2D
        end
    elseif ext ∈ [".nii", ".nii.gz"]
        return NIFTI
    elseif ext == ".stl"
        return STL
    elseif ext ∈ [".png", ".jpg", ".jpeg"]
        return IMAGE_2D
    else
        return UNKNOWN
    end
end

"""
    load_scaffold_data(filepath::String; voxel_size_um::Float64=10.0)

Load scaffold volume data from various file formats.

# Arguments
- `filepath`: Path to the file or directory
- `voxel_size_um`: Voxel size in micrometers (for metadata)

# Returns
- `volume::Array{<:Real, 3}`: 3D volume data
- `metadata::Dict`: Additional information (voxel_size, dimensions, etc.)
"""
function load_scaffold_data(filepath::String; voxel_size_um::Float64=10.0)
    format = detect_file_format(filepath)
    
    @info "Loading scaffold data" filepath format voxel_size_um
    
    if format == TIFF_STACK
        return load_tiff_stack(filepath, voxel_size_um)
    elseif format == NIFTI
        return load_nifti(filepath, voxel_size_um)
    elseif format == IMAGE_2D
        return load_2d_image(filepath, voxel_size_um)
    elseif format == STL
        error("STL loading not yet implemented. STL is for export, not import.")
    else
        error("Unknown file format: $filepath")
    end
end

"""
    load_tiff_stack(dirpath::String, voxel_size_um::Float64)

Load a stack of TIFF images as a 3D volume.
"""
function load_tiff_stack(dirpath::String, voxel_size_um::Float64)
    if isfile(dirpath)
        # Single TIFF file - treat as 2D slice repeated
        img = load(dirpath)
        volume = repeat(Gray.(img), outer=(1, 1, 10))  # Fake 3D for testing
    else
        # Directory of TIFFs
        files = filter(f -> endswith(lowercase(f), ".tif") || endswith(lowercase(f), ".tiff"), 
                      readdir(dirpath, join=true))
        sort!(files)  # Ensure correct order
        
        if isempty(files)
            error("No TIFF files found in directory: $dirpath")
        end
        
        @info "Loading $(length(files)) TIFF slices..."
        
        # Load first image to get dimensions
        first_img = load(files[1])
        h, w = size(first_img)
        
        # Allocate volume
        volume = zeros(Float32, h, w, length(files))
        
        # Load all slices
        for (i, file) in enumerate(files)
            img = load(file)
            volume[:, :, i] = Gray.(img)
        end
    end
    
    metadata = Dict(
        "voxel_size_um" => voxel_size_um,
        "dimensions" => size(volume),
        "format" => "TIFF_STACK"
    )
    
    return Float32.(volume), metadata
end

"""
    load_nifti(filepath::String, voxel_size_um::Float64)

Load NIfTI medical imaging format.
"""
function load_nifti(filepath::String, voxel_size_um::Float64)
    nii = niread(filepath)
    volume = Float32.(nii.raw)
    
    # NIfTI files contain voxel size metadata
    actual_voxel_size = nii.header.pixdim[2:4]  # x, y, z voxel dimensions
    
    metadata = Dict(
        "voxel_size_um" => voxel_size_um,
        "actual_voxel_size_from_header" => actual_voxel_size,
        "dimensions" => size(volume),
        "format" => "NIFTI"
    )
    
    @info "Loaded NIfTI" size=size(volume) header_voxel_size=actual_voxel_size
    
    return volume, metadata
end

"""
    load_2d_image(filepath::String, voxel_size_um::Float64)

Load a 2D image (SEM, microscopy) and convert to pseudo-3D.
"""
function load_2d_image(filepath::String, voxel_size_um::Float64)
    img = load(filepath)
    
    # Convert to grayscale
    gray_img = Gray.(img)
    
    # Create pseudo-3D by repeating slice (for compatibility)
    volume = repeat(Float32.(gray_img), outer=(1, 1, 5))
    
    metadata = Dict(
        "voxel_size_um" => voxel_size_um,
        "dimensions" => size(volume),
        "format" => "IMAGE_2D",
        "original_2d_size" => size(img)
    )
    
    @warn "Loaded 2D image. Created pseudo-3D volume by repeating slices."
    
    return volume, metadata
end

"""
    generate_synthetic_scaffold(;
        size_voxels::Tuple{Int,Int,Int}=(100,100,100),
        porosity::Float64=0.75,
        pore_size_voxels::Int=10,
        voxel_size_um::Float64=10.0
    )

Generate a synthetic porous scaffold for testing.

# Returns
- `volume::Array{Bool, 3}`: Binary volume (true = solid, false = pore)
- `metadata::Dict`: Scaffold parameters
"""
function generate_synthetic_scaffold(;
    size_voxels::Tuple{Int,Int,Int}=(100,100,100),
    porosity::Float64=0.75,
    pore_size_voxels::Int=10,
    voxel_size_um::Float64=10.0
)
    @info "Generating synthetic scaffold" size_voxels porosity pore_size_voxels
    
    # Method: Random spherical pores
    volume = ones(Bool, size_voxels)  # Start with solid
    
    # Calculate number of pores needed to achieve target porosity
    total_voxels = prod(size_voxels)
    target_pore_voxels = Int(round(total_voxels * porosity))
    
    current_pore_voxels = 0
    attempts = 0
    max_attempts = 10000
    
    while current_pore_voxels < target_pore_voxels && attempts < max_attempts
        # Random pore center
        cx, cy, cz = rand(1:size_voxels[1]), rand(1:size_voxels[2]), rand(1:size_voxels[3])
        
        # Create spherical pore
        radius = pore_size_voxels ÷ 2
        for x in max(1, cx-radius):min(size_voxels[1], cx+radius)
            for y in max(1, cy-radius):min(size_voxels[2], cy+radius)
                for z in max(1, cz-radius):min(size_voxels[3], cz+radius)
                    if sqrt((x-cx)^2 + (y-cy)^2 + (z-cz)^2) <= radius
                        if volume[x, y, z]  # Only count newly created pores
                            volume[x, y, z] = false
                            current_pore_voxels += 1
                        end
                    end
                end
            end
        end
        
        attempts += 1
    end
    
    actual_porosity = current_pore_voxels / total_voxels
    
    metadata = Dict(
        "voxel_size_um" => voxel_size_um,
        "dimensions" => size_voxels,
        "target_porosity" => porosity,
        "actual_porosity" => actual_porosity,
        "pore_size_voxels" => pore_size_voxels,
        "format" => "SYNTHETIC"
    )
    
    @info "Synthetic scaffold generated" actual_porosity
    
    return volume, metadata
end

end # module
