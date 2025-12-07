"""
    OntologyQuery

Cross-library query engine for tissue engineering ontologies.

Provides unified querying across:
- PhysicalPropertiesLibrary (materials)
- MolecularPropertiesLibrary (molecules)
- DrugDeliveryLibrary (drugs/PK)
- CompatibilityMatrix (interactions)
- BiomarkersLibrary (biomarkers)

Features:
- Multi-criteria material selection
- Drug-material compatibility checking
- Tissue-matched scaffold design
- Biomarker panel recommendation
- Complete formulation design

Author: Dr. Demetrios Agourakis
"""
module OntologyQuery

using ..PhysicalPropertiesLibrary
using ..MolecularPropertiesLibrary
using ..DrugDeliveryLibrary
using ..CompatibilityMatrix
using ..BiomarkersLibrary

export ScaffoldQuery, DrugLoadingQuery, FormulationResult
export find_materials_for_tissue, find_drug_compatible_materials
export design_drug_loaded_scaffold, recommend_biomarker_panel
export query_by_criteria, find_optimal_formulation
export MaterialMatch, DrugMaterialMatch, FormulationDesign

# =============================================================================
# Query Result Types
# =============================================================================

"""Result of a material query with matching criteria."""
struct MaterialMatch
    material_id::String
    name::String
    category::Symbol
    score::Float64
    matched_criteria::Dict{Symbol,Any}
    warnings::Vector{String}
end

"""Result of drug-material compatibility query."""
struct DrugMaterialMatch
    material_id::String
    drug_id::String
    compatibility_score::Float64
    loading_capacity::Symbol  # :high, :medium, :low
    release_mechanism::Symbol # :diffusion, :degradation, :swelling
    estimated_release_days::Float64
    notes::String
end

"""Complete formulation design result."""
struct FormulationDesign
    scaffold_material::String
    drug::String
    target_tissue::Symbol
    porosity::Float64
    predicted_modulus_mpa::Float64
    drug_loading_ug::Float64
    release_duration_days::Float64
    biomarkers::Vector{String}
    compatibility_score::Float64
    fabrication_methods::Vector{Symbol}
    sterilization_methods::Vector{Symbol}
    warnings::Vector{String}
    recommendations::Vector{String}
end

# =============================================================================
# Material Query Functions
# =============================================================================

"""
    find_materials_for_tissue(tissue::Symbol; kwargs...)

Find materials suitable for a specific tissue type.

# Arguments
- `tissue`: Target tissue (:bone, :cartilage, :skin, :cardiac, :neural, :vascular)
- `porosity`: Target porosity (0-1)
- `biodegradable`: Require biodegradable material (default: true)
- `min_modulus_mpa`: Minimum elastic modulus
- `max_modulus_mpa`: Maximum elastic modulus
- `cell_type`: Target cell type for compatibility check

# Returns
Vector of MaterialMatch sorted by score
"""
function find_materials_for_tissue(tissue::Symbol;
    porosity::Float64=0.7,
    biodegradable::Bool=true,
    min_modulus_mpa::Float64=0.0,
    max_modulus_mpa::Float64=Inf,
    cell_type::Union{Symbol,Nothing}=nothing)

    # Get tissue mechanical properties
    tissue_props = get(PhysicalPropertiesLibrary.TISSUE_MECHANICAL_PROPERTIES, tissue, nothing)

    # Map tissue to default cell type if not specified
    if isnothing(cell_type)
        cell_type = tissue_to_cell_type(tissue)
    end

    matches = MaterialMatch[]

    for (id, props) in PhysicalPropertiesLibrary.PHYSICAL_DB
        score = 0.0
        criteria = Dict{Symbol,Any}()
        warnings = String[]

        # Check category (biodegradability)
        if biodegradable && props.category == :metal
            continue  # Skip non-biodegradable metals unless specified
        end

        # Calculate scaffold modulus
        E_solid = props.mechanical.elastic_modulus_mpa
        if !isnan(E_solid)
            E_scaffold = PhysicalPropertiesLibrary.gibson_ashby_modulus(E_solid, porosity)
            criteria[:scaffold_modulus_mpa] = E_scaffold

            # Check modulus range
            if E_scaffold < min_modulus_mpa || E_scaffold > max_modulus_mpa
                continue
            end

            # Score based on tissue match
            if !isnothing(tissue_props)
                target_E = tissue_props.E_mpa
                ratio = E_scaffold / target_E
                if 0.5 <= ratio <= 2.0
                    score += 0.3 * (1 - abs(ratio - 1) / 1.5)
                    criteria[:modulus_match] = ratio
                else
                    push!(warnings, "Modulus mismatch: $(round(ratio, digits=2))x target")
                end
            end
        end

        # Check cell compatibility
        if !isnothing(cell_type)
            compat = get(CompatibilityMatrix.MATERIAL_CELL_COMPATIBILITY,
                        (id, cell_type), nothing)
            if !isnothing(compat)
                score += 0.4 * compat.score
                criteria[:cell_compatibility] = compat.rating
                if compat.rating == :poor || compat.rating == :incompatible
                    push!(warnings, "Poor cell compatibility")
                end
            end
        end

        # Bonus for hydrophilic surfaces (better cell adhesion)
        if props.surface.hydrophilicity == :hydrophilic
            score += 0.1
            criteria[:hydrophilicity] = :hydrophilic
        end

        # Bonus for good cell adhesion
        if props.surface.cell_adhesion in ["Excellent", "Good"]
            score += 0.1
            criteria[:cell_adhesion] = props.surface.cell_adhesion
        end

        # Bonus for appropriate category
        category_bonus = get_category_bonus(props.category, tissue)
        score += 0.1 * category_bonus

        if score > 0.1
            push!(matches, MaterialMatch(id, props.name, props.category,
                                        score, criteria, warnings))
        end
    end

    # Sort by score descending
    sort!(matches, by=m -> m.score, rev=true)

    return matches
end

"""
    find_drug_compatible_materials(drug_id::String; kwargs...)

Find materials compatible with a specific drug for loading.

# Arguments
- `drug_id`: Drug identifier
- `release_days`: Target release duration
- `min_loading_ug`: Minimum drug loading requirement

# Returns
Vector of DrugMaterialMatch sorted by compatibility
"""
function find_drug_compatible_materials(drug_id::String;
    release_days::Float64=14.0,
    min_loading_ug::Float64=100.0)

    # Get drug info
    drug = DrugDeliveryLibrary.get_drug_pk(drug_id)
    if isnothing(drug)
        error("Drug $drug_id not found in database")
    end

    matches = DrugMaterialMatch[]

    for (id, props) in PhysicalPropertiesLibrary.PHYSICAL_DB
        # Check drug-material compatibility
        compat = get(CompatibilityMatrix.MATERIAL_DRUG_COMPATIBILITY,
                    (id, drug_id), nothing)

        compat_score = 0.5  # Default moderate
        if !isnothing(compat)
            compat_score = compat.score
        end

        # Estimate loading capacity based on material properties
        loading_capacity = estimate_loading_capacity(props, drug)

        # Estimate release mechanism
        release_mechanism = estimate_release_mechanism(props)

        # Estimate release duration
        estimated_release = estimate_release_duration(props, drug, release_days)

        # Build notes
        notes = build_drug_material_notes(props, drug, compat)

        push!(matches, DrugMaterialMatch(
            id, drug_id, compat_score, loading_capacity,
            release_mechanism, estimated_release, notes
        ))
    end

    # Sort by compatibility score
    sort!(matches, by=m -> m.compatibility_score, rev=true)

    return matches
end

"""
    design_drug_loaded_scaffold(tissue::Symbol, drug_id::String; kwargs...)

Design a complete drug-loaded scaffold formulation.

# Arguments
- `tissue`: Target tissue type
- `drug_id`: Drug to load
- `porosity`: Target porosity (default: 0.7)
- `release_days`: Target release duration

# Returns
FormulationDesign with complete specifications
"""
function design_drug_loaded_scaffold(tissue::Symbol, drug_id::String;
    porosity::Float64=0.7,
    release_days::Float64=14.0)

    # Find tissue-compatible materials
    tissue_materials = find_materials_for_tissue(tissue; porosity=porosity)

    # Find drug-compatible materials
    drug_materials = find_drug_compatible_materials(drug_id; release_days=release_days)

    # Create lookup for drug compatibility
    drug_compat = Dict(m.material_id => m for m in drug_materials)

    # Find best combined match
    best_material = nothing
    best_score = 0.0
    best_drug_match = nothing

    for mat in tissue_materials
        if haskey(drug_compat, mat.material_id)
            dm = drug_compat[mat.material_id]
            combined_score = 0.5 * mat.score + 0.5 * dm.compatibility_score
            if combined_score > best_score
                best_score = combined_score
                best_material = mat
                best_drug_match = dm
            end
        end
    end

    if isnothing(best_material)
        error("No compatible material found for $tissue + $drug_id")
    end

    # Get material properties
    props = PhysicalPropertiesLibrary.get_physical_properties(best_material.material_id)
    drug = DrugDeliveryLibrary.get_drug_pk(drug_id)

    # Calculate predicted modulus
    E_solid = props.mechanical.elastic_modulus_mpa
    predicted_modulus = isnan(E_solid) ? NaN :
        PhysicalPropertiesLibrary.gibson_ashby_modulus(E_solid, porosity)

    # Get recommended biomarkers
    biomarkers = recommend_biomarker_panel(tissue)

    # Get compatible fabrication methods
    fab_methods = get_compatible_fabrication(best_material.material_id)

    # Get compatible sterilization methods
    steril_methods = get_compatible_sterilization(best_material.material_id)

    # Build warnings and recommendations
    warnings = copy(best_material.warnings)
    recommendations = String[]

    # Add drug-specific recommendations
    if drug.half_life_h < 1.0
        push!(recommendations, "Short drug half-life - consider encapsulation for sustained release")
    end

    if best_drug_match.loading_capacity == :low
        push!(recommendations, "Low loading capacity - consider surface modification or nanoparticles")
    end

    # Tissue-specific recommendations
    add_tissue_recommendations!(recommendations, tissue, props)

    return FormulationDesign(
        best_material.material_id,
        drug_id,
        tissue,
        porosity,
        predicted_modulus,
        drug.local_therapeutic_dose_ug,
        best_drug_match.estimated_release_days,
        biomarkers,
        best_score,
        fab_methods,
        steril_methods,
        warnings,
        recommendations
    )
end

"""
    query_by_criteria(criteria::Dict{Symbol,Any})

Query materials by multiple criteria.

# Criteria options
- `:category` => :polymer, :ceramic, :metal, :hydrogel, :composite
- `:min_modulus` => Float64 (MPa)
- `:max_modulus` => Float64 (MPa)
- `:biodegradable` => Bool
- `:cell_type` => Symbol (for compatibility check)
- `:drug` => String (for drug compatibility)
- `:hydrophilicity` => :hydrophilic, :hydrophobic
- `:conductive` => Bool
"""
function query_by_criteria(criteria::Dict{Symbol,Any})
    matches = MaterialMatch[]

    for (id, props) in PhysicalPropertiesLibrary.PHYSICAL_DB
        match = true
        score = 1.0
        matched = Dict{Symbol,Any}()
        warnings = String[]

        # Category filter
        if haskey(criteria, :category)
            if props.category != criteria[:category]
                match = false
            else
                matched[:category] = props.category
            end
        end

        # Modulus range
        E = props.mechanical.elastic_modulus_mpa
        if !isnan(E)
            if haskey(criteria, :min_modulus) && E < criteria[:min_modulus]
                match = false
            end
            if haskey(criteria, :max_modulus) && E > criteria[:max_modulus]
                match = false
            end
            matched[:elastic_modulus_mpa] = E
        end

        # Biodegradable
        if haskey(criteria, :biodegradable) && criteria[:biodegradable]
            if props.category == :metal && !(id in ["Magnesium", "Mg_AZ31", "Zinc"])
                match = false
            end
        end

        # Cell compatibility
        if haskey(criteria, :cell_type)
            compat = get(CompatibilityMatrix.MATERIAL_CELL_COMPATIBILITY,
                        (id, criteria[:cell_type]), nothing)
            if !isnothing(compat)
                score *= compat.score
                matched[:cell_compatibility] = compat.rating
            end
        end

        # Drug compatibility
        if haskey(criteria, :drug)
            compat = get(CompatibilityMatrix.MATERIAL_DRUG_COMPATIBILITY,
                        (id, criteria[:drug]), nothing)
            if !isnothing(compat)
                score *= compat.score
                matched[:drug_compatibility] = compat.rating
            end
        end

        # Hydrophilicity
        if haskey(criteria, :hydrophilicity)
            if props.surface.hydrophilicity != criteria[:hydrophilicity]
                match = false
            else
                matched[:hydrophilicity] = props.surface.hydrophilicity
            end
        end

        # Conductivity
        if haskey(criteria, :conductive)
            if props.electrical.is_conductive != criteria[:conductive]
                match = false
            else
                matched[:conductive] = props.electrical.is_conductive
            end
        end

        if match
            push!(matches, MaterialMatch(id, props.name, props.category,
                                        score, matched, warnings))
        end
    end

    sort!(matches, by=m -> m.score, rev=true)
    return matches
end

"""
    recommend_biomarker_panel(tissue::Symbol; timepoints::Vector{Int}=[7, 14, 21, 28])

Recommend biomarker panel for tissue engineering evaluation.

# Returns
Vector of gene symbols for qPCR panel
"""
function recommend_biomarker_panel(tissue::Symbol; timepoints::Vector{Int}=[7, 14, 21, 28])
    markers = String[]

    # Get tissue-specific markers
    tissue_markers = if tissue == :bone
        keys(BiomarkersLibrary.OSTEOGENIC_MARKERS)
    elseif tissue == :cartilage
        keys(BiomarkersLibrary.CHONDROGENIC_MARKERS)
    elseif tissue in [:fat, :adipose]
        keys(BiomarkersLibrary.ADIPOGENIC_MARKERS)
    elseif tissue == :vascular
        keys(BiomarkersLibrary.ANGIOGENIC_MARKERS)
    elseif tissue == :neural
        keys(BiomarkersLibrary.NEURAL_MARKERS)
    elseif tissue == :cardiac
        keys(BiomarkersLibrary.CARDIAC_MARKERS)
    elseif tissue == :skin
        keys(BiomarkersLibrary.SKIN_MARKERS)
    else
        String[]
    end

    append!(markers, collect(tissue_markers))

    # Add reference genes
    append!(markers, collect(keys(BiomarkersLibrary.REFERENCE_GENES)))

    return unique(markers)
end

"""
    find_optimal_formulation(tissue::Symbol, drugs::Vector{String}; kwargs...)

Find optimal formulation for multiple drug delivery.

# Arguments
- `tissue`: Target tissue
- `drugs`: Vector of drug IDs to co-deliver
- `porosity`: Target porosity

# Returns
Vector of FormulationDesign options ranked by overall score
"""
function find_optimal_formulation(tissue::Symbol, drugs::Vector{String};
    porosity::Float64=0.7)

    formulations = FormulationDesign[]

    for drug in drugs
        try
            form = design_drug_loaded_scaffold(tissue, drug; porosity=porosity)
            push!(formulations, form)
        catch e
            @warn "Could not design formulation for $drug: $e"
        end
    end

    # Sort by compatibility score
    sort!(formulations, by=f -> f.compatibility_score, rev=true)

    return formulations
end

# =============================================================================
# Helper Functions
# =============================================================================

function tissue_to_cell_type(tissue::Symbol)
    mapping = Dict(
        :bone => :osteoblast,
        :cartilage => :chondrocyte,
        :skin => :fibroblast,
        :cardiac => :cardiomyocyte,
        :neural => :neuron,
        :vascular => :endothelial,
        :muscle => :myoblast,
        :fat => :adipocyte,
        :liver => :hepatocyte
    )
    return get(mapping, tissue, :msc)
end

function get_category_bonus(category::Symbol, tissue::Symbol)
    # Tissue-specific material preferences
    preferences = Dict(
        :bone => Dict(:ceramic => 1.0, :composite => 0.8, :polymer => 0.6),
        :cartilage => Dict(:hydrogel => 1.0, :polymer => 0.7),
        :skin => Dict(:polymer => 0.9, :hydrogel => 0.8),
        :cardiac => Dict(:hydrogel => 1.0, :polymer => 0.6),
        :neural => Dict(:hydrogel => 1.0, :polymer => 0.5),
        :vascular => Dict(:polymer => 0.9, :hydrogel => 0.7)
    )

    tissue_prefs = get(preferences, tissue, Dict{Symbol,Float64}())
    return get(tissue_prefs, category, 0.5)
end

function estimate_loading_capacity(props, drug)
    # Estimate based on material properties
    if props.category == :hydrogel
        return :high  # Hydrogels have high water content for drug absorption
    elseif props.category == :polymer && props.surface.hydrophilicity == :hydrophilic
        return :medium
    elseif props.category == :ceramic
        return :medium  # Porous ceramics can load drugs
    else
        return :low
    end
end

function estimate_release_mechanism(props)
    if props.category == :hydrogel
        return :swelling
    elseif props.category in [:polymer, :composite]
        return :degradation
    else
        return :diffusion
    end
end

function estimate_release_duration(props, drug, target_days)
    # Simplified estimation based on material degradation
    if props.category == :hydrogel
        return min(target_days, 7.0)  # Faster release from hydrogels
    elseif props.category == :polymer
        return target_days  # Polymers can achieve sustained release
    elseif props.category == :ceramic
        return target_days * 1.5  # Slower release from ceramics
    else
        return target_days
    end
end

function build_drug_material_notes(props, drug, compat)
    notes = String[]

    if props.category == :hydrogel
        push!(notes, "Suitable for hydrophilic drugs")
    end

    if !isnothing(compat) && !isempty(compat.notes)
        push!(notes, compat.notes)
    end

    if drug.half_life_h < 1.0
        push!(notes, "Short half-life drug requires sustained release formulation")
    end

    return join(notes, "; ")
end

function get_compatible_fabrication(material_id::String)
    methods = Symbol[]

    # Check fabrication compatibility
    for method in [:electrospinning, :fdm_3d_printing, :sla_3d_printing,
                   :bioprinting, :freeze_drying, :salt_leaching, :gas_foaming]
        compat = get(CompatibilityMatrix.FABRICATION_COMPATIBILITY,
                    (material_id, method), nothing)
        if !isnothing(compat) && compat.score >= 0.5
            push!(methods, method)
        end
    end

    # Default methods if none found
    if isempty(methods)
        push!(methods, :solvent_casting)
    end

    return methods
end

function get_compatible_sterilization(material_id::String)
    methods = Symbol[]

    for method in [:gamma_irradiation, :eto_sterilization, :autoclave,
                   :uv_sterilization, :electron_beam]
        compat = get(CompatibilityMatrix.STERILIZATION_COMPATIBILITY,
                    (material_id, method), nothing)
        if !isnothing(compat) && compat.score >= 0.5
            push!(methods, method)
        end
    end

    # Default if none found
    if isempty(methods)
        push!(methods, :uv_sterilization)
    end

    return methods
end

function add_tissue_recommendations!(recommendations, tissue, props)
    if tissue == :bone
        if props.mechanical.elastic_modulus_mpa < 100
            push!(recommendations, "Consider ceramic reinforcement for bone tissue")
        end
        push!(recommendations, "Include osteogenic factors (BMP-2, simvastatin)")
    elseif tissue == :cartilage
        push!(recommendations, "Maintain hypoxic culture conditions")
        push!(recommendations, "Consider TGF-β3 for chondrogenic differentiation")
    elseif tissue == :vascular
        push!(recommendations, "Include endothelial cells and VEGF")
        push!(recommendations, "Consider luminal surface modification")
    elseif tissue == :neural
        push!(recommendations, "Include neurotrophic factors (NGF, BDNF)")
        push!(recommendations, "Consider conductive materials for electrical stimulation")
    end
end

# =============================================================================
# Convenience Aliases
# =============================================================================

"""Alias for find_materials_for_tissue"""
const find_scaffold_materials = find_materials_for_tissue

"""Alias for design_drug_loaded_scaffold"""
const design_formulation = design_drug_loaded_scaffold

end # module
