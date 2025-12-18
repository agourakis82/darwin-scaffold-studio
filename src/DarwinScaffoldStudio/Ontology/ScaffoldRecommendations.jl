"""
    ScaffoldRecommendations

Evidence-based scaffold design recommendations from Q1 tissue engineering literature.

References:
- Murphy et al. 2010: Pore sizes for bone (100-200um)
- Karageorgiou & Kaplan 2005: Porosity 90%+ for bone
- Engler et al. 2006: Substrate stiffness for stem cell differentiation
- Hutmacher 2000: Scaffold design criteria
"""
module ScaffoldRecommendations

export ScaffoldRecommendation, TISSUE_RECOMMENDATIONS
export get_scaffold_recommendations, get_cells_for_tissue
export get_materials_for_application, get_biological_processes
export recommend_pore_size

# Import from parent - will be set by OntologyManager
const _smart_lookup = Ref{Function}(id -> nothing)
const _get_ancestors = Ref{Function}((id; max_depth=5) -> [])

"""Configure lookup functions (called by OntologyManager)."""
function configure!(smart_lookup_fn::Function, get_ancestors_fn::Function)
    _smart_lookup[] = smart_lookup_fn
    _get_ancestors[] = get_ancestors_fn
end

#=============================================================================
  TYPES
=============================================================================#

"""
    ScaffoldRecommendation

Evidence-based recommendation for scaffold design.
"""
struct ScaffoldRecommendation
    category::Symbol           # :cell, :material, :process, :parameter
    term_id::Union{String,Nothing}  # OBO term ID if applicable
    name::String
    rationale::String          # Why this is recommended
    evidence_level::Symbol     # :high (RCT/meta), :medium (cohort), :low (case/expert)
    references::Vector{String} # DOI or PMID
    parameters::Dict{String,Any}  # Specific values (e.g., pore_size_um)
end

#=============================================================================
  KNOWLEDGE BASE

  Evidence-based recommendations organized by UBERON tissue ID.
  Each tissue has recommendations for cells, materials, processes, and parameters.
=============================================================================#

const TISSUE_RECOMMENDATIONS = Dict{String,Dict{Symbol,Vector{NamedTuple}}}(
    # Bone tissue recommendations
    "UBERON:0002481" => Dict(  # bone tissue
        :cells => [
            (id="CL:0000062", name="osteoblast", rationale="Primary bone-forming cells", evidence=:high,
                refs=["10.1038/nrrheum.2015.40"]),
            (id="CL:0000134", name="mesenchymal stem cell", rationale="Osteogenic differentiation potential", evidence=:high,
                refs=["10.1002/stem.684"]),
            (id="CL:0000092", name="osteoclast", rationale="Bone remodeling, required for integration", evidence=:medium,
                refs=["10.1016/j.bone.2015.03.017"]),
        ],
        :materials => [
            (id="CHEBI:53719", name="hydroxyapatite", rationale="Osteoconductive, mimics bone mineral", evidence=:high,
                refs=["10.1002/jbm.a.32794"], params=Dict("Ca_P_ratio" => 1.67)),
            (id="CHEBI:60027", name="tricalcium phosphate", rationale="Resorbable, promotes remodeling", evidence=:high,
                refs=["10.1016/j.actbio.2010.09.019"]),
            (id="CHEBI:27899", name="collagen type I", rationale="Major organic bone component", evidence=:high,
                refs=["10.1016/j.biomaterials.2006.02.016"]),
        ],
        :processes => [
            (id="GO:0001503", name="ossification", rationale="Target biological process", evidence=:high,
                refs=["10.1038/nature10290"]),
            (id="GO:0030282", name="bone mineralization", rationale="Required for mechanical strength", evidence=:high,
                refs=["10.1016/j.bone.2012.02.007"]),
            (id="GO:0045453", name="bone resorption", rationale="Remodeling for integration", evidence=:medium,
                refs=["10.1016/j.bone.2015.03.017"]),
        ],
        :parameters => [
            (name="pore_size_um", min=100, optimal=150, max=300, rationale="Murphy et al. 2010: optimal for bone ingrowth",
                refs=["10.1016/j.biomaterials.2009.09.063"]),
            (name="porosity_percent", min=70, optimal=90, max=95, rationale="Karageorgiou 2005: high porosity for vascularization",
                refs=["10.1016/j.biomaterials.2005.01.016"]),
            (name="interconnectivity_percent", min=80, optimal=95, max=100, rationale="Required for nutrient transport",
                refs=["10.1089/ten.2006.12.3307"]),
            (name="elastic_modulus_mpa", min=100, optimal=500, max=20000, rationale="Match trabecular bone (100-500 MPa)",
                refs=["10.1016/j.jmbbm.2012.01.006"]),
        ]
    ),

    # Cartilage tissue recommendations
    "UBERON:0002418" => Dict(  # cartilage tissue
        :cells => [
            (id="CL:0000138", name="chondrocyte", rationale="Native cartilage cells, maintain ECM", evidence=:high,
                refs=["10.1016/j.joca.2013.07.009"]),
            (id="CL:0000134", name="mesenchymal stem cell", rationale="Chondrogenic potential, less donor morbidity", evidence=:high,
                refs=["10.1002/art.21972"]),
        ],
        :materials => [
            (id="CHEBI:16991", name="hyaluronic acid", rationale="Native cartilage GAG, supports chondrogenesis", evidence=:high,
                refs=["10.1016/j.biomaterials.2005.07.013"]),
            (id="CHEBI:27899", name="collagen type II", rationale="Major cartilage collagen", evidence=:high,
                refs=["10.1016/j.actbio.2013.01.017"]),
            (id="CHEBI:16150", name="alginate", rationale="Maintains chondrocyte phenotype in 3D", evidence=:medium,
                refs=["10.1016/j.biomaterials.2006.09.027"]),
        ],
        :processes => [
            (id="GO:0051216", name="cartilage development", rationale="Target developmental program", evidence=:high,
                refs=["10.1016/j.devcel.2005.04.003"]),
            (id="GO:0030199", name="collagen fibril organization", rationale="ECM architecture critical", evidence=:medium,
                refs=["10.1016/j.matbio.2014.08.001"]),
        ],
        :parameters => [
            (name="pore_size_um", min=50, optimal=100, max=200, rationale="Smaller pores for cartilage vs bone",
                refs=["10.1016/j.biomaterials.2010.01.116"]),
            (name="porosity_percent", min=70, optimal=85, max=95, rationale="Balance cell seeding and mechanics",
                refs=["10.1016/j.actbio.2009.12.006"]),
            (name="elastic_modulus_mpa", min=0.5, optimal=1.0, max=10.0, rationale="Match articular cartilage",
                refs=["10.1016/j.jbiomech.2009.10.015"]),
        ]
    ),

    # Skin/dermis recommendations
    "UBERON:0002067" => Dict(  # dermis
        :cells => [
            (id="CL:0000057", name="fibroblast", rationale="Primary dermis cell, collagen production", evidence=:high,
                refs=["10.1016/j.biomaterials.2013.03.024"]),
            (id="CL:0000312", name="keratinocyte", rationale="Epidermis regeneration", evidence=:high,
                refs=["10.1016/j.biomaterials.2012.01.015"]),
            (id="CL:0000115", name="endothelial cell", rationale="Vascularization essential for thick grafts", evidence=:medium,
                refs=["10.1016/j.addr.2010.11.001"]),
        ],
        :materials => [
            (id="CHEBI:27899", name="collagen type I", rationale="Major dermis component", evidence=:high,
                refs=["10.1016/j.biomaterials.2013.03.024"]),
            (id="CHEBI:28815", name="fibrin", rationale="Natural wound healing matrix", evidence=:high,
                refs=["10.1016/j.biomaterials.2010.01.076"]),
        ],
        :processes => [
            (id="GO:0042060", name="wound healing", rationale="Primary goal of skin scaffolds", evidence=:high,
                refs=["10.1038/nrm.2016.109"]),
            (id="GO:0001525", name="angiogenesis", rationale="Vascularization for graft survival", evidence=:high,
                refs=["10.1016/j.addr.2010.11.001"]),
        ],
        :parameters => [
            (name="pore_size_um", min=20, optimal=100, max=200, rationale="Fibroblast migration optimal range",
                refs=["10.1016/j.biomaterials.2010.03.019"]),
            (name="porosity_percent", min=60, optimal=80, max=90, rationale="Balance cell infiltration and mechanics",
                refs=["10.1016/j.biomaterials.2013.03.024"]),
        ]
    ),

    # Cardiac tissue recommendations
    "UBERON:0002349" => Dict(  # myocardium
        :cells => [
            (id="CL:0000746", name="cardiomyocyte", rationale="Contractile cardiac cells", evidence=:high,
                refs=["10.1038/nature13985"]),
            (id="CL:0000134", name="mesenchymal stem cell", rationale="Paracrine effects, reduce fibrosis", evidence=:medium,
                refs=["10.1016/j.jacc.2012.05.012"]),
            (id="CL:0010020", name="cardiac fibroblast", rationale="ECM production, electrical coupling support", evidence=:medium,
                refs=["10.1016/j.yjmcc.2015.03.016"]),
        ],
        :materials => [
            (id="CHEBI:28815", name="fibrin", rationale="Injectable, supports cell survival", evidence=:high,
                refs=["10.1016/j.jacc.2016.02.057"]),
            (id="CHEBI:27899", name="collagen type I", rationale="Cardiac ECM component", evidence=:medium,
                refs=["10.1016/j.biomaterials.2014.03.005"]),
        ],
        :processes => [
            (id="GO:0060048", name="cardiac muscle contraction", rationale="Functional goal", evidence=:high,
                refs=["10.1038/nature13985"]),
            (id="GO:0055017", name="cardiac muscle tissue development", rationale="Regeneration program", evidence=:high,
                refs=["10.1016/j.cell.2012.11.053"]),
        ],
        :parameters => [
            (name="elastic_modulus_kpa", min=10, optimal=50, max=100, rationale="Match native myocardium stiffness",
                refs=["10.1016/j.biomaterials.2010.01.033"]),
            (name="conductivity_s_m", min=0.1, optimal=0.5, max=1.0, rationale="Electrical propagation",
                refs=["10.1016/j.actbio.2014.09.036"]),
        ]
    ),

    # Neural tissue recommendations
    "UBERON:0001017" => Dict(  # central nervous system
        :cells => [
            (id="CL:0000540", name="neuron", rationale="Functional neural cells", evidence=:high,
                refs=["10.1016/j.biomaterials.2013.06.045"]),
            (id="CL:0000127", name="astrocyte", rationale="Support cells, guide regeneration", evidence=:medium,
                refs=["10.1016/j.biomaterials.2012.09.052"]),
            (id="CL:0000128", name="oligodendrocyte", rationale="Myelination for signal conduction", evidence=:medium,
                refs=["10.1016/j.stem.2014.07.002"]),
        ],
        :materials => [
            (id="CHEBI:16991", name="hyaluronic acid", rationale="CNS ECM component, hydrogel formation", evidence=:high,
                refs=["10.1016/j.biomaterials.2013.06.045"]),
            (id="CHEBI:28790", name="laminin", rationale="Promotes neurite outgrowth", evidence=:high,
                refs=["10.1016/j.biomaterials.2014.05.003"]),
        ],
        :processes => [
            (id="GO:0007409", name="axonogenesis", rationale="Axon regeneration goal", evidence=:high,
                refs=["10.1038/nrn.2016.29"]),
            (id="GO:0048812", name="neuron projection morphogenesis", rationale="Neurite guidance", evidence=:high,
                refs=["10.1016/j.biomaterials.2013.06.045"]),
        ],
        :parameters => [
            (name="elastic_modulus_kpa", min=0.1, optimal=1.0, max=10.0, rationale="Brain tissue is very soft",
                refs=["10.1016/j.biomaterials.2010.01.033"]),
            (name="pore_size_um", min=10, optimal=50, max=100, rationale="Allow neurite ingrowth",
                refs=["10.1016/j.biomaterials.2012.09.052"]),
        ]
    ),

    # Vascular tissue recommendations
    "UBERON:0001981" => Dict(  # blood vessel
        :cells => [
            (id="CL:0000115", name="endothelial cell", rationale="Line vessel lumen, prevent thrombosis", evidence=:high,
                refs=["10.1016/j.biomaterials.2014.01.078"]),
            (id="CL:0000192", name="smooth muscle cell", rationale="Vessel wall structure and function", evidence=:high,
                refs=["10.1016/j.actbio.2014.07.005"]),
        ],
        :materials => [
            (id="CHEBI:53325", name="polycaprolactone", rationale="Biodegradable, mechanical strength", evidence=:high,
                refs=["10.1016/j.actbio.2010.09.028"]),
            (id="CHEBI:27899", name="collagen type I", rationale="Vessel wall ECM", evidence=:medium,
                refs=["10.1016/j.biomaterials.2014.01.078"]),
        ],
        :processes => [
            (id="GO:0001525", name="angiogenesis", rationale="Vessel formation", evidence=:high,
                refs=["10.1038/nrm3722"]),
            (id="GO:0001570", name="vasculogenesis", rationale="De novo vessel formation", evidence=:high,
                refs=["10.1016/j.cell.2014.02.007"]),
        ],
        :parameters => [
            (name="inner_diameter_mm", min=1.0, optimal=4.0, max=10.0, rationale="Small diameter grafts most needed",
                refs=["10.1016/j.actbio.2014.07.005"]),
            (name="burst_pressure_mmhg", min=1500, optimal=2000, max=3000, rationale="Match native vessel strength",
                refs=["10.1016/j.biomaterials.2014.01.078"]),
        ]
    ),
)

#=============================================================================
  RECOMMENDATION FUNCTIONS
=============================================================================#

"""
    get_scaffold_recommendations(tissue_id::String) -> Vector{ScaffoldRecommendation}

Get evidence-based scaffold design recommendations for a target tissue.

# Arguments
- `tissue_id`: UBERON term ID (e.g., "UBERON:0002481" for bone)

# Returns
Vector of ScaffoldRecommendation with cells, materials, processes, and parameters.
"""
function get_scaffold_recommendations(tissue_id::String)::Vector{ScaffoldRecommendation}
    recommendations = ScaffoldRecommendation[]

    # Check if we have recommendations for this tissue
    if !haskey(TISSUE_RECOMMENDATIONS, tissue_id)
        # Try to find recommendations for parent tissue
        ancestors = _get_ancestors[](tissue_id; max_depth=5)
        found = false
        for anc in ancestors
            if haskey(TISSUE_RECOMMENDATIONS, anc.id)
                tissue_id = anc.id
                found = true
                break
            end
        end
        !found && return recommendations
    end

    tissue_recs = TISSUE_RECOMMENDATIONS[tissue_id]

    # Add cell recommendations
    if haskey(tissue_recs, :cells)
        for rec in tissue_recs[:cells]
            push!(recommendations, ScaffoldRecommendation(
                :cell,
                rec.id,
                rec.name,
                rec.rationale,
                rec.evidence,
                rec.refs,
                Dict{String,Any}()
            ))
        end
    end

    # Add material recommendations
    if haskey(tissue_recs, :materials)
        for rec in tissue_recs[:materials]
            params = haskey(rec, :params) ? rec.params : Dict{String,Any}()
            push!(recommendations, ScaffoldRecommendation(
                :material,
                rec.id,
                rec.name,
                rec.rationale,
                rec.evidence,
                rec.refs,
                params
            ))
        end
    end

    # Add process recommendations
    if haskey(tissue_recs, :processes)
        for rec in tissue_recs[:processes]
            push!(recommendations, ScaffoldRecommendation(
                :process,
                rec.id,
                rec.name,
                rec.rationale,
                rec.evidence,
                rec.refs,
                Dict{String,Any}()
            ))
        end
    end

    # Add parameter recommendations
    if haskey(tissue_recs, :parameters)
        for rec in tissue_recs[:parameters]
            push!(recommendations, ScaffoldRecommendation(
                :parameter,
                nothing,
                rec.name,
                rec.rationale,
                :high,
                rec.refs,
                Dict{String,Any}("min" => rec.min, "optimal" => rec.optimal, "max" => rec.max)
            ))
        end
    end

    return recommendations
end

"""
    get_cells_for_tissue(tissue_id::String) -> Vector

Get recommended cell types for a target tissue.
"""
function get_cells_for_tissue(tissue_id::String)
    recs = get_scaffold_recommendations(tissue_id)
    cell_ids = [r.term_id for r in recs if r.category == :cell && !isnothing(r.term_id)]
    return [t for t in [_smart_lookup[](id) for id in cell_ids] if !isnothing(t)]
end

"""
    get_materials_for_application(tissue_id::String) -> Vector

Get recommended materials for scaffold targeting specific tissue.
"""
function get_materials_for_application(tissue_id::String)
    recs = get_scaffold_recommendations(tissue_id)
    mat_ids = [r.term_id for r in recs if r.category == :material && !isnothing(r.term_id)]
    return [t for t in [_smart_lookup[](id) for id in mat_ids] if !isnothing(t)]
end

"""
    get_biological_processes(tissue_id::String) -> Vector

Get relevant biological processes for tissue regeneration.
"""
function get_biological_processes(tissue_id::String)
    recs = get_scaffold_recommendations(tissue_id)
    proc_ids = [r.term_id for r in recs if r.category == :process && !isnothing(r.term_id)]
    return [t for t in [_smart_lookup[](id) for id in proc_ids] if !isnothing(t)]
end

"""
    recommend_pore_size(tissue_id::String) -> NamedTuple

Get recommended pore size range for tissue type.

# Returns
NamedTuple with (min, optimal, max) in micrometers.
"""
function recommend_pore_size(tissue_id::String)
    recs = get_scaffold_recommendations(tissue_id)

    for rec in recs
        if rec.category == :parameter && rec.name == "pore_size_um"
            return (
                min=rec.parameters["min"],
                optimal=rec.parameters["optimal"],
                max=rec.parameters["max"],
                rationale=rec.rationale,
                references=rec.references
            )
        end
    end

    # Default: general scaffold guidelines
    return (min=50, optimal=150, max=300, rationale="General scaffold guidelines", references=String[])
end

end # module
