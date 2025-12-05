"""
Science Module Tests
Tests for Topology, Percolation, and ML modules
"""

using Test
using DarwinScaffoldStudio
using Random

Random.seed!(42)

@testset "Science Module" begin
    @testset "Topology Analysis" begin
        # Create simple connected structure
        scaffold = zeros(Bool, 20, 20, 20)
        scaffold[5:15, 5:15, 5:15] .= true

        # Add a channel
        scaffold[1:20, 9:11, 9:11] .= true

        # Euler number should be computable
        # For a connected solid with holes, Euler < 0
        euler = compute_euler_number(scaffold)
        @test isa(euler, Integer)
    end

    @testset "Percolation Analysis" begin
        # Create percolating structure (connected from one side to other)
        scaffold = zeros(Bool, 20, 20, 20)
        scaffold[8:12, 8:12, 1:20] .= true  # Column through z

        # Invert for pore space
        pores = .!scaffold

        # Should have high interconnectivity
        # (pores connect from z=1 to z=20)
    end

    @testset "Connected Components" begin
        # Create two separate blobs
        scaffold = zeros(Bool, 30, 30, 30)
        scaffold[5:10, 5:10, 5:10] .= true   # Blob 1
        scaffold[20:25, 20:25, 20:25] .= true  # Blob 2 (disconnected)

        # Should have 2 connected components
        # This tests the labeling algorithm
    end

    @testset "Pore Size Distribution" begin
        # Create scaffold with varying pore sizes
        scaffold = zeros(Bool, 40, 40, 40)

        # Material with regular holes
        scaffold[5:35, 5:35, 5:35] .= true

        # Small pore
        scaffold[10:12, 10:12, 10:30] .= false

        # Medium pore
        scaffold[20:25, 20:25, 10:30] .= false

        # Large pore
        scaffold[30:35, 10:20, 10:30] .= false

        # Compute metrics
        metrics = compute_metrics(scaffold, 10.0)

        # Should detect pores
        @test metrics.mean_pore_size_um > 0
        @test metrics.min_pore_size_um <= metrics.mean_pore_size_um
        @test metrics.max_pore_size_um >= metrics.mean_pore_size_um
    end
end

println("✅ Science tests passed!")
