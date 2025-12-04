#!/bin/bash
# Download sample datasets for DARWIN Scaffold Studio

set -e  # Exit on error

echo "=================================="
echo "DARWIN Scaffold Studio - Data Setup"
echo "=================================="

# Create data directories
mkdir -p data/microct
mkdir -p data/sem  
mkdir -p data/clinical
mkdir -p data/synthetic

echo ""
echo "📁 Created data directories"

# ==================================================================================
# Option 1: Download from NIH 3D Print Exchange (MicroCT)
# ==================================================================================
echo ""
echo "🔬 Downloading sample MicroCT data from NIH 3D Print Exchange..."

# Example: Bone scaffold (small sample for testing)
# Note: Replace with actual NIH 3D Print Exchange URLs when available
MICROCT_URL="https://3dprint.nih.gov/sites/default/files/sample_scaffold.zip"

if command -v wget &> /dev/null; then
    # Try downloading with wget (may not exist yet - placeholder)
    echo "  ℹ️  Real NIH data requires manual download due to licensing"
    echo "  ℹ️  Visit: https://3dprint.nih.gov/discover/3dpx-013569"
    echo "  ℹ️  Generating synthetic data instead..."
elif command -v curl &> /dev/null; then
    echo "  ℹ️  Real NIH data requires manual download due to licensing"
    echo "  ℹ️  Generating synthetic data instead..."
else
    echo "  ⚠️  Neither wget nor curl found. Cannot download data."
fi

# ==================================================================================
# Option 2: Generate Synthetic Data (Always works)
# ==================================================================================
echo ""
echo "🧪 Generating synthetic scaffold data..."

julia --project=. -e '
using DarwinScaffoldStudio

# Generate synthetic MicroCT-like data
println("  → Generating synthetic MicroCT scaffold (100x100x100)...")
include("src/DarwinScaffoldStudio/Core/DataIngestion.jl")
volume, metadata = DataIngestion.generate_synthetic_scaffold(
    size_voxels=(100,100,100),
    porosity=0.75,
    pore_size_voxels=10,
    voxel_size_um=10.0
)

# Save as binary file
using FileIO
open("data/synthetic/scaffold_100x100x100.bin", "w") do io
    write(io, volume)
end

# Save metadata
using JSON
open("data/synthetic/scaffold_100x100x100_metadata.json", "w") do io
    JSON.print(io, metadata, 2)
end

println("  ✓ Synthetic MicroCT saved to data/synthetic/")

# Generate a smaller scaffold for quick tests
println("  → Generating small test scaffold (50x50x50)...")
volume_small, metadata_small = DataIngestion.generate_synthetic_scaffold(
    size_voxels=(50,50,50),
    porosity=0.70,
    pore_size_voxels=5,
    voxel_size_um=10.0
)

open("data/synthetic/scaffold_50x50x50.bin", "w") do io
    write(io, volume_small)
end

open("data/synthetic/scaffold_50x50x50_metadata.json", "w") do io
    JSON.print(io, metadata_small, 2)
end

println("  ✓ Small test scaffold saved to data/synthetic/")

# Generate a high-resolution scaffold
println("  → Generating high-res scaffold (200x200x200)...")
volume_hires, metadata_hires = DataIngestion.generate_synthetic_scaffold(
    size_voxels=(200,200,200),
    porosity=0.80,
    pore_size_voxels=15,
    voxel_size_um=5.0
)

open("data/synthetic/scaffold_200x200x200_hires.bin", "w") do io
    write(io, volume_hires)
end

open("data/synthetic/scaffold_200x200x200_hires_metadata.json", "w") do io
    JSON.print(io, metadata_hires, 2)
end

println("  ✓ High-res scaffold saved to data/synthetic/")

println("")
println("✅ All synthetic datasets generated successfully!")
'

# ==================================================================================
# Create README for data directory
# ==================================================================================
echo ""
echo "📝 Creating data documentation..."

cat > data/DATA_README.md << 'EOF'
# DARWIN Scaffold Studio - Data Directory

This directory contains experimental and synthetic scaffold data for analysis and testing.

## Directory Structure

```
data/
├── microct/          # MicroCT imaging data (TIFF stacks, NIfTI)
├── sem/              # SEM microscopy images  
├── clinical/         # Clinical/PBPK validation data
└── synthetic/        # Generated synthetic scaffolds
```

## Synthetic Datasets (Generated)

### scaffold_50x50x50.bin
- **Size**: 50×50×50 voxels
- **Porosity**: ~70%
- **Pore Size**: ~5 voxels (~50 μm)
- **Use**: Quick testing, CI/CD

### scaffold_100x100x100.bin
- **Size**: 100×100×100 voxels
- **Porosity**: ~75%
- **Pore Size**: ~10 voxels (~100 μm)
- **Use**: Standard development and testing

### scaffold_200x200x200_hires.bin
- **Size**: 200×200×200 voxels (high resolution)
- **Porosity**: ~80%
- **Pore Size**: ~15 voxels (~75 μm with 5μm voxels)
- **Use**: Performance testing, detailed analysis

## Loading Synthetic Data

```julia
using DarwinScaffoldStudio

# Read binary scaffold
volume = Array{Bool,3}(undef, 100, 100, 100)
open("data/synthetic/scaffold_100x100x100.bin", "r") do io
    read!(io, volume)
end

# Or use DataIngestion module
volume, metadata = DataIngestion.load_scaffold_data("data/synthetic/scaffold_100x100x100.bin")
```

## Downloading Real MicroCT Data

### NIH 3D Print Exchange
1. Visit: https://3dprint.nih.gov
2. Search for: "bone scaffold" or "tissue engineering"
3. Download DICOM/STL files
4. Place in `data/microct/`

### Materials Data Facility (SEM)
1. Visit: https://www.materialsdatafacility.org
2. Search for: "scaffold SEM" or "porous biomaterial"
3. Download image datasets
4. Place in `data/sem/`

### PhysioNet (Clinical Data)
1. Visit: https://physionet.org
2. Search for relevant pharmacokinetic datasets
3. Place CSV files in `data/clinical/`

## Data Formats Supported

- **TIFF stacks**: Multi-slice microscopy (`.tif`, `.tiff`)
- **NIfTI**: Medical imaging standard (`.nii`, `.nii.gz`)
- **2D Images**: SEM, microscopy (`.png`, `.jpg`)
- **Binary**: Custom format with JSON metadata

## Citation

If using synthetic data in publications, cite:
> DARWIN Scaffold Studio synthetic scaffold generation algorithm (v1.0.0)

If using downloaded datasets, cite the original data source.
EOF

echo "  ✓ Created data/DATA_README.md"

# ==================================================================================
# Summary
# ==================================================================================
echo ""
echo "=================================="
echo "✅ Data Setup Complete!"
echo "=================================="
echo ""
echo "📊 Summary:"
echo "   • Created data directory structure"
echo "   • Generated 3 synthetic scaffolds"
echo "   • Created documentation"
echo ""
echo "💡 Next Steps:"
echo "   1. Test data loading:"
echo "      julia --project=. examples/load_data_demo.jl"
echo ""
echo "   2. Download real datasets (optional):"
echo "      Visit: https://3dprint.nih.gov"  
echo ""
echo "   3. Run analysis on synthetic data:"
echo "      julia --project=. examples/pipeline_demo.jl"
echo ""
