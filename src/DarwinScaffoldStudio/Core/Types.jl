"""
Type definitions for DarwinScaffoldStudio
"""

module Types

export ScaffoldMetrics, ScaffoldParameters, OptimizationResults

"""
    ScaffoldMetrics

Complete scaffold analysis metrics.

# Fields
- `porosity::Float64`: Porosity (0-1)
- `mean_pore_size_um::Float64`: Mean pore size in micrometers
- `interconnectivity::Float64`: Interconnectivity (0-1)
- `tortuosity::Float64`: Tortuosity
- `specific_surface_area::Float64`: Specific surface area (mm⁻¹)
- `elastic_modulus::Float64`: Elastic modulus (MPa)
- `yield_strength::Float64`: Yield strength (MPa)
- `permeability::Float64`: Permeability (m²)
"""
struct ScaffoldMetrics
    porosity::Float64
    mean_pore_size_um::Float64
    interconnectivity::Float64
    tortuosity::Float64
    specific_surface_area::Float64
    elastic_modulus::Float64
    yield_strength::Float64
    permeability::Float64
end

"""
    ScaffoldParameters

Scaffold design parameters for optimization.

# Fields
- `porosity_target::Float64`: Target porosity
- `pore_size_target_um::Float64`: Target pore size (μm)
- `interconnectivity_target::Float64`: Target interconnectivity
- `tortuosity_target::Float64`: Target tortuosity
- `volume_mm3::Tuple{Float64, Float64, Float64}`: Physical size (x, y, z)
- `resolution_um::Float64`: Voxel size
"""
struct ScaffoldParameters
    porosity_target::Float64
    pore_size_target_um::Float64
    interconnectivity_target::Float64
    tortuosity_target::Float64
    volume_mm3::Tuple{Float64, Float64, Float64}
    resolution_um::Float64
end

"""
    OptimizationResults

Results from scaffold optimization.

# Fields
- `optimized_volume::Array{Bool, 3}`: Optimized 3D binary volume
- `original_metrics::ScaffoldMetrics`: Original scaffold metrics
- `optimized_metrics::ScaffoldMetrics`: Optimized scaffold metrics
- `improvement_percent::Dict{String, Float64}`: Improvement percentages
- `fabrication_method::String`: Recommended fabrication method
- `fabrication_parameters::Dict{String, Any}`: Fabrication parameters
"""
struct OptimizationResults
    optimized_volume::Array{Bool, 3}
    original_metrics::ScaffoldMetrics
    optimized_metrics::ScaffoldMetrics
    improvement_percent::Dict{String, Float64}
    fabrication_method::String
    fabrication_parameters::Dict{String, Any}
end

end # module Types

