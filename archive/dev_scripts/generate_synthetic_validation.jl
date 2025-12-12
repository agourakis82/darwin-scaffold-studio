"""
    generate_synthetic_validation.jl

Generate synthetic scaffold datasets with known properties for validation.
Uses TPMS (Triply Periodic Minimal Surfaces) with analytical ground truth.

Author: Dr. Demetrios Agourakis
Master's Thesis: Tissue Engineering Scaffold Optimization - PUC/SP
"""

using LinearAlgebra
using Statistics

#=============================================================================
    TPMS FUNCTIONS
    Reference: Kapfer et al. (2011) Biomaterials 32:6875-6882
=============================================================================#

"""
    gyroid(x, y, z)

Gyroid TPMS: sin(x)cos(y) + sin(y)cos(z) + sin(z)cos(x)
"""
gyroid(x, y, z) = sin(x)*cos(y) + sin(y)*cos(z) + sin(z)*cos(x)

"""
    diamond(x, y, z)

Diamond TPMS: cos(x)cos(y)cos(z) - sin(x)sin(y)sin(z)
"""
diamond(x, y, z) = cos(x)*cos(y)*cos(z) - sin(x)*sin(y)*sin(z)

"""
    schwarz_p(x, y, z)

Schwarz P (Primitive) TPMS: cos(x) + cos(y) + cos(z)
"""
schwarz_p(x, y, z) = cos(x) + cos(y) + cos(z)

"""
    neovius(x, y, z)

Neovius TPMS: 3*(cos(x)+cos(y)+cos(z)) + 4*cos(x)*cos(y)*cos(z)
"""
neovius(x, y, z) = 3*(cos(x)+cos(y)+cos(z)) + 4*cos(x)*cos(y)*cos(z)

#=============================================================================
    SCAFFOLD GENERATION
=============================================================================#

"""
    generate_tpms_scaffold(tpms_func; size=100, periods=2, threshold=0.0)

Generate a 3D binary scaffold using a TPMS function.

# Arguments
- `tpms_func`: TPMS function (gyroid, diamond, schwarz_p, neovius)
- `size`: Voxel resolution (size × size × size)
- `periods`: Number of unit cell repetitions
- `threshold`: Iso-surface threshold (controls porosity)

# Returns
- Binary 3D array (1 = solid, 0 = pore)
- Analytical porosity
"""
function generate_tpms_scaffold(tpms_func; size::Int=100, periods::Int=2, threshold::Float64=0.0)
    # Create coordinate grid
    coords = range(0, 2π * periods, length=size)

    # Evaluate TPMS function
    scaffold = zeros(Bool, size, size, size)

    for (i, x) in enumerate(coords)
        for (j, y) in enumerate(coords)
            for (k, z) in enumerate(coords)
                scaffold[i, j, k] = tpms_func(x, y, z) > threshold
            end
        end
    end

    # Calculate actual porosity
    porosity = 1.0 - sum(scaffold) / length(scaffold)

    return scaffold, porosity
end

"""
    generate_scaffold_with_target_porosity(tpms_func, target_porosity; size=100, periods=2, tol=0.01)

Generate scaffold with a specific target porosity by adjusting threshold.
"""
function generate_scaffold_with_target_porosity(tpms_func, target_porosity::Float64;
                                                  size::Int=100, periods::Int=2, tol::Float64=0.01)
    # Binary search for correct threshold
    t_low, t_high = -3.0, 3.0

    for _ in 1:50  # Max iterations
        t_mid = (t_low + t_high) / 2
        scaffold, porosity = generate_tpms_scaffold(tpms_func; size=size, periods=periods, threshold=t_mid)

        if abs(porosity - target_porosity) < tol
            return scaffold, porosity, t_mid
        elseif porosity < target_porosity
            t_low = t_mid
        else
            t_high = t_mid
        end
    end

    # Return best attempt
    scaffold, porosity = generate_tpms_scaffold(tpms_func; size=size, periods=periods, threshold=(t_low+t_high)/2)
    return scaffold, porosity, (t_low+t_high)/2
end

#=============================================================================
    GROUND TRUTH METRICS
=============================================================================#

"""
    compute_ground_truth(scaffold, voxel_size_um)

Compute ground truth metrics for validation.

# Returns
Dict with:
- porosity: Volume fraction of pores
- solid_fraction: Volume fraction of solid (BV/TV equivalent)
- surface_area: Approximate surface area
- pore_size_estimate: Estimated mean pore size from geometry
"""
function compute_ground_truth(scaffold::Array{Bool,3}, voxel_size_um::Float64)
    nx, ny, nz = size(scaffold)
    total_voxels = nx * ny * nz
    solid_voxels = sum(scaffold)
    pore_voxels = total_voxels - solid_voxels

    # Porosity
    porosity = pore_voxels / total_voxels

    # Solid volume fraction (BV/TV in bone terminology)
    solid_fraction = solid_voxels / total_voxels

    # Surface area estimation (count face transitions)
    surface_voxels = 0
    for i in 1:nx, j in 1:ny, k in 1:nz
        if scaffold[i, j, k]
            # Check 6-connectivity neighbors
            neighbors = [
                i > 1 ? scaffold[i-1, j, k] : false,
                i < nx ? scaffold[i+1, j, k] : false,
                j > 1 ? scaffold[i, j-1, k] : false,
                j < ny ? scaffold[i, j+1, k] : false,
                k > 1 ? scaffold[i, j, k-1] : false,
                k < nz ? scaffold[i, j, k+1] : false
            ]
            surface_voxels += 6 - sum(neighbors)
        end
    end

    # Surface area in mm²
    voxel_area_mm2 = (voxel_size_um / 1000)^2
    surface_area_mm2 = surface_voxels * voxel_area_mm2

    # Volume in mm³
    voxel_volume_mm3 = (voxel_size_um / 1000)^3
    total_volume_mm3 = total_voxels * voxel_volume_mm3

    # Specific surface area (mm²/mm³)
    specific_surface = surface_area_mm2 / total_volume_mm3

    # Pore size estimate (hydraulic diameter approximation)
    # d_h = 4 * V_pore / S
    pore_volume_mm3 = pore_voxels * voxel_volume_mm3
    pore_size_um = 4 * pore_volume_mm3 / surface_area_mm2 * 1000  # Convert to μm

    return Dict(
        "porosity" => porosity,
        "solid_fraction" => solid_fraction,
        "surface_area_mm2" => surface_area_mm2,
        "specific_surface_mm2_mm3" => specific_surface,
        "pore_size_estimate_um" => pore_size_um,
        "total_volume_mm3" => total_volume_mm3,
        "voxel_size_um" => voxel_size_um,
        "dimensions" => (nx, ny, nz)
    )
end

#=============================================================================
    FILE I/O
=============================================================================#

"""
    save_raw(filename, scaffold)

Save scaffold as raw binary file (compatible with ImageJ, CTAn, etc.)
"""
function save_raw(filename::String, scaffold::Array{Bool,3})
    # Convert to UInt8 (0 = pore, 255 = solid)
    data = UInt8.(scaffold) .* UInt8(255)
    # Write as raw bytes (column-major order)
    open(filename, "w") do f
        unsafe_write(f, pointer(data), length(data))
    end
    println("Saved: $filename ($(size(scaffold)), $(length(data)) bytes)")
end

"""
    save_ground_truth(filename, metrics)

Save ground truth metrics as JSON.
"""
function save_ground_truth(filename::String, metrics::Dict)
    open(filename, "w") do f
        println(f, "{")
        for (i, (k, v)) in enumerate(metrics)
            comma = i < length(metrics) ? "," : ""
            if v isa Tuple
                println(f, "  \"$k\": [$(join(v, ", "))]$comma")
            elseif v isa AbstractFloat
                println(f, "  \"$k\": $(round(v, digits=6))$comma")
            elseif v isa AbstractString
                println(f, "  \"$k\": \"$v\"$comma")  # Strings need quotes
            else
                println(f, "  \"$k\": $v$comma")
            end
        end
        println(f, "}")
    end
    println("Saved: $filename")
end

#=============================================================================
    MAIN: GENERATE VALIDATION DATASET
=============================================================================#

function generate_validation_dataset(output_dir::String="data/validation/synthetic")
    # Create output directory
    mkpath(output_dir)

    println("="^60)
    println("GENERATING SYNTHETIC VALIDATION DATASET")
    println("="^60)

    # Configuration
    voxel_size_um = 10.0  # 10 μm voxel size (typical high-res microCT)
    size = 100  # 100³ = 1 million voxels
    periods = 2  # 2 unit cells

    # Target porosities for tissue engineering (Murphy 2010, Karageorgiou 2005)
    target_porosities = [0.50, 0.70, 0.85, 0.90]

    # TPMS structures
    tpms_functions = [
        ("gyroid", gyroid),
        ("diamond", diamond),
        ("schwarz_p", schwarz_p),
        ("neovius", neovius)
    ]

    all_results = Dict[]

    for (tpms_name, tpms_func) in tpms_functions
        println("\n--- $tpms_name ---")

        for target_p in target_porosities
            # Generate scaffold
            scaffold, actual_p, threshold = generate_scaffold_with_target_porosity(
                tpms_func, target_p; size=size, periods=periods, tol=0.005
            )

            # Compute ground truth
            metrics = compute_ground_truth(scaffold, voxel_size_um)
            metrics["tpms_type"] = tpms_name
            metrics["target_porosity"] = target_p
            metrics["threshold"] = threshold

            # Generate filename
            porosity_str = replace(string(Int(target_p * 100)), "." => "")
            base_name = "$(tpms_name)_p$(porosity_str)"

            # Save files
            save_raw(joinpath(output_dir, "$(base_name).raw"), scaffold)
            save_ground_truth(joinpath(output_dir, "$(base_name)_ground_truth.json"), metrics)

            push!(all_results, metrics)

            println("  Porosity $(Int(target_p*100))%: actual=$(round(actual_p*100, digits=1))%, " *
                   "pore_size≈$(round(metrics["pore_size_estimate_um"], digits=0))μm")
        end
    end

    # Save summary
    println("\n" * "="^60)
    println("SUMMARY")
    println("="^60)
    println("Generated $(length(all_results)) synthetic scaffolds")
    println("Voxel size: $(voxel_size_um) μm")
    println("Volume size: $(size)³ = $(size^3) voxels")
    println("Physical size: $(size * voxel_size_um / 1000) mm³")
    println("\nFiles saved to: $output_dir")

    return all_results
end

# Run if executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    generate_validation_dataset()
end
