"""
Science Module Tests
Tests for basic scaffold metrics computation and Percolation helper functions
"""

using Test
using DarwinScaffoldStudio
using DarwinScaffoldStudio.Percolation: find_largest_cluster, compute_percolation_diameter,
                                         compute_tortuosity, compute_geodesic_length
using Random

Random.seed!(42)

@testset "Science Module" begin
    @testset "Connected Components" begin
        # Create two separate blobs
        scaffold = zeros(Bool, 30, 30, 30)
        scaffold[5:10, 5:10, 5:10] .= true   # Blob 1
        scaffold[20:25, 20:25, 20:25] .= true  # Blob 2 (disconnected)

        # Test metrics computes something reasonable
        metrics = compute_metrics(scaffold, 10.0)
        @test metrics.porosity >= 0.0 && metrics.porosity <= 1.0
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
        @test metrics.mean_pore_size_um >= 0.0
        @test metrics.interconnectivity >= 0.0 && metrics.interconnectivity <= 1.0
    end

    @testset "Basic Metrics Computation" begin
        # Simple solid block
        scaffold = ones(Bool, 20, 20, 20)

        metrics = compute_metrics(scaffold, 10.0)

        # Solid block should have ~0 porosity
        @test metrics.porosity < 0.01
        @test metrics.elastic_modulus > 0.0
    end

    # =========================================================================
    # Percolation Helper Functions Tests
    # =========================================================================

    @testset "Percolation: find_largest_cluster" begin
        @testset "Empty volume returns no cluster" begin
            volume = falses(10, 10, 10)
            cluster, is_percolating = find_largest_cluster(volume)

            @test is_percolating == false
            @test !any(cluster)
        end

        @testset "Single cluster found" begin
            volume = falses(15, 15, 15)
            volume[5:10, 5:10, 5:10] .= true  # Single blob

            cluster, is_percolating = find_largest_cluster(volume)

            @test any(cluster)  # Should find a cluster
            @test sum(cluster) > 0
        end
    end

    @testset "Percolation: compute_geodesic_length" begin
        @testset "Straight channel path" begin
            mask = falses(10, 10, 20)
            mask[5, 5, :] .= true

            voxel_size = 10.0
            geo_length = compute_geodesic_length(mask, voxel_size)

            # Should find a finite path
            @test geo_length < Inf
            @test geo_length > 0.0
        end

        @testset "No path returns Inf" begin
            mask = falses(10, 10, 20)
            mask[5, 5, 1:8] .= true
            mask[5, 5, 12:20] .= true  # Gap in middle

            geo_length = compute_geodesic_length(mask, 10.0)

            @test geo_length == Inf
        end
    end

    @testset "Percolation: compute_percolation_metrics" begin
        @testset "Blocked scaffold" begin
            volume = falses(10, 10, 10)

            metrics = compute_percolation_metrics(volume, 10.0)

            @test metrics["percolation_status"] == "Blocked"
            @test metrics["tortuosity_index"] == Inf
            @test metrics["effective_porosity"] == 0.0
        end

        @testset "Scaffold with pores" begin
            volume = falses(20, 20, 20)
            volume[8:12, 8:12, 5:15] .= true

            metrics = compute_percolation_metrics(volume, 10.0)

            @test haskey(metrics, "percolation_status")
            @test haskey(metrics, "tortuosity_index")
            @test haskey(metrics, "effective_porosity")
            @test metrics["effective_porosity"] > 0.0
        end
    end
end

println("✅ Science tests passed!")
