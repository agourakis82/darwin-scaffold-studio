# Darwin Scaffold Studio - Quick Start Guide

## 🚀 **Get Running in 5 Minutes**

### **Prerequisites**
- Julia 1.10+
- Rust/Cargo
- 16GB RAM minimum
- (Optional) NVIDIA GPU for acceleration

---

## **Step 1: Clone & Setup (2 min)**

```bash
cd ~/workspace/darwin-scaffold-studio

# Install Julia dependencies
julia --project=. -e 'using Pkg; Pkg.instantiate()'

# Build Rust server
cd darwin-server
cargo build --release
cd ..

# Setup LLMs (optional, for agents)
chmod +x scripts/setup_llm.sh
./scripts/setup_llm.sh
```

---

## **Step 2: Run First Analysis (3 min)**

```julia
# Start Julia REPL
julia --project=.

# Load Darwin
using DarwinScaffoldStudio

# Create a test scaffold
scaffold = create_test_scaffold(100, 100, 100, porosity=0.7)

# Run complete analysis pipeline
results = analyze_complete(scaffold)

# View results
println("Porosity: $(results["porosity"])%")
println("Betti numbers: β₀=$(results["topology"]["num_components"]), β₁=$(results["topology"]["num_loops"])")
println("Percolation: $(results["percolation"]["tortuosity"])")
```

**Expected output:**
```
Porosity: 70.2%
Betti numbers: β₀=142, β₁=87, β₂=34
Percolation: 1.42
✓ Analysis complete in 2.3 seconds
```

---

## **Step 3: Visualize (Optional)**

```bash
# Start Rust web server
cd darwin-server
cargo run --release

# Open browser
# Navigate to: http://localhost:3000/agents.html
```

---

## **Common Workflows**

### **Workflow 1: Analyze Real MicroCT**
```julia
using DarwinScaffoldStudio

# Load your data
scaffold = load_image("path/to/microct.tif")

# Preprocess
denoised = denoise_microct(scaffold, method="dncnn")
clean = remove_artifacts(denoised, artifact_type="ring")

# Analyze
metrics = compute_kec_metrics(clean, voxel_size=20.0)  # 20 µm voxels
topology = analyze_pore_topology(clean)
perc = compute_percolation_metrics(clean, 20.0)

# Drug delivery prediction
drug_release = model_drug_release(clean, 50.0, [0, 6, 12, 24, 48])

# Save results
save_results("output/analysis_results.json", 
    Dict("metrics" => metrics, 
         "topology" => topology,
         "drug_release" => drug_release))
```

### **Workflow 2: Design Optimal Scaffold**
```julia
# Use biomimetic patterns
pores = fibonacci_pore_distribution((200, 200, 200), 300)
golden_params = golden_ratio_optimization(0.75)

# Generate vascular network
vessels = generate_murray_tree(
    zeros(200, 200, 200), 
    (100, 100, 1),
    target_depth=6
)

# Optimize with quantum
quantum_result = quantum_scaffold_optimization(0.75, 60.0)

# Combine into final design
scaffold_design = create_scaffold_from_specs(
    pores, vessels, quantum_result
)
```

### **Workflow 3: Multi-Organ Simulation**
```julia
# Create organ system
system = create_multi_organ_system("bone")

# Simulate drug distribution
drug_conc = simulate_organ_crosstalk(
    system, 
    dose=100.0,  # mg
    times=[0, 6, 12, 24, 48]
)

# Check safety
response = predict_systemic_response(drug_conc)
println(response["recommendation"])
```

### **Workflow 4: Discover Physical Law**
```julia
# You have experimental data
X = load_experimental_data("porosity_strength.csv")  # [porosity, pore_size, ...]
y = X[:, end]  # strength

# Discover equation
law = discover_physical_law(X[:, 1:end-1], y, 
    ["porosity", "pore_size", "strut_thickness"],
    generations=100
)

println("Discovered: $(law["equation"])")
println("R² = $(law["r_squared"])")
# Output: "strength = 85.3 * porosity - 12.1 * (pore_size)^2 + ..."
```

---

## **Troubleshooting**

### **Issue: Package errors**
```julia
# Update all packages
julia --project=. -e 'using Pkg; Pkg.update(); Pkg.resolve()'
```

### **Issue: Ollama not found**
```bash
# Install Ollama manually
curl -fsSL https://ollama.com/install.sh | sh

# Pull models
ollama pull llama3.2-vision
ollama pull qwen2.5-coder:7b
```

### **Issue: Rust build fails**
```bash
# Update Rust
rustup update

# Clean and rebuild
cd darwin-server
cargo clean
cargo build --release
```

### **Issue: Out of memory**
```julia
# Reduce problem size
scaffold = create_test_scaffold(50, 50, 50)  # Instead of 100³

# Or use subsampling
scaffold_downsampled = scaffold[1:2:end, 1:2:end, 1:2:end]
```

---

## **Next Steps**

1. **Read Documentation**: `README.md`
2. **See Examples**: `examples/` directory
3. **Run Tests**: `julia --project=. test/complete_validation.jl`
4. **Check Roadmap**: `30_day_roadmap.md`
5. **Validate Against Literature**: `q1_literature_validation.md`

---

## **Getting Help**

- **Documentation**: `docs/` folder
- **Issues**: GitHub Issues
- **Community**: Discord/Slack (if you create one)

---

## **Citation**

If you use Darwin in your research, please cite:

```bibtex
@software{darwin_scaffold_studio_2025,
  title={Darwin Scaffold Studio: Multi-Modal AI Platform for Tissue Engineering},
  author={Your Name},
  year={2025},
  url={https://github.com/yourusername/darwin-scaffold-studio}
}
```

---

**You're all set! Start analyzing scaffolds in 5 minutes.** 🚀
