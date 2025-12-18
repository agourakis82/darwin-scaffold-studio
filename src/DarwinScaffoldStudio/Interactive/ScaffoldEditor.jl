"""
    ScaffoldEditor

Interactive 3D Scaffold Editor with Real-time Q1 Validation.

# Features
- Material-agnostic scaffold editing
- Real-time property heatmaps (porosity, stress, permeability)
- Q1 literature validation with citations
- Multi-view visualization
- Undo/redo history
- Live metrics dashboard

# Q1 Literature Base
- Murphy et al. 2010: Pore size 100-500µm for bone
- Karageorgiou & Kaplan 2005: Porosity >90%, interconnectivity >90%
- Gibson & Ashby 1997: Mechanical scaling laws
- Kuboki et al. 2001: Optimal pore geometry
- Hulbert et al. 1970: Minimum pore size 100µm
- Itälä et al. 2001: 300-400µm optimal for bone ingrowth

# Author: Dr. Demetrios Agourakis
# Master's Thesis: Tissue Engineering Scaffold Optimization
"""
module ScaffoldEditor

# Import from DarwinScaffoldStudio's submodules (Interactive is inside DarwinScaffoldStudio)
# ScaffoldEditor -> Interactive -> DarwinScaffoldStudio -> Types
using ...Types: ScaffoldMetrics, ScaffoldParameters
using ...Config: ScaffoldConfig, get_config
using LinearAlgebra
using Statistics
using Dates

export ScaffoldWorkspace, EditOperation, ValidationResult
export create_workspace, apply_operation!, undo!, redo!
export compute_heatmap, validate_q1, get_live_metrics
export PropertyMap, HeatmapType

#=============================================================================
  Q1 LITERATURE DATABASE
=============================================================================#

"""
Q1 Literature references with validated parameter ranges.
Each entry includes DOI, parameter ranges, and tissue type.
"""
const Q1_LITERATURE = Dict{String, NamedTuple}(
    "Murphy2010" => (
        doi = "10.1016/j.biomaterials.2009.09.063",
        citation = "Murphy CM, Haugh MG, O'Brien FJ. Biomaterials. 2010;31(3):461-466",
        tissue = :bone,
        porosity = (0.85, 0.95),
        pore_size_um = (100.0, 500.0),
        note = "Collagen-GAG scaffolds for bone tissue engineering"
    ),
    "Karageorgiou2005" => (
        doi = "10.1016/j.biomaterials.2005.01.016",
        citation = "Karageorgiou V, Kaplan D. Biomaterials. 2005;26(27):5474-5491",
        tissue = :bone,
        porosity = (0.90, 0.95),
        interconnectivity = (0.90, 1.0),
        pore_size_um = (100.0, 400.0),
        note = "Porosity of 3D biomaterial scaffolds and osteogenesis"
    ),
    "GibsonAshby1997" => (
        doi = "10.1017/CBO9781139878326",
        citation = "Gibson LJ, Ashby MF. Cellular Solids. Cambridge University Press. 1997",
        tissue = :general,
        modulus_exponent = 2.0,
        strength_exponent = 1.5,
        note = "Structure and properties of cellular solids"
    ),
    "Hulbert1970" => (
        doi = "10.1002/jbm.820040206",
        citation = "Hulbert SF et al. J Biomed Mater Res. 1970;4(3):433-456",
        tissue = :bone,
        min_pore_size_um = 100.0,
        note = "Minimum pore size for bone ingrowth"
    ),
    "Itala2001" => (
        doi = "10.1002/jbm.1046",
        citation = "Itälä AI et al. J Biomed Mater Res. 2001;58(6):679-683",
        tissue = :bone,
        optimal_pore_size_um = (300.0, 400.0),
        note = "Pore diameter of more than 100µm is not requisite for bone ingrowth"
    ),
    "Kuboki2001" => (
        doi = "10.1023/A:1011256903702",
        citation = "Kuboki Y et al. Connect Tissue Res. 2001;42(4):251-260",
        tissue = :bone,
        geometry = :interconnected,
        note = "Geometry of carriers controlling BMP-induced differentiation"
    ),
    "OBrien2005" => (
        doi = "10.1016/j.biomaterials.2004.02.055",
        citation = "O'Brien FJ et al. Biomaterials. 2005;26(4):433-441",
        tissue = :bone,
        pore_size_um = (96.0, 150.0),
        note = "Effect of pore size on cell adhesion"
    ),
    "Loh2013" => (
        doi = "10.1016/j.tibtech.2012.12.002",
        citation = "Loh QL, Choong C. Tissue Eng Part B. 2013;19(6):485-502",
        tissue = :general,
        porosity = (0.50, 0.95),
        pore_size_um = (50.0, 500.0),
        note = "Three-dimensional scaffolds for tissue engineering"
    ),
    "Hollister2005" => (
        doi = "10.1038/nmat1421",
        citation = "Hollister SJ. Nat Mater. 2005;4(7):518-524",
        tissue = :general,
        note = "Porous scaffold design for tissue engineering"
    )
)

"""
Material database with mechanical properties and OBO Foundry annotations.

OBO References:
- CHEBI: Chemical Entities of Biological Interest
- CAS: Chemical Abstracts Service Registry Number
"""
const MATERIAL_DATABASE = Dict{String, NamedTuple}(
    "PCL" => (
        name = "Poly(ε-caprolactone)",
        chebi_id = "CHEBI:53310",
        cas = "24980-41-4",
        E_solid_MPa = 400.0,
        σ_solid_MPa = 25.0,
        ρ_solid_kg_m3 = 1145.0,
        degradation_months = (24, 36),
        biocompatibility = :excellent,
        fda_approved = true
    ),
    "PLA" => (
        name = "Poly(lactic acid)",
        chebi_id = "CHEBI:53309",
        cas = "26100-51-6",
        E_solid_MPa = 3500.0,
        σ_solid_MPa = 55.0,
        ρ_solid_kg_m3 = 1240.0,
        degradation_months = (12, 24),
        biocompatibility = :excellent,
        fda_approved = true
    ),
    "PLGA" => (
        name = "Poly(lactic-co-glycolic acid)",
        chebi_id = "CHEBI:53426",
        cas = "26780-50-7",
        E_solid_MPa = 2000.0,
        σ_solid_MPa = 45.0,
        ρ_solid_kg_m3 = 1300.0,
        degradation_months = (1, 6),
        biocompatibility = :excellent,
        fda_approved = true
    ),
    "Collagen" => (
        name = "Type I Collagen",
        chebi_id = "CHEBI:3815",
        cas = "9007-34-5",
        E_solid_MPa = 5.0,
        σ_solid_MPa = 1.0,
        ρ_solid_kg_m3 = 1350.0,
        degradation_months = (1, 3),
        biocompatibility = :excellent,
        fda_approved = true
    ),
    "Hydrogel_PEG" => (
        name = "PEG Hydrogel",
        chebi_id = "CHEBI:46793",
        cas = "25322-68-3",
        E_solid_MPa = 0.1,
        σ_solid_MPa = 0.05,
        ρ_solid_kg_m3 = 1050.0,
        degradation_months = (1, 12),
        biocompatibility = :excellent,
        fda_approved = true
    ),
    "HA_TCP" => (
        name = "Hydroxyapatite/TCP Ceramic",
        chebi_id = "CHEBI:52251",  # Hydroxyapatite
        cas = "1306-06-5",
        E_solid_MPa = 15000.0,
        σ_solid_MPa = 40.0,
        ρ_solid_kg_m3 = 3150.0,
        degradation_months = (36, 120),
        biocompatibility = :excellent,
        fda_approved = true
    ),
    "Ti6Al4V" => (
        name = "Titanium Alloy",
        chebi_id = "CHEBI:33341",  # Titanium
        cas = "7440-32-6",
        E_solid_MPa = 110000.0,
        σ_solid_MPa = 900.0,
        ρ_solid_kg_m3 = 4430.0,
        degradation_months = nothing,  # Non-degradable
        biocompatibility = :excellent,
        fda_approved = true
    ),
    "BioactiveGlass_45S5" => (
        name = "Bioglass 45S5",
        chebi_id = "CHEBI:52254",
        cas = nothing,  # Composite material
        E_solid_MPa = 35000.0,
        σ_solid_MPa = 42.0,
        ρ_solid_kg_m3 = 2700.0,
        degradation_months = (6, 24),
        biocompatibility = :excellent,
        fda_approved = true
    ),
    # Additional materials with OBO annotations
    "Chitosan" => (
        name = "Chitosan",
        chebi_id = "CHEBI:16737",
        cas = "9012-76-4",
        E_solid_MPa = 2.0,
        σ_solid_MPa = 0.5,
        ρ_solid_kg_m3 = 1400.0,
        degradation_months = (3, 12),
        biocompatibility = :excellent,
        fda_approved = true
    ),
    "Alginate" => (
        name = "Alginate",
        chebi_id = "CHEBI:52747",
        cas = "9005-38-3",
        E_solid_MPa = 0.05,
        σ_solid_MPa = 0.02,
        ρ_solid_kg_m3 = 1600.0,
        degradation_months = (1, 6),
        biocompatibility = :excellent,
        fda_approved = true
    ),
    "Fibrin" => (
        name = "Fibrin",
        chebi_id = "CHEBI:18237",
        cas = "9001-31-4",
        E_solid_MPa = 0.02,
        σ_solid_MPa = 0.01,
        ρ_solid_kg_m3 = 1100.0,
        degradation_months = (0.5, 2),
        biocompatibility = :excellent,
        fda_approved = true
    ),
    "HyaluronicAcid" => (
        name = "Hyaluronic Acid",
        chebi_id = "CHEBI:18154",
        cas = "9004-61-9",
        E_solid_MPa = 0.01,
        σ_solid_MPa = 0.005,
        ρ_solid_kg_m3 = 1200.0,
        degradation_months = (0.25, 3),
        biocompatibility = :excellent,
        fda_approved = true
    ),
    "Gelatin" => (
        name = "Gelatin (Methacrylated)",
        chebi_id = "CHEBI:28512",
        cas = "9000-70-8",
        E_solid_MPa = 0.1,
        σ_solid_MPa = 0.05,
        ρ_solid_kg_m3 = 1300.0,
        degradation_months = (1, 6),
        biocompatibility = :excellent,
        fda_approved = true
    )
)

"""
Tissue target mapping to OBO UBERON terms.
"""
const TISSUE_OBO_MAP = Dict{Symbol, NamedTuple}(
    :bone => (
        uberon_id = "UBERON:0002481",
        name = "bone tissue",
        cell_types = ["CL:0000062", "CL:0000137", "CL:0000222"],  # osteoblast, osteocyte, MSC
        go_processes = ["GO:0001503", "GO:0030282"]  # ossification, bone mineralization
    ),
    :cartilage => (
        uberon_id = "UBERON:0002418",
        name = "cartilage tissue",
        cell_types = ["CL:0000138", "CL:0000222"],  # chondrocyte, MSC
        go_processes = ["GO:0051216"]  # cartilage development
    ),
    :skin => (
        uberon_id = "UBERON:0002097",
        name = "skin of body",
        cell_types = ["CL:0000312", "CL:0000057"],  # keratinocyte, fibroblast
        go_processes = ["GO:0042060"]  # wound healing
    ),
    :neural => (
        uberon_id = "UBERON:0001017",
        name = "central nervous system",
        cell_types = ["CL:0000540", "CL:0000127", "CL:0002573"],  # neuron, astrocyte, Schwann
        go_processes = []
    ),
    :vascular => (
        uberon_id = "UBERON:0001981",
        name = "blood vessel",
        cell_types = ["CL:0000115", "CL:0000192"],  # endothelial, smooth muscle
        go_processes = ["GO:0001525"]  # angiogenesis
    ),
    :cardiac => (
        uberon_id = "UBERON:0001133",
        name = "cardiac muscle tissue",
        cell_types = ["CL:0000746"],  # cardiomyocyte
        go_processes = []
    ),
    :tendon => (
        uberon_id = "UBERON:0006590",
        name = "tendon",
        cell_types = ["CL:0000057"],  # fibroblast
        go_processes = ["GO:0030198"]  # ECM organization
    ),
    :liver => (
        uberon_id = "UBERON:0002107",
        name = "liver",
        cell_types = [],
        go_processes = []
    )
)

#=============================================================================
  HEATMAP TYPES
=============================================================================#

@enum HeatmapType begin
    POROSITY_LOCAL      # Local porosity distribution
    STRESS_VONMISES     # Von Mises stress under load
    PERMEABILITY        # Local permeability (Kozeny-Carman)
    CURVATURE_MEAN      # Mean curvature (cell attachment)
    CURVATURE_GAUSSIAN  # Gaussian curvature (topology)
    PORE_SIZE           # Local pore size (distance transform)
    WALL_THICKNESS      # Strut/wall thickness
    INTERCONNECTIVITY   # Local connectivity
    TORTUOSITY          # Path tortuosity from surface
    NUTRIENT_DIFFUSION  # Steady-state nutrient concentration
    CELL_MIGRATION      # Predicted cell migration potential
end

"""
    PropertyMap

3D scalar field mapped to scaffold volume.
"""
struct PropertyMap
    data::Array{Float64, 3}
    property_type::HeatmapType
    min_value::Float64
    max_value::Float64
    unit::String
    colormap::Symbol  # :viridis, :plasma, :inferno, :bone, :jet
end

#=============================================================================
  EDIT OPERATIONS
=============================================================================#

"""
Edit operation types for undo/redo.
"""
@enum EditType begin
    ADD_MATERIAL        # Add solid voxels
    REMOVE_MATERIAL     # Remove voxels (create pores)
    SMOOTH_SURFACE      # Morphological smoothing
    ERODE               # Morphological erosion
    DILATE              # Morphological dilation
    SET_REGION          # Set region to value
    APPLY_PATTERN       # Apply periodic pattern (TPMS, lattice)
    CHANGE_MATERIAL     # Change material type
    SCALE_UNIFORM       # Uniform scaling
    SCALE_ANISOTROPIC   # Directional scaling
end

"""
    EditOperation

Single atomic edit operation with full state for undo.
"""
struct EditOperation
    id::Int
    type::EditType
    timestamp::DateTime
    parameters::Dict{String, Any}
    affected_region::Tuple{UnitRange{Int}, UnitRange{Int}, UnitRange{Int}}
    before_state::Union{Array{Bool, 3}, Nothing}  # For undo (compressed)
    metrics_before::Union{ScaffoldMetrics, Nothing}
    metrics_after::Union{ScaffoldMetrics, Nothing}
end

#=============================================================================
  VALIDATION RESULT
=============================================================================#

"""
    ValidationResult

Q1 literature validation result with detailed feedback.
"""
struct ValidationResult
    is_valid::Bool
    score::Float64  # 0-100

    # Individual validations
    porosity_valid::Bool
    porosity_score::Float64
    porosity_refs::Vector{String}

    pore_size_valid::Bool
    pore_size_score::Float64
    pore_size_refs::Vector{String}

    interconnectivity_valid::Bool
    interconnectivity_score::Float64
    interconnectivity_refs::Vector{String}

    mechanical_valid::Bool
    mechanical_score::Float64
    mechanical_refs::Vector{String}

    # Recommendations
    recommendations::Vector{String}
    citations::Vector{String}

    # Target tissue
    tissue_type::Symbol
end

#=============================================================================
  SCAFFOLD WORKSPACE
=============================================================================#

"""
    ScaffoldWorkspace

Main editing workspace with history and validation.
"""
mutable struct ScaffoldWorkspace
    # Scaffold data
    volume::Array{Bool, 3}
    voxel_size_um::Float64
    material::String
    tissue_target::Symbol  # :bone, :cartilage, :skin, :neural, :vascular

    # Dimensions
    dims_mm::Tuple{Float64, Float64, Float64}

    # Current metrics (cached)
    metrics::ScaffoldMetrics
    validation::ValidationResult

    # Property maps (lazy computed)
    property_maps::Dict{HeatmapType, PropertyMap}

    # Edit history
    operations::Vector{EditOperation}
    current_op_idx::Int  # For undo/redo
    max_history::Int

    # Metadata
    name::String
    created::DateTime
    modified::DateTime

    function ScaffoldWorkspace(volume::Array{Bool, 3};
                               voxel_size_um::Float64=10.0,
                               material::String="PCL",
                               tissue::Symbol=:bone,
                               name::String="Untitled")
        dims = size(volume)
        dims_mm = (dims[1] * voxel_size_um / 1000,
                   dims[2] * voxel_size_um / 1000,
                   dims[3] * voxel_size_um / 1000)

        # Compute initial metrics
        metrics = compute_scaffold_metrics(volume, voxel_size_um, material)

        # Initial validation
        validation = validate_q1(metrics, tissue)

        new(volume, voxel_size_um, material, tissue,
            dims_mm, metrics, validation,
            Dict{HeatmapType, PropertyMap}(),
            EditOperation[], 0, 50,
            name, now(), now())
    end
end

"""
    create_workspace(volume; kwargs...) -> ScaffoldWorkspace

Create a new scaffold editing workspace.
"""
function create_workspace(volume::Array{Bool, 3}; kwargs...)
    ScaffoldWorkspace(volume; kwargs...)
end

"""
    create_workspace(dims::Tuple{Int,Int,Int}; porosity=0.7, method=:random) -> ScaffoldWorkspace

Create workspace with generated scaffold.
"""
function create_workspace(dims::Tuple{Int,Int,Int};
                         porosity::Float64=0.7,
                         pore_size_um::Float64=200.0,
                         method::Symbol=:random,
                         kwargs...)
    volume = generate_scaffold(dims, porosity, pore_size_um, method)
    ScaffoldWorkspace(volume; kwargs...)
end

#=============================================================================
  SCAFFOLD GENERATION
=============================================================================#

"""
    generate_scaffold(dims, porosity, pore_size, method) -> Array{Bool,3}

Generate scaffold with specified parameters.
Methods: :random, :gyroid, :diamond, :primitive, :lattice
"""
function generate_scaffold(dims::Tuple{Int,Int,Int},
                          porosity::Float64,
                          pore_size_um::Float64,
                          method::Symbol)
    volume = Array{Bool, 3}(undef, dims)

    if method == :random
        # Random distribution with target porosity
        threshold = 1.0 - porosity
        for i in eachindex(volume)
            volume[i] = rand() > threshold
        end

    elseif method == :gyroid
        # Gyroid TPMS: f(x,y,z) = sin(x)cos(y) + sin(y)cos(z) + sin(z)cos(x)
        # Range: approximately [-1.5, 1.5]
        # Solid where f > t (isovalue threshold)
        values = zeros(Float64, dims)
        for i in 1:dims[1], j in 1:dims[2], k in 1:dims[3]
            x = 2π * i / dims[1]
            y = 2π * j / dims[2]
            z = 2π * k / dims[3]
            values[i,j,k] = sin(x)*cos(y) + sin(y)*cos(z) + sin(z)*cos(x)
        end
        t = compute_threshold_for_porosity(values, porosity)
        volume .= values .> t

    elseif method == :diamond
        # Diamond TPMS: f = cos(x)cos(y)cos(z) - sin(x)sin(y)sin(z)
        # Range: approximately [-1, 1]
        values = zeros(Float64, dims)
        for i in 1:dims[1], j in 1:dims[2], k in 1:dims[3]
            x = 2π * i / dims[1]
            y = 2π * j / dims[2]
            z = 2π * k / dims[3]
            values[i,j,k] = cos(x)*cos(y)*cos(z) - sin(x)*sin(y)*sin(z)
        end
        t = compute_threshold_for_porosity(values, porosity)
        volume .= values .> t

    elseif method == :primitive
        # Schwarz P (Primitive): f = cos(x) + cos(y) + cos(z)
        # Range: [-3, 3]
        values = zeros(Float64, dims)
        for i in 1:dims[1], j in 1:dims[2], k in 1:dims[3]
            x = 2π * i / dims[1]
            y = 2π * j / dims[2]
            z = 2π * k / dims[3]
            values[i,j,k] = cos(x) + cos(y) + cos(z)
        end
        t = compute_threshold_for_porosity(values, porosity)
        volume .= values .> t

    elseif method == :lattice
        # Regular cubic lattice
        strut_width = max(1, round(Int, (1.0 - porosity) * minimum(dims) / 8))
        period = max(strut_width + 2, round(Int, minimum(dims) / 4))

        for i in 1:dims[1], j in 1:dims[2], k in 1:dims[3]
            on_strut_x = (i % period) < strut_width
            on_strut_y = (j % period) < strut_width
            on_strut_z = (k % period) < strut_width

            volume[i,j,k] = (on_strut_x && on_strut_y) ||
                           (on_strut_y && on_strut_z) ||
                           (on_strut_x && on_strut_z)
        end
    else
        error("Unknown generation method: $method")
    end

    volume
end

"""
Compute threshold to achieve target porosity using quantile.
Solid fraction = 1 - porosity, so we need that fraction of voxels above threshold.
"""
function compute_threshold_for_porosity(values::Array{Float64, 3}, porosity::Float64)
    # We want (1-porosity) fraction of voxels to be solid (above threshold)
    # So threshold should be at quantile = porosity
    sorted_values = sort(vec(values))
    idx = max(1, round(Int, porosity * length(sorted_values)))
    sorted_values[idx]
end

#=============================================================================
  METRICS COMPUTATION
=============================================================================#

"""
    compute_scaffold_metrics(volume, voxel_size, material) -> ScaffoldMetrics

Compute all scaffold metrics with material-specific mechanical properties.
"""
function compute_scaffold_metrics(volume::Array{Bool, 3},
                                  voxel_size_um::Float64,
                                  material::String)
    # Basic morphology
    total_voxels = length(volume)
    solid_voxels = sum(volume)
    porosity = 1.0 - solid_voxels / total_voxels
    relative_density = 1.0 - porosity

    # Pore size via distance transform (simplified)
    pore_mask = .!volume  # Element-wise negation
    pore_distances = compute_distance_transform(pore_mask)
    mean_pore_size = mean(filter(x -> x > 0, pore_distances)) * voxel_size_um * 2

    # Interconnectivity via connected components
    interconnectivity = compute_interconnectivity(volume)

    # Tortuosity (Gibson-Ashby approximation)
    tortuosity = 1.0 + 0.5 * relative_density

    # Surface area
    surface_voxels = count_surface_voxels(volume)
    specific_surface_area = surface_voxels * (voxel_size_um * 1e-6)^2 /
                           (total_voxels * (voxel_size_um * 1e-6)^3)

    # Material-specific mechanical properties
    mat = get(MATERIAL_DATABASE, material, MATERIAL_DATABASE["PCL"])

    # Gibson-Ashby scaling
    E_scaffold = mat.E_solid_MPa * relative_density^2
    σ_scaffold = mat.σ_solid_MPa * relative_density^1.5

    # Kozeny-Carman permeability
    d_pore = mean_pore_size * 1e-6  # Convert to meters
    permeability = (porosity^3 * d_pore^2) / (180 * (1 - porosity)^2)

    ScaffoldMetrics(
        porosity,
        mean_pore_size,
        interconnectivity,
        tortuosity,
        specific_surface_area,
        E_scaffold,
        σ_scaffold,
        permeability
    )
end

"""
    compute_distance_transform(mask::AbstractArray{Bool, 3}) -> Array{Float64, 3}

Compute Euclidean Distance Transform using Meijster's linear-time algorithm.
Returns distance to nearest false voxel for each true voxel (0 for false voxels).

Complexity: O(n³) instead of naive O(n³ × r³)

Reference: Meijster et al. (2000) "A General Algorithm for Computing Distance
Transforms in Linear Time"
"""
function compute_distance_transform(mask::AbstractArray{Bool, 3})
    dims = size(mask)
    INF = sum(dims)^2  # Squared infinity (larger than any possible squared distance)

    # Work with squared distances, take sqrt at the end
    G = fill(INF, dims)

    # Phase 1: Transform along first dimension (x)
    for j in 1:dims[2], k in 1:dims[3]
        # Forward scan
        if !mask[1, j, k]
            G[1, j, k] = 0
        end
        for i in 2:dims[1]
            if !mask[i, j, k]
                G[i, j, k] = 0
            else
                G[i, j, k] = G[i-1, j, k] + 1
            end
        end
        # Backward scan
        for i in (dims[1]-1):-1:1
            if G[i+1, j, k] < G[i, j, k]
                G[i, j, k] = G[i+1, j, k] + 1
            end
        end
    end

    # Phase 2: Transform along second dimension (y)
    # Uses Voronoi-based optimization
    G2 = fill(INF, dims)
    for i in 1:dims[1], k in 1:dims[3]
        _edt_voronoi_1d!(view(G, i, :, k), view(G2, i, :, k), dims[2])
    end

    # Phase 3: Transform along third dimension (z)
    result = zeros(Float64, dims)
    for i in 1:dims[1], j in 1:dims[2]
        _edt_voronoi_1d!(view(G2, i, j, :), view(result, i, j, :), dims[3])
    end

    # Convert squared distances to actual distances
    @. result = sqrt(result)

    return result
end

"""
Helper: 1D Voronoi-based distance transform (Meijster algorithm phase 2/3)
Transforms squared distances along one dimension.
"""
function _edt_voronoi_1d!(g::AbstractVector, dt::AbstractVector, n::Int)
    INF = n^2 * 4  # Large value

    # Parabola positions and intersection points
    s = zeros(Int, n)    # Voronoi sites (positions of parabola vertices)
    t = zeros(Float64, n+1)  # Intersection points between parabolas

    q = 0  # Number of parabolas in lower envelope

    # Build lower envelope of parabolas
    for u in 1:n
        gu = g[u]
        if gu >= INF
            continue
        end

        # f(x, u) = (x - u)² + g[u]²
        # Find where parabola u intersects with rightmost parabola in envelope
        while q > 0
            v = s[q]
            gv = g[v]
            # Intersection of parabolas at u and v:
            # (x-u)² + gu² = (x-v)² + gv²
            # x = (u² + gu² - v² - gv²) / (2(u-v))
            sep = ((u^2 + gu^2) - (v^2 + gv^2)) / (2.0 * (u - v))

            if sep > t[q]
                break
            end
            q -= 1
        end

        q += 1
        s[q] = u
        if q == 1
            t[q] = -Inf
        else
            v = s[q-1]
            gv = g[v]
            t[q] = ((u^2 + gu^2) - (v^2 + gv^2)) / (2.0 * (u - v))
        end
        t[q+1] = Inf
    end

    if q == 0
        # All values were INF - no valid parabolas
        fill!(dt, INF)
        return
    end

    # Scan and compute distance transform
    k = 1
    for u in 1:n
        while t[k+1] < u
            k += 1
        end
        v = s[k]
        dt[u] = (u - v)^2 + g[v]^2
    end
end

function compute_interconnectivity(volume::Array{Bool, 3})
    # Ratio of largest connected pore component to total pore volume
    # Uses flood-fill from boundary surfaces (more realistic for permeability)
    pore_mask = .!volume
    total_pore = sum(pore_mask)

    if total_pore == 0
        return 0.0
    end

    dims = size(volume)
    visited = falses(dims)

    # Find seed points: pore voxels on any boundary face
    seed_points = Tuple{Int,Int,Int}[]

    # Top and bottom faces (z=1 and z=dims[3])
    for i in 1:dims[1], j in 1:dims[2]
        if pore_mask[i, j, 1]
            push!(seed_points, (i, j, 1))
        end
        if pore_mask[i, j, dims[3]]
            push!(seed_points, (i, j, dims[3]))
        end
    end

    # Left and right faces (x=1 and x=dims[1])
    for j in 1:dims[2], k in 1:dims[3]
        if pore_mask[1, j, k]
            push!(seed_points, (1, j, k))
        end
        if pore_mask[dims[1], j, k]
            push!(seed_points, (dims[1], j, k))
        end
    end

    # Front and back faces (y=1 and y=dims[2])
    for i in 1:dims[1], k in 1:dims[3]
        if pore_mask[i, 1, k]
            push!(seed_points, (i, 1, k))
        end
        if pore_mask[i, dims[2], k]
            push!(seed_points, (i, dims[2], k))
        end
    end

    if isempty(seed_points)
        return 0.0  # No pores on surfaces = closed porosity
    end

    # Flood fill from all boundary seed points
    stack = copy(seed_points)
    connected = 0

    while !isempty(stack)
        pos = pop!(stack)
        i, j, k = pos

        if i < 1 || i > dims[1] || j < 1 || j > dims[2] || k < 1 || k > dims[3]
            continue
        end

        if visited[i,j,k] || volume[i,j,k]
            continue
        end

        visited[i,j,k] = true
        connected += 1

        # 6-connectivity for pore network
        push!(stack, (i+1,j,k))
        push!(stack, (i-1,j,k))
        push!(stack, (i,j+1,k))
        push!(stack, (i,j-1,k))
        push!(stack, (i,j,k+1))
        push!(stack, (i,j,k-1))
    end

    connected / total_pore
end

function count_surface_voxels(volume::Array{Bool, 3})
    dims = size(volume)
    count = 0

    for i in 1:dims[1], j in 1:dims[2], k in 1:dims[3]
        if volume[i,j,k]
            # Check if any neighbor is pore
            is_surface = false
            for (di, dj, dk) in [(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(0,0,1),(0,0,-1)]
                ni, nj, nk = i+di, j+dj, k+dk
                if ni < 1 || ni > dims[1] || nj < 1 || nj > dims[2] || nk < 1 || nk > dims[3]
                    is_surface = true
                    break
                elseif !volume[ni, nj, nk]
                    is_surface = true
                    break
                end
            end
            if is_surface
                count += 1
            end
        end
    end

    count
end

#=============================================================================
  Q1 VALIDATION
=============================================================================#

"""
    validate_q1(metrics::ScaffoldMetrics, tissue::Symbol) -> ValidationResult

Validate scaffold against Q1 literature for target tissue.
Returns detailed validation with citations and recommendations.
"""
function validate_q1(metrics::ScaffoldMetrics, tissue::Symbol)
    recommendations = String[]
    citations = String[]

    # Get tissue-specific requirements
    requirements = get_tissue_requirements(tissue)

    # Porosity validation
    porosity_valid = requirements.porosity_min <= metrics.porosity <= requirements.porosity_max
    porosity_score = if porosity_valid
        100.0
    else
        dist = min(abs(metrics.porosity - requirements.porosity_min),
                   abs(metrics.porosity - requirements.porosity_max))
        max(0, 100 - dist * 500)
    end
    porosity_refs = ["Karageorgiou2005", "Loh2013"]

    if !porosity_valid
        if metrics.porosity < requirements.porosity_min
            push!(recommendations,
                "Increase porosity from $(round(metrics.porosity*100, digits=1))% to ≥$(requirements.porosity_min*100)% (Karageorgiou & Kaplan, 2005)")
        else
            push!(recommendations,
                "Decrease porosity from $(round(metrics.porosity*100, digits=1))% to ≤$(requirements.porosity_max*100)% for mechanical integrity")
        end
    end

    # Pore size validation
    pore_size_valid = requirements.pore_size_min <= metrics.mean_pore_size_um <= requirements.pore_size_max
    pore_size_score = if pore_size_valid
        100.0
    else
        dist = min(abs(metrics.mean_pore_size_um - requirements.pore_size_min),
                   abs(metrics.mean_pore_size_um - requirements.pore_size_max))
        max(0, 100 - dist * 0.5)
    end
    pore_size_refs = ["Murphy2010", "Hulbert1970", "Itala2001"]

    if !pore_size_valid
        push!(recommendations,
            "Adjust pore size from $(round(metrics.mean_pore_size_um, digits=1))µm to $(requirements.pore_size_min)-$(requirements.pore_size_max)µm range (Murphy et al., 2010)")
    end

    # Interconnectivity validation
    interconnectivity_valid = metrics.interconnectivity >= requirements.interconnectivity_min
    interconnectivity_score = min(100, metrics.interconnectivity / requirements.interconnectivity_min * 100)
    interconnectivity_refs = ["Karageorgiou2005", "Kuboki2001"]

    if !interconnectivity_valid
        push!(recommendations,
            "Improve interconnectivity from $(round(metrics.interconnectivity*100, digits=1))% to ≥$(requirements.interconnectivity_min*100)% for nutrient transport")
    end

    # Mechanical validation (tissue-specific)
    mechanical_valid = metrics.elastic_modulus >= requirements.E_min_MPa
    mechanical_score = min(100, metrics.elastic_modulus / requirements.E_min_MPa * 100)
    mechanical_refs = ["GibsonAshby1997"]

    if !mechanical_valid
        push!(recommendations,
            "Increase mechanical stiffness from $(round(metrics.elastic_modulus, digits=1))MPa to ≥$(requirements.E_min_MPa)MPa")
    end

    # Collect citations
    for ref in unique([porosity_refs; pore_size_refs; interconnectivity_refs; mechanical_refs])
        if haskey(Q1_LITERATURE, ref)
            push!(citations, Q1_LITERATURE[ref].citation)
        end
    end

    # Overall score
    overall_score = (porosity_score * 0.25 + pore_size_score * 0.30 +
                    interconnectivity_score * 0.25 + mechanical_score * 0.20)
    is_valid = porosity_valid && pore_size_valid && interconnectivity_valid && mechanical_valid

    ValidationResult(
        is_valid, overall_score,
        porosity_valid, porosity_score, porosity_refs,
        pore_size_valid, pore_size_score, pore_size_refs,
        interconnectivity_valid, interconnectivity_score, interconnectivity_refs,
        mechanical_valid, mechanical_score, mechanical_refs,
        recommendations, unique(citations),
        tissue
    )
end

"""
Get tissue-specific parameter requirements from Q1 literature.
"""
function get_tissue_requirements(tissue::Symbol)
    if tissue == :bone
        (
            porosity_min = 0.70,
            porosity_max = 0.95,
            pore_size_min = 100.0,
            pore_size_max = 500.0,
            interconnectivity_min = 0.90,
            E_min_MPa = 10.0,  # Trabecular bone modulus range
            refs = ["Murphy2010", "Karageorgiou2005", "Hulbert1970"]
        )
    elseif tissue == :cartilage
        (
            porosity_min = 0.80,
            porosity_max = 0.95,
            pore_size_min = 150.0,
            pore_size_max = 500.0,
            interconnectivity_min = 0.85,
            E_min_MPa = 0.5,  # Cartilage is softer
            refs = ["Loh2013"]
        )
    elseif tissue == :skin
        (
            porosity_min = 0.70,
            porosity_max = 0.90,
            pore_size_min = 50.0,
            pore_size_max = 200.0,
            interconnectivity_min = 0.80,
            E_min_MPa = 0.1,
            refs = ["Loh2013"]
        )
    elseif tissue == :neural
        (
            porosity_min = 0.85,
            porosity_max = 0.95,
            pore_size_min = 10.0,
            pore_size_max = 100.0,
            interconnectivity_min = 0.95,  # Critical for axon guidance
            E_min_MPa = 0.01,  # Very soft
            refs = ["Loh2013"]
        )
    elseif tissue == :vascular
        (
            porosity_min = 0.70,
            porosity_max = 0.85,
            pore_size_min = 100.0,
            pore_size_max = 300.0,
            interconnectivity_min = 0.95,  # Must allow blood flow
            E_min_MPa = 0.5,
            refs = ["Loh2013", "Hollister2005"]
        )
    else
        # General tissue engineering defaults
        (
            porosity_min = 0.70,
            porosity_max = 0.95,
            pore_size_min = 100.0,
            pore_size_max = 400.0,
            interconnectivity_min = 0.85,
            E_min_MPa = 1.0,
            refs = ["Loh2013", "Hollister2005"]
        )
    end
end

#=============================================================================
  HEATMAP COMPUTATION
=============================================================================#

"""
    compute_heatmap(workspace::ScaffoldWorkspace, type::HeatmapType) -> PropertyMap

Compute property heatmap for visualization.
"""
function compute_heatmap(workspace::ScaffoldWorkspace, type::HeatmapType)
    # Check cache
    if haskey(workspace.property_maps, type)
        return workspace.property_maps[type]
    end

    volume = workspace.volume
    voxel_size = workspace.voxel_size_um
    dims = size(volume)

    data = if type == POROSITY_LOCAL
        compute_local_porosity(volume, kernel_size=5)
    elseif type == STRESS_VONMISES
        compute_stress_field(volume, workspace.material, voxel_size)
    elseif type == PERMEABILITY
        compute_permeability_field(volume, voxel_size)
    elseif type == CURVATURE_MEAN
        compute_mean_curvature_field(volume)
    elseif type == CURVATURE_GAUSSIAN
        compute_gaussian_curvature_field(volume)
    elseif type == PORE_SIZE
        compute_distance_transform(.!volume) .* voxel_size .* 2
    elseif type == WALL_THICKNESS
        compute_distance_transform(volume) .* voxel_size .* 2
    elseif type == INTERCONNECTIVITY
        compute_local_connectivity(volume)
    elseif type == TORTUOSITY
        compute_tortuosity_field(volume)
    elseif type == NUTRIENT_DIFFUSION
        compute_diffusion_field(volume)
    elseif type == CELL_MIGRATION
        compute_migration_potential(volume, voxel_size)
    else
        zeros(Float64, dims)
    end

    min_val = minimum(filter(!isnan, data))
    max_val = maximum(filter(!isnan, data))

    unit = get_unit_for_property(type)
    colormap = get_colormap_for_property(type)

    property_map = PropertyMap(data, type, min_val, max_val, unit, colormap)
    workspace.property_maps[type] = property_map

    property_map
end

function compute_local_porosity(volume::Array{Bool, 3}; kernel_size::Int=5)
    dims = size(volume)
    result = zeros(Float64, dims)
    half_k = kernel_size ÷ 2

    for i in 1:dims[1], j in 1:dims[2], k in 1:dims[3]
        count = 0
        total = 0
        for di in -half_k:half_k, dj in -half_k:half_k, dk in -half_k:half_k
            ni, nj, nk = i+di, j+dj, k+dk
            if 1 <= ni <= dims[1] && 1 <= nj <= dims[2] && 1 <= nk <= dims[3]
                total += 1
                if !volume[ni, nj, nk]
                    count += 1
                end
            end
        end
        result[i,j,k] = count / total
    end

    result
end

function compute_stress_field(volume::Array{Bool, 3}, material::String, voxel_size::Float64)
    # Simplified stress approximation using distance from surface
    # Real implementation would use FEM
    mat = get(MATERIAL_DATABASE, material, MATERIAL_DATABASE["PCL"])

    dims = size(volume)
    stress = zeros(Float64, dims)

    # Distance from surface approximates stress concentration
    wall_dist = compute_distance_transform(volume)

    for i in eachindex(volume)
        if volume[i]
            # Stress inversely proportional to wall thickness
            thickness = wall_dist[i] * voxel_size * 2
            if thickness > 0
                # Simplified: stress = σ_0 * (1 + 2/t) where t is normalized thickness
                stress[i] = mat.σ_solid_MPa * (1 + 2.0 / max(thickness/100, 0.1))
            end
        end
    end

    stress
end

function compute_permeability_field(volume::Array{Bool, 3}, voxel_size::Float64)
    # Local permeability using Kozeny-Carman
    local_porosity = compute_local_porosity(volume, kernel_size=7)
    pore_size = compute_distance_transform(.!volume) .* voxel_size .* 2

    dims = size(volume)
    perm = zeros(Float64, dims)

    for i in eachindex(volume)
        ε = local_porosity[i]
        d = pore_size[i] * 1e-6  # Convert to meters

        if ε > 0.01 && ε < 0.99 && d > 0
            perm[i] = (ε^3 * d^2) / (180 * (1 - ε)^2)
        end
    end

    perm
end

function compute_mean_curvature_field(volume::Array{Bool, 3})
    dims = size(volume)
    curvature = zeros(Float64, dims)

    # Sobel gradients for normal estimation
    for i in 2:dims[1]-1, j in 2:dims[2]-1, k in 2:dims[3]-1
        if volume[i,j,k]
            # Check if surface voxel
            is_surface = false
            for (di, dj, dk) in [(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(0,0,1),(0,0,-1)]
                if !volume[i+di, j+dj, k+dk]
                    is_surface = true
                    break
                end
            end

            if is_surface
                # Estimate curvature from local neighborhood
                neighbors = 0
                for di in -1:1, dj in -1:1, dk in -1:1
                    if volume[i+di, j+dj, k+dk]
                        neighbors += 1
                    end
                end
                # More neighbors = flatter surface = lower curvature
                curvature[i,j,k] = (27 - neighbors) / 27.0
            end
        end
    end

    curvature
end

function compute_gaussian_curvature_field(volume::Array{Bool, 3})
    # Simplified Gaussian curvature approximation
    mean_curv = compute_mean_curvature_field(volume)
    return mean_curv .^ 2  # Approximation
end

function compute_local_connectivity(volume::Array{Bool, 3})
    # Local connectivity: ratio of pore voxels reachable from each point
    dims = size(volume)
    connectivity = zeros(Float64, dims)

    # For each pore voxel, count connected neighbors
    for i in 2:dims[1]-1, j in 2:dims[2]-1, k in 2:dims[3]-1
        if !volume[i,j,k]
            connected = 0
            total = 0
            for di in -1:1, dj in -1:1, dk in -1:1
                if !(di == 0 && dj == 0 && dk == 0)
                    total += 1
                    if !volume[i+di, j+dj, k+dk]
                        connected += 1
                    end
                end
            end
            connectivity[i,j,k] = connected / total
        end
    end

    connectivity
end

function compute_tortuosity_field(volume::Array{Bool, 3})
    # Distance-based tortuosity from top surface
    dims = size(volume)

    # Start from top surface pores
    pore_mask = .!volume

    # Geodesic distance through pores
    geo_dist = fill(Inf, dims)
    eucl_dist = fill(Inf, dims)

    # Initialize from top surface
    for i in 1:dims[1], j in 1:dims[2]
        if pore_mask[i, j, 1]
            geo_dist[i, j, 1] = 0.0
            eucl_dist[i, j, 1] = 0.0
        end
    end

    # Simple propagation (not full Dijkstra for performance)
    for iter in 1:dims[3]
        for i in 2:dims[1]-1, j in 2:dims[2]-1, k in 2:dims[3]-1
            if pore_mask[i,j,k] && geo_dist[i,j,k] == Inf
                min_geo = Inf
                for (di, dj, dk) in [(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(0,0,1),(0,0,-1)]
                    ni, nj, nk = i+di, j+dj, k+dk
                    if 1 <= ni <= dims[1] && 1 <= nj <= dims[2] && 1 <= nk <= dims[3]
                        if geo_dist[ni, nj, nk] < min_geo
                            min_geo = geo_dist[ni, nj, nk] + 1
                        end
                    end
                end
                if min_geo < Inf
                    geo_dist[i,j,k] = min_geo
                    eucl_dist[i,j,k] = Float64(k - 1)
                end
            end
        end
    end

    # Tortuosity = geodesic / euclidean
    tortuosity = zeros(Float64, dims)
    for i in eachindex(volume)
        if eucl_dist[i] > 0 && !isinf(geo_dist[i])
            tortuosity[i] = geo_dist[i] / eucl_dist[i]
        end
    end

    tortuosity
end

function compute_diffusion_field(volume::Array{Bool, 3})
    # Steady-state diffusion from top surface (simplified Laplacian solution)
    dims = size(volume)
    pore_mask = .!volume

    concentration = zeros(Float64, dims)

    # Boundary condition: top surface = 1.0
    for i in 1:dims[1], j in 1:dims[2]
        if pore_mask[i, j, 1]
            concentration[i, j, 1] = 1.0
        end
    end

    # Gauss-Seidel iteration
    for iter in 1:50
        for i in 2:dims[1]-1, j in 2:dims[2]-1, k in 2:dims[3]-1
            if pore_mask[i,j,k]
                neighbors_sum = 0.0
                count = 0
                for (di, dj, dk) in [(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(0,0,1),(0,0,-1)]
                    ni, nj, nk = i+di, j+dj, k+dk
                    if pore_mask[ni, nj, nk]
                        neighbors_sum += concentration[ni, nj, nk]
                        count += 1
                    end
                end
                if count > 0
                    concentration[i,j,k] = neighbors_sum / count
                end
            end
        end
    end

    concentration
end

function compute_migration_potential(volume::Array{Bool, 3}, voxel_size::Float64)
    # Cell migration potential based on pore size and connectivity
    pore_size = compute_distance_transform(.!volume) .* voxel_size .* 2
    connectivity = compute_local_connectivity(volume)

    # Optimal pore size for cell migration: 100-300 µm
    dims = size(volume)
    migration = zeros(Float64, dims)

    for i in eachindex(volume)
        if !volume[i]
            # Pore size factor (peak at 200 µm)
            ps = pore_size[i]
            size_factor = exp(-((ps - 200)^2) / (2 * 100^2))

            # Connectivity factor
            conn_factor = connectivity[i]

            migration[i] = size_factor * conn_factor
        end
    end

    migration
end

function get_unit_for_property(type::HeatmapType)
    if type == POROSITY_LOCAL
        "%"
    elseif type == STRESS_VONMISES
        "MPa"
    elseif type == PERMEABILITY
        "m²"
    elseif type in (CURVATURE_MEAN, CURVATURE_GAUSSIAN)
        "1/µm"
    elseif type in (PORE_SIZE, WALL_THICKNESS)
        "µm"
    elseif type == INTERCONNECTIVITY
        "%"
    elseif type == TORTUOSITY
        ""
    elseif type == NUTRIENT_DIFFUSION
        "normalized"
    elseif type == CELL_MIGRATION
        "score"
    else
        ""
    end
end

function get_colormap_for_property(type::HeatmapType)
    if type == STRESS_VONMISES
        :inferno  # Hot colors for stress
    elseif type == PERMEABILITY
        :viridis  # Green-yellow for flow
    elseif type in (CURVATURE_MEAN, CURVATURE_GAUSSIAN)
        :coolwarm  # Diverging for curvature
    elseif type == NUTRIENT_DIFFUSION
        :plasma  # Purple-yellow for concentration
    elseif type == CELL_MIGRATION
        :viridis
    else
        :viridis  # Default
    end
end

#=============================================================================
  EDIT OPERATIONS
=============================================================================#

"""
    apply_operation!(workspace, op_type, params) -> EditOperation

Apply an edit operation with automatic metrics update and validation.
"""
function apply_operation!(workspace::ScaffoldWorkspace,
                         op_type::EditType,
                         params::Dict{String, Any})
    # Store before state
    metrics_before = workspace.metrics

    # Determine affected region
    region = get(params, "region", (1:size(workspace.volume,1),
                                    1:size(workspace.volume,2),
                                    1:size(workspace.volume,3)))

    # Store previous state for undo (compressed if large)
    before_state = copy(workspace.volume[region...])

    # Apply operation
    if op_type == ADD_MATERIAL
        add_material!(workspace, params)
    elseif op_type == REMOVE_MATERIAL
        remove_material!(workspace, params)
    elseif op_type == SMOOTH_SURFACE
        smooth_surface!(workspace, params)
    elseif op_type == ERODE
        erode!(workspace, params)
    elseif op_type == DILATE
        dilate!(workspace, params)
    elseif op_type == APPLY_PATTERN
        apply_pattern!(workspace, params)
    elseif op_type == CHANGE_MATERIAL
        workspace.material = params["material"]
    end

    # Clear cached property maps
    empty!(workspace.property_maps)

    # Recompute metrics
    workspace.metrics = compute_scaffold_metrics(workspace.volume,
                                                  workspace.voxel_size_um,
                                                  workspace.material)

    # Revalidate
    workspace.validation = validate_q1(workspace.metrics, workspace.tissue_target)

    # Create operation record
    op_id = length(workspace.operations) + 1
    operation = EditOperation(
        op_id, op_type, now(), params, region,
        before_state, metrics_before, workspace.metrics
    )

    # Truncate future if we're not at end
    if workspace.current_op_idx < length(workspace.operations)
        resize!(workspace.operations, workspace.current_op_idx)
    end

    push!(workspace.operations, operation)
    workspace.current_op_idx = length(workspace.operations)
    workspace.modified = now()

    # Limit history size
    if length(workspace.operations) > workspace.max_history
        popfirst!(workspace.operations)
        workspace.current_op_idx -= 1
    end

    operation
end

function add_material!(workspace::ScaffoldWorkspace, params::Dict)
    region = params["region"]
    shape = get(params, "shape", :sphere)

    if shape == :sphere
        center = params["center"]
        radius = params["radius"]

        dims = size(workspace.volume)
        for i in 1:dims[1], j in 1:dims[2], k in 1:dims[3]
            if (i-center[1])^2 + (j-center[2])^2 + (k-center[3])^2 <= radius^2
                workspace.volume[i,j,k] = true
            end
        end
    elseif shape == :box
        workspace.volume[region...] .= true
    end
end

function remove_material!(workspace::ScaffoldWorkspace, params::Dict)
    region = params["region"]
    shape = get(params, "shape", :sphere)

    if shape == :sphere
        center = params["center"]
        radius = params["radius"]

        dims = size(workspace.volume)
        for i in 1:dims[1], j in 1:dims[2], k in 1:dims[3]
            if (i-center[1])^2 + (j-center[2])^2 + (k-center[3])^2 <= radius^2
                workspace.volume[i,j,k] = false
            end
        end
    elseif shape == :box
        workspace.volume[region...] .= false
    end
end

function smooth_surface!(workspace::ScaffoldWorkspace, params::Dict)
    iterations = get(params, "iterations", 1)

    for _ in 1:iterations
        dims = size(workspace.volume)
        new_volume = copy(workspace.volume)

        for i in 2:dims[1]-1, j in 2:dims[2]-1, k in 2:dims[3]-1
            # Count solid neighbors
            neighbors = 0
            for di in -1:1, dj in -1:1, dk in -1:1
                if workspace.volume[i+di, j+dj, k+dk]
                    neighbors += 1
                end
            end

            # Majority voting
            new_volume[i,j,k] = neighbors >= 14  # 14 out of 27
        end

        workspace.volume = new_volume
    end
end

function erode!(workspace::ScaffoldWorkspace, params::Dict)
    iterations = get(params, "iterations", 1)

    for _ in 1:iterations
        dims = size(workspace.volume)
        new_volume = copy(workspace.volume)

        for i in 2:dims[1]-1, j in 2:dims[2]-1, k in 2:dims[3]-1
            if workspace.volume[i,j,k]
                # Erode if any neighbor is pore
                for (di, dj, dk) in [(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(0,0,1),(0,0,-1)]
                    if !workspace.volume[i+di, j+dj, k+dk]
                        new_volume[i,j,k] = false
                        break
                    end
                end
            end
        end

        workspace.volume = new_volume
    end
end

function dilate!(workspace::ScaffoldWorkspace, params::Dict)
    iterations = get(params, "iterations", 1)

    for _ in 1:iterations
        dims = size(workspace.volume)
        new_volume = copy(workspace.volume)

        for i in 2:dims[1]-1, j in 2:dims[2]-1, k in 2:dims[3]-1
            if !workspace.volume[i,j,k]
                # Dilate if any neighbor is solid
                for (di, dj, dk) in [(1,0,0),(-1,0,0),(0,1,0),(0,-1,0),(0,0,1),(0,0,-1)]
                    if workspace.volume[i+di, j+dj, k+dk]
                        new_volume[i,j,k] = true
                        break
                    end
                end
            end
        end

        workspace.volume = new_volume
    end
end

function apply_pattern!(workspace::ScaffoldWorkspace, params::Dict)
    pattern = params["pattern"]  # :gyroid, :diamond, :primitive

    new_volume = generate_scaffold(size(workspace.volume),
                                   workspace.metrics.porosity,
                                   workspace.metrics.mean_pore_size_um,
                                   pattern)

    # Blend with existing
    blend = get(params, "blend", 1.0)
    if blend < 1.0
        for i in eachindex(workspace.volume)
            if rand() < blend
                workspace.volume[i] = new_volume[i]
            end
        end
    else
        workspace.volume = new_volume
    end
end

"""
    undo!(workspace) -> Bool

Undo last operation. Returns true if successful.
"""
function undo!(workspace::ScaffoldWorkspace)
    if workspace.current_op_idx < 1
        return false
    end

    op = workspace.operations[workspace.current_op_idx]

    # Restore previous state
    if !isnothing(op.before_state)
        workspace.volume[op.affected_region...] = op.before_state
    end

    # Restore metrics
    if !isnothing(op.metrics_before)
        workspace.metrics = op.metrics_before
        workspace.validation = validate_q1(workspace.metrics, workspace.tissue_target)
    end

    # Clear cached maps
    empty!(workspace.property_maps)

    workspace.current_op_idx -= 1
    workspace.modified = now()

    true
end

"""
    redo!(workspace) -> Bool

Redo previously undone operation. Returns true if successful.
"""
function redo!(workspace::ScaffoldWorkspace)
    if workspace.current_op_idx >= length(workspace.operations)
        return false
    end

    workspace.current_op_idx += 1
    op = workspace.operations[workspace.current_op_idx]

    # Re-apply operation
    apply_operation!(workspace, op.type, op.parameters)

    true
end

#=============================================================================
  LIVE METRICS
=============================================================================#

"""
    get_live_metrics(workspace) -> Dict

Get current metrics with validation status for real-time display.
"""
function get_live_metrics(workspace::ScaffoldWorkspace)
    m = workspace.metrics
    v = workspace.validation

    Dict(
        "porosity" => Dict(
            "value" => round(m.porosity * 100, digits=1),
            "unit" => "%",
            "valid" => v.porosity_valid,
            "score" => round(v.porosity_score, digits=0),
            "target" => "70-95%"
        ),
        "pore_size" => Dict(
            "value" => round(m.mean_pore_size_um, digits=1),
            "unit" => "µm",
            "valid" => v.pore_size_valid,
            "score" => round(v.pore_size_score, digits=0),
            "target" => "100-500 µm"
        ),
        "interconnectivity" => Dict(
            "value" => round(m.interconnectivity * 100, digits=1),
            "unit" => "%",
            "valid" => v.interconnectivity_valid,
            "score" => round(v.interconnectivity_score, digits=0),
            "target" => "≥90%"
        ),
        "elastic_modulus" => Dict(
            "value" => round(m.elastic_modulus, digits=2),
            "unit" => "MPa",
            "valid" => v.mechanical_valid,
            "score" => round(v.mechanical_score, digits=0)
        ),
        "yield_strength" => Dict(
            "value" => round(m.yield_strength, digits=2),
            "unit" => "MPa"
        ),
        "permeability" => Dict(
            "value" => m.permeability,
            "unit" => "m²"
        ),
        "tortuosity" => Dict(
            "value" => round(m.tortuosity, digits=2)
        ),
        "surface_area" => Dict(
            "value" => round(m.specific_surface_area, digits=0),
            "unit" => "m⁻¹"
        ),
        "overall_score" => round(v.score, digits=0),
        "is_valid" => v.is_valid,
        "recommendations" => v.recommendations,
        "citations" => v.citations,
        "tissue_target" => string(workspace.tissue_target),
        "material" => workspace.material
    )
end

end # module
