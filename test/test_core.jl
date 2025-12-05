"""
Core Module Tests
Tests for Types, Config, Utils, and ErrorHandling
"""

using Test
using DarwinScaffoldStudio

@testset "Core Module" begin
    @testset "ScaffoldMetrics Type" begin
        metrics = ScaffoldMetrics(
            porosity=0.85,
            mean_pore_size_um=150.0,
            std_pore_size_um=25.0,
            min_pore_size_um=50.0,
            max_pore_size_um=300.0,
            surface_area_mm2=100.0,
            volume_mm3=1.0,
            interconnectivity=0.92,
            tortuosity=1.15,
            euler_number=-500,
            elastic_modulus=50.0,
            yield_strength=2.0
        )

        @test metrics.porosity == 0.85
        @test metrics.mean_pore_size_um == 150.0
        @test metrics.interconnectivity == 0.92
        @test metrics.tortuosity == 1.15
    end

    @testset "ScaffoldParameters Type" begin
        params = ScaffoldParameters(
            0.90,           # target_porosity
            200.0,          # target_pore_size_um
            0.95,           # target_interconnectivity
            1.1,            # target_tortuosity
            (5.0, 5.0, 5.0),  # volume_mm
            10.0            # resolution_um
        )

        @test params.target_porosity == 0.90
        @test params.target_pore_size_um == 200.0
        @test params.volume_mm == (5.0, 5.0, 5.0)
    end

    @testset "GlobalConfig" begin
        config = get_config()

        @test haskey(config, :enable_gpu)
        @test haskey(config, :default_voxel_size)
    end
end

println("✅ Core tests passed!")
