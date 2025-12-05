"""
    CrossOntologyRelations

Comprehensive mappings between biomedical ontologies for tissue engineering scaffold design.
Maps relationships between tissues, cells, materials, processes, and diseases.
"""
module CrossOntologyRelations

export TISSUE_CELL_RELATIONS, TISSUE_MATERIAL_RELATIONS, TISSUE_PROCESS_RELATIONS
export DISEASE_TISSUE_RELATIONS, DISEASE_CELL_RELATIONS, MATERIAL_PROPERTY_RELATIONS
export CELL_PROCESS_RELATIONS, TISSUE_PARAMETERS
export ScaffoldProfile, TreatmentPlan, MaterialProfile
export get_complete_scaffold_profile, get_treatment_plan, find_compatible_materials
export get_cells_for_tissue, get_materials_for_tissue, get_processes_for_cell
export get_processes_for_tissue, get_material_properties
export validate_scaffold_design

using ..Types: ScaffoldParameters

#=============================================================================
                            DATA STRUCTURES
=============================================================================#

"""
    ScaffoldProfile

Complete profile for tissue-specific scaffold design including cells, materials,
processes, and optimal parameters.
"""
struct ScaffoldProfile
    tissue_id::String
    tissue_name::String
    recommended_cells::Vector{String}
    recommended_materials::Vector{String}
    target_processes::Vector{String}
    optimal_parameters::Dict{String,Any}
    mechanical_requirements::Dict{String,Any}
end

"""
    TreatmentPlan

Complete treatment plan for disease-specific scaffold design.
"""
struct TreatmentPlan
    disease_id::String
    disease_name::String
    target_tissues::Vector{String}
    required_cells::Vector{String}
    recommended_materials::Vector{String}
    therapeutic_processes::Vector{String}
    scaffold_parameters::Dict{String,Any}
    bioactive_factors::Vector{String}
end

"""
    MaterialProfile

Physical and chemical properties of scaffold materials.
"""
struct MaterialProfile
    material_id::String
    material_name::String
    mechanical_properties::Dict{String,Any}
    degradation_rate::String
    biocompatibility::Float64
    osteoconductivity::Float64
    cell_adhesion::Float64
    suitable_tissues::Vector{String}
end

#=============================================================================
                    TISSUE → CELLS RELATIONSHIPS
=============================================================================#

"""
Mapping from tissue types to their constituent cell types.
Uses UBERON (tissue) and CL (cell) ontologies.
"""
const TISSUE_CELL_RELATIONS = Dict{String,Vector{String}}(
    # Skeletal System
    "UBERON:0002481" => ["CL:0000062", "CL:0000136", "CL:0000137", "CL:0000138"],  # Bone → osteoblast, adipocyte, chondrocyte, chondroblast
    "UBERON:0002418" => ["CL:0000137", "CL:0000138", "CL:0000559"],  # Cartilage → chondrocyte, chondroblast, proendothelial cell
    "UBERON:0001976" => ["CL:0000062", "CL:0000136", "CL:0002092"],  # Bone marrow → osteoblast, adipocyte, hematopoietic stem cell

    # Cardiovascular System
    "UBERON:0000948" => ["CL:0000746", "CL:0000187", "CL:0000169"],  # Heart → cardiac muscle cell, muscle cell, endothelial cell
    "UBERON:0001981" => ["CL:0000359", "CL:0000169", "CL:0000071"],  # Blood vessel → vascular smooth muscle, endothelial, blood vessel endothelial
    "UBERON:0002348" => ["CL:0000746", "CL:0000746"],  # Myocardium → cardiac muscle cell

    # Nervous System
    "UBERON:0001016" => ["CL:0000540", "CL:0000125", "CL:0000127"],  # Nervous tissue → neuron, glial cell, astrocyte
    "UBERON:0000955" => ["CL:0000540", "CL:0000125", "CL:0000128"],  # Brain → neuron, glial cell, oligodendrocyte
    "UBERON:0002240" => ["CL:0000540", "CL:0000125", "CL:0002319"],  # Spinal cord → neuron, glial cell, neural cell

    # Skin and Connective Tissue
    "UBERON:0001003" => ["CL:0000312", "CL:0000115", "CL:0000147"],  # Skin → keratinocyte, endothelial cell, fibroblast
    "UBERON:0002358" => ["CL:0000057", "CL:0000147", "CL:0000359"],  # Dermis → fibroblast, smooth muscle
    "UBERON:0007376" => ["CL:0000057", "CL:0002620"],  # Connective tissue → fibroblast, skin fibroblast

    # Muscle
    "UBERON:0001630" => ["CL:0000187", "CL:0000188"],  # Muscle tissue → muscle cell, skeletal muscle cell
    "UBERON:0001134" => ["CL:0000188", "CL:0000037"],  # Skeletal muscle → skeletal muscle cell, satellite cell
    "UBERON:0001135" => ["CL:0000359", "CL:0000192"],  # Smooth muscle → vascular smooth muscle, smooth muscle cell

    # Organs
    "UBERON:0002107" => ["CL:0000182", "CL:0000169", "CL:0000632"],  # Liver → hepatocyte, endothelial cell, hepatic stellate cell
    "UBERON:0002113" => ["CL:0002584", "CL:0000169", "CL:0000650"],  # Kidney → renal epithelial cell, endothelial cell, mesangial cell
    "UBERON:0001443" => ["CL:0000650", "CL:0002371"],  # Chest → mesangial cell, somatic cell
    "UBERON:0001264" => ["CL:0000169", "CL:0000057"],  # Pancreas → endothelial cell, fibroblast

    # Respiratory
    "UBERON:0002048" => ["CL:0002632", "CL:0000082", "CL:0000169"],  # Lung → alveolar cell, epithelial cell, endothelial cell
    "UBERON:0000117" => ["CL:0000082", "CL:0000066"],  # Respiratory tube → epithelial cell, epithelial cell of lung

    # Dental
    "UBERON:0001091" => ["CL:0000062", "CL:0000060", "CL:0000065"],  # Tooth → osteoblast, odontoblast, enamel cell
    "UBERON:0001684" => ["CL:0000060", "CL:0000062"],  # Dentin → odontoblast, osteoblast

    # Other
    "UBERON:0003688" => ["CL:0000065", "CL:0000147"],  # Orofacial → enamel cell, fibroblast
    "UBERON:0001017" => ["CL:0000057", "CL:0000169"],  # Central nervous system → fibroblast, endothelial cell
    "UBERON:0001434" => ["CL:0000187", "CL:0000359"],  # Skeletal system → muscle cell, smooth muscle
)

#=============================================================================
                TISSUE → MATERIALS RELATIONSHIPS
=============================================================================#

"""
Mapping from tissue types to recommended scaffold materials.
"""
const TISSUE_MATERIAL_RELATIONS = Dict{String,Vector{String}}(
    # Skeletal System
    "UBERON:0002481" => ["CHEBI:46662", "CHEBI:53448", "CHEBI:74811", "bioactive_glass_45S5", "beta_TCP"],  # Bone
    "UBERON:0002418" => ["CHEBI:16135", "CHEBI:37684", "CHEBI:46662", "collagen_type_II"],  # Cartilage
    "UBERON:0001976" => ["CHEBI:46662", "CHEBI:53448", "collagen_gelatin_blend"],  # Bone marrow

    # Cardiovascular System
    "UBERON:0000948" => ["CHEBI:37684", "CHEBI:53448", "CHEBI:46195", "decellularized_ECM"],  # Heart
    "UBERON:0001981" => ["CHEBI:53448", "CHEBI:46195", "CHEBI:37684", "elastin_collagen"],  # Blood vessel
    "UBERON:0002348" => ["CHEBI:53448", "CHEBI:46195", "cardiac_patch"],  # Myocardium

    # Nervous System
    "UBERON:0001016" => ["CHEBI:37684", "CHEBI:46195", "CHEBI:53448", "laminin_substrate"],  # Nervous tissue
    "UBERON:0000955" => ["CHEBI:46195", "CHEBI:37684", "neural_hydrogel"],  # Brain
    "UBERON:0002240" => ["CHEBI:46195", "CHEBI:37684", "collagen_tube"],  # Spinal cord

    # Skin and Connective Tissue
    "UBERON:0001003" => ["CHEBI:16135", "CHEBI:53448", "CHEBI:37684", "chitosan_collagen"],  # Skin
    "UBERON:0002358" => ["CHEBI:53448", "CHEBI:16135", "dermal_matrix"],  # Dermis
    "UBERON:0007376" => ["CHEBI:53448", "CHEBI:16135", "CHEBI:37684"],  # Connective tissue

    # Muscle
    "UBERON:0001630" => ["CHEBI:53448", "CHEBI:37684", "CHEBI:46195"],  # Muscle tissue
    "UBERON:0001134" => ["CHEBI:53448", "CHEBI:46195", "myogenic_scaffold"],  # Skeletal muscle
    "UBERON:0001135" => ["CHEBI:46195", "CHEBI:53448", "elastin_blend"],  # Smooth muscle

    # Organs
    "UBERON:0002107" => ["CHEBI:37684", "CHEBI:53448", "decellularized_liver"],  # Liver
    "UBERON:0002113" => ["CHEBI:53448", "CHEBI:37684", "renal_ECM"],  # Kidney
    "UBERON:0001443" => ["CHEBI:53448", "CHEBI:46662"],  # Chest
    "UBERON:0001264" => ["CHEBI:37684", "CHEBI:53448", "pancreatic_ECM"],  # Pancreas

    # Respiratory
    "UBERON:0002048" => ["CHEBI:53448", "CHEBI:37684", "lung_ECM"],  # Lung
    "UBERON:0000117" => ["CHEBI:46195", "CHEBI:53448"],  # Respiratory tube

    # Dental
    "UBERON:0001091" => ["CHEBI:46662", "CHEBI:74811", "bioactive_glass_45S5"],  # Tooth
    "UBERON:0001684" => ["CHEBI:46662", "CHEBI:74811"],  # Dentin

    # Other
    "UBERON:0003688" => ["CHEBI:46662", "CHEBI:53448"],  # Orofacial
    "UBERON:0001017" => ["CHEBI:37684", "CHEBI:46195"],  # Central nervous system
    "UBERON:0001434" => ["CHEBI:46662", "CHEBI:53448"],  # Skeletal system
)

#=============================================================================
                TISSUE → PROCESSES RELATIONSHIPS
=============================================================================#

"""
Mapping from tissue types to biological processes needed for regeneration.
Uses GO (Gene Ontology) process terms.
"""
const TISSUE_PROCESS_RELATIONS = Dict{String,Vector{String}}(
    "UBERON:0002481" => ["GO:0001503", "GO:0001649", "GO:0030278", "GO:0045668"],  # Bone → ossification, osteoblast differentiation, regulation of bone mineralization
    "UBERON:0002418" => ["GO:0051216", "GO:0001501", "GO:0030198"],  # Cartilage → cartilage development, skeletal system development, ECM organization
    "UBERON:0001976" => ["GO:0030099", "GO:0002063"],  # Bone marrow → myeloid cell differentiation, chondrocyte development
    "UBERON:0000948" => ["GO:0060047", "GO:0055007", "GO:0003007"],  # Heart → heart contraction, cardiac muscle cell differentiation
    "UBERON:0001981" => ["GO:0001568", "GO:0001974"],  # Blood vessel → blood vessel development, blood vessel remodeling
    "UBERON:0002348" => ["GO:0055008", "GO:0060047"],  # Myocardium → cardiac muscle tissue morphogenesis, heart contraction
    "UBERON:0001016" => ["GO:0022008", "GO:0007409", "GO:0007420"],  # Nervous tissue → neurogenesis, axonogenesis, brain development
    "UBERON:0000955" => ["GO:0007420", "GO:0022008", "GO:0048666"],  # Brain → brain development, neurogenesis, neuron development
    "UBERON:0002240" => ["GO:0021510", "GO:0007409"],  # Spinal cord → spinal cord development, axonogenesis
    "UBERON:0001003" => ["GO:0043588", "GO:0008544", "GO:0042060"],  # Skin → skin development, epidermis development, wound healing
    "UBERON:0002358" => ["GO:0060485", "GO:0030198"],  # Dermis → mesenchyme development, ECM organization
    "UBERON:0007376" => ["GO:0030198", "GO:0022617"],  # Connective tissue → ECM organization, ECM disassembly
    "UBERON:0001630" => ["GO:0042692", "GO:0014706"],  # Muscle tissue → muscle cell differentiation, striated muscle tissue development
    "UBERON:0001134" => ["GO:0014706", "GO:0014866"],  # Skeletal muscle → striated muscle development, skeletal myofibril assembly
    "UBERON:0001135" => ["GO:0014706", "GO:0048513"],  # Smooth muscle → organ development
    "UBERON:0002107" => ["GO:0061008", "GO:0070365"],  # Liver → hepatocyte differentiation, hepatocyte growth
    "UBERON:0002113" => ["GO:0072006", "GO:0072073"],  # Kidney → nephron development, renal filtration
    "UBERON:0001264" => ["GO:0031016", "GO:0003323"],  # Pancreas → pancreas development
    "UBERON:0002048" => ["GO:0030324", "GO:0060541"],  # Lung → lung development, respiratory system development
    "UBERON:0000117" => ["GO:0060541", "GO:0030323"],  # Respiratory tube → respiratory system development
    "UBERON:0001091" => ["GO:0042475", "GO:0042476"],  # Tooth → odontogenesis, odontogenesis of dentin
    "UBERON:0001684" => ["GO:0042476"],  # Dentin → odontogenesis of dentin
    "UBERON:0003688" => ["GO:0060434"],  # Orofacial → bronchus morphogenesis
    "UBERON:0001017" => ["GO:0007399", "GO:0022008"],  # Central nervous system → nervous system development, neurogenesis
    "UBERON:0001434" => ["GO:0001501", "GO:0001503"],  # Skeletal system → skeletal system development, ossification
)

#=============================================================================
                DISEASE → TISSUE RELATIONSHIPS
=============================================================================#

"""
Mapping from diseases to target tissues for treatment.
Uses DOID (Disease Ontology) and UBERON.
"""
const DISEASE_TISSUE_RELATIONS = Dict{String,Vector{String}}(
    # Musculoskeletal Diseases
    "DOID:11476" => ["UBERON:0002481", "UBERON:0001976"],  # Osteoporosis → bone, bone marrow
    "DOID:1470" => ["UBERON:0002481"],  # Bone fracture → bone
    "DOID:8398" => ["UBERON:0002481", "UBERON:0001434"],  # Osteoarthritis → bone, skeletal system
    "DOID:7148" => ["UBERON:0002481", "UBERON:0001976"],  # Rheumatoid arthritis → bone, bone marrow
    "DOID:9352" => ["UBERON:0002481"],  # Osteonecrosis → bone
    "DOID:10609" => ["UBERON:0002418"],  # Rickets → cartilage
    "DOID:0060448" => ["UBERON:0001976"],  # Anemia → bone marrow

    # Cardiovascular Diseases
    "DOID:5844" => ["UBERON:0000948", "UBERON:0002348"],  # Myocardial infarction → heart, myocardium
    "DOID:6000" => ["UBERON:0000948"],  # Heart failure → heart
    "DOID:0060625" => ["UBERON:0001981"],  # Atherosclerosis → blood vessel
    "DOID:0080004" => ["UBERON:0000948"],  # Cardiomyopathy → heart
    "DOID:1287" => ["UBERON:0001981"],  # Peripheral vascular disease → blood vessel

    # Neurological Diseases
    "DOID:2377" => ["UBERON:0001016", "UBERON:0000955"],  # Multiple sclerosis → nervous tissue, brain
    "DOID:14330" => ["UBERON:0000955"],  # Parkinson's disease → brain
    "DOID:10652" => ["UBERON:0000955"],  # Alzheimer's disease → brain
    "DOID:3082" => ["UBERON:0002240"],  # Spinal cord injury → spinal cord
    "DOID:1826" => ["UBERON:0001016"],  # Epilepsy → nervous tissue
    "DOID:10286" => ["UBERON:0000955"],  # Prostate cancer → brain (metastasis)

    # Skin and Wound Diseases
    "DOID:2729" => ["UBERON:0001003", "UBERON:0002358"],  # Burn → skin, dermis
    "DOID:0060429" => ["UBERON:0001003"],  # Chronic wound → skin
    "DOID:8577" => ["UBERON:0001003"],  # Ulcer → skin
    "DOID:1492" => ["UBERON:0001003"],  # Dermatitis → skin

    # Muscle Diseases
    "DOID:423" => ["UBERON:0001134"],  # Muscular dystrophy → skeletal muscle
    "DOID:206" => ["UBERON:0001630"],  # Sarcopenia → muscle tissue
    "DOID:10763" => ["UBERON:0001134"],  # Rhabdomyolysis → skeletal muscle

    # Organ Diseases
    "DOID:5082" => ["UBERON:0002107"],  # Liver cirrhosis → liver
    "DOID:9744" => ["UBERON:0002107"],  # Hepatic failure → liver
    "DOID:1686" => ["UBERON:0002113"],  # Chronic kidney disease → kidney
    "DOID:557" => ["UBERON:0002113"],  # Kidney failure → kidney
    "DOID:1192" => ["UBERON:0001264"],  # Diabetes mellitus → pancreas

    # Respiratory Diseases
    "DOID:1686" => ["UBERON:0002048"],  # COPD → lung
    "DOID:4471" => ["UBERON:0002048"],  # Pulmonary fibrosis → lung
    "DOID:552" => ["UBERON:0002048", "UBERON:0000117"],  # Pneumonia → lung, respiratory tube

    # Dental Diseases
    "DOID:1091" => ["UBERON:0001091"],  # Tooth loss → tooth
    "DOID:12167" => ["UBERON:0001684"],  # Periodontal disease → dentin
)

#=============================================================================
                DISEASE → CELLS RELATIONSHIPS
=============================================================================#

"""
Mapping from diseases to cells needed for treatment.
"""
const DISEASE_CELL_RELATIONS = Dict{String,Vector{String}}(
    "DOID:11476" => ["CL:0000062", "CL:0000136"],  # Osteoporosis → osteoblast, adipocyte
    "DOID:1470" => ["CL:0000062", "CL:0002092"],  # Bone fracture → osteoblast, stem cell
    "DOID:8398" => ["CL:0000062", "CL:0000137"],  # Osteoarthritis → osteoblast, chondrocyte
    "DOID:7148" => ["CL:0000062", "CL:0002092"],  # Rheumatoid arthritis → osteoblast, stem cell
    "DOID:9352" => ["CL:0000062", "CL:0000169"],  # Osteonecrosis → osteoblast, endothelial
    "DOID:5844" => ["CL:0000746", "CL:0000169"],  # Myocardial infarction → cardiac muscle, endothelial
    "DOID:6000" => ["CL:0000746", "CL:0002371"],  # Heart failure → cardiac muscle, somatic cell
    "DOID:0060625" => ["CL:0000169", "CL:0000359"],  # Atherosclerosis → endothelial, smooth muscle
    "DOID:0080004" => ["CL:0000746"],  # Cardiomyopathy → cardiac muscle
    "DOID:2377" => ["CL:0000540", "CL:0000125"],  # Multiple sclerosis → neuron, glial
    "DOID:14330" => ["CL:0000540", "CL:0000127"],  # Parkinson's → neuron, astrocyte
    "DOID:10652" => ["CL:0000540", "CL:0000125"],  # Alzheimer's → neuron, glial
    "DOID:3082" => ["CL:0000540", "CL:0000125"],  # Spinal cord injury → neuron, glial
    "DOID:2729" => ["CL:0000312", "CL:0000057"],  # Burn → keratinocyte, fibroblast
    "DOID:0060429" => ["CL:0000312", "CL:0000169"],  # Chronic wound → keratinocyte, endothelial
    "DOID:8577" => ["CL:0000057", "CL:0000169"],  # Ulcer → fibroblast, endothelial
    "DOID:423" => ["CL:0000188", "CL:0000037"],  # Muscular dystrophy → skeletal muscle, satellite cell
    "DOID:206" => ["CL:0000187"],  # Sarcopenia → muscle cell
    "DOID:5082" => ["CL:0000182", "CL:0000632"],  # Liver cirrhosis → hepatocyte, stellate cell
    "DOID:9744" => ["CL:0000182"],  # Hepatic failure → hepatocyte
    "DOID:1686" => ["CL:0002584", "CL:0000650"],  # Chronic kidney disease → renal epithelial, mesangial
    "DOID:557" => ["CL:0002584"],  # Kidney failure → renal epithelial
    "DOID:1192" => ["CL:0000169"],  # Diabetes → endothelial
    "DOID:4471" => ["CL:0002632", "CL:0000082"],  # Pulmonary fibrosis → alveolar, epithelial
    "DOID:552" => ["CL:0000082"],  # Pneumonia → epithelial
    "DOID:1091" => ["CL:0000062", "CL:0000060"],  # Tooth loss → osteoblast, odontoblast
    "DOID:12167" => ["CL:0000060"],  # Periodontal disease → odontoblast
    "DOID:10609" => ["CL:0000137"],  # Rickets → chondrocyte
    "DOID:0060448" => ["CL:0002092"],  # Anemia → stem cell
    "DOID:1287" => ["CL:0000169", "CL:0000359"],  # Peripheral vascular → endothelial, smooth muscle
    "DOID:1826" => ["CL:0000540"],  # Epilepsy → neuron
    "DOID:10286" => ["CL:0000540"],  # Prostate cancer → neuron
    "DOID:1492" => ["CL:0000312"],  # Dermatitis → keratinocyte
    "DOID:10763" => ["CL:0000188"],  # Rhabdomyolysis → skeletal muscle
)

#=============================================================================
                MATERIAL → PROPERTIES RELATIONSHIPS
=============================================================================#

"""
Physical and chemical properties of scaffold materials.
"""
const MATERIAL_PROPERTY_RELATIONS = Dict{String,Dict{String,Any}}(
    "CHEBI:46662" => Dict(  # Hydroxyapatite
        "youngs_modulus_GPa" => 80.0,
        "compressive_strength_MPa" => 600.0,
        "degradation_rate" => "slow",
        "biocompatibility" => 1.0,
        "osteoconductivity" => 1.0,
        "cell_adhesion" => 0.9,
        "porosity_range" => (0.5, 0.8),
        "pore_size_um" => (100, 500)
    ),
    "CHEBI:53448" => Dict(  # Collagen
        "youngs_modulus_GPa" => 0.005,
        "compressive_strength_MPa" => 0.5,
        "degradation_rate" => "fast",
        "biocompatibility" => 1.0,
        "osteoconductivity" => 0.7,
        "cell_adhesion" => 1.0,
        "porosity_range" => (0.8, 0.95),
        "pore_size_um" => (50, 200)
    ),
    "CHEBI:16135" => Dict(  # Chitosan
        "youngs_modulus_GPa" => 0.003,
        "compressive_strength_MPa" => 2.0,
        "degradation_rate" => "medium",
        "biocompatibility" => 0.95,
        "osteoconductivity" => 0.6,
        "cell_adhesion" => 0.85,
        "porosity_range" => (0.7, 0.9),
        "pore_size_um" => (100, 300)
    ),
    "CHEBI:37684" => Dict(  # Polylactic acid (PLA)
        "youngs_modulus_GPa" => 3.5,
        "compressive_strength_MPa" => 50.0,
        "degradation_rate" => "medium",
        "biocompatibility" => 0.9,
        "osteoconductivity" => 0.5,
        "cell_adhesion" => 0.7,
        "porosity_range" => (0.6, 0.85),
        "pore_size_um" => (100, 400)
    ),
    "CHEBI:74811" => Dict(  # Polycaprolactone (PCL)
        "youngs_modulus_GPa" => 0.4,
        "compressive_strength_MPa" => 16.0,
        "degradation_rate" => "slow",
        "biocompatibility" => 0.92,
        "osteoconductivity" => 0.6,
        "cell_adhesion" => 0.75,
        "porosity_range" => (0.65, 0.85),
        "pore_size_um" => (100, 350)
    ),
    "CHEBI:46195" => Dict(  # Alginate
        "youngs_modulus_GPa" => 0.001,
        "compressive_strength_MPa" => 0.1,
        "degradation_rate" => "fast",
        "biocompatibility" => 0.98,
        "osteoconductivity" => 0.3,
        "cell_adhesion" => 0.8,
        "porosity_range" => (0.85, 0.95),
        "pore_size_um" => (50, 150)
    ),
    "bioactive_glass_45S5" => Dict(
        "youngs_modulus_GPa" => 35.0,
        "compressive_strength_MPa" => 500.0,
        "degradation_rate" => "medium",
        "biocompatibility" => 1.0,
        "osteoconductivity" => 0.95,
        "cell_adhesion" => 0.9,
        "porosity_range" => (0.5, 0.75),
        "pore_size_um" => (100, 500)
    ),
    "beta_TCP" => Dict(  # Beta-tricalcium phosphate
        "youngs_modulus_GPa" => 50.0,
        "compressive_strength_MPa" => 400.0,
        "degradation_rate" => "medium",
        "biocompatibility" => 1.0,
        "osteoconductivity" => 0.95,
        "cell_adhesion" => 0.88,
        "porosity_range" => (0.55, 0.8),
        "pore_size_um" => (100, 500)
    )
)

#=============================================================================
                CELL → PROCESSES RELATIONSHIPS
=============================================================================#

"""
Biological processes that cells undergo during tissue regeneration.
"""
const CELL_PROCESS_RELATIONS = Dict{String,Vector{String}}(
    "CL:0000062" => ["GO:0001649", "GO:0030278", "GO:0001503"],  # Osteoblast → differentiation, mineralization, ossification
    "CL:0000137" => ["GO:0002063", "GO:0051216"],  # Chondrocyte → development, cartilage development
    "CL:0000746" => ["GO:0055007", "GO:0060047"],  # Cardiac muscle → differentiation, contraction
    "CL:0000169" => ["GO:0001568", "GO:0001974"],  # Endothelial → vessel development, vessel remodeling
    "CL:0000540" => ["GO:0022008", "GO:0007409"],  # Neuron → neurogenesis, axonogenesis
    "CL:0000312" => ["GO:0008544", "GO:0043588"],  # Keratinocyte → epidermis development, skin development
    "CL:0000057" => ["GO:0030198", "GO:0042060"],  # Fibroblast → ECM organization, wound healing
    "CL:0000188" => ["GO:0014866", "GO:0042692"],  # Skeletal muscle → myofibril assembly, differentiation
    "CL:0000182" => ["GO:0061008"],  # Hepatocyte → differentiation
    "CL:0002584" => ["GO:0072006"],  # Renal epithelial → nephron development
    "CL:0000125" => ["GO:0007409"],  # Glial → axonogenesis
    "CL:0000359" => ["GO:0001974"],  # Vascular smooth muscle → vessel remodeling
    "CL:0000060" => ["GO:0042476"],  # Odontoblast → dentin formation
)

#=============================================================================
                TISSUE → OPTIMAL PARAMETERS
=============================================================================#

"""
Optimal scaffold parameters for each tissue type based on literature.
"""
const TISSUE_PARAMETERS = Dict{String,Dict{String,Any}}(
    "UBERON:0002481" => Dict(  # Bone
        "porosity" => 0.70,
        "pore_size_um" => 350.0,
        "interconnectivity" => 0.95,
        "youngs_modulus_GPa" => 15.0,
        "target_mechanical_strength" => "high",
        "degradation_profile" => "slow_controlled",
        "growth_factors" => ["BMP-2", "BMP-7", "VEGF"]
    ),
    "UBERON:0002418" => Dict(  # Cartilage
        "porosity" => 0.85,
        "pore_size_um" => 150.0,
        "interconnectivity" => 0.90,
        "youngs_modulus_GPa" => 0.01,
        "target_mechanical_strength" => "medium",
        "degradation_profile" => "medium",
        "growth_factors" => ["TGF-β", "IGF-1"]
    ),
    "UBERON:0000948" => Dict(  # Heart
        "porosity" => 0.80,
        "pore_size_um" => 100.0,
        "interconnectivity" => 0.92,
        "youngs_modulus_GPa" => 0.05,
        "target_mechanical_strength" => "medium",
        "degradation_profile" => "slow",
        "growth_factors" => ["VEGF", "FGF", "IGF-1"]
    ),
    "UBERON:0001003" => Dict(  # Skin
        "porosity" => 0.88,
        "pore_size_um" => 80.0,
        "interconnectivity" => 0.85,
        "youngs_modulus_GPa" => 0.001,
        "target_mechanical_strength" => "low",
        "degradation_profile" => "fast",
        "growth_factors" => ["EGF", "PDGF", "VEGF"]
    ),
    "UBERON:0001016" => Dict(  # Nervous tissue
        "porosity" => 0.90,
        "pore_size_um" => 50.0,
        "interconnectivity" => 0.88,
        "youngs_modulus_GPa" => 0.0005,
        "target_mechanical_strength" => "low",
        "degradation_profile" => "slow",
        "growth_factors" => ["NGF", "BDNF", "GDNF"]
    ),
    "UBERON:0001134" => Dict(  # Skeletal muscle
        "porosity" => 0.82,
        "pore_size_um" => 120.0,
        "interconnectivity" => 0.90,
        "youngs_modulus_GPa" => 0.01,
        "target_mechanical_strength" => "medium",
        "degradation_profile" => "medium",
        "growth_factors" => ["IGF-1", "HGF", "FGF"]
    ),
    "UBERON:0002107" => Dict(  # Liver
        "porosity" => 0.85,
        "pore_size_um" => 100.0,
        "interconnectivity" => 0.92,
        "youngs_modulus_GPa" => 0.005,
        "target_mechanical_strength" => "low",
        "degradation_profile" => "medium",
        "growth_factors" => ["HGF", "EGF", "VEGF"]
    ),
    "UBERON:0002113" => Dict(  # Kidney
        "porosity" => 0.83,
        "pore_size_um" => 110.0,
        "interconnectivity" => 0.91,
        "youngs_modulus_GPa" => 0.008,
        "target_mechanical_strength" => "medium",
        "degradation_profile" => "slow",
        "growth_factors" => ["VEGF", "FGF", "IGF-1"]
    ),
    "UBERON:0002048" => Dict(  # Lung
        "porosity" => 0.92,
        "pore_size_um" => 70.0,
        "interconnectivity" => 0.90,
        "youngs_modulus_GPa" => 0.002,
        "target_mechanical_strength" => "low",
        "degradation_profile" => "medium",
        "growth_factors" => ["VEGF", "KGF"]
    ),
    "UBERON:0001091" => Dict(  # Tooth
        "porosity" => 0.65,
        "pore_size_um" => 200.0,
        "interconnectivity" => 0.88,
        "youngs_modulus_GPa" => 20.0,
        "target_mechanical_strength" => "very_high",
        "degradation_profile" => "very_slow",
        "growth_factors" => ["BMP-2", "VEGF"]
    )
)

#=============================================================================
                        QUERY FUNCTIONS
=============================================================================#

"""
    get_cells_for_tissue(tissue_id::String)

Get all cell types associated with a tissue.
"""
function get_cells_for_tissue(tissue_id::String)::Vector{String}
    return get(TISSUE_CELL_RELATIONS, tissue_id, String[])
end

"""
    get_materials_for_tissue(tissue_id::String)

Get recommended materials for a tissue type.
"""
function get_materials_for_tissue(tissue_id::String)::Vector{String}
    return get(TISSUE_MATERIAL_RELATIONS, tissue_id, String[])
end

"""
    get_processes_for_tissue(tissue_id::String)

Get biological processes needed for tissue regeneration.
"""
function get_processes_for_tissue(tissue_id::String)::Vector{String}
    return get(TISSUE_PROCESS_RELATIONS, tissue_id, String[])
end

"""
    get_processes_for_cell(cell_id::String)

Get biological processes that a cell type undergoes.
"""
function get_processes_for_cell(cell_id::String)::Vector{String}
    return get(CELL_PROCESS_RELATIONS, cell_id, String[])
end

"""
    get_material_properties(material_id::String)

Get physical and chemical properties of a material.
"""
function get_material_properties(material_id::String)::Dict{String,Any}
    return get(MATERIAL_PROPERTY_RELATIONS, material_id, Dict{String,Any}())
end

"""
    get_complete_scaffold_profile(tissue_id::String)::ScaffoldProfile

Returns a complete scaffold design profile for a specific tissue type,
including recommended cells, materials, processes, and optimal parameters.

# Arguments
- `tissue_id::String`: UBERON tissue ontology ID (e.g., "UBERON:0002481" for bone)

# Returns
- `ScaffoldProfile`: Complete design specification

# Example
```julia
profile = get_complete_scaffold_profile("UBERON:0002481")
println("Tissue: ", profile.tissue_name)
println("Cells: ", profile.recommended_cells)
println("Materials: ", profile.recommended_materials)
println("Optimal porosity: ", profile.optimal_parameters["porosity"])
```
"""
function get_complete_scaffold_profile(tissue_id::String)::ScaffoldProfile
    # Get tissue name mapping
    tissue_names = Dict(
        "UBERON:0002481" => "Bone",
        "UBERON:0002418" => "Cartilage",
        "UBERON:0001976" => "Bone Marrow",
        "UBERON:0000948" => "Heart",
        "UBERON:0001981" => "Blood Vessel",
        "UBERON:0002348" => "Myocardium",
        "UBERON:0001016" => "Nervous Tissue",
        "UBERON:0000955" => "Brain",
        "UBERON:0002240" => "Spinal Cord",
        "UBERON:0001003" => "Skin",
        "UBERON:0002358" => "Dermis",
        "UBERON:0007376" => "Connective Tissue",
        "UBERON:0001630" => "Muscle Tissue",
        "UBERON:0001134" => "Skeletal Muscle",
        "UBERON:0001135" => "Smooth Muscle",
        "UBERON:0002107" => "Liver",
        "UBERON:0002113" => "Kidney",
        "UBERON:0001264" => "Pancreas",
        "UBERON:0002048" => "Lung",
        "UBERON:0000117" => "Respiratory Tube",
        "UBERON:0001091" => "Tooth",
        "UBERON:0001684" => "Dentin"
    )

    tissue_name = get(tissue_names, tissue_id, "Unknown Tissue")
    cells = get_cells_for_tissue(tissue_id)
    materials = get_materials_for_tissue(tissue_id)
    processes = get_processes_for_tissue(tissue_id)
    params = get(TISSUE_PARAMETERS, tissue_id, Dict{String,Any}())

    # Extract mechanical requirements
    mechanical_reqs = Dict{String,Any}()
    if haskey(params, "youngs_modulus_GPa")
        mechanical_reqs["youngs_modulus_GPa"] = params["youngs_modulus_GPa"]
    end
    if haskey(params, "target_mechanical_strength")
        mechanical_reqs["strength_level"] = params["target_mechanical_strength"]
    end

    return ScaffoldProfile(
        tissue_id,
        tissue_name,
        cells,
        materials,
        processes,
        params,
        mechanical_reqs
    )
end

"""
    get_treatment_plan(disease_id::String)::TreatmentPlan

Returns a comprehensive treatment plan for a specific disease,
including target tissues, required cells, recommended materials,
and therapeutic processes.

# Arguments
- `disease_id::String`: DOID disease ontology ID (e.g., "DOID:11476" for osteoporosis)

# Returns
- `TreatmentPlan`: Complete treatment specification

# Example
```julia
plan = get_treatment_plan("DOID:11476")
println("Disease: ", plan.disease_name)
println("Target tissues: ", plan.target_tissues)
println("Required cells: ", plan.required_cells)
println("Bioactive factors: ", plan.bioactive_factors)
```
"""
function get_treatment_plan(disease_id::String)::TreatmentPlan
    # Disease name mapping
    disease_names = Dict(
        "DOID:11476" => "Osteoporosis",
        "DOID:1470" => "Bone Fracture",
        "DOID:8398" => "Osteoarthritis",
        "DOID:7148" => "Rheumatoid Arthritis",
        "DOID:9352" => "Osteonecrosis",
        "DOID:10609" => "Rickets",
        "DOID:0060448" => "Anemia",
        "DOID:5844" => "Myocardial Infarction",
        "DOID:6000" => "Heart Failure",
        "DOID:0060625" => "Atherosclerosis",
        "DOID:0080004" => "Cardiomyopathy",
        "DOID:1287" => "Peripheral Vascular Disease",
        "DOID:2377" => "Multiple Sclerosis",
        "DOID:14330" => "Parkinson's Disease",
        "DOID:10652" => "Alzheimer's Disease",
        "DOID:3082" => "Spinal Cord Injury",
        "DOID:1826" => "Epilepsy",
        "DOID:2729" => "Burn",
        "DOID:0060429" => "Chronic Wound",
        "DOID:8577" => "Ulcer",
        "DOID:1492" => "Dermatitis",
        "DOID:423" => "Muscular Dystrophy",
        "DOID:206" => "Sarcopenia",
        "DOID:10763" => "Rhabdomyolysis",
        "DOID:5082" => "Liver Cirrhosis",
        "DOID:9744" => "Hepatic Failure",
        "DOID:1686" => "Chronic Kidney Disease",
        "DOID:557" => "Kidney Failure",
        "DOID:1192" => "Diabetes Mellitus",
        "DOID:4471" => "Pulmonary Fibrosis",
        "DOID:552" => "Pneumonia",
        "DOID:1091" => "Tooth Loss",
        "DOID:12167" => "Periodontal Disease"
    )

    disease_name = get(disease_names, disease_id, "Unknown Disease")
    target_tissues = get(DISEASE_TISSUE_RELATIONS, disease_id, String[])
    required_cells = get(DISEASE_CELL_RELATIONS, disease_id, String[])

    # Aggregate materials from all target tissues
    materials = String[]
    processes = String[]
    scaffold_params = Dict{String,Any}()

    for tissue_id in target_tissues
        append!(materials, get_materials_for_tissue(tissue_id))
        append!(processes, get_processes_for_tissue(tissue_id))

        # Use parameters from primary tissue
        if isempty(scaffold_params)
            scaffold_params = get(TISSUE_PARAMETERS, tissue_id, Dict{String,Any}())
        end
    end

    # Remove duplicates
    materials = unique(materials)
    processes = unique(processes)

    # Get bioactive factors from tissue parameters
    bioactive_factors = String[]
    for tissue_id in target_tissues
        params = get(TISSUE_PARAMETERS, tissue_id, Dict{String,Any}())
        if haskey(params, "growth_factors")
            append!(bioactive_factors, params["growth_factors"])
        end
    end
    bioactive_factors = unique(bioactive_factors)

    return TreatmentPlan(
        disease_id,
        disease_name,
        target_tissues,
        required_cells,
        materials,
        processes,
        scaffold_params,
        bioactive_factors
    )
end

"""
    find_compatible_materials(tissue_id::String, property_requirements::Dict{String,Any})

Find materials compatible with a tissue type that meet specific property requirements.

# Arguments
- `tissue_id::String`: UBERON tissue ID
- `property_requirements::Dict{String,Any}`: Required properties (e.g., min/max Young's modulus)

# Returns
- `Vector{Tuple{String,Float64}}`: List of (material_id, compatibility_score) pairs

# Example
```julia
requirements = Dict(
    "min_youngs_modulus_GPa" => 10.0,
    "min_biocompatibility" => 0.9,
    "degradation_rate" => "slow"
)
compatible = find_compatible_materials("UBERON:0002481", requirements)
```
"""
function find_compatible_materials(
    tissue_id::String,
    property_requirements::Dict{String,Any}
)::Vector{Tuple{String,Float64}}

    recommended_materials = get_materials_for_tissue(tissue_id)
    compatible = Tuple{String,Float64}[]

    for material_id in recommended_materials
        props = get_material_properties(material_id)
        if isempty(props)
            continue
        end

        score = 1.0
        compatible_material = true

        # Check Young's modulus requirements
        if haskey(property_requirements, "min_youngs_modulus_GPa")
            min_modulus = property_requirements["min_youngs_modulus_GPa"]
            if get(props, "youngs_modulus_GPa", 0.0) < min_modulus
                compatible_material = false
            end
        end

        if haskey(property_requirements, "max_youngs_modulus_GPa")
            max_modulus = property_requirements["max_youngs_modulus_GPa"]
            if get(props, "youngs_modulus_GPa", Inf) > max_modulus
                compatible_material = false
            end
        end

        # Check biocompatibility
        if haskey(property_requirements, "min_biocompatibility")
            min_biocomp = property_requirements["min_biocompatibility"]
            biocomp = get(props, "biocompatibility", 0.0)
            if biocomp < min_biocomp
                compatible_material = false
            else
                score *= biocomp
            end
        end

        # Check degradation rate
        if haskey(property_requirements, "degradation_rate")
            required_rate = property_requirements["degradation_rate"]
            material_rate = get(props, "degradation_rate", "")
            if material_rate != required_rate
                score *= 0.8  # Penalty but not disqualifying
            end
        end

        # Check osteoconductivity
        if haskey(property_requirements, "min_osteoconductivity")
            min_osteo = property_requirements["min_osteoconductivity"]
            osteo = get(props, "osteoconductivity", 0.0)
            if osteo < min_osteo
                compatible_material = false
            else
                score *= osteo
            end
        end

        if compatible_material
            push!(compatible, (material_id, score))
        end
    end

    # Sort by compatibility score (descending)
    sort!(compatible, by=x -> x[2], rev=true)

    return compatible
end

"""
    validate_scaffold_design(tissue_id::String, material_id::String, params::ScaffoldParameters)::Tuple{Bool,Vector{String}}

Validate a scaffold design against tissue-specific requirements.

# Arguments
- `tissue_id::String`: Target tissue UBERON ID
- `material_id::String`: Selected material ID
- `params::ScaffoldParameters`: Proposed scaffold parameters

# Returns
- `Tuple{Bool,Vector{String}}`: (is_valid, list of warnings/errors)

# Example
```julia
params = ScaffoldParameters(0.7, 350.0, 0.95, 0.0)
is_valid, messages = validate_scaffold_design("UBERON:0002481", "CHEBI:46662", params)
```
"""
function validate_scaffold_design(
    tissue_id::String,
    material_id::String,
    params::ScaffoldParameters
)::Tuple{Bool,Vector{String}}

    messages = String[]
    is_valid = true

    # Get optimal parameters for tissue
    optimal = get(TISSUE_PARAMETERS, tissue_id, Dict{String,Any}())
    if isempty(optimal)
        push!(messages, "WARNING: No optimal parameters found for tissue $tissue_id")
        return (true, messages)  # Can't validate, but don't reject
    end

    # Check if material is recommended for this tissue
    recommended_materials = get_materials_for_tissue(tissue_id)
    if !isempty(recommended_materials) && !(material_id in recommended_materials)
        push!(messages, "WARNING: Material $material_id not in recommended list for this tissue")
    end

    # Validate porosity
    if haskey(optimal, "porosity")
        optimal_porosity = optimal["porosity"]
        porosity_diff = abs(params.porosity_target - optimal_porosity)
        if porosity_diff > 0.15
            push!(messages, "ERROR: Porosity $(params.porosity_target) deviates significantly from optimal $optimal_porosity")
            is_valid = false
        elseif porosity_diff > 0.05
            push!(messages, "WARNING: Porosity $(params.porosity_target) differs from optimal $optimal_porosity")
        end
    end

    # Validate pore size
    if haskey(optimal, "pore_size_um")
        optimal_pore = optimal["pore_size_um"]
        pore_diff = abs(params.pore_size_target_um - optimal_pore)
        if pore_diff > optimal_pore * 0.3
            push!(messages, "ERROR: Pore size $(params.pore_size_target_um)μm deviates significantly from optimal $(optimal_pore)μm")
            is_valid = false
        elseif pore_diff > optimal_pore * 0.1
            push!(messages, "WARNING: Pore size $(params.pore_size_target_um)μm differs from optimal $(optimal_pore)μm")
        end
    end

    # Validate interconnectivity
    if haskey(optimal, "interconnectivity")
        optimal_intercon = optimal["interconnectivity"]
        if params.interconnectivity_target < optimal_intercon - 0.05
            push!(messages, "ERROR: Interconnectivity $(params.interconnectivity_target) below optimal $optimal_intercon")
            is_valid = false
        end
    end

    # Check material properties
    material_props = get_material_properties(material_id)
    if !isempty(material_props)
        # Check if porosity is within material's capability
        if haskey(material_props, "porosity_range")
            pore_range = material_props["porosity_range"]
            if params.porosity_target < pore_range[1] || params.porosity_target > pore_range[2]
                push!(messages, "ERROR: Target porosity outside material's range $(pore_range)")
                is_valid = false
            end
        end

        # Check pore size
        if haskey(material_props, "pore_size_um")
            pore_range = material_props["pore_size_um"]
            if params.pore_size_target_um < pore_range[1] || params.pore_size_target_um > pore_range[2]
                push!(messages, "WARNING: Target pore size outside material's typical range $(pore_range)")
            end
        end
    end

    return (is_valid, messages)
end

end # module CrossOntologyRelations
