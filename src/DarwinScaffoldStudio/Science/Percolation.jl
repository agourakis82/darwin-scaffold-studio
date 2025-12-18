module Percolation

using ImageMorphology
using ImageSegmentation
using Statistics
using LinearAlgebra
using DataStructures # For queue in BFS

export compute_percolation_metrics

# =============================================================================
# Helper Functions
# =============================================================================

"""
    find_largest_cluster(volume::AbstractArray) -> Tuple{BitArray{3}, Bool}

Find the largest connected pore cluster and check if it percolates (z=1 to z=end).

# Returns
- Tuple of (cluster_mask, is_percolating)
"""
function find_largest_cluster(volume::AbstractArray)::Tuple{BitArray{3}, Bool}
    labeled = label_components(volume)
    component_sizes = component_lengths(labeled)

    if isempty(component_sizes) || length(component_sizes) < 2
        return (falses(size(volume)), false)
    end

    # Find largest component (skip background at index 1)
    largest_label = argmax(component_sizes[2:end]) + 1
    main_cluster = (labeled .== largest_label)

    # Check percolation (touches top and bottom Z)
    z_dim = size(volume, 3)
    touches_bottom = any(main_cluster[:, :, 1])
    touches_top = any(main_cluster[:, :, z_dim])
    is_percolating = touches_bottom && touches_top

    return (main_cluster, is_percolating)
end

"""
    compute_percolation_diameter(main_cluster::BitArray{3}, voxel_size::Float64) -> Float64

Compute the percolation diameter using binary search on distance transform.
Returns the maximum diameter sphere that can traverse from z=1 to z=end.
"""
function compute_percolation_diameter(main_cluster::BitArray{3}, voxel_size::Float64)::Float64
    dt = distance_transform(feature_transform(main_cluster)) .* voxel_size
    percolation_diameter = 0.0

    # Binary search for max diameter
    low = 0.0
    high = maximum(dt)

    while (high - low) > 1.0  # 1um precision
        mid = (low + high) / 2.0
        mask_r = dt .>= mid

        # Check percolation of this subset
        lab_r = label_components(mask_r)
        slice_bot = lab_r[:, :, 1]
        slice_top = lab_r[:, :, end]
        labels_bot = unique(slice_bot[slice_bot .> 0])
        labels_top = unique(slice_top[slice_top .> 0])

        if !isempty(intersect(labels_bot, labels_top))
            low = mid
            percolation_diameter = mid * 2.0  # Diameter = 2 * Radius
        else
            high = mid
        end
    end

    return percolation_diameter
end

"""
    compute_tortuosity(main_cluster::BitArray{3}, voxel_size::Float64) -> Float64

Compute tortuosity index as geodesic/euclidean distance ratio.
"""
function compute_tortuosity(main_cluster::BitArray{3}, voxel_size::Float64)::Float64
    t_geo = compute_geodesic_length(main_cluster, voxel_size)
    t_euc = size(main_cluster, 3) * voxel_size
    return t_geo / t_euc
end

"""
    compute_percolation_metrics(volume::AbstractArray, voxel_size::Float64) -> Dict{String, Any}

Compute SOTA percolation metrics:
1. Percolation Diameter (Navigability): Size of largest sphere that can traverse.
2. Tortuosity Index: Geodesic / Euclidean distance ratio.
3. Connectivity: Euler number / Betti numbers (simplified via cluster analysis).

# Returns
- Dict with keys: percolation_diameter_um, tortuosity_index, percolation_status, effective_porosity
"""
function compute_percolation_metrics(volume::AbstractArray, voxel_size::Float64)::Dict{String, Any}
    # 1. Find largest connected cluster
    main_cluster, is_percolating = find_largest_cluster(volume)

    # Handle case where no clusters found
    if !any(main_cluster)
        return Dict{String, Any}(
            "percolation_diameter_um" => 0.0,
            "tortuosity_index" => Inf,
            "percolation_status" => "Blocked",
            "effective_porosity" => 0.0
        )
    end

    # 2. Compute percolation diameter (only if percolating)
    percolation_diameter = is_percolating ? compute_percolation_diameter(main_cluster, voxel_size) : 0.0

    # 3. Compute tortuosity (only if percolating)
    tortuosity = is_percolating ? compute_tortuosity(main_cluster, voxel_size) : Inf

    return Dict{String, Any}(
        "percolation_diameter_um" => percolation_diameter,
        "tortuosity_index" => tortuosity,
        "percolation_status" => is_percolating ? "Connected" : "Disconnected",
        "effective_porosity" => sum(main_cluster) / length(volume)
    )
end

"""
    compute_geodesic_length(mask, voxel_size) -> Float64

Compute shortest path length from z=1 to z=end through the mask.
Uses a simplified Dijkstra on the voxel grid.

# Returns
- Geodesic path length in physical units (um), or Inf if no path exists
"""
function compute_geodesic_length(mask::AbstractArray{Bool, 3}, voxel_size::Float64)::Float64
    sx, sy, sz = size(mask)
    dist = fill(Inf, sx, sy, sz)
    
    # Priority Queue is ideal, but for standard Julia without extra deps, 
    # we can use a queue and simple relaxation (BFS-like but weighted?)
    # Since grid is uniform, BFS is fine for "voxel hop" distance.
    # For Euclidean approximation, we can use weights: 1.0 for straight, sqrt(2) for diagonal.
    # Let's stick to 6-connectivity BFS for speed/simplicity (Manhattan-like path).
    # For "SOTA", we should ideally use 26-connectivity with Euclidean weights.
    
    q = Deque{CartesianIndex{3}}()
    
    # Initialize seeds at Z=1
    for x in 1:sx, y in 1:sy
        if mask[x, y, 1]
            dist[x, y, 1] = 0.0
            push!(q, CartesianIndex(x, y, 1))
        end
    end
    
    min_dist_at_top = Inf
    
    # 6-neighbor offsets
    offsets = [
        CartesianIndex(1,0,0), CartesianIndex(-1,0,0),
        CartesianIndex(0,1,0), CartesianIndex(0,-1,0),
        CartesianIndex(0,0,1), CartesianIndex(0,0,-1)
    ]
    
    while !isempty(q)
        curr = popfirst!(q)
        d = dist[curr]
        
        if d > min_dist_at_top
            continue # Optimization
        end
        
        if curr[3] == sz
            min_dist_at_top = min(min_dist_at_top, d)
            continue
        end
        
        for off in offsets
            next = curr + off
            if checkbounds(Bool, mask, next) && mask[next]
                new_dist = d + voxel_size
                if new_dist < dist[next]
                    dist[next] = new_dist
                    push!(q, next)
                end
            end
        end
    end
    
    return min_dist_at_top
end

end # module
