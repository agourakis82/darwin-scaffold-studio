"""
TPMS Validation Tests
Tests for Triply Periodic Minimal Surface scaffold generation and metrics
"""

using Test
using Random

Random.seed!(42)

@testset "TPMS Validation" begin
    # TPMS implicit functions
    gyroid(x, y, z) = sin(x)*cos(y) + sin(y)*cos(z) + sin(z)*cos(x)
    diamond(x, y, z) = sin(x)*sin(y)*sin(z) + sin(x)*cos(y)*cos(z) + cos(x)*sin(y)*cos(z) + cos(x)*cos(y)*sin(z)
    schwarz_p(x, y, z) = cos(x) + cos(y) + cos(z)
    neovius(x, y, z) = 3*(cos(x) + cos(y) + cos(z)) + 4*cos(x)*cos(y)*cos(z)

    function generate_tpms(func::Function, size::Int, porosity::Float64)
        scaffold = zeros(Bool, size, size, size)
        scale = 2π / size

        # Sample function values to find threshold
        samples = Float64[]
        for i in 1:size, j in 1:size, k in 1:size
            x, y, z = (i-1)*scale, (j-1)*scale, (k-1)*scale
            push!(samples, func(x, y, z))
        end
        sort!(samples)

        # Find threshold for target porosity
        idx = round(Int, porosity * length(samples))
        idx = clamp(idx, 1, length(samples))
        threshold = samples[idx]

        # Generate scaffold
        for i in 1:size, j in 1:size, k in 1:size
            x, y, z = (i-1)*scale, (j-1)*scale, (k-1)*scale
            scaffold[i,j,k] = func(x, y, z) > threshold
        end

        return scaffold
    end

    function compute_porosity(scaffold::AbstractArray{Bool,3})
        return 1.0 - sum(scaffold) / length(scaffold)
    end

    @testset "Gyroid Generation" begin
        for target_porosity in [0.5, 0.7, 0.85, 0.9]
            scaffold = generate_tpms(gyroid, 50, target_porosity)
            actual_porosity = compute_porosity(scaffold)

            # Should match within 1%
            @test abs(actual_porosity - target_porosity) < 0.01
        end
    end

    @testset "Diamond Generation" begin
        for target_porosity in [0.5, 0.7, 0.85, 0.9]
            scaffold = generate_tpms(diamond, 50, target_porosity)
            actual_porosity = compute_porosity(scaffold)

            @test abs(actual_porosity - target_porosity) < 0.01
        end
    end

    @testset "Schwarz P Generation" begin
        for target_porosity in [0.5, 0.7, 0.85, 0.9]
            scaffold = generate_tpms(schwarz_p, 50, target_porosity)
            actual_porosity = compute_porosity(scaffold)

            @test abs(actual_porosity - target_porosity) < 0.01
        end
    end

    @testset "Neovius Generation" begin
        for target_porosity in [0.5, 0.7, 0.85, 0.9]
            scaffold = generate_tpms(neovius, 50, target_porosity)
            actual_porosity = compute_porosity(scaffold)

            @test abs(actual_porosity - target_porosity) < 0.01
        end
    end

    @testset "Surface Area Computation" begin
        # Generate test scaffold
        scaffold = generate_tpms(gyroid, 50, 0.7)

        # Count surface voxels (6-connectivity)
        function count_surface_voxels(s::AbstractArray{Bool,3})
            nx, ny, nz = size(s)
            count = 0
            for i in 1:nx, j in 1:ny, k in 1:nz
                if s[i,j,k]  # Material voxel
                    # Check neighbors
                    neighbors = [
                        (i > 1 && !s[i-1,j,k]),
                        (i < nx && !s[i+1,j,k]),
                        (j > 1 && !s[i,j-1,k]),
                        (j < ny && !s[i,j+1,k]),
                        (k > 1 && !s[i,j,k-1]),
                        (k < nz && !s[i,j,k+1])
                    ]
                    count += sum(neighbors)
                end
            end
            return count
        end

        surface_count = count_surface_voxels(scaffold)

        # Should have significant surface area for TPMS
        @test surface_count > 0

        # Surface area should scale with size
        small = generate_tpms(gyroid, 30, 0.7)
        large = generate_tpms(gyroid, 60, 0.7)

        small_surface = count_surface_voxels(small)
        large_surface = count_surface_voxels(large)

        # Larger scaffold should have more surface
        @test large_surface > small_surface
    end

    @testset "TPMS Properties" begin
        # TPMS should have connected pore networks
        scaffold = generate_tpms(gyroid, 50, 0.7)

        # Material should not be all at edges
        center = scaffold[20:30, 20:30, 20:30]
        @test sum(center) > 0  # Has material in center
        @test sum(center) < length(center)  # Has pores in center

        # Porosity should be uniform throughout
        top_half_porosity = 1.0 - sum(scaffold[:,:,1:25]) / (50*50*25)
        bottom_half_porosity = 1.0 - sum(scaffold[:,:,26:50]) / (50*50*25)

        @test abs(top_half_porosity - bottom_half_porosity) < 0.05
    end
end

println("✅ TPMS tests passed!")
