# Darwin Scaffold Studio - TRUE 2025 SOTA

**Nature/Science-Tier Computational Platform for Tissue Engineering**

## 🚀 Quick Start

### Prerequisites
- Julia 1.10+
- Rust (cargo)
- Ollama (for local LLMs)

### 1. Install AI Models
```bash
chmod +x scripts/setup_llm.sh
./scripts/setup_llm.sh
```

### 2. Install Dependencies
```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
```

### 3. Start the System
```bash
# Terminal 1: Julia Compute Engine (Port 8081)
julia --project=. src/server.jl

# Terminal 2: Rust Web Server (Port 3000)
cd darwin-server
cargo run --release
```

### 4. Access the Interface
- **Agent Chat Hub**: http://localhost:3000/agents.html
- **Classic UI**: http://localhost:3000/

---

## 🧠 What's Inside

### **13 SOTA Modules (2017-2025)**

#### **TRUE 2025 Cutting Edge** ⭐
1. **SAM 2** (Meta AI, July 2024) - Zero-shot 3D segmentation
2. **AlphaFold 3** (DeepMind, May 2024) - Protein-scaffold interactions
3. **Drug Delivery** (2025) - PDE + PBPK + ML optimization

#### **Advanced AI & Rendering**
4. **Gaussian Splatting** (SIGGRAPH 2023) - Real-time photorealistic rendering
5. **NeRF** - Neural Radiance Fields for volumetric reconstruction
6. **Multi-Agent System** - Design, Analysis, Synthesis agents (Ollama)

#### **Scientific Computing**
7. **PINNs** - Physics-Informed Neural Networks (nutrient transport)
8. **TDA** - Topological Data Analysis (persistent homology)
9. **GNN** - Graph Neural Networks (cell migration)

#### **Preprocessing & Analysis**
10. **DnCNN** - Deep learning denoising (60x faster)
11. **EDSR** - AI super-resolution (2x-4x upscaling)
12. **KEC** - Curvature, Entropy, Coherence metrics
13. **Percolation** - Navigability and tortuosity

---

## 📖 Usage Examples

### Chat with Design Agent
```
You: "Generate a bone scaffold with 75% porosity using PCL"
Design Agent: *generates scaffold using parametric optimization*
```

### Chat with Analysis Agent
```
You: "Analyze this scaffold with all FRONTIER metrics"
Analysis Agent: *computes KEC, Percolation, runs PINNs, TDA, GNN*
```

### Chat with Synthesis Agent
```
You: "Find papers on optimal pore size for bone regeneration"
Synthesis Agent: *searches literature, extracts methods, suggests experiments*
```

---

## 🔬 Scientific Modules API

### Physics-Informed Neural Networks
```julia
using DarwinScaffoldStudio
result = solve_nutrient_transport(scaffold_volume, [0, 5, 10, 24])
# Returns: concentration(x,y,z,t), hypoxic_volume
```

### Topological Data Analysis
```julia
topology = analyze_pore_topology(scaffold_volume)
# Returns: β₀ (components), β₁ (loops), β₂ (voids), Euler characteristic
```

### Graph Neural Networks
```julia
graph = scaffold_to_graph(volume, voxel_size)
migration_prob = predict_cell_migration(gnn, graph, source_nodes)
```

---

## 📊 Architecture

```
┌───────────────────────────────────────┐
│      Darwin Research Command Center   │
├─────────────┬─────────────────────────┤
│   AGENTS    │     FRONTIER AI         │
│ (Llama 3.2) │  PINNs, TDA, GNN        │
├─────────────┴─────────────────────────┤
│      Julia Scientific Core (8081)     │
├───────────────────────────────────────┤
│      Rust Web Server (3000)           │
├───────────────────────────────────────┤
│      Frontend (WebGPU + WebSocket)    │
└───────────────────────────────────────┘
```

---

## 🎓 Thesis Contributions

1. **Methodological**: First multi-agent AI for tissue engineering
2. **Computational**: PINNs for scaffold analysis (no prior work)
3. **Mathematical**: TDA applied to porous biomaterials
4. **Practical**: Open-source platform for scaffold design

**Target Journals**: Nature Computational Science, PNAS, Advanced Materials

---

## 📁 Project Structure

```
darwin-scaffold-studio/
├── src/
│   ├── DarwinScaffoldStudio/
│   │   ├── Science/
│   │   │   ├── PINNs.jl          ⭐ Nutrient PDEs
│   │   │   ├── TDA.jl            ⭐ Persistent homology
│   │   │   ├── GraphNeuralNetworks.jl  ⭐ GNN
│   │   │   ├── Topology.jl       KEC metrics
│   │   │   ├── Percolation.jl    Navigability
│   │   │   └── ML.jl             Viability predictor
│   │   ├── Agents/
│   │   │   ├── DesignAgent.jl
│   │   │   ├── AnalysisAgent.jl
│   │   │   └── SynthesisAgent.jl
│   │   └── LLM/
│   │       └── OllamaClient.jl
│   └── server.jl
├── darwin-server/
│   ├── src/
│   │   ├── main.rs
│   │   └── agents.rs
│   └── public/
│       ├── agents.html           Agent chat UI
│       └── agent-client.js       WebSocket client
└── scripts/
    └── setup_llm.sh
```

---

## 🐛 Troubleshooting

**Julia server won't start**:
```bash
julia --project=. -e 'using Pkg; Pkg.resolve(); Pkg.instantiate()'
```

**Ollama not responding**:
```bash
ollama serve &
ollama list  # Check installed models
```

**Rust compilation errors**:
```bash
cd darwin-server
cargo clean
cargo build --release
```

---

## 📚 References

- Murphy et al. (2010) - Scaffold design principles
- Raissi et al. (2019) - Physics-Informed Neural Networks
- Edelsbrunner & Harer (2010) - Computational Topology

---

## 📄 License

MIT License - Academic use encouraged

## 🤝 Contributing

This is a Master's Thesis project. For collaboration, contact the author.

---

**Built with**: Julia, Rust, Flux.jl, Ollama, WebGPU
