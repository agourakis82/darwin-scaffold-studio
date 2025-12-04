module GraphNeuralNetworks

using Flux
using Graphs
using Statistics

export ScaffoldGNN, scaffold_to_graph, predict_cell_migration

"""
Graph Neural Network for scaffold-as-graph representation.

Nodes = Pores
Edges = Connections (throats)
Node features = [pore_volume, surface_area, curvature]
Edge features = [throat_diameter, length]
"""
struct ScaffoldGNN
    node_encoder::Chain
    edge_encoder::Chain
    message_passing::Chain
    readout::Chain
end

function ScaffoldGNN(; node_dim::Int=8, edge_dim::Int=4, hidden_dim::Int=64)
    ScaffoldGNN(
        Chain(Dense(node_dim, hidden_dim, relu)),
        Chain(Dense(edge_dim, hidden_dim, relu)),
        Chain(Dense(hidden_dim * 2, hidden_dim, relu)),  # Aggregate messages
        Chain(Dense(hidden_dim, 1, sigmoid))  # Predict cell occupancy
    )
end

"""
    scaffold_to_graph(scaffold_volume, voxel_size)

Convert 3D scaffold volume to graph representation.
Uses watershed or connected components for pore identification.
"""
function scaffold_to_graph(scaffold_volume::AbstractArray, voxel_size::Float64)
    # 1. Identify pores (connected components in pore space)
    # For demo, use simple grid-based approach
    
    nx, ny, nz = size(scaffold_volume)
    
    # Create adjacency graph
    g = SimpleGraph()
    
    # Sample pore centers (simplified)
    pore_centers = []
    node_features = []
    
    # Grid sampling
    step = 10
    for x in step:step:nx-step
        for y in step:step:ny-step
            for z in step:step:nz-step
                if scaffold_volume[x, y, z] > 0  # Is pore
                    add_vertex!(g)
                    push!(pore_centers, (x, y, z))
                    
                    # Node feature: local porosity
                    local_vol = scaffold_volume[max(1,x-5):min(nx,x+5), 
                                               max(1,y-5):min(ny,y+5),
                                               max(1,z-5):min(nz,z+5)]
                    local_porosity = sum(local_vol) / length(local_vol)
                    
                    push!(node_features, [local_porosity, x/nx, y/ny, z/nz])
                end
            end
        end
    end
    
    # 2. Create edges (connect nearby pores)
    edge_features = []
    for i in 1:nv(g)
        for j in i+1:nv(g)
            dist = sqrt(sum((collect(pore_centers[i]) .- collect(pore_centers[j])).^2))
            if dist < 20.0  # Threshold
                add_edge!(g, i, j)
                push!(edge_features, [dist * voxel_size, 1.0])  # [length, diameter]
            end
        end
    end
    
    return Dict(
        "graph" => g,
        "node_features" => hcat(node_features...)',
        "edge_features" => isempty(edge_features) ? zeros(0, 2) : hcat(edge_features...)',
        "pore_centers" => pore_centers
    )
end

"""
    predict_cell_migration(gnn, graph_data, source_nodes)

Predict cell migration probability for each node.
"""
function predict_cell_migration(gnn::ScaffoldGNN, graph_data::Dict, source_nodes::Vector{Int})
    g = graph_data["graph"]
    node_feats = graph_data["node_features"]
    
    # Encode nodes
    h = gnn.node_encoder(node_feats')
    
    # Message passing (simplified - single layer)
    h_new = similar(h)
    for i in 1:nv(g)
        neighbors = neighbors(g, i)
        if !isempty(neighbors)
            messages = h[:, neighbors]
            h_new[:, i] = gnn.message_passing([h[:, i]; mean(messages, dims=2)])
        else
            h_new[:, i] = h[:, i]
        end
    end
    
    # Readout: predict cell occupancy probability
    predictions = gnn.readout(h_new)
    
    return vec(predictions)
end

end # module
