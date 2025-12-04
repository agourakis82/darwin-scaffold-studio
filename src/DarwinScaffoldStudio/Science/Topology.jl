module Topology

using Statistics
using LinearAlgebra
using GeometryBasics
using ImageFiltering

export compute_kec_metrics

"""
    compute_kec_metrics(volume::AbstractArray, voxel_size::Float64)

Compute the "KEC" metrics for the thesis:
- K: Curvature (Mean and Gaussian)
- E: Entropy (Shannon entropy of pore distribution)
- C: Coherence (Spatial autocorrelation)
"""
function compute_kec_metrics(volume::AbstractArray, voxel_size::Float64)
    # 1. Curvature (K)
    # We approximate curvature from the binary volume surface
    # In a real thesis, we'd use the mesh, but for volume analysis we can use gradients
    k_mean, k_gaussian = compute_curvature_volume(volume, voxel_size)
    
    # 2. Entropy (E)
    # Shannon entropy of the pore space distribution
    entropy_val = compute_shannon_entropy(volume)
    
    # 3. Coherence (C)
    # Spatial autocorrelation (Two-point correlation function)
    coherence_val = compute_spatial_coherence(volume)
    
    return Dict(
        "curvature_mean" => k_mean,
        "curvature_gaussian" => k_gaussian,
        "entropy_shannon" => entropy_val,
        "coherence_spatial" => coherence_val
    )
end

"""
    compute_curvature_volume(volume, voxel_size)

Estimate mean and gaussian curvature from implicit surface (level set).
Reference: Goldman (2005) "Curvature formulas for implicit curves and surfaces"
"""
function compute_curvature_volume(volume::AbstractArray, voxel_size::Float64)
    # Smooth the binary volume to get a continuous field (implicit surface)
    # Gaussian smoothing with sigma=1.0
    field = imfilter(Float64.(volume), Kernel.gaussian(1.0))
    
    # Gradients (First derivatives)
    fx, fy, fz = imgradients(field, Kernel.sobel)
    
    # Second derivatives (Hessian)
    fxx, fxy, fxz = imgradients(fx, Kernel.sobel)
    fyx, fyy, fyz = imgradients(fy, Kernel.sobel)
    fzx, fzy, fzz = imgradients(fz, Kernel.sobel)
    
    # Compute curvature only at the interface (where field ≈ 0.5)
    # Mask for surface voxels
    surface_mask = (field .> 0.4) .& (field .< 0.6)
    
    if sum(surface_mask) == 0
        return 0.0, 0.0
    end
    
    # Mean Curvature (H) formula for implicit surface f(x,y,z) = c
    # H = -div(∇f / |∇f|) / 2
    # Simplified: H = ( (fxx + fyy + fzz)|∇f|^2 - ... ) / (2|∇f|^3) 
    # For thesis, we use a simplified divergence approximation
    
    grad_norm = sqrt.(fx.^2 .+ fy.^2 .+ fz.^2) .+ 1e-10
    nx = fx ./ grad_norm
    ny = fy ./ grad_norm
    nz = fz ./ grad_norm
    
    # Divergence of normal field
    div_n = imfilter(nx, Kernel.sobel)[1] .+ imfilter(ny, Kernel.sobel)[2] .+ imfilter(nz, Kernel.sobel)[3]
    
    H = -div_n ./ 2.0
    
    # Gaussian Curvature (K)
    # K = det(Hessian restricted to tangent plane)
    # Simplified approximation for volume data
    K = (fxx.*fyy .+ fyy.*fzz .+ fzz.*fxx .- fxy.^2 .- fyz.^2 .- fxz.^2) ./ (grad_norm.^2 .+ 1e-10)
    
    # Average over surface
    mean_H = mean(H[surface_mask]) / voxel_size
    mean_K = mean(K[surface_mask]) / (voxel_size^2)
    
    return mean_H, mean_K
end

"""
    compute_shannon_entropy(volume)

Compute Shannon entropy of the pore distribution.
Higher entropy = more heterogeneous/disordered structure.
"""
function compute_shannon_entropy(volume::AbstractArray)
    # Calculate local porosity in windows
    # Window size: 10x10x10 voxels
    window_size = (10, 10, 10)
    
    # Pad volume to handle boundaries
    padded = padarray(volume, Pad(:replicate, window_size))
    
    # Use mapwindow to compute local sum (porosity * volume)
    # Note: mapwindow in 3D can be slow, using simplified block processing
    
    # Block processing
    sx, sy, sz = size(volume)
    bx, by, bz = window_size
    
    local_porosities = Float64[]
    
    for z in 1:bz:sz-bz
        for y in 1:by:sy-by
            for x in 1:bx:sx-bx
                block = volume[x:x+bx-1, y:y+by-1, z:z+bz-1]
                push!(local_porosities, sum(block) / length(block))
            end
        end
    end
    
    # Histogram of local porosities
    if isempty(local_porosities)
        return 0.0
    end
    
    # Binning
    bins = 0.0:0.05:1.0
    counts = fit(Histogram, local_porosities, bins).weights
    probs = counts ./ sum(counts)
    
    # Shannon Entropy: H = -Σ p * log(p)
    entropy = -sum(p * log(p + 1e-10) for p in probs if p > 0)
    
    return entropy
end

"""
    compute_spatial_coherence(volume)

Compute spatial coherence length using autocorrelation.
"""
function compute_spatial_coherence(volume::AbstractArray)
    # 1D autocorrelation along axes
    # We take the average of X, Y, Z directions
    
    function autocorr_1d(arr)
        n = length(arr)
        mean_val = mean(arr)
        centered = arr .- mean_val
        # FFT based autocorrelation would be faster, but direct is fine for 1D slices
        # Using simple lag-1 correlation for "coherence index"
        
        num = sum(centered[1:end-1] .* centered[2:end])
        den = sum(centered.^2)
        return den > 0 ? num / den : 0.0
    end
    
    # Sample lines
    coherence_x = mean([autocorr_1d(volume[:, y, z]) for y in 1:5:size(volume,2), z in 1:5:size(volume,3)])
    coherence_y = mean([autocorr_1d(volume[x, :, z]) for x in 1:5:size(volume,1), z in 1:5:size(volume,3)])
    coherence_z = mean([autocorr_1d(volume[x, y, :]) for x in 1:5:size(volume,1), y in 1:5:size(volume,2)])
    
    return (coherence_x + coherence_y + coherence_z) / 3.0
end

# Helper for histogram
using StatsBase

end # module
