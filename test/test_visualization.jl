"""
Visualization Module Tests
Tests for mesh creation and export
"""

using Test
using DarwinScaffoldStudio
using Random

Random.seed!(42)

@testset "Visualization Module" begin
    @testset "Simple Mesh Creation" begin
        # Create simple cube
        scaffold = zeros(Bool, 15, 15, 15)
        scaffold[5:10, 5:10, 5:10] .= true

        vertices, faces = create_mesh_simple(scaffold, 10.0)

        @test size(vertices, 2) == 3  # x, y, z
        @test size(faces, 2) == 3     # triangles
        @test size(vertices, 1) > 0   # Has vertices
        @test size(faces, 1) > 0      # Has faces
    end

    @testset "Mesh Vertices Valid" begin
        scaffold = zeros(Bool, 10, 10, 10)
        scaffold[3:7, 3:7, 3:7] .= true

        vertices, faces = create_mesh_simple(scaffold, 5.0)

        # All vertices should be finite
        @test all(isfinite, vertices)

        # Vertices should be within expected bounds
        voxel_size = 5.0
        max_coord = 10 * voxel_size / 1000  # Convert to mm
        @test all(v -> v >= 0, vertices)
    end

    @testset "Mesh Faces Valid" begin
        scaffold = zeros(Bool, 10, 10, 10)
        scaffold[3:7, 3:7, 3:7] .= true

        vertices, faces = create_mesh_simple(scaffold, 5.0)

        # All face indices should be valid
        n_vertices = size(vertices, 1)
        @test all(f -> f >= 1 && f <= n_vertices, faces)

        # Faces should be triangles (3 vertices each)
        @test size(faces, 2) == 3
    end

    @testset "Empty Scaffold" begin
        scaffold = zeros(Bool, 10, 10, 10)

        vertices, faces = create_mesh_simple(scaffold, 10.0)

        # Empty scaffold should produce empty mesh
        @test size(vertices, 1) == 0 || size(faces, 1) == 0
    end

    @testset "Full Scaffold" begin
        scaffold = ones(Bool, 10, 10, 10)

        vertices, faces = create_mesh_simple(scaffold, 10.0)

        # Full scaffold should only have outer surface
        @test size(vertices, 1) > 0
        @test size(faces, 1) > 0
    end

    @testset "Mesh Scaling" begin
        scaffold = zeros(Bool, 10, 10, 10)
        scaffold[4:6, 4:6, 4:6] .= true

        # Different voxel sizes
        v1, f1 = create_mesh_simple(scaffold, 10.0)
        v2, f2 = create_mesh_simple(scaffold, 20.0)

        # Same number of vertices and faces
        @test size(v1, 1) == size(v2, 1)
        @test size(f1, 1) == size(f2, 1)
    end
end

println("✅ Visualization tests passed!")
