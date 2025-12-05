# Validation Datasets for Darwin Scaffold Studio

Darwin Scaffold Studio analisa scaffolds a partir de duas modalidades de imagem:
1. **MicroCT** - Tomografia computadorizada de alta resolução (3D volumétrico)
2. **SEM** - Microscopia eletrônica de varredura (2D/3D com células)

---

## MicroCT Datasets

### 1. Figshare microCT Bone Dataset
- **Source**: https://figshare.com/articles/dataset/microCT_scans_of_bone_and_cement-bone_microstructures/4308926/2
- **Format**: DICOM
- **Resolution**: 39 μm
- **License**: CC BY 4.0
- **Contents**: 
  - Trabecular bone regions (VOI1-VOI5)
  - Cement-augmented bone
  - Cortical bone interfaces
- **Use case**: Validação de métricas de porosidade, conectividade, espessura trabecular

### 2. Preclinical microCT Database (Nature Scientific Data)
- **Source**: https://www.nature.com/articles/sdata2018294
- **Format**: DICOM/NIfTI
- **Contents**: 140 whole body scans + organ segmentations
- **License**: CC BY 4.0
- **Use case**: Validação de segmentação automática

---

## SEM Datasets

### 3. SEM Nanoscience Dataset (Nature Scientific Data)
- **Source**: https://www.nature.com/articles/sdata2018172
- **Images**: 21,272 SEM images (1024×728 pixels)
- **Format**: JPEG
- **Size**: ~11 GB total
- **Categories**: 10 classes including:
  - Porous sponge (relevante para scaffolds)
  - Biological structures
  - Fibres (relevante para electrospinning)
  - Particles
- **License**: CC BY 4.0
- **Use case**: Treinamento/validação de classificação de imagens SEM

### 4. Nanofiber SEM Dataset (Figshare)
- **Source**: https://figshare.com/articles/dataset/Nanofiber_SEM_Dataset/28376219
- **Contents**: Imagens SEM de nanofibras
- **Use case**: Validação de análise de scaffolds eletrofiados

### 5. PoreD2 Training Dataset
- **Source**: https://github.com/ilaydakaraca/PoreD2
- **Contents**: SEM images de scaffolds PolyHIPE com anotações de poros
- **Use case**: Validação de medição de tamanho de poros em SEM

---

## Synthetic Test Data (Ground Truth)

### 6. TPMS Synthetic Scaffolds
Scaffolds gerados matematicamente com propriedades conhecidas:

| Estrutura | Porosidade | Pore Size | Fórmula |
|-----------|------------|-----------|---------|
| Gyroid | 50-90% | 100-500 μm | sin(x)cos(y) + sin(y)cos(z) + sin(z)cos(x) = t |
| Diamond | 50-90% | 100-500 μm | cos(x)cos(y)cos(z) - sin(x)sin(y)sin(z) = t |
| Schwarz P | 50-90% | 100-500 μm | cos(x) + cos(y) + cos(z) = t |

**Use case**: Validação de métricas contra valores analíticos conhecidos

---

## Download Instructions

### Quick Download (Figshare microCT)
```bash
cd data/validation

# Download microCT bone dataset
curl -L -o figshare_bone_microct.zip \
  "https://figshare.com/ndownloader/files/7026608"
unzip figshare_bone_microct.zip -d bone_microct/
```

### SEM Nanoscience Dataset
```bash
# Dataset is large (~11GB), download specific categories
# Visit: https://doi.org/10.6084/m9.figshare.6374331
# Download "Porous_sponge" and "Biological" categories
```

### Generate Synthetic Data
```julia
using DarwinScaffoldStudio
include("scripts/generate_synthetic_validation.jl")

# Generate gyroid with 70% porosity, 200μm pores
scaffold = generate_gyroid(porosity=0.70, pore_size=200e-6)
save_raw("data/validation/synthetic/gyroid_70_200.raw", scaffold)
```

---

## Ground Truth Comparison

For validation, Darwin metrics are compared against:

| Tool | Type | Metrics | Reference |
|------|------|---------|-----------|
| **BoneJ** | ImageJ plugin | Tb.Th, Tb.Sp, BV/TV, Conn.D | Doube et al. 2010 |
| **CTAn** | Commercial | Full trabecular analysis | Bruker |
| **Analytical** | Mathematical | TPMS exact solutions | Kapfer et al. 2011 |
| **ImageJ** | Open source | Basic morphometry | Schneider et al. 2012 |

---

## Validation Protocol

### MicroCT Validation
1. Load sample dataset
2. Compute Darwin metrics (porosity, pore size, interconnectivity)
3. Compare against BoneJ/CTAn values
4. Report % error and correlation

### SEM Validation
1. Load SEM images with known cell types
2. Run cell identification (Vision/SEMCellIdentification.jl)
3. Compare against manual annotations
4. Report precision/recall/F1

### Synthetic Validation
1. Generate TPMS with known parameters
2. Compute metrics with Darwin
3. Compare against analytical solutions
4. Report absolute error

---

## References

1. Murphy CM, O'Brien FJ (2010) Cell Adhesion & Migration 4:377-381
2. Karageorgiou V, Kaplan D (2005) Biomaterials 26:5474-5491
3. Gibson LJ, Ashby MF (1997) Cellular Solids. Cambridge University Press
4. Doube M et al. (2010) BoneJ: Free bone image analysis. Bone 47:1076-1079
5. Kapfer SC et al. (2011) Minimal surface scaffold designs. Biomaterials 32:6875-6882
6. Mostaço-Guidolin LB et al. (2018) First annotated SEM dataset. Sci Data 5:180172
