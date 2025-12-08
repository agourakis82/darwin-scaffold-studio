#!/usr/bin/env julia
"""
Test Pipeline - Run full analysis on real bone micro-CT data

Usage: julia --project=. scripts/test_pipeline.jl
"""

println("="^60)
println("DARWIN SCAFFOLD STUDIO - Pipeline Test")
println("="^60)

using NIfTI

# Get project root and include modules
const PROJECT_ROOT = dirname(dirname(@__FILE__))

include(joinpath(PROJECT_ROOT, "src/DarwinScaffoldStudio/Core/Types.jl"))
include(joinpath(PROJECT_ROOT, "src/DarwinScaffoldStudio/Core/Utils.jl"))
include(joinpath(PROJECT_ROOT, "src/DarwinScaffoldStudio/Core/Config.jl"))
include(joinpath(PROJECT_ROOT, "src/DarwinScaffoldStudio/MicroCT/Metrics.jl"))

using .Types
using .Utils
using .Metrics

println("\n1. Loading real bone micro-CT data...")
nii = niread(joinpath(PROJECT_ROOT, "data/public/bone_sample_001.nii"))
raw_data = Float64.(nii.raw)
voxel_size_um = Float64(nii.header.pixdim[2] * 1000)  # mm to μm
println("   Loaded: ", size(raw_data), " voxels")
println("   Voxel size: ", round(voxel_size_um, digits=2), " μm")

println("\n2. Binarizing (threshold at 50% of max)...")
threshold = 0.5 * maximum(raw_data)
binary = raw_data .> threshold
println("   Solid voxels: ", sum(binary), " / ", length(binary))

println("\n3. Computing scaffold metrics...")
metrics = compute_metrics(binary, voxel_size_um)

println("\n", "="^60)
println("RESULTS - Trabecular Bone Sample")
println("="^60)
println("   Porosity:           ", round(metrics.porosity * 100, digits=2), "%")
println("   Mean pore size:     ", round(metrics.mean_pore_size_um, digits=1), " μm")
println("   Interconnectivity:  ", round(metrics.interconnectivity * 100, digits=2), "%")
println("   Tortuosity:         ", round(metrics.tortuosity, digits=3))
println("   Specific surface:   ", round(metrics.specific_surface_area, digits=2), " mm⁻¹")
println("   Elastic modulus:    ", round(metrics.elastic_modulus, digits=1), " MPa")
println("   Yield strength:     ", round(metrics.yield_strength, digits=2), " MPa")
println("   Permeability:       ", round(metrics.permeability * 1e12, digits=4), " ×10⁻¹² m²")

println("\n4. Quality assessment (Murphy 2010, Karageorgiou 2005)...")
# Check against literature values
pore_ok = 100 <= metrics.mean_pore_size_um <= 200
porosity_ok = 0.5 <= metrics.porosity <= 0.95
interconnect_ok = metrics.interconnectivity >= 0.90

println("   Pore size (100-200 μm):     ", pore_ok ? "✓ OK" : "✗ Outside range")
println("   Porosity (50-95%):          ", porosity_ok ? "✓ OK" : "✗ Outside range")
println("   Interconnectivity (≥90%):   ", interconnect_ok ? "✓ OK" : "✗ Below threshold")

println("\n", "="^60)
println("Pipeline test COMPLETE!")
println("="^60)
