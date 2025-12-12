<p align="center">
  <h1 align="center">Darwin Scaffold Studio</h1>
  <p align="center">
    <strong>Computational Platform for Tissue Engineering Scaffold Analysis</strong>
    <br/>
    <em>Integrating Image Analysis, Topology, and Scientific Discovery</em>
  </p>
</p>

<p align="center">
  <a href="https://github.com/agourakis82/darwin-scaffold-studio/actions/workflows/ci.yml">
    <img src="https://github.com/agourakis82/darwin-scaffold-studio/actions/workflows/ci.yml/badge.svg" alt="CI Status">
  </a>
  <a href="https://github.com/agourakis82/darwin-scaffold-studio/releases/latest">
    <img src="https://img.shields.io/github/v/release/agourakis82/darwin-scaffold-studio" alt="Latest Release">
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT">
  </a>
  <a href="https://www.julia-lang.org/">
    <img src="https://img.shields.io/badge/Julia-1.10+-9558B2.svg?logo=julia" alt="Julia 1.10+">
  </a>
</p>

<p align="center">
  <a href="#scientific-discoveries">Discoveries</a> |
  <a href="#features">Features</a> |
  <a href="#installation">Installation</a> |
  <a href="#quick-start">Quick Start</a> |
  <a href="#documentation">Documentation</a> |
  <a href="#citation">Citation</a>
</p>

---

## Overview

Darwin Scaffold Studio is an open-source Julia platform for analyzing tissue engineering scaffolds from MicroCT and SEM imaging data. Beyond standard metrics computation, this platform enabled the discovery of a **universal entropic law** governing polymer degradation kinetics.

---

## Scientific Discoveries

### Entropic Causality Law

Using Darwin Scaffold Studio's analysis capabilities, we discovered a universal relationship between configurational entropy and Granger causality in PLDLA polymer degradation:

```
C = Omega^(-lambda)    where lambda = ln(2)/d
```

**Key Results:**
- **Universal exponent:** lambda = ln(2)/3 = 0.231 (for 3D systems)
- **Validation:** 84 polymers, observed lambda = 0.227, error = 1.6%
- **Polya connection:** C(Omega=100) = 0.345 matches P_return(3D) = 0.341 (1.2% error)

This connects information theory, random walk theory, and polymer physics through a single dimensionless law.

**Publications:**
- `paper/entropic_causality_manuscript_v2.md` - Nature Communications format
- `paper/softwarex_paper_v2.pdf` - Software description (SoftwareX)

See [`MANUAL.md`](MANUAL.md) for complete scientific derivation.

---

## Features

### Image Analysis
- **MicroCT/SEM loading:** RAW, TIFF, NIfTI formats
- **Preprocessing:** Denoising, normalization, artifact removal
- **Segmentation:** Otsu, adaptive thresholding, watershed

### Metrics Computation

| Metric | Method | Validation |
|--------|--------|------------|
| Porosity | Voxel counting | <1% error |
| Surface Area | Marching cubes | <1% error |
| Pore Size | Connected components | 14% APE (SEM) |
| Interconnectivity | Graph analysis | Validated |
| Tortuosity | Dijkstra paths | Validated |

### Advanced Capabilities
- **TPMS Generation:** Gyroid, Schwarz D/P, Neovius surfaces
- **Ontology Integration:** 1200+ terms from OBO Foundry
- **Topological Analysis:** Betti numbers, persistence homology
- **FAIR Export:** Schema.org compatible JSON-LD

---

## Installation

### Requirements
- Julia 1.10+
- 8GB RAM (16GB recommended)

### Quick Install

```bash
git clone https://github.com/agourakis82/darwin-scaffold-studio.git
cd darwin-scaffold-studio
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

### Docker

```bash
docker build -t darwin-scaffold-studio .
docker run -it -v $(pwd)/data:/app/user_data darwin-scaffold-studio
```

---

## Quick Start

```julia
include("src/DarwinScaffoldStudio.jl")
using .DarwinScaffoldStudio

# Load and analyze scaffold
img = load_microct("scaffold.raw", (512, 512, 512))
binary = segment_scaffold(preprocess_image(img), "otsu")
metrics = compute_metrics(binary, 10.0)  # 10 um voxel

println("Porosity: $(round(metrics.porosity * 100, digits=1))%")
println("Pore size: $(round(metrics.mean_pore_size_um, digits=1)) um")

# Export for 3D printing
vertices, faces = create_mesh_simple(binary, 10.0)
export_stl("scaffold.stl", vertices, faces)
```

---

## Documentation

| Document | Description |
|----------|-------------|
| [`MANUAL.md`](MANUAL.md) | Complete scientific and software manual |
| [`QUICKSTART.md`](QUICKSTART.md) | Getting started guide |
| [`docs/`](docs/) | Technical documentation |

### Repository Structure

```
darwin-scaffold-studio/
|-- src/                    # Julia source code
|   +-- DarwinScaffoldStudio/
|       |-- Core/           # Types, Config, Utils
|       |-- MicroCT/        # Image processing
|       |-- Science/        # Topology, ML, Analysis
|       +-- ...
|-- paper/                  # Manuscripts and figures
|-- data/                   # Sample datasets
|-- docs/                   # Documentation
|-- examples/               # Usage examples
+-- test/                   # Test suite
```

---

## Citation

```bibtex
@software{darwin_scaffold_studio,
  author = {Agourakis, Demetrios Chiuratto},
  title = {Darwin Scaffold Studio: Computational Platform for 
           Tissue Engineering Scaffold Analysis},
  year = {2025},
  doi = {10.5281/zenodo.17832882},
  url = {https://github.com/agourakis82/darwin-scaffold-studio}
}
```

For the entropic causality discovery:
```bibtex
@article{agourakis2025entropic,
  title = {Entropic Causality: A Universal Law Connecting 
           Information Theory and Polymer Degradation},
  author = {Agourakis, D. C.},
  journal = {Nature Communications},
  year = {2025},
  note = {In preparation}
}
```

---

## Contributing

See [`docs/development/CONTRIBUTING.md`](docs/development/CONTRIBUTING.md) for guidelines.

```bash
# Run tests
julia --project=. test/runtests.jl
```

---

## License

MIT License - see [LICENSE](LICENSE)

---

## Acknowledgments

- PUC-SP Biomaterials and Regenerative Medicine Program
- OBO Foundry for biomedical ontologies
- Julia community

---

<p align="center">
  <sub>Advancing tissue engineering through computational science</sub>
</p>
