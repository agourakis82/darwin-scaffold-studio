# Load Data Demo - Test DataIngestion module

using DarwinScaffoldStudio

println("="^60)
println("DARWIN Scaffold Studio - Data Loading Demo")
println("="^60)

# Import DataIngestion module
include("../src/DarwinScaffoldStudio/Core/DataIngestion.jl")
using .DataIngestion

println("\n📊 Demo 1: Generate Synthetic Scaffold")
println("-"^60)

# Generate a test scaffold
volume, metadata = generate_synthetic_scaffold(
    size_voxels=(80, 80, 80),
    porosity=0.72,
    pore_size_voxels=8,
    voxel_size_um=10.0
)

println("Generated scaffold:")
println("  Size: $(metadata["dimensions"])")
println("  Target porosity: $(metadata["target_porosity"])")
println("  Actual porosity: $(round(metadata["actual_porosity"], digits=3))")
println("  Pore size (voxels): $(metadata["pore_size_voxels"])")
println("  Voxel size (μm): $(metadata["voxel_size_um"])")

# Calculate some basic stats
solid_voxels = sum(volume)
pore_voxels = length(volume) - solid_voxels
println("\n  Solid voxels: $solid_voxels")
println("  Pore voxels: $pore_voxels")

println("\n✅ Demo 1 Complete!")

println("\n📊 Demo 2: Save and Load Synthetic Data")
println("-"^60)

# Save to file
using FileIO, JSON

filepath = "data/synthetic/demo_scaffold.bin"
mkpath("data/synthetic")

open(filepath, "w") do io
    write(io, volume)
end
println("  ✓ Saved binary volume to: $filepath")

# Save metadata
metadata_path = "data/synthetic/demo_scaffold_metadata.json"
open(metadata_path, "w") do io
    JSON.print(io, metadata, 2)
end
println("  ✓ Saved metadata to: $metadata_path")

# Load it back
volume_loaded = Array{Bool,3}(undef, size(volume)...)
open(filepath, "r") do io
    read!(io, volume_loaded)
end

# Verify integrity
if volume_loaded == volume
    println("  ✓ Data integrity verified!")
else
    println("  ✗ Data mismatch!")
end

println("\n✅ Demo 2 Complete!")

println("\n📊 Demo 3: Multiple Scaffold Sizes")
println("-"^60)

sizes = [(50,50,50), (100,100,100), (150,150,150)]
porosities = [0.70, 0.75, 0.80]

for (i, (size, target_por)) in enumerate(zip(sizes, porosities))
    println("\n  Scaffold $i:")
    vol, meta = generate_synthetic_scaffold(
        size_voxels=size,
        porosity=target_por,
        pore_size_voxels=10
    )
    
    actual_por = meta["actual_porosity"]
    error = abs(actual_por - target_por) / target_por * 100
    
    println("    Size: $(size)")
    println("    Target porosity: $(target_por)")
    println("    Actual porosity: $(round(actual_por, digits=3))")
    println("    Error: $(round(error, digits=2))%")
    println("    Memory: $(sizeof(vol) / 1024 / 1024) MB")
end

println("\n✅ Demo 3 Complete!")

println("\n" * "="^60)
println("🎉 All data loading demos completed successfully!")
println("="^60)

println("\n💡 Next steps:")
println("   • Load real MicroCT data (TIFF/NIfTI)")
println("   • Run scaffold analysis pipeline")
println("   • Generate STL exports")
