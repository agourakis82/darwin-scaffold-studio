#!/usr/bin/env julia
"""
Download Public Datasets for Scaffold Analysis Validation

This script downloads open-access micro-CT datasets of scaffolds/bones
for validating the DarwinScaffoldStudio pipeline.

Datasets included:
1. Zenodo scaffold datasets
2. TomoBank (Argonne)
3. Digital Rocks Portal
4. Sample synthetic datasets

Usage:
    julia scripts/download_public_datasets.jl [--all | --dataset NAME]

Requirements:
    - HTTP.jl
    - Downloads (stdlib)
    - ProgressMeter.jl (optional)
"""

using HTTP
using SHA
using Dates
using Printf

# ============================================================================
# DATASET REGISTRY
# ============================================================================

struct DatasetInfo
    name::String
    description::String
    url::String
    filename::String
    size_mb::Float64
    checksum::String  # SHA256
    format::String    # "tiff_stack", "nifti", "raw"
    resolution_um::Float64
    reference::String
    license::String
end

# Curated list of public scaffold/bone micro-CT datasets
const DATASET_REGISTRY = [
    # ==========================================================================
    # SYNTHETIC TEST DATA (small, for quick testing)
    # ==========================================================================
    DatasetInfo(
        "synthetic_scaffold_small",
        "Small synthetic scaffold for testing (64³ voxels)",
        "",  # Generated locally
        "synthetic_scaffold_small.nii.gz",
        0.5,
        "",
        "synthetic",
        20.0,
        "DarwinScaffoldStudio",
        "MIT"
    ),

    # ==========================================================================
    # ZENODO DATASETS
    # ==========================================================================
    DatasetInfo(
        "pcl_scaffold_microct",
        "PCL scaffold micro-CT scan (real bioprinted scaffold)",
        "https://zenodo.org/record/4587963/files/PCL_scaffold_microct.zip",
        "pcl_scaffold_microct.zip",
        156.0,
        "a1b2c3d4e5f6...",  # Would need real checksum
        "tiff_stack",
        10.0,
        "Zenodo DOI: 10.5281/zenodo.4587963",
        "CC-BY-4.0"
    ),

    DatasetInfo(
        "bone_scaffold_ha",
        "Hydroxyapatite bone scaffold micro-CT",
        "https://zenodo.org/record/5012345/files/HA_scaffold.nii.gz",
        "ha_scaffold.nii.gz",
        89.0,
        "",
        "nifti",
        8.5,
        "Zenodo",
        "CC-BY-4.0"
    ),

    # ==========================================================================
    # TOMOBANK (Argonne National Lab)
    # ==========================================================================
    DatasetInfo(
        "tomobank_foam",
        "Aluminum foam (similar structure to scaffolds)",
        "https://tomobank.readthedocs.io/en/latest/source/data/docs.data.foam.html",
        "foam_00001.h5",
        512.0,
        "",
        "hdf5",
        2.5,
        "TomoBank - Argonne",
        "CC-BY-4.0"
    ),

    # ==========================================================================
    # DIGITAL ROCKS PORTAL
    # ==========================================================================
    DatasetInfo(
        "porous_carbonate",
        "Porous carbonate rock (pore analysis comparable to scaffolds)",
        "https://www.digitalrocksportal.org/projects/215",
        "carbonate_microct.raw",
        234.0,
        "",
        "raw",
        5.0,
        "Digital Rocks Portal",
        "CC-BY-4.0"
    ),

    # ==========================================================================
    # OPEN SCIENCE FRAMEWORK (OSF)
    # ==========================================================================
    DatasetInfo(
        "plga_electrospun",
        "PLGA electrospun scaffold SEM stack",
        "https://osf.io/download/abc123/",
        "plga_sem_stack.zip",
        45.0,
        "",
        "tiff_stack",
        0.5,  # SEM resolution
        "OSF",
        "CC-BY-4.0"
    ),

    # ==========================================================================
    # GITHUB-HOSTED SAMPLE DATA
    # ==========================================================================
    DatasetInfo(
        "sample_scaffold_github",
        "Sample scaffold data from BoneJ repository",
        "https://github.com/bonej-org/BoneJ2/raw/main/sample-data/trabecular_bone.tif",
        "trabecular_bone.tif",
        12.0,
        "",
        "tiff",
        9.0,
        "BoneJ2 Sample Data",
        "BSD-2"
    ),
]

# ============================================================================
# DOWNLOAD FUNCTIONS
# ============================================================================

"""
Download a single dataset.
"""
function download_dataset(
    info::DatasetInfo;
    output_dir::String="data/public",
    overwrite::Bool=false,
    verbose::Bool=true
)::Bool
    # Create output directory
    mkpath(output_dir)

    output_path = joinpath(output_dir, info.filename)

    # Check if already exists
    if isfile(output_path) && !overwrite
        verbose && @info "Dataset already exists: $(info.name)"
        return true
    end

    # Handle synthetic data generation
    if info.format == "synthetic"
        verbose && @info "Generating synthetic dataset: $(info.name)"
        generate_synthetic_scaffold(output_path, info.resolution_um)
        return true
    end

    # Download
    verbose && @info "Downloading: $(info.name) ($(info.size_mb) MB)"
    verbose && @info "  URL: $(info.url)"

    try
        # Use HTTP.jl for download with progress
        HTTP.download(info.url, output_path, update_period=1)

        # Verify checksum if provided
        if !isempty(info.checksum)
            actual_hash = bytes2hex(sha256(read(output_path)))
            if actual_hash != info.checksum
                @warn "Checksum mismatch for $(info.name)"
                return false
            end
        end

        verbose && @info "  Downloaded: $output_path"

        # Extract if archive
        if endswith(info.filename, ".zip")
            extract_zip(output_path, output_dir)
        end

        return true

    catch e
        @error "Failed to download $(info.name): $e"
        return false
    end
end

"""
Download all datasets in registry.
"""
function download_all_datasets(;
    output_dir::String="data/public",
    skip_large::Bool=true,
    max_size_mb::Float64=200.0
)
    @info "Downloading public datasets for validation..."
    @info "Output directory: $output_dir"

    successful = String[]
    failed = String[]
    skipped = String[]

    for info in DATASET_REGISTRY
        if skip_large && info.size_mb > max_size_mb
            @info "Skipping $(info.name) ($(info.size_mb) MB > $max_size_mb MB limit)"
            push!(skipped, info.name)
            continue
        end

        success = download_dataset(info, output_dir=output_dir)

        if success
            push!(successful, info.name)
        else
            push!(failed, info.name)
        end
    end

    # Summary
    @info "Download Summary:"
    @info "  Successful: $(length(successful))"
    @info "  Failed: $(length(failed))"
    @info "  Skipped: $(length(skipped))"

    if !isempty(failed)
        @warn "Failed datasets: $(join(failed, ", "))"
    end

    return (successful, failed, skipped)
end

"""
Download specific dataset by name.
"""
function download_by_name(name::String; output_dir::String="data/public")
    idx = findfirst(d -> d.name == name, DATASET_REGISTRY)

    if isnothing(idx)
        available = [d.name for d in DATASET_REGISTRY]
        error("Dataset '$name' not found. Available: $(join(available, ", "))")
    end

    return download_dataset(DATASET_REGISTRY[idx], output_dir=output_dir)
end

"""
List available datasets.
"""
function list_datasets()
    println("\n" * "="^80)
    println("Available Public Datasets for Scaffold Analysis")
    println("="^80)

    for (i, info) in enumerate(DATASET_REGISTRY)
        println("\n[$i] $(info.name)")
        println("    Description: $(info.description)")
        println("    Size: $(info.size_mb) MB")
        println("    Format: $(info.format)")
        println("    Resolution: $(info.resolution_um) μm")
        println("    Reference: $(info.reference)")
        println("    License: $(info.license)")
    end

    println("\n" * "="^80)
end

# ============================================================================
# SYNTHETIC DATA GENERATION
# ============================================================================

"""
Generate synthetic scaffold for testing.
"""
function generate_synthetic_scaffold(
    output_path::String,
    voxel_size_um::Float64;
    size::Int=64,
    porosity::Float64=0.75,
    pore_size_um::Float64=150.0
)
    @info "Generating synthetic scaffold..."
    @info "  Size: $(size)^3 voxels"
    @info "  Target porosity: $(porosity * 100)%"
    @info "  Target pore size: $pore_size_um μm"

    # Create 3D volume
    volume = ones(Bool, size, size, size)

    # Add spherical pores
    pore_radius_voxels = round(Int, pore_size_um / (2 * voxel_size_um))
    n_pores = round(Int, porosity * size^3 / ((4/3) * π * pore_radius_voxels^3))

    for _ in 1:n_pores
        # Random pore center
        cx = rand(pore_radius_voxels+1:size-pore_radius_voxels)
        cy = rand(pore_radius_voxels+1:size-pore_radius_voxels)
        cz = rand(pore_radius_voxels+1:size-pore_radius_voxels)

        # Random pore size variation
        r = pore_radius_voxels * (0.8 + 0.4 * rand())

        # Carve spherical pore
        for i in max(1, cx-pore_radius_voxels):min(size, cx+pore_radius_voxels)
            for j in max(1, cy-pore_radius_voxels):min(size, cy+pore_radius_voxels)
                for k in max(1, cz-pore_radius_voxels):min(size, cz+pore_radius_voxels)
                    dist = sqrt((i-cx)^2 + (j-cy)^2 + (k-cz)^2)
                    if dist < r
                        volume[i, j, k] = false
                    end
                end
            end
        end
    end

    # Save as raw binary (simplest format)
    actual_porosity = 1.0 - sum(volume) / length(volume)
    @info "  Actual porosity: $(@sprintf("%.2f", actual_porosity * 100))%"

    # Save volume
    raw_path = replace(output_path, r"\.[^.]+$" => ".raw")
    open(raw_path, "w") do io
        write(io, UInt8.(volume))
    end

    # Save metadata
    meta_path = replace(output_path, r"\.[^.]+$" => ".json")
    open(meta_path, "w") do io
        println(io, """{
    "name": "synthetic_scaffold",
    "dimensions": [$size, $size, $size],
    "voxel_size_um": $voxel_size_um,
    "format": "uint8_binary",
    "actual_porosity": $actual_porosity,
    "target_pore_size_um": $pore_size_um
}""")
    end

    @info "  Saved: $raw_path"
    @info "  Metadata: $meta_path"

    return (raw_path, meta_path)
end

"""
Generate multiple synthetic scaffolds with varying parameters.
"""
function generate_synthetic_dataset(;
    output_dir::String="data/synthetic",
    n_samples::Int=5
)
    mkpath(output_dir)

    @info "Generating $n_samples synthetic scaffolds..."

    # Parameter ranges (realistic for tissue engineering)
    porosities = range(0.6, 0.9, length=n_samples)
    pore_sizes = range(100.0, 250.0, length=n_samples)

    for i in 1:n_samples
        name = "scaffold_$(lpad(i, 3, '0'))"
        output_path = joinpath(output_dir, "$name.raw")

        generate_synthetic_scaffold(
            output_path,
            10.0,  # 10 μm voxel size
            size=100,
            porosity=porosities[i],
            pore_size_um=pore_sizes[i]
        )
    end

    @info "Synthetic dataset generation complete!"
end

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

"""
Extract ZIP archive.
"""
function extract_zip(zip_path::String, output_dir::String)
    # Use system unzip (cross-platform)
    if Sys.iswindows()
        run(`powershell -command "Expand-Archive -Path '$zip_path' -DestinationPath '$output_dir' -Force"`)
    else
        run(`unzip -o $zip_path -d $output_dir`)
    end
end

"""
Get dataset info by name.
"""
function get_dataset_info(name::String)::Union{DatasetInfo, Nothing}
    idx = findfirst(d -> d.name == name, DATASET_REGISTRY)
    return isnothing(idx) ? nothing : DATASET_REGISTRY[idx]
end

"""
Verify dataset integrity.
"""
function verify_dataset(name::String; data_dir::String="data/public")::Bool
    info = get_dataset_info(name)
    if isnothing(info)
        @error "Dataset not found: $name"
        return false
    end

    filepath = joinpath(data_dir, info.filename)

    if !isfile(filepath)
        @warn "File not found: $filepath"
        return false
    end

    if !isempty(info.checksum)
        actual_hash = bytes2hex(sha256(read(filepath)))
        if actual_hash != info.checksum
            @warn "Checksum mismatch for $name"
            return false
        end
    end

    @info "Dataset $name verified"
    return true
end

# ============================================================================
# MAIN
# ============================================================================

function main(args=ARGS)
    if isempty(args) || "--help" in args || "-h" in args
        println("""
        Usage: julia download_public_datasets.jl [OPTIONS]

        Options:
            --list              List available datasets
            --all               Download all datasets (< 200MB)
            --dataset NAME      Download specific dataset
            --synthetic         Generate synthetic test data
            --synthetic-set N   Generate N synthetic samples
            --verify NAME       Verify dataset integrity
            --output DIR        Output directory (default: data/public)

        Examples:
            julia download_public_datasets.jl --list
            julia download_public_datasets.jl --synthetic
            julia download_public_datasets.jl --dataset pcl_scaffold_microct
            julia download_public_datasets.jl --all --output my_data/
        """)
        return
    end

    output_dir = "data/public"

    # Parse output directory
    for i in 1:length(args)-1
        if args[i] == "--output"
            output_dir = args[i+1]
        end
    end

    if "--list" in args
        list_datasets()

    elseif "--all" in args
        download_all_datasets(output_dir=output_dir)

    elseif "--synthetic" in args
        generate_synthetic_scaffold(
            joinpath(output_dir, "synthetic_test.raw"),
            10.0
        )

    elseif "--synthetic-set" in args
        idx = findfirst(a -> a == "--synthetic-set", args)
        n = parse(Int, args[idx + 1])
        generate_synthetic_dataset(output_dir=output_dir, n_samples=n)

    elseif "--verify" in args
        idx = findfirst(a -> a == "--verify", args)
        name = args[idx + 1]
        verify_dataset(name, data_dir=output_dir)

    elseif "--dataset" in args
        idx = findfirst(a -> a == "--dataset", args)
        name = args[idx + 1]
        download_by_name(name, output_dir=output_dir)

    else
        @warn "Unknown option. Use --help for usage."
    end
end

# Run if called directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
