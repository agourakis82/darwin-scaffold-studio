"""
3D Mesh Visualization Module

Create 3D meshes from binary volumes for visualization.
"""

module Mesh3D

using GeometryBasics
using MeshIO

"""
    create_mesh(binary::Array{Bool, 3}, voxel_size_um::Float64) -> Mesh

Create 3D mesh from binary volume using marching cubes.

# Arguments
- `binary`: Binary 3D array (true = solid)
- `voxel_size_um`: Voxel size in micrometers

# Returns
- GeometryBasics.Mesh
"""
function create_mesh(
    binary::Array{Bool, 3},
    voxel_size_um::Float64
)
    # Simplified: create mesh from surface voxels
    # In production, would use marching cubes algorithm
    
    dims = size(binary)
    vertices = Vector{Point3{Float64}}()
    faces = Vector{Face{3, Int}}()
    
    # Extract surface voxels and create simple mesh
    # For now, create bounding box mesh
    x_max = dims[1] * voxel_size_um / 1000.0  # Convert to mm
    y_max = dims[2] * voxel_size_um / 1000.0
    z_max = dims[3] * voxel_size_um / 1000.0
    
    # Simple box mesh (placeholder - would use marching cubes in production)
    box_vertices = [
        Point3(0.0, 0.0, 0.0),
        Point3(x_max, 0.0, 0.0),
        Point3(x_max, y_max, 0.0),
        Point3(0.0, y_max, 0.0),
        Point3(0.0, 0.0, z_max),
        Point3(x_max, 0.0, z_max),
        Point3(x_max, y_max, z_max),
        Point3(0.0, y_max, z_max)
    ]
    
    box_faces = [
        Face(1, 2, 3),
        Face(1, 3, 4),
        Face(5, 6, 7),
        Face(5, 7, 8),
        Face(1, 2, 6),
        Face(1, 6, 5),
        Face(3, 4, 8),
        Face(3, 8, 7),
        Face(2, 3, 7),
        Face(2, 7, 6),
        Face(1, 4, 8),
        Face(1, 8, 5)
    ]
    
    return GeometryBasics.Mesh(box_vertices, box_faces)
end

"""
    create_mesh_simple(binary::Array{Bool, 3}, voxel_size_um::Float64) -> Tuple{Array{Float64, 2}, Array{Int, 2}}

Create simple mesh representation (vertices and faces arrays).

# Returns
- (vertices, faces) where vertices is N×3 and faces is M×3
"""
function create_mesh_simple(
    binary::Array{Bool, 3},
    voxel_size_um::Float64
)::Tuple{Array{Float64, 2}, Array{Int, 2}}
    # Extract surface voxels
    dims = size(binary)
    vertices_list = Vector{Vector{Float64}}()
    faces_list = Vector{Vector{Int}}()
    
    voxel_size_mm = voxel_size_um / 1000.0
    
    # Create vertices for each surface voxel
    vertex_idx = 1
    vertex_map = Dict{Tuple{Int, Int, Int}, Int}()
    
    for i in 1:dims[1], j in 1:dims[2], k in 1:dims[3]
        if binary[i, j, k]
            # Check if surface voxel (has at least one neighbor that's not solid)
            is_surface = false
            if i == 1 || i == dims[1] || j == 1 || j == dims[2] || k == 1 || k == dims[3]
                is_surface = true
            elseif !binary[i-1, j, k] || !binary[i+1, j, k] || 
                   !binary[i, j-1, k] || !binary[i, j+1, k] ||
                   !binary[i, j, k-1] || !binary[i, j, k+1]
                is_surface = true
            end
            
            if is_surface
                # Create 8 vertices for this voxel
                v0 = [i * voxel_size_mm, j * voxel_size_mm, k * voxel_size_mm]
                v1 = [(i+1) * voxel_size_mm, j * voxel_size_mm, k * voxel_size_mm]
                v2 = [(i+1) * voxel_size_mm, (j+1) * voxel_size_mm, k * voxel_size_mm]
                v3 = [i * voxel_size_mm, (j+1) * voxel_size_mm, k * voxel_size_mm]
                v4 = [i * voxel_size_mm, j * voxel_size_mm, (k+1) * voxel_size_mm]
                v5 = [(i+1) * voxel_size_mm, j * voxel_size_mm, (k+1) * voxel_size_mm]
                v6 = [(i+1) * voxel_size_mm, (j+1) * voxel_size_mm, (k+1) * voxel_size_mm]
                v7 = [i * voxel_size_mm, (j+1) * voxel_size_mm, (k+1) * voxel_size_mm]
                
                push!(vertices_list, v0, v1, v2, v3, v4, v5, v6, v7)
                
                # Create 12 faces (2 per cube face)
                base = length(vertices_list) - 8
                push!(faces_list, [base+1, base+2, base+3], [base+1, base+3, base+4])  # Bottom
                push!(faces_list, [base+5, base+6, base+7], [base+5, base+7, base+8])  # Top
                push!(faces_list, [base+1, base+2, base+6], [base+1, base+6, base+5])  # Front
                push!(faces_list, [base+3, base+4, base+8], [base+3, base+8, base+7])  # Back
                push!(faces_list, [base+2, base+3, base+7], [base+2, base+7, base+6])  # Right
                push!(faces_list, [base+1, base+4, base+8], [base+1, base+8, base+5])  # Left
            end
        end
    end
    
    # Convert to arrays
    if isempty(vertices_list)
        return (zeros(Float64, 0, 3), zeros(Int, 0, 3))
    end
    
    vertices = hcat(vertices_list...)'
    faces = hcat(faces_list...)'
    
    return (vertices, faces)
end

end # module Mesh3D

