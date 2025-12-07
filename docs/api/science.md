# Science Modules API Reference

Darwin Scaffold Studio v0.5.0 includes three complete science modules for advanced scaffold analysis.

## PINNs (Physics-Informed Neural Networks)

**Module**: `DarwinScaffoldStudio.Science.PINNs`

Solves reaction-diffusion PDEs for nutrient/oxygen transport in scaffolds using neural networks with physics constraints.

### Types

```julia
struct NutrientPINN
    network::Chain      # Flux neural network (4 -> hidden -> 1)
    D::Float64          # Diffusion coefficient (m^2/s)
    k::Float64          # Consumption rate (1/s)
end
```

### Functions

#### `NutrientPINN(; hidden_dims, D, k)`
Create a PINN for nutrient transport.

```julia
pinn = NutrientPINN(
    hidden_dims = [64, 64, 64],  # 3 hidden layers
    D = 2.5e-9,                   # Oxygen diffusion in water
    k = 0.01                      # Cell consumption rate
)
```

#### `train_pinn!(pinn, scaffold_volume; epochs, lr, n_collocation, verbose)`
Train PINN on scaffold geometry.

```julia
scaffold = rand(Bool, 32, 32, 32)  # 3D binary scaffold
loss_history = train_pinn!(pinn, scaffold; 
    epochs = 1000,
    lr = 0.001,
    n_collocation = 5000,
    verbose = true
)
```

**Returns**: Vector of loss values per epoch.

#### `solve_nutrient_transport(scaffold_volume, time_points; kwargs...)`
Complete nutrient transport solution.

```julia
result = solve_nutrient_transport(scaffold, [0.0, 0.1, 0.5, 1.0];
    epochs = 1000,
    hidden_dims = [64, 64, 64],
    D = 2.5e-9,
    k = 0.01
)
```

**Returns Dict**:
- `concentration`: 4D array (nx, ny, nz, nt)
- `time_points`: Input time values
- `min_oxygen`: Minimum concentration (hypoxia indicator)
- `hypoxic_volume`: Fraction with C < 0.2
- `loss_history`: Training curve

#### `physics_loss_fast(pinn, points)`
Compute physics-informed loss using finite differences (Zygote-compatible).

**PDE**: `dC/dt = D * laplacian(C) - k * C`

---

## TDA (Topological Data Analysis)

**Module**: `DarwinScaffoldStudio.Science.TDA`

Uses persistent homology to characterize scaffold pore networks.

### Types

```julia
struct PersistenceSummary
    dimension::Int
    n_features::Int
    n_essential::Int        # Features persisting to infinity
    births::Vector{Float64}
    deaths::Vector{Float64}
    persistence::Vector{Float64}
    total_persistence::Float64
    mean_persistence::Float64
    max_persistence::Float64
    entropy::Float64        # Persistence entropy
end
```

### Functions

#### `compute_persistent_homology(scaffold_volume; max_dim, n_samples, threshold)`
Compute persistence diagrams using Ripserer.

```julia
result = compute_persistent_homology(scaffold;
    max_dim = 2,        # H0, H1, H2
    n_samples = 5000,   # Subsample for performance
    threshold = 0.0
)
```

**Returns Dict**:
- `diagrams`: Dict of "H0", "H1", "H2" -> [(birth, death), ...]
- `betti_numbers`: [B0, B1, B2]
- `summaries`: Dict of PersistenceSummary per dimension
- `euler_characteristic`: chi = B0 - B1 + B2

#### `analyze_pore_topology(scaffold_volume; kwargs...)`
High-level topological analysis with interpretable metrics.

```julia
result = analyze_pore_topology(scaffold; n_samples = 3000)
```

**Returns Dict**:
- `num_components`: B0 (connected pore clusters)
- `num_loops`: B1 (tunnel/channel count)
- `num_voids`: B2 (enclosed cavity count)
- `interconnectivity_score`: Normalized B1 metric [0, 1]
- `mean_loop_persistence`: Average robustness of tunnels
- `euler_characteristic`: Topological invariant
- `persistence_entropy_H1`: Complexity of tunnel network

#### `betti_numbers(scaffold_volume; kwargs...)`
Compute Betti numbers directly.

```julia
beta = betti_numbers(scaffold)
# beta[1] = B0 (components)
# beta[2] = B1 (loops/tunnels)
# beta[3] = B2 (voids)
```

#### `persistence_entropy(persistence_values)`
Shannon entropy of persistence diagram.

- High entropy = complex structure with many similar features
- Low entropy = simple structure with few dominant features

#### `bottleneck_distance(diagram1, diagram2)`
Measure similarity between two persistence diagrams.

#### `compare_scaffolds(scaffold1, scaffold2; kwargs...)`
Compare topological features of two scaffolds.

```julia
comparison = compare_scaffolds(scaffold_a, scaffold_b)
# comparison["similarity_score"] in [0, 1]
```

#### `plot_persistence_diagram(diagrams; dim)`
ASCII visualization of persistence diagram.

#### `plot_betti_barcode(diagrams; dim, max_bars)`
ASCII barcode plot showing feature lifetimes.

---

## GNN (Graph Neural Networks)

**Module**: `DarwinScaffoldStudio.Science.GraphNeuralNetworks`

Represents scaffolds as graphs for property prediction.

### Types

```julia
struct ScaffoldGraph
    graph::SimpleGraph{Int}
    node_features::Matrix{Float32}   # (n_features x n_nodes)
    edge_features::Matrix{Float32}   # (n_features x n_edges)
    edge_index::Matrix{Int}          # (2 x n_edges)
    node_labels::Vector{Float32}
    pore_centers::Vector{Tuple{Int,Int,Int}}
    adjacency::SparseMatrixCSC{Float32,Int}
    degree::Vector{Float32}
end

struct ScaffoldGNN
    node_encoder::Chain
    gnn_layers::Vector{Any}
    readout::Symbol         # :mean, :max, :sum
    predictor::Chain
    layer_type::Symbol      # :gcn, :sage, :gat
end
```

### Graph Layers

#### `GCNConv(in_dim, out_dim; sigma)`
Graph Convolutional Network layer (Kipf & Welling 2017).

#### `GraphSAGEConv(in_dim, out_dim; sigma, aggregator)`
GraphSAGE layer with neighbor sampling.

#### `GATConv(in_dim, out_dim; n_heads, sigma, negative_slope)`
Graph Attention Network layer.

### Functions

#### `scaffold_to_graph(scaffold_volume; voxel_size, grid_step, connect_radius)`
Convert 3D scaffold to graph representation.

```julia
graph = scaffold_to_graph(scaffold;
    voxel_size = 1.0,
    grid_step = 10,
    connect_radius = 20.0
)
```

**Node features** (8 dims):
1. Local porosity
2-4. Normalized x, y, z coordinates
5. Surface area estimate
6. Local curvature
7. Distance to boundary
8. Cluster size indicator

**Edge features** (4 dims):
1. Euclidean distance
2. Path porosity
3. Minimum throat width
4. Tortuosity

#### `create_scaffold_gnn(; kwargs...)`
Create a ScaffoldGNN model.

```julia
model = create_scaffold_gnn(
    node_dim = 8,
    hidden_dim = 64,
    output_dim = 1,
    n_layers = 3,
    layer_type = :gcn,    # :gcn, :sage, :gat
    readout = :mean,      # :mean, :max, :sum
    dropout = 0.1
)
```

#### `train_gnn!(model, graphs, targets; epochs, lr, verbose)`
Train GNN on scaffold dataset.

```julia
loss_history = train_gnn!(model, scaffolds, porosities;
    epochs = 100,
    lr = 0.001,
    verbose = true
)
```

#### `forward_gnn(model, graph; return_node_embeddings)`
Forward pass through GNN.

#### `predict_properties(model, graph)`
Predict scaffold properties from graph structure.

```julia
result = predict_properties(model, graph)
# result["prediction"]      - predicted value
# result["node_importance"] - importance scores per node
# result["n_nodes"]         - graph size
```

#### `node_classification(model, graph)`
Classify each node (e.g., high/low permeability region).

#### `graph_classification(model, graph)`
Classify entire graph (e.g., scaffold type).

#### `visualize_graph_stats(graph)`
Print statistics about a scaffold graph.

---

## Example: Complete Analysis Pipeline

```julia
using DarwinScaffoldStudio

# Load scaffold
scaffold = load_image("scaffold.tif") .> 0.5

# 1. Topological analysis
tda_result = analyze_pore_topology(scaffold)
println("Betti numbers: ", tda_result["betti_numbers"])
println("Interconnectivity: ", tda_result["interconnectivity_score"])

# 2. Nutrient transport simulation
pinn = NutrientPINN(hidden_dims=[64, 64])
train_pinn!(pinn, scaffold; epochs=500)
transport = solve_nutrient_transport(scaffold, [0.0, 0.5, 1.0])
println("Hypoxic volume: ", transport["hypoxic_volume"])

# 3. Graph-based property prediction
graph = scaffold_to_graph(scaffold)
model = create_scaffold_gnn(node_dim=8, hidden_dim=32)
prediction = predict_properties(model, graph)
println("Predicted porosity: ", prediction["prediction"])
```
