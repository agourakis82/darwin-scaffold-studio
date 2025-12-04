module TDA

using Ripserer
using PersistenceDiagrams
using Statistics

export compute_persistent_homology, analyze_pore_topology

"""
Topological Data Analysis for scaffold pore networks.

Uses persistent homology to characterize topological features:
- H0: Connected components (pore clusters)
- H1: Loops/tunnels (interconnectivity)
- H2: Voids/cavities (enclosed spaces)
"""

"""
    compute_persistent_homology(scaffold_volume, max_dimension=2)

Compute persistence diagrams for the scaffold pore space.
"""
function compute_persistent_homology(scaffold_volume::AbstractArray; max_dimension::Int=2)
    # Extract pore space point cloud
    pore_coords = findall(scaffold_volume .> 0)
    
    if isempty(pore_coords)
        return Dict(
            "H0" => [],
            "H1" => [],
            "H2" => [],
            "betti_numbers" => [0, 0, 0]
        )
    end
    
    # Convert to matrix of coordinates
    points = hcat([[p[1], p[2], p[3]] for p in pore_coords]...)'
    
    # Subsample if too large (for performance)
    if size(points, 1) > 5000
        indices = rand(1:size(points, 1), 5000)
        points = points[indices, :]
    end
    
    # Compute Rips filtration and persistence
    # (Vietoris-Rips complex built on distance matrix)
    try
        result = ripserer(points, dim_max=max_dimension)
        
        # Extract persistence diagrams
        diagrams = Dict()
        for dim in 0:max_dimension
            key = "H$(dim)"
            diagrams[key] = [(p[1], p[2]) for p in result[dim+1]]  # (birth, death) pairs
        end
        
        # Compute Betti numbers (count features at infinity)
       betti = [sum(isinf(d[2]) for d in get(diagrams, "H$(i)", [])) for i in 0:max_dimension]
        
        diagrams["betti_numbers"] = betti
        
        return diagrams
    catch e
        @warn "TDA computation failed" exception=e
        return Dict(
            "H0" => [],
            "H1" => [],
            "H2" => [],
            "betti_numbers" => [0, 0, 0],
            "error" => string(e)
        )
    end
end

"""
    analyze_pore_topology(scaffold_volume)

High-level analysis returning interpretable topological features.
"""
function analyze_pore_topology(scaffold_volume::AbstractArray)
    ph = compute_persistent_homology(scaffold_volume)
    
    # Extract features
    H0 = get(ph, "H0", [])
    H1 = get(ph, "H1", [])
    H2 = get(ph, "H2", [])
    betti = get(ph, "betti_numbers", [0, 0, 0])
    
    # Persistence (lifetime) of features
    persistence_H1 = [d[2] - d[1] for d in H1 if !isinf(d[2])]
    persistence_H2 = [d[2] - d[1] for d in H2 if !isinf(d[2])]
    
    return Dict(
        "num_components" => betti[1],  # β0
        "num_loops" => betti[2],       # β1 (tunnels)
        "num_voids" => betti[3],       # β2 (cavities)
        "mean_loop_persistence" => isempty(persistence_H1) ? 0.0 : mean(persistence_H1),
        "mean_void_persistence" => isempty(persistence_H2) ? 0.0 : mean(persistence_H2),
        "euler_characteristic" => betti[1] - betti[2] + betti[3],
        "topological_complexity" => length(H1) + length(H2)
    )
end

end # module
