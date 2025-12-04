# Darwin Scaffold Studio Data Directory

This directory stores experimental and synthetic data for analysis.

## Quick Start

### Generate Synthetic Test Data
```bash
chmod +x scripts/download_sample_data.sh
./scripts/download_sample_data.sh
```

This creates:
- `data/synthetic/scaffold_50x50x50.bin` - Quick testing (125KB)
- `data/synthetic/scaffold_100x100x100.bin` - Standard tests (1MB)  
- `data/synthetic/scaffold_200x200x200_hires.bin` - Performance testing (8MB)

### Load Data in Julia
```julia
using DarwinScaffoldStudio

# Option 1: Generate on-the-fly
include("src/DarwinScaffoldStudio/Core/DataIngestion.jl") 
volume, metadata = DataIngestion.generate_synthetic_scaffold(
    size_voxels=(100,100,100),
    porosity=0.75
)

# Option 2: Load from file (after running download script)
volume_loaded = Array{Bool,3}(undef, 100, 100, 100)
open("data/synthetic/scaffold_100x100x100.bin", "r") do io
    read!(io, volume_loaded)
end
```

## Directory Structure

```
data/
├── microct/          # MicroCT TIFF stacks or NIfTI files
├── sem/              # SEM microscopy images (PNG/JPG)
├── clinical/         # Clinical PBPK validation data (CSV)
└── synthetic/        # Generated synthetic scaffolds
    ├── *.bin             # Binary volume data
    └── *_metadata.json   # Scaffold parameters
```

## Required Datasets for Validation (Week 1)

### 1. MicroCT Scaffolds (`data/microct/`)
- **Source**: [NIH 3D Print Exchange](https://3dprint.nih.gov)
- **Search**: "bone scaffold" or "tissue engineering"
- **Format**: .tif stack or .stl
- **Purpose**: Validation of KEC metrics, TDA, and percolation
- **Example**: [3DPX-013569 - Bone Scaffold](https://3dprint.nih.gov/discover/3dpx-013569)

### 2. SEM Images (`data/sem/`)
- **Source**: [Materials Data Facility](https://www.materialsdatafacility.org)
- **Search**: "scaffold SEM" or "porous biomaterial"
- **Format**: .png or .jpg
- **Purpose**: Training/testing cell identification models
- **Recommended Resolution**: >1024×1024 pixels

### 3. Clinical Data (`data/clinical/`)
- **Source**: [PhysioNet](https://physionet.org)
- **Search**: "pharmacokinetics" or "drug delivery"
- **Format**: .csv
- **Purpose**: Validation of PBPK drug delivery models
- **Note**: Requires PhysioNet credentialing

## Supported File Formats

| Format | Extension | Use Case | Loading |
|--------|-----------|----------|---------|
| **TIFF Stack** | `.tif`, `.tiff` | MicroCT multi-slice | Automatic |
| **NIfTI** | `.nii`, `.nii.gz` | Medical imaging | Automatic |
| **2D Images** | `.png`, `.jpg` | SEM, microscopy | Automatic (→ pseudo-3D) |
| **Binary + JSON** | `.bin` + `.json` | Synthetic scaffolds | Manual read |

## Synthetic Data Specifications

### scaffold_50x50x50.bin
- **Dimensions**: 50×50×50 voxels (125,000 voxels)
- **Physical Size**: 0.5×0.5×0.5 mm (with 10μm voxels)
- **Porosity**: ~70%
- **Pore Size**: ~50 μm
- **Memory**: 125 KB
- **Use**: Unit tests, CI/CD, quick prototyping

### scaffold_100x100x100.bin
- **Dimensions**: 100×100×100 voxels (1M voxels)
- **Physical Size**: 1×1×1 mm
- **Porosity**: ~75%
- **Pore Size**: ~100 μm  
- **Memory**: 1 MB
- **Use**: Standard development and testing

### scaffold_200x200x200_hires.bin
- **Dimensions**: 200×200×200 voxels (8M voxels)
- **Physical Size**: 1×1×1 mm (with 5μm voxels)
- **Porosity**: ~80%
- **Pore Size**: ~75 μm
- **Memory**: 8 MB
- **Use**: Performance benchmarks, high-resolution analysis

## Examples

### Run Data Loading Demo
```bash
julia --project=. examples/load_data_demo.jl
```

### Generate Custom Synthetic Scaffold
```julia
using DarwinScaffoldStudio
include("src/DarwinScaffoldStudio/Core/DataIngestion.jl")

volume, metadata = DataIngestion.generate_synthetic_scaffold(
    size_voxels=(120, 120, 120),
    porosity=0.85,                # 85% porous
    pore_size_voxels=12,          # ~120 μm pores
    voxel_size_um=10.0            # 10 μm resolution
)

println("Generated: $(metadata["actual_porosity"]) porosity")
```

### Load Real MicroCT TIFF Stack
```julia
volume, metadata = DataIngestion.load_scaffold_data(
    "data/microct/sample_scaffold/",  # Directory of TIFFs
    voxel_size_um=15.0                # From scanner metadata
)

println("Loaded: $(metadata["dimensions"]) volume")
```

### Load NIfTI File
```julia
volume, metadata = DataIngestion.load_scaffold_data(
    "data/microct/sample.nii.gz",
    voxel_size_um=10.0
)

# NIfTI files include voxel size in header
println("Header voxel size: $(metadata["actual_voxel_size_from_header"])")
```

## Data Citation

### Synthetic Data
If using synthetic scaffolds in publications:
```bibtex
@software{darwin_synthetic_2025,
  title={DARWIN Scaffold Studio Synthetic Scaffold Generator},
  author={Agourakis, Demetrios C.},
  year={2025},
  version={1.0.0},
  url={https://github.com/agourakis82/darwin-scaffold-studio}
}
```

### Real Datasets
Always cite the original data source:
- NIH 3D Print Exchange: Include 3DPX ID
- Materials Data Facility: Include dataset DOI
- PhysioNet: Include dataset name and version

## Troubleshooting

**"No TIFF files found"**: Ensure directory contains `.tif` or `.tiff` files

**"NIfTI loading failed"**: Check if NIfTI.jl package is installed

**"Out of memory"**: Use smaller synthetic scaffolds or subsample real data

**"Porosity mismatch"**: Synthetic generation is stochastic, ~5% error is normal
