# Analyze Scaffold

Analyze a MicroCT or SEM scaffold image using Darwin Scaffold Studio.

## Instructions

Run scaffold analysis on the specified file: $ARGUMENTS

1. First, check if the file exists
2. Load the image using Julia's DarwinScaffoldStudio
3. Compute metrics (porosity, pore size, interconnectivity, tortuosity)
4. Compute KEC metrics (curvature, entropy, coherence)
5. Detect any design problems based on Q1 literature
6. Provide recommendations

Use this Julia command structure:
```julia
cd("/home/agourakis82/workspace/darwin-scaffold-studio")
using Pkg; Pkg.activate(".")
include("src/DarwinScaffoldStudio.jl")
using .DarwinScaffoldStudio

# Load and analyze
img = load_image("$ARGUMENTS")
processed = preprocess_image(img)
binary = segment_scaffold(processed)
metrics = compute_metrics(binary, 10.0)  # 10um voxel size
kec = compute_kec_metrics(binary, 10.0)

# Report results
println("Porosity: $(metrics.porosity)")
println("Pore Size: $(metrics.mean_pore_size_um) um")
println("Interconnectivity: $(metrics.interconnectivity)")
```

Present results in a clear table format with literature comparisons (Murphy 2010, Karageorgiou 2005).
