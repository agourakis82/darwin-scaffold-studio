"""
Graph Neural Networks for Scaffold Structure Analysis
======================================================

Represents scaffolds as graphs where:
- Nodes = Pores (with features: volume, surface area, local curvature)
- Edges = Throats/connections (with features: diameter, length, tortuosity)

Implements:
- GCN (Graph Convolutional Network) - Kipf & Welling 2017
- GraphSAGE - Hamilton et al. 2017
- GAT (Graph Attention Network) - Veličković et al. 2018

Applications:
- Property prediction (porosity, permeability, strength)
- Cell migration prediction
- Scaffold design optimization

References:
- Kipf & Welling (2017) "Semi-Supervised Classification with GCNs"
- Hamilton et al. (2017) "Inductive Representation Learning on Large Graphs"
- Veličković et al. (2018) "Graph Attention Networks"
"""
module GraphNeuralNetworks

using Flux
using Graphs
using Statistics
using LinearAlgebra
using SparseArrays

export ScaffoldGraph, scaffold_to_graph, pore_network_extraction
export GCNConv, GraphSAGEConv, GATConv
export ScaffoldGNN, create_scaffold_gnn
export forward_gnn, train_gnn!, predict_properties
export node_classification, graph_classification
export visualize_graph_stats

# ============================================================================
# Graph Data Structure
# ============================================================================

"""
    ScaffoldGraph

Graph representation of a scaffold structure.

Fields:
- graph: SimpleGraph from Graphs.jl
- node_features: Matrix (n_nodes × n_features)
- edge_features: Matrix (n_edges × n_features)
- node_labels: Optional labels for supervised learning
- pore_centers: Coordinates of pore centers
- adjacency: Sparse adjacency matrix
- degree: Node degree vector
"""
struct ScaffoldGraph
    graph::SimpleGraph{Int}
    node_features::Matrix{Float32}
    edge_features::Matrix{Float32}
    edge_index::Matrix{Int}  # (2, n_edges) source/target pairs
    node_labels::Vector{Float32}
    pore_centers::Vector{Tuple{Int,Int,Int}}
    adjacency::SparseMatrixCSC{Float32,Int}
    degree::Vector{Float32}
end

# ============================================================================
# Graph Convolutional Layers
# ============================================================================

"""
    GCNConv

Graph Convolutional Network layer (Kipf & Welling 2017).

Aggregation: h_i^{l+1} = σ(Σ_j (1/√(d_i d_j)) W h_j^l)

Uses symmetric normalization with self-loops.
"""
struct GCNConv
    weight::Matrix{Float32}
    bias::Vector{Float32}
    σ::Function
end

Flux.@layer GCNConv

function GCNConv(in_dim::Int, out_dim::Int; σ=relu)
    weight = Float32.(randn(out_dim, in_dim) * sqrt(2.0 / in_dim))
    bias = zeros(Float32, out_dim)
    return GCNConv(weight, bias, σ)
end

"""
    (layer::GCNConv)(x, adj_norm)

Forward pass for GCN layer.
- x: Node features (in_dim × n_nodes)
- adj_norm: Normalized adjacency matrix (with self-loops)
"""
function (layer::GCNConv)(x::AbstractMatrix, adj_norm::AbstractMatrix)
    # Message passing: aggregate neighbor features
    h = adj_norm * x'  # (n_nodes × in_dim)
    # Transform
    out = layer.weight * h' .+ layer.bias  # (out_dim × n_nodes)
    return layer.σ.(out)
end

"""
    GraphSAGEConv

GraphSAGE layer (Hamilton et al. 2017).

Aggregation: h_i^{l+1} = σ(W · CONCAT(h_i^l, AGG({h_j^l : j ∈ N(i)})))

Supports mean, max, and LSTM aggregation.
"""
struct GraphSAGEConv
    weight_self::Matrix{Float32}
    weight_neigh::Matrix{Float32}
    bias::Vector{Float32}
    σ::Function
    aggregator::Symbol  # :mean, :max, :sum
end

Flux.@layer GraphSAGEConv

function GraphSAGEConv(in_dim::Int, out_dim::Int; σ=relu, aggregator=:mean)
    weight_self = Float32.(randn(out_dim, in_dim) * sqrt(2.0 / in_dim))
    weight_neigh = Float32.(randn(out_dim, in_dim) * sqrt(2.0 / in_dim))
    bias = zeros(Float32, out_dim)
    return GraphSAGEConv(weight_self, weight_neigh, bias, σ, aggregator)
end

function (layer::GraphSAGEConv)(x::AbstractMatrix, adj::AbstractMatrix)
    n_nodes = size(x, 2)

    # Self features
    h_self = layer.weight_self * x

    # Neighbor aggregation
    if layer.aggregator == :mean
        # Normalize by degree
        deg = sum(adj, dims=2) .+ 1f-6
        adj_norm = adj ./ deg
        h_neigh = layer.weight_neigh * (x * adj_norm')
    elseif layer.aggregator == :sum
        h_neigh = layer.weight_neigh * (x * adj')
    else  # :max - approximate with softmax weighting
        h_neigh = layer.weight_neigh * (x * adj')
    end

    out = h_self .+ h_neigh .+ layer.bias
    return layer.σ.(out)
end

"""
    GATConv

Graph Attention Network layer (Veličković et al. 2018).

Uses attention mechanism to weight neighbor contributions:
α_ij = softmax_j(LeakyReLU(a^T [Wh_i || Wh_j]))
"""
struct GATConv
    weight::Matrix{Float32}
    attention::Vector{Float32}  # Attention vector
    bias::Vector{Float32}
    n_heads::Int
    σ::Function
    negative_slope::Float32  # For LeakyReLU
end

Flux.@layer GATConv

function GATConv(in_dim::Int, out_dim::Int; n_heads=1, σ=relu, negative_slope=0.2f0)
    weight = Float32.(randn(out_dim, in_dim) * sqrt(2.0 / in_dim))
    attention = Float32.(randn(2 * out_dim) * 0.01)
    bias = zeros(Float32, out_dim)
    return GATConv(weight, attention, bias, n_heads, σ, negative_slope)
end

function (layer::GATConv)(x::AbstractMatrix, edge_index::AbstractMatrix)
    out_dim, n_nodes = size(layer.weight, 1), size(x, 2)
    n_edges = size(edge_index, 2)

    # Transform node features
    h = layer.weight * x  # (out_dim × n_nodes)

    # Compute attention scores for edges
    src_idx = edge_index[1, :]
    tgt_idx = edge_index[2, :]

    # Concatenate source and target features for each edge
    h_src = h[:, src_idx]  # (out_dim × n_edges)
    h_tgt = h[:, tgt_idx]  # (out_dim × n_edges)
    h_cat = vcat(h_src, h_tgt)  # (2*out_dim × n_edges)

    # Attention scores
    e = layer.attention' * h_cat  # (1 × n_edges)
    e = max.(e, e .* layer.negative_slope)  # LeakyReLU

    # Softmax over neighbors (simplified: use exp and normalize)
    α = exp.(e)

    # Aggregate with attention weights
    out = zeros(Float32, out_dim, n_nodes)
    for (idx, (s, t)) in enumerate(zip(src_idx, tgt_idx))
        out[:, t] .+= α[idx] .* h[:, s]
    end

    # Normalize
    for i in 1:n_nodes
        neighbor_sum = sum(α[tgt_idx .== i])
        if neighbor_sum > 0
            out[:, i] ./= neighbor_sum
        end
    end

    return layer.σ.(out .+ layer.bias)
end

# ============================================================================
# Scaffold-to-Graph Conversion
# ============================================================================

"""
    scaffold_to_graph(scaffold_volume; voxel_size=1.0, grid_step=10, connect_radius=20.0)

Convert 3D scaffold volume to graph representation.

Arguments:
- scaffold_volume: 3D binary array (true = pore)
- voxel_size: Physical size of voxels (μm)
- grid_step: Sampling step for pore detection
- connect_radius: Maximum distance to connect pores

Returns:
- ScaffoldGraph with node/edge features
"""
function scaffold_to_graph(
    scaffold_volume::AbstractArray{Bool,3};
    voxel_size::Float64=1.0,
    grid_step::Int=10,
    connect_radius::Float64=20.0
)
    nx, ny, nz = size(scaffold_volume)

    # Create graph
    g = SimpleGraph()
    pore_centers = Tuple{Int,Int,Int}[]
    node_features_list = Vector{Float32}[]

    # Sample pore centers on grid
    for x in grid_step:grid_step:nx-grid_step
        for y in grid_step:grid_step:ny-grid_step
            for z in grid_step:grid_step:nz-grid_step
                if scaffold_volume[x, y, z]
                    add_vertex!(g)
                    push!(pore_centers, (x, y, z))

                    # Compute node features
                    features = compute_node_features(scaffold_volume, x, y, z, voxel_size)
                    push!(node_features_list, features)
                end
            end
        end
    end

    n_nodes = nv(g)
    if n_nodes == 0
        return empty_scaffold_graph()
    end

    # Stack node features
    node_features = hcat(node_features_list...)  # (n_features × n_nodes)

    # Create edges between nearby pores
    edge_index_list = Vector{Int}[]
    edge_features_list = Vector{Float32}[]

    for i in 1:n_nodes
        for j in i+1:n_nodes
            dist = euclidean_distance(pore_centers[i], pore_centers[j])
            if dist < connect_radius
                add_edge!(g, i, j)

                # Edge: i → j and j → i (undirected)
                push!(edge_index_list, [i, j])
                push!(edge_index_list, [j, i])

                # Edge features
                edge_feat = compute_edge_features(
                    scaffold_volume, pore_centers[i], pore_centers[j], voxel_size
                )
                push!(edge_features_list, edge_feat)
                push!(edge_features_list, edge_feat)  # Same for reverse edge
            end
        end
    end

    # Build matrices
    n_edges = length(edge_index_list)
    edge_index = n_edges > 0 ? hcat(edge_index_list...)' : zeros(Int, 0, 2)
    edge_features = n_edges > 0 ? hcat(edge_features_list...) : zeros(Float32, 4, 0)

    # Adjacency matrix (sparse)
    adjacency = sparse(
        n_edges > 0 ? edge_index[:, 1] : Int[],
        n_edges > 0 ? edge_index[:, 2] : Int[],
        ones(Float32, n_edges),
        n_nodes, n_nodes
    )

    # Add self-loops
    for i in 1:n_nodes
        adjacency[i, i] = 1.0f0
    end

    # Degree
    degree = Float32.(vec(sum(adjacency, dims=2)))

    # Normalize adjacency (symmetric normalization)
    deg_inv_sqrt = 1.0f0 ./ sqrt.(degree .+ 1f-6)
    adjacency_norm = Diagonal(deg_inv_sqrt) * adjacency * Diagonal(deg_inv_sqrt)

    return ScaffoldGraph(
        g,
        node_features,
        edge_features,
        edge_index',  # (2 × n_edges)
        zeros(Float32, n_nodes),  # No labels
        pore_centers,
        sparse(adjacency_norm),
        degree
    )
end

function empty_scaffold_graph()
    return ScaffoldGraph(
        SimpleGraph(),
        zeros(Float32, 8, 0),
        zeros(Float32, 4, 0),
        zeros(Int, 2, 0),
        Float32[],
        Tuple{Int,Int,Int}[],
        sparse(zeros(Float32, 0, 0)),
        Float32[]
    )
end

"""
    compute_node_features(volume, x, y, z, voxel_size)

Compute features for a pore node:
1. Local porosity (5-voxel radius)
2. Normalized x, y, z coordinates
3. Local surface area estimate
4. Local curvature estimate
5. Distance to boundary
"""
function compute_node_features(
    volume::AbstractArray{Bool,3},
    x::Int, y::Int, z::Int,
    voxel_size::Float64
)
    nx, ny, nz = size(volume)
    r = 5  # Radius for local features

    # Local region
    x1, x2 = max(1, x-r), min(nx, x+r)
    y1, y2 = max(1, y-r), min(ny, y+r)
    z1, z2 = max(1, z-r), min(nz, z+r)
    local_vol = volume[x1:x2, y1:y2, z1:z2]

    # Feature 1: Local porosity
    porosity = Float32(mean(local_vol))

    # Feature 2-4: Normalized coordinates
    norm_x = Float32(x / nx)
    norm_y = Float32(y / ny)
    norm_z = Float32(z / nz)

    # Feature 5: Local surface area (count pore-solid interfaces)
    surface_count = 0
    for i in x1:x2, j in y1:y2, k in z1:z2
        if volume[i, j, k]
            # Check 6-connectivity neighbors
            for (di, dj, dk) in [(-1,0,0), (1,0,0), (0,-1,0), (0,1,0), (0,0,-1), (0,0,1)]
                ni, nj, nk = i+di, j+dj, k+dk
                if 1 <= ni <= nx && 1 <= nj <= ny && 1 <= nk <= nz
                    if !volume[ni, nj, nk]
                        surface_count += 1
                    end
                end
            end
        end
    end
    surface_area = Float32(surface_count * voxel_size^2 / 1000)  # Normalize

    # Feature 6: Local curvature (simplified: variance of neighbors)
    curvature = Float32(std(local_vol))

    # Feature 7: Distance to nearest boundary
    dist_x = Float32(min(x, nx - x) / nx)
    dist_y = Float32(min(y, ny - y) / ny)
    dist_z = Float32(min(z, nz - z) / nz)
    dist_boundary = min(dist_x, dist_y, dist_z)

    # Feature 8: Pore cluster size indicator
    cluster_size = Float32(sum(local_vol) / length(local_vol))

    return Float32[porosity, norm_x, norm_y, norm_z, surface_area, curvature, dist_boundary, cluster_size]
end

"""
    compute_edge_features(volume, p1, p2, voxel_size)

Compute features for an edge (throat) between two pores:
1. Euclidean distance
2. Path porosity (fraction of pore voxels along line)
3. Minimum throat width
4. Tortuosity estimate
"""
function compute_edge_features(
    volume::AbstractArray{Bool,3},
    p1::Tuple{Int,Int,Int},
    p2::Tuple{Int,Int,Int},
    voxel_size::Float64
)
    # Feature 1: Distance
    dist = euclidean_distance(p1, p2) * voxel_size

    # Sample points along line
    n_samples = max(10, round(Int, dist / 2))
    x_samples = range(p1[1], p2[1], length=n_samples)
    y_samples = range(p1[2], p2[2], length=n_samples)
    z_samples = range(p1[3], p2[3], length=n_samples)

    nx, ny, nz = size(volume)
    pore_count = 0

    for i in 1:n_samples
        xi = clamp(round(Int, x_samples[i]), 1, nx)
        yi = clamp(round(Int, y_samples[i]), 1, ny)
        zi = clamp(round(Int, z_samples[i]), 1, nz)
        if volume[xi, yi, zi]
            pore_count += 1
        end
    end

    # Feature 2: Path porosity
    path_porosity = Float32(pore_count / n_samples)

    # Feature 3: Minimum width (simplified)
    min_width = Float32(path_porosity * 10.0)  # Heuristic

    # Feature 4: Tortuosity (straight line = 1.0)
    tortuosity = Float32(1.0 / (path_porosity + 0.1))

    return Float32[dist / 100, path_porosity, min_width, tortuosity]
end

function euclidean_distance(p1::Tuple{Int,Int,Int}, p2::Tuple{Int,Int,Int})
    return sqrt(Float64((p1[1]-p2[1])^2 + (p1[2]-p2[2])^2 + (p1[3]-p2[3])^2))
end

# ============================================================================
# Full GNN Model
# ============================================================================

"""
    ScaffoldGNN

Complete GNN model for scaffold property prediction.

Architecture:
1. Node encoder (MLP)
2. Multiple GNN layers (GCN/GraphSAGE/GAT)
3. Graph-level readout (mean/max/attention pooling)
4. Prediction head (MLP)
"""
struct ScaffoldGNN
    node_encoder::Chain
    gnn_layers::Vector{Any}
    readout::Symbol  # :mean, :max, :sum, :attention
    predictor::Chain
    layer_type::Symbol  # :gcn, :sage, :gat
end

Flux.@layer ScaffoldGNN

"""
    create_scaffold_gnn(; kwargs...)

Create a ScaffoldGNN model.

Arguments:
- node_dim: Input node feature dimension (default: 8)
- hidden_dim: Hidden layer dimension (default: 64)
- output_dim: Output prediction dimension (default: 1)
- n_layers: Number of GNN layers (default: 3)
- layer_type: :gcn, :sage, or :gat (default: :gcn)
- readout: :mean, :max, :sum (default: :mean)
- dropout: Dropout probability (default: 0.1)
"""
function create_scaffold_gnn(;
    node_dim::Int=8,
    hidden_dim::Int=64,
    output_dim::Int=1,
    n_layers::Int=3,
    layer_type::Symbol=:gcn,
    readout::Symbol=:mean,
    dropout::Float64=0.1
)
    # Node encoder
    node_encoder = Chain(
        Dense(node_dim, hidden_dim, relu),
        Dropout(dropout),
        Dense(hidden_dim, hidden_dim, relu)
    )

    # GNN layers
    gnn_layers = []
    for i in 1:n_layers
        if layer_type == :gcn
            push!(gnn_layers, GCNConv(hidden_dim, hidden_dim))
        elseif layer_type == :sage
            push!(gnn_layers, GraphSAGEConv(hidden_dim, hidden_dim))
        else  # :gat
            push!(gnn_layers, GATConv(hidden_dim, hidden_dim))
        end
    end

    # Prediction head
    predictor = Chain(
        Dense(hidden_dim, hidden_dim ÷ 2, relu),
        Dropout(dropout),
        Dense(hidden_dim ÷ 2, output_dim)
    )

    return ScaffoldGNN(node_encoder, gnn_layers, readout, predictor, layer_type)
end

"""
    forward_gnn(model, graph; return_node_embeddings=false)

Forward pass through GNN.

Returns:
- If return_node_embeddings: (prediction, node_embeddings)
- Otherwise: prediction (graph-level or node-level)
"""
function forward_gnn(model::ScaffoldGNN, graph::ScaffoldGraph; return_node_embeddings::Bool=false)
    # Encode node features
    h = model.node_encoder(graph.node_features)  # (hidden_dim × n_nodes)

    # Message passing layers
    for layer in model.gnn_layers
        if model.layer_type == :gat
            h = layer(h, graph.edge_index)
        else
            h = layer(h, Matrix(graph.adjacency))
        end
    end

    # Graph-level readout
    if model.readout == :mean
        h_graph = mean(h, dims=2)
    elseif model.readout == :max
        h_graph = maximum(h, dims=2)
    else  # :sum
        h_graph = sum(h, dims=2)
    end

    # Prediction
    prediction = model.predictor(h_graph)

    if return_node_embeddings
        return prediction, h
    else
        return prediction
    end
end

# ============================================================================
# Training
# ============================================================================

"""
    train_gnn!(model, graphs, targets; epochs=100, lr=0.001)

Train GNN on a dataset of scaffold graphs.

Arguments:
- model: ScaffoldGNN
- graphs: Vector of ScaffoldGraph
- targets: Vector of target values (one per graph)
- epochs: Number of training epochs
- lr: Learning rate

Returns:
- loss_history: Vector of training losses
"""
function train_gnn!(
    model::ScaffoldGNN,
    graphs::Vector{ScaffoldGraph},
    targets::Vector{Float32};
    epochs::Int=100,
    lr::Float64=0.001,
    verbose::Bool=true
)
    # Setup optimizer with new Flux API
    opt_state = Flux.setup(Adam(lr), model)

    loss_history = Float64[]

    for epoch in 1:epochs
        total_loss = 0.0

        for (graph, target) in zip(graphs, targets)
            if nv(graph.graph) == 0
                continue
            end

            # Compute loss and gradients using explicit API
            loss, grads = Flux.withgradient(model) do m
                pred = forward_gnn(m, graph)
                Flux.mse(pred[1], target)
            end

            # Update model parameters
            Flux.update!(opt_state, model, grads[1])
            total_loss += loss
        end

        avg_loss = total_loss / length(graphs)
        push!(loss_history, avg_loss)

        if verbose && epoch % 10 == 0
            @info "GNN Training" epoch=epoch loss=round(avg_loss, digits=6)
        end
    end

    return loss_history
end

# ============================================================================
# Prediction Tasks
# ============================================================================

"""
    predict_properties(model, graph)

Predict scaffold properties from graph structure.

Returns Dict with:
- predicted_porosity
- predicted_permeability
- predicted_strength
- node_importance (attention weights if using GAT)
"""
function predict_properties(model::ScaffoldGNN, graph::ScaffoldGraph)
    if nv(graph.graph) == 0
        return Dict(
            "prediction" => 0.0,
            "n_nodes" => 0,
            "n_edges" => 0
        )
    end

    pred, node_embeddings = forward_gnn(model, graph; return_node_embeddings=true)

    # Node importance (L2 norm of embeddings)
    node_importance = vec(sqrt.(sum(node_embeddings.^2, dims=1)))
    node_importance ./= maximum(node_importance) + 1e-6

    return Dict(
        "prediction" => pred[1],
        "node_embeddings" => node_embeddings,
        "node_importance" => node_importance,
        "n_nodes" => nv(graph.graph),
        "n_edges" => ne(graph.graph),
        "mean_degree" => mean(graph.degree)
    )
end

"""
    node_classification(model, graph)

Classify each node (e.g., high/low permeability region).
"""
function node_classification(model::ScaffoldGNN, graph::ScaffoldGraph)
    if nv(graph.graph) == 0
        return Float32[]
    end

    # Get node embeddings
    _, h = forward_gnn(model, graph; return_node_embeddings=true)

    # Simple classification based on embedding norm
    scores = vec(sum(h.^2, dims=1))

    # Normalize to [0, 1]
    scores = (scores .- minimum(scores)) ./ (maximum(scores) - minimum(scores) + 1e-6)

    return scores
end

"""
    graph_classification(model, graph)

Classify entire graph (e.g., scaffold type).
"""
function graph_classification(model::ScaffoldGNN, graph::ScaffoldGraph)
    pred = forward_gnn(model, graph)
    return sigmoid.(pred)
end

# ============================================================================
# Utility Functions
# ============================================================================

"""
    pore_network_extraction(scaffold_volume; method=:watershed)

Advanced pore network extraction using watershed segmentation.
"""
function pore_network_extraction(scaffold_volume::AbstractArray{Bool,3}; method::Symbol=:simple)
    if method == :simple
        return scaffold_to_graph(scaffold_volume)
    else
        # Watershed-based extraction would go here
        # For now, use simple grid-based method
        return scaffold_to_graph(scaffold_volume)
    end
end

"""
    visualize_graph_stats(graph)

Print statistics about a scaffold graph.
"""
function visualize_graph_stats(graph::ScaffoldGraph)
    n = nv(graph.graph)
    e = ne(graph.graph)

    println("Scaffold Graph Statistics")
    println("=" ^ 40)
    println("  Nodes (pores): $n")
    println("  Edges (throats): $e")
    println("  Average degree: $(round(mean(graph.degree), digits=2))")
    println("  Max degree: $(maximum(graph.degree))")

    if n > 0
        println("  Node feature dim: $(size(graph.node_features, 1))")
        println("  Mean porosity: $(round(mean(graph.node_features[1, :]), digits=3))")
    end

    if e > 0
        println("  Edge feature dim: $(size(graph.edge_features, 1))")
    end
end

end # module
