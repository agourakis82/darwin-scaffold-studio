"""
Scaffold Metrics Module

Compute Q1-validated scaffold metrics (Murphy 2010, Karageorgiou 2005).
"""

module Metrics

using ..Types: ScaffoldMetrics
using ..Utils
using Statistics
using LinearAlgebra
using StatsBase

export compute_metrics

"""
    compute_metrics(binary::AbstractArray{Bool, 3}, voxel_size_um::Real) -> ScaffoldMetrics

Compute complete scaffold metrics.

# Arguments
- `binary`: Binary 3D array (true = solid, false = pore)
- `voxel_size_um`: Voxel size in micrometers

# Returns
- ScaffoldMetrics with all computed metrics
"""
function compute_metrics(
    binary::AbstractArray{Bool, 3},
    voxel_size_um::Real
)::ScaffoldMetrics
    # 1. Porosity
    porosity = 1.0 - compute_relative_density(binary)

    # 2. Mean pore size
    mean_pore_size_um = compute_mean_pore_size(binary, voxel_size_um)

    # 3. Interconnectivity
    interconnectivity = compute_interconnectivity(binary)

    # 4. Tortuosity (Gibson-Ashby approximation)
    tortuosity = compute_tortuosity(binary)

    # 5. Specific surface area
    surface_area_mm2 = Utils.compute_surface_area(binary, voxel_size_um)
    volume_mm3 = Utils.compute_volume_mm3(size(binary), voxel_size_um)
    total_volume_mm3 = volume_mm3[1] * volume_mm3[2] * volume_mm3[3]
    specific_surface_area = surface_area_mm2 / max(total_volume_mm3, 1e-10)

    # 6. Mechanical properties (Gibson-Ashby)
    relative_density = 1.0 - porosity
    elastic_modulus, yield_strength = compute_mechanical_properties(relative_density)

    # 7. Permeability (Kozeny-Carman)
    permeability = compute_permeability(porosity, mean_pore_size_um)

    return ScaffoldMetrics(
        porosity,
        mean_pore_size_um,
        interconnectivity,
        tortuosity,
        specific_surface_area,
        elastic_modulus,
        yield_strength,
        permeability
    )
end

"""
    compute_mean_pore_size(binary::AbstractArray{Bool, 3}, voxel_size_um::Real) -> Float64

Compute mean pore size using distance transform.
"""
function compute_mean_pore_size(
    binary::AbstractArray{Bool, 3},
    voxel_size_um::Real
)::Float64
    # Pore mask (inverse of solid)
    pore_mask = .!binary

    if sum(pore_mask) == 0
        return 0.0
    end

    # Distance transform (3D Euclidean)
    # Simplified: use 2D per slice and average
    pore_sizes = Float64[]

    for k in 1:size(binary, 3)
        slice_mask = pore_mask[:, :, k]
        if sum(slice_mask) > 0
            # Distance transform
            dist = distance_transform_2d(slice_mask)
            if sum(dist) > 0
                mean_radius_voxels = mean(dist[dist .> 0])
                mean_diameter_um = 2.0 * mean_radius_voxels * voxel_size_um
                push!(pore_sizes, mean_diameter_um)
            end
        end
    end

    return isempty(pore_sizes) ? 0.0 : mean(pore_sizes)
end

"""
    distance_transform_2d(mask::AbstractMatrix{Bool}) -> Array{Float64, 2}

2D Euclidean distance transform.
Returns distance from each pore voxel to nearest solid.
"""
function distance_transform_2d(mask::AbstractMatrix{Bool})::Array{Float64, 2}
    h, w = size(mask)
    dist = zeros(Float64, h, w)

    # Find boundary pixels (solid voxels adjacent to pores)
    boundary = CartesianIndex{2}[]
    for i in 1:h, j in 1:w
        if !mask[i, j]  # solid
            # Check if adjacent to pore
            for di in -1:1, dj in -1:1
                ni, nj = i + di, j + dj
                if 1 <= ni <= h && 1 <= nj <= w && mask[ni, nj]
                    push!(boundary, CartesianIndex(i, j))
                    break
                end
            end
        end
    end

    if isempty(boundary)
        # No boundary found - estimate based on pore fraction
        pore_count = sum(mask)
        if pore_count > 0
            # Approximate as circular pores
            avg_radius = sqrt(pore_count / π) / 2
            for i in 1:h, j in 1:w
                if mask[i, j]
                    dist[i, j] = avg_radius
                end
            end
        end
        return dist
    end

    # Compute distance from each pore pixel to nearest boundary
    for i in 1:h, j in 1:w
        if mask[i, j]  # pore
            min_dist = Inf
            for b in boundary
                d = sqrt(Float64((i - b[1])^2 + (j - b[2])^2))
                if d < min_dist
                    min_dist = d
                end
            end
            dist[i, j] = min_dist
        end
    end

    return dist
end

"""
    compute_interconnectivity(binary::AbstractArray{Bool, 3}) -> Float64

Compute interconnectivity (largest connected component / total pore volume).
"""
function compute_interconnectivity(binary::AbstractArray{Bool, 3})::Float64
    pore_mask = .!binary

    if sum(pore_mask) == 0
        return 0.0
    end

    # Connected components (26-connectivity)
    labels = label_components_3d(pore_mask)

    if maximum(labels) == 0
        return 0.0
    end

    # Count pixels per component
    component_sizes = [sum(labels .== i) for i in 1:maximum(labels)]
    largest_component_size = maximum(component_sizes)
    total_pore_size = sum(pore_mask)

    return largest_component_size / total_pore_size
end

"""
    label_components_3d(mask::BitArray{3}) -> Array{Int, 3}

Label connected components in 3D (26-connectivity).
"""
function label_components_3d(mask::BitArray{3})::Array{Int, 3}
    dims = size(mask)
    labels = zeros(Int, dims)
    current_label = 1

    # Simple flood fill (can be optimized)
    for i in 1:dims[1], j in 1:dims[2], k in 1:dims[3]
        if mask[i, j, k] && labels[i, j, k] == 0
            flood_fill_3d!(mask, labels, i, j, k, current_label)
            current_label += 1
        end
    end

    return labels
end

"""
    flood_fill_3d!(mask::BitArray{3}, labels::Array{Int, 3},
                   start_i::Int, start_j::Int, start_k::Int, label::Int)

Flood fill for 3D connected components.
"""
function flood_fill_3d!(
    mask::BitArray{3},
    labels::Array{Int, 3},
    start_i::Int,
    start_j::Int,
    start_k::Int,
    label::Int
)
    dims = size(mask)
    stack = [(start_i, start_j, start_k)]

    while !isempty(stack)
        i, j, k = pop!(stack)

        if i < 1 || i > dims[1] || j < 1 || j > dims[2] || k < 1 || k > dims[3]
            continue
        end

        if !mask[i, j, k] || labels[i, j, k] != 0
            continue
        end

        labels[i, j, k] = label

        # Add 26 neighbors
        for di in -1:1, dj in -1:1, dk in -1:1
            if di == 0 && dj == 0 && dk == 0
                continue
            end
            push!(stack, (i + di, j + dj, k + dk))
        end
    end
end

"""
    compute_tortuosity(binary::AbstractArray{Bool, 3}) -> Float64

Compute tortuosity (Gibson-Ashby approximation).
"""
function compute_tortuosity(binary::AbstractArray{Bool, 3})::Float64
    relative_density = compute_relative_density(binary)
    # Gibson-Ashby: τ ≈ 1 + 0.5 * ρ_rel
    return 1.0 + 0.5 * relative_density
end

"""
    compute_relative_density(binary::AbstractArray{Bool, 3}) -> Float64

Compute relative density (solid fraction).
"""
function compute_relative_density(binary::AbstractArray{Bool, 3})::Float64
    return sum(binary) / length(binary)
end

"""
    compute_mechanical_properties(relative_density::Float64) -> Tuple{Float64, Float64}

Compute elastic modulus and yield strength (Gibson-Ashby).

# Returns
- (elastic_modulus_MPa, yield_strength_MPa)
"""
function compute_mechanical_properties(
    relative_density::Float64
)::Tuple{Float64, Float64}
    # Gibson-Ashby scaling laws
    # E* / Es = C1 * (ρ* / ρs)^n
    # σ* / σs = C2 * (ρ* / ρs)^m

    # Typical values for bone scaffolds
    Es = 20.0e3  # Solid modulus (MPa)
    σs = 100.0   # Solid strength (MPa)
    C1 = 0.3
    C2 = 0.65
    n = 2.0
    m = 1.5

    elastic_modulus = Es * C1 * (relative_density^n)
    yield_strength = σs * C2 * (relative_density^m)

    return (elastic_modulus, yield_strength)
end

"""
    compute_permeability(porosity::Float64, mean_pore_size_um::Float64) -> Float64

Compute permeability using Kozeny-Carman equation.

# Returns
- Permeability in m²
"""
function compute_permeability(
    porosity::Float64,
    mean_pore_size_um::Float64
)::Float64
    if porosity <= 0.0 || mean_pore_size_um <= 0.0
        return 0.0
    end

    # Kozeny-Carman: k = (ε³ * d²) / (180 * (1 - ε)²)
    # where ε = porosity, d = pore diameter

    pore_diameter_m = mean_pore_size_um * 1e-6  # Convert to meters
    k = (porosity^3 * pore_diameter_m^2) / (180.0 * (1.0 - porosity)^2)

    return k
end

end # module Metrics
