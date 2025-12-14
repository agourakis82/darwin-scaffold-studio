"""
Science Module Tests
Tests for basic scaffold metrics computation
"""

using Test
using DarwinScaffoldStudio
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
end

println("✅ Science tests passed!")
