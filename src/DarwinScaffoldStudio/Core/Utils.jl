"""
Utility functions for DarwinScaffoldStudio
"""

module Utils

using Statistics
using LinearAlgebra

"""
    compute_volume_mm3(dims::Tuple, voxel_size_um::Float64) -> Tuple{Float64, Float64, Float64}

Compute physical volume dimensions in mm³.
"""
function compute_volume_mm3(dims::Tuple, voxel_size_um::Float64)
    x_mm = dims[1] * voxel_size_um / 1000.0
    y_mm = dims[2] * voxel_size_um / 1000.0
    z_mm = dims[3] * voxel_size_um / 1000.0
    return (x_mm, y_mm, z_mm)
end

"""
    compute_surface_area(volume::Array{Bool, 3}, voxel_size_um::Float64) -> Float64

Compute surface area in mm².
"""
function compute_surface_area(volume::Array{Bool, 3}, voxel_size_um::Float64)
    # Count boundary voxels (6-connectivity)
    dims = size(volume)
    surface_voxels = 0
    
    for i in 1:dims[1], j in 1:dims[2], k in 1:dims[3]
        if volume[i, j, k]
            # Check 6 neighbors
            neighbors = 0
            if i > 1 && volume[i-1, j, k]; neighbors += 1; end
            if i < dims[1] && volume[i+1, j, k]; neighbors += 1; end
            if j > 1 && volume[i, j-1, k]; neighbors += 1; end
            if j < dims[2] && volume[i, j+1, k]; neighbors += 1; end
            if k > 1 && volume[i, j, k-1]; neighbors += 1; end
            if k < dims[3] && volume[i, j, k+1]; neighbors += 1; end
            
            # Surface voxel has < 6 neighbors
            if neighbors < 6
                surface_voxels += (6 - neighbors)
            end
        end
    end
    
    # Convert to mm²
    voxel_area_mm2 = (voxel_size_um / 1000.0)^2
    return surface_voxels * voxel_area_mm2
end

"""
    compute_relative_density(volume::Array{Bool, 3}) -> Float64

Compute relative density (solid fraction).
"""
function compute_relative_density(volume::Array{Bool, 3})
    return sum(volume) / length(volume)
end

end # module Utils

