"""
Export Module

Export scaffolds to STL and other formats.
"""

module Export

using MeshIO
using FileIO
using GeometryBasics
using ..Mesh3D

"""
    export_stl(mesh::Mesh, path::String)

Export mesh to STL file.
"""
function export_stl(mesh::Mesh, path::String)
    save(path, mesh)
end

"""
    export_stl_from_binary(binary::Array{Bool, 3}, 
                           voxel_size_um::Float64,
                           path::String)

Export binary volume directly to STL.
"""
function export_stl_from_binary(
    binary::Array{Bool, 3},
    voxel_size_um::Float64,
    path::String
)
    mesh = Mesh3D.create_mesh(binary, voxel_size_um)
    export_stl(mesh, path)
end

"""
    export_stl_simple(vertices::Array{Float64, 2},
                     faces::Array{Int, 2},
                     path::String)

Export mesh from vertices/faces arrays to STL.
"""
function export_stl_simple(
    vertices::Array{Float64, 2},
    faces::Array{Int, 2},
    path::String
)
    # Convert to GeometryBasics format
    points = [Point3(vertices[i, :]...) for i in 1:size(vertices, 1)]
    mesh_faces = [Face{3, Int}(faces[i, :]...) for i in 1:size(faces, 1)]
    
    mesh = GeometryBasics.Mesh(points, mesh_faces)
    save(path, mesh)
end

end # module Export

