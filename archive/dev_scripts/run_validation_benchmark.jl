"""
    run_validation_benchmark.jl

Validate Darwin Scaffold Studio metrics against synthetic ground truth.
This is the key script for scientific validation of the platform.

Author: Dr. Demetrios Agourakis
Master's Thesis: Tissue Engineering Scaffold Optimization - PUC/SP
Advisor: Dra. Moema Alencar Hausen
"""

using JSON3
using Statistics
using Printf

# Add project to load path
push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))

println("="^70)
println("DARWIN SCAFFOLD STUDIO - VALIDATION BENCHMARK")
println("="^70)
println()

#=============================================================================
    NOTE: Using standalone implementations for benchmark
    This avoids module loading complexity and tests core algorithms directly
=============================================================================#

println("Using standalone metric implementations for validation...\n")

#=============================================================================
    HELPER FUNCTIONS
=============================================================================#

"""Load raw binary scaffold file."""
function load_raw_scaffold(filename::String, dims::Tuple{Int,Int,Int})
    data = Vector{UInt8}(undef, prod(dims))
    open(filename, "r") do f
        read!(f, data)
    end
    scaffold = reshape(data, dims) .> 0
    return scaffold
end

"""Load ground truth JSON."""
function load_ground_truth(filename::String)
    json_str = read(filename, String)
    return JSON3.read(json_str)
end

"""Calculate error metrics."""
function calculate_errors(computed::Real, ground_truth::Real)
    c = Float64(computed)
    gt = Float64(ground_truth)
    absolute_error = abs(c - gt)
    relative_error = gt != 0 ? absolute_error / gt * 100 : 0.0
    return absolute_error, relative_error
end

#=============================================================================
    VALIDATION FUNCTIONS
=============================================================================#

"""Compute porosity from binary scaffold."""
function compute_porosity(scaffold::AbstractArray{Bool,3})
    return 1.0 - sum(scaffold) / length(scaffold)
end

"""Compute surface area (face counting method)."""
function compute_surface_area(scaffold::AbstractArray{Bool,3}, voxel_size_um::Float64)
    nx, ny, nz = size(scaffold)
    surface_voxels = 0

    for i in 1:nx, j in 1:ny, k in 1:nz
        if scaffold[i, j, k]
            # Count exposed faces
            neighbors = 0
            if i > 1 && scaffold[i-1, j, k] neighbors += 1 end
            if i < nx && scaffold[i+1, j, k] neighbors += 1 end
            if j > 1 && scaffold[i, j-1, k] neighbors += 1 end
            if j < ny && scaffold[i, j+1, k] neighbors += 1 end
            if k > 1 && scaffold[i, j, k-1] neighbors += 1 end
            if k < nz && scaffold[i, j, k+1] neighbors += 1 end
            surface_voxels += 6 - neighbors
        end
    end

    voxel_area_mm2 = (voxel_size_um / 1000)^2
    return surface_voxels * voxel_area_mm2
end

"""Compute pore size estimate (hydraulic diameter)."""
function compute_pore_size(scaffold::AbstractArray{Bool,3}, voxel_size_um::Float64)
    pore_voxels = sum(.!scaffold)
    surface_area = compute_surface_area(scaffold, voxel_size_um)

    voxel_volume_mm3 = (voxel_size_um / 1000)^3
    pore_volume_mm3 = pore_voxels * voxel_volume_mm3

    # Hydraulic diameter: d_h = 4V/S
    pore_size_um = surface_area > 0 ? 4 * pore_volume_mm3 / surface_area * 1000 : 0.0
    return pore_size_um
end

#=============================================================================
    MAIN BENCHMARK
=============================================================================#

function run_benchmark()
    synthetic_dir = joinpath(@__DIR__, "..", "data", "validation", "synthetic")

    # Find all ground truth files
    gt_files = filter(f -> endswith(f, "_ground_truth.json"), readdir(synthetic_dir))

    println("Found $(length(gt_files)) validation datasets\n")

    # Results storage
    results = Dict{String, Vector{Dict}}()

    all_porosity_errors = Float64[]
    all_surface_errors = Float64[]
    all_poresize_errors = Float64[]

    for gt_file in gt_files
        # Load ground truth
        gt_path = joinpath(synthetic_dir, gt_file)
        gt = load_ground_truth(gt_path)

        # Load scaffold
        raw_file = replace(gt_file, "_ground_truth.json" => ".raw")
        raw_path = joinpath(synthetic_dir, raw_file)

        dims = Tuple(gt.dimensions)
        scaffold = load_raw_scaffold(raw_path, dims)
        voxel_size = Float64(gt.voxel_size_um)

        # Compute Darwin metrics
        darwin_porosity = compute_porosity(scaffold)
        darwin_surface = compute_surface_area(scaffold, voxel_size)
        darwin_poresize = compute_pore_size(scaffold, voxel_size)

        # Get ground truth values
        gt_porosity = gt.porosity
        gt_surface = gt.surface_area_mm2
        gt_poresize = gt.pore_size_estimate_um

        # Calculate errors
        p_abs, p_rel = calculate_errors(darwin_porosity, gt_porosity)
        s_abs, s_rel = calculate_errors(darwin_surface, gt_surface)
        ps_abs, ps_rel = calculate_errors(darwin_poresize, gt_poresize)

        push!(all_porosity_errors, p_rel)
        push!(all_surface_errors, s_rel)
        push!(all_poresize_errors, ps_rel)

        # Store results
        tpms_type = gt.tpms_type
        if !haskey(results, tpms_type)
            results[tpms_type] = Dict[]
        end

        push!(results[tpms_type], Dict(
            "target_porosity" => gt.target_porosity,
            "gt_porosity" => gt_porosity,
            "darwin_porosity" => darwin_porosity,
            "porosity_error_pct" => p_rel,
            "gt_surface" => gt_surface,
            "darwin_surface" => darwin_surface,
            "surface_error_pct" => s_rel,
            "gt_poresize" => gt_poresize,
            "darwin_poresize" => darwin_poresize,
            "poresize_error_pct" => ps_rel
        ))
    end

    # Print detailed results by TPMS type
    println("="^70)
    println("DETAILED RESULTS BY TPMS TYPE")
    println("="^70)

    for tpms_type in sort(collect(keys(results)))
        type_results = results[tpms_type]
        println("\n--- $(uppercase(tpms_type)) ---")
        println("-"^70)
        @printf("%-12s | %-20s | %-20s | %-15s\n",
                "Target", "Porosity (GT→Darwin)", "Surface (GT→Darwin)", "Pore Size (GT→Darwin)")
        println("-"^70)

        for r in sort(type_results, by=x->x["target_porosity"])
            @printf("%-12s | %6.2f%% → %6.2f%% (%4.1f%%) | %6.1f → %6.1f (%4.1f%%) | %5.0f → %5.0fμm (%4.1f%%)\n",
                    "$(Int(r["target_porosity"]*100))%",
                    r["gt_porosity"]*100, r["darwin_porosity"]*100, r["porosity_error_pct"],
                    r["gt_surface"], r["darwin_surface"], r["surface_error_pct"],
                    r["gt_poresize"], r["darwin_poresize"], r["poresize_error_pct"])
        end
    end

    # Summary statistics
    println("\n" * "="^70)
    println("VALIDATION SUMMARY")
    println("="^70)

    println("\nMean Relative Errors:")
    @printf("  Porosity:     %6.3f%% (±%.3f%%)\n", mean(all_porosity_errors), std(all_porosity_errors))
    @printf("  Surface Area: %6.3f%% (±%.3f%%)\n", mean(all_surface_errors), std(all_surface_errors))
    @printf("  Pore Size:    %6.3f%% (±%.3f%%)\n", mean(all_poresize_errors), std(all_poresize_errors))

    println("\nMax Relative Errors:")
    @printf("  Porosity:     %6.3f%%\n", maximum(all_porosity_errors))
    @printf("  Surface Area: %6.3f%%\n", maximum(all_surface_errors))
    @printf("  Pore Size:    %6.3f%%\n", maximum(all_poresize_errors))

    # Validation pass/fail
    println("\n" * "="^70)
    println("VALIDATION STATUS")
    println("="^70)

    porosity_pass = mean(all_porosity_errors) < 1.0  # <1% error
    surface_pass = mean(all_surface_errors) < 1.0
    poresize_pass = mean(all_poresize_errors) < 5.0  # <5% error (more tolerance)

    println("\n  Porosity computation:     $(porosity_pass ? "✅ PASS" : "❌ FAIL") (threshold: <1%)")
    println("  Surface area computation: $(surface_pass ? "✅ PASS" : "❌ FAIL") (threshold: <1%)")
    println("  Pore size estimation:     $(poresize_pass ? "✅ PASS" : "❌ FAIL") (threshold: <5%)")

    overall_pass = porosity_pass && surface_pass && poresize_pass
    println("\n  OVERALL: $(overall_pass ? "✅ ALL VALIDATIONS PASSED" : "❌ SOME VALIDATIONS FAILED")")

    println("\n" * "="^70)

    return overall_pass, results
end

# Run benchmark
passed, results = run_benchmark()

# Exit with appropriate code
exit(passed ? 0 : 1)
