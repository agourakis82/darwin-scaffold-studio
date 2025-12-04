"""
    OBOFoundry

Integration with Open Biological and Biomedical Ontologies (OBO Foundry).

Provides standardized terminology for:
- UBERON: Anatomical structures (tissues, organs)
- CL: Cell types
- CHEBI: Chemical entities (biomaterials, drugs)
- NCIT: NCI Thesaurus (diseases, treatments)
- GO: Gene Ontology (biological processes)
- BTO: Tissues and cell lines
- DOID: Disease Ontology

# References
- OBO Foundry: https://obofoundry.org/
- UBERON: https://obofoundry.org/ontology/uberon.html
- CL: https://obofoundry.org/ontology/cl.html
- CHEBI: https://www.ebi.ac.uk/chebi/

# Author: Dr. Demetrios Agourakis
# Master's Thesis: Tissue Engineering Scaffold Optimization
"""
module OBOFoundry

export OBOTerm, OBOOntology
export UBERON, CL, CHEBI, NCIT, GO, BTO, DOID
export lookup_term, get_parents, get_children, get_related
export validate_term, get_obo_uri, get_iri
export TISSUE_TERMS, CELL_TERMS, MATERIAL_TERMS, DRUG_TERMS
export annotate_scaffold, get_tissue_for_scaffold
export get_cells_for_tissue, get_materials_for_tissue

#=============================================================================
  OBO TERM STRUCTURE
=============================================================================#

"""
    OBOTerm

Standard OBO Foundry term with full metadata.
"""
struct OBOTerm
    id::String           # e.g., "UBERON:0002481"
    name::String         # e.g., "bone tissue"
    definition::String   # Full definition
    synonyms::Vector{String}
    parents::Vector{String}  # is_a relationships
    part_of::Vector{String}  # part_of relationships
    xrefs::Vector{String}    # Cross-references to other ontologies
    ontology::Symbol     # :UBERON, :CL, :CHEBI, etc.
end

# Convenience constructor
function OBOTerm(id::String, name::String;
                 definition::String="",
                 synonyms::Vector{String}=String[],
                 parents::Vector{String}=String[],
                 part_of::Vector{String}=String[],
                 xrefs::Vector{String}=String[])
    ontology = Symbol(split(id, ":")[1])
    OBOTerm(id, name, definition, synonyms, parents, part_of, xrefs, ontology)
end

"""Get IRI (Internationalized Resource Identifier) for OBO term."""
function get_iri(term::OBOTerm)
    prefix, local_id = split(term.id, ":")
    "http://purl.obolibrary.org/obo/$(prefix)_$(local_id)"
end

"""Get OBO PURL URI for term."""
get_obo_uri(term::OBOTerm) = get_iri(term)

#=============================================================================
  UBERON - ANATOMY ONTOLOGY
  Tissues and anatomical structures relevant to scaffold applications
=============================================================================#

const UBERON = Dict{String, OBOTerm}(
    # Bone tissues
    "UBERON:0002481" => OBOTerm("UBERON:0002481", "bone tissue";
        definition = "Skelite that has as part collagen and calcium phosphate",
        synonyms = ["osseous tissue", "bone"],
        parents = ["UBERON:0000479"],  # tissue
        xrefs = ["FMA:5018", "MESH:D001842"]
    ),
    "UBERON:0001474" => OBOTerm("UBERON:0001474", "trabecular bone tissue";
        definition = "Bone tissue with trabecular architecture",
        synonyms = ["cancellous bone", "spongy bone"],
        parents = ["UBERON:0002481"],
        xrefs = ["FMA:24018"]
    ),
    "UBERON:0001475" => OBOTerm("UBERON:0001475", "cortical bone tissue";
        definition = "Compact bone tissue forming outer shell",
        synonyms = ["compact bone"],
        parents = ["UBERON:0002481"],
        xrefs = ["FMA:24017"]
    ),

    # Cartilage tissues
    "UBERON:0002418" => OBOTerm("UBERON:0002418", "cartilage tissue";
        definition = "Skeletal tissue that is avascular, composed of chondrocytes and extracellular matrix",
        synonyms = ["cartilage"],
        parents = ["UBERON:0000479"],
        xrefs = ["FMA:71500", "MESH:D002356"]
    ),
    "UBERON:0001994" => OBOTerm("UBERON:0001994", "hyaline cartilage tissue";
        definition = "Cartilage tissue with ground substance is homogeneous",
        synonyms = ["hyaline cartilage"],
        parents = ["UBERON:0002418"],
        xrefs = ["FMA:64783"]
    ),
    "UBERON:0001995" => OBOTerm("UBERON:0001995", "fibrocartilage";
        definition = "Cartilage with bundles of collagen fibers",
        parents = ["UBERON:0002418"],
        xrefs = ["FMA:64784"]
    ),

    # Skin and soft tissues
    "UBERON:0002097" => OBOTerm("UBERON:0002097", "skin of body";
        definition = "The external covering of the body",
        synonyms = ["skin", "integument"],
        parents = ["UBERON:0000479"],
        xrefs = ["FMA:7163", "MESH:D012867"]
    ),
    "UBERON:0002067" => OBOTerm("UBERON:0002067", "dermis";
        definition = "Layer of skin deep to epidermis",
        parents = ["UBERON:0002097"],
        xrefs = ["FMA:70323"]
    ),
    "UBERON:0002069" => OBOTerm("UBERON:0002069", "stratum corneum";
        definition = "Outermost layer of epidermis",
        parents = ["UBERON:0002097"],
        xrefs = ["FMA:70322"]
    ),

    # Vascular tissues
    "UBERON:0001981" => OBOTerm("UBERON:0001981", "blood vessel";
        definition = "Tubular structure carrying blood",
        synonyms = ["vas sanguineum"],
        parents = ["UBERON:0000479"],
        xrefs = ["FMA:63183", "MESH:D001808"]
    ),
    "UBERON:0001637" => OBOTerm("UBERON:0001637", "artery";
        definition = "Blood vessel that carries blood away from heart",
        parents = ["UBERON:0001981"],
        xrefs = ["FMA:50720"]
    ),
    "UBERON:0001638" => OBOTerm("UBERON:0001638", "vein";
        definition = "Blood vessel that carries blood toward heart",
        parents = ["UBERON:0001981"],
        xrefs = ["FMA:50723"]
    ),

    # Neural tissues
    "UBERON:0001017" => OBOTerm("UBERON:0001017", "central nervous system";
        definition = "The brain and spinal cord",
        synonyms = ["CNS", "neuraxis"],
        parents = ["UBERON:0000479"],
        xrefs = ["FMA:55675", "MESH:D002490"]
    ),
    "UBERON:0001021" => OBOTerm("UBERON:0001021", "nerve";
        definition = "Bundle of neuronal axons",
        parents = ["UBERON:0001017"],
        xrefs = ["FMA:65132"]
    ),
    "UBERON:0002240" => OBOTerm("UBERON:0002240", "spinal cord";
        definition = "Part of CNS within vertebral canal",
        parents = ["UBERON:0001017"],
        xrefs = ["FMA:7647"]
    ),

    # Muscle tissues
    "UBERON:0002385" => OBOTerm("UBERON:0002385", "muscle tissue";
        definition = "Tissue composed of muscle cells",
        synonyms = ["muscle"],
        parents = ["UBERON:0000479"],
        xrefs = ["FMA:9641"]
    ),
    "UBERON:0001133" => OBOTerm("UBERON:0001133", "cardiac muscle tissue";
        definition = "Muscle tissue of the heart",
        synonyms = ["heart muscle", "myocardium"],
        parents = ["UBERON:0002385"],
        xrefs = ["FMA:9462"]
    ),
    "UBERON:0001134" => OBOTerm("UBERON:0001134", "skeletal muscle tissue";
        definition = "Striated muscle attached to skeleton",
        parents = ["UBERON:0002385"],
        xrefs = ["FMA:9463"]
    ),

    # Connective tissues
    "UBERON:0002384" => OBOTerm("UBERON:0002384", "connective tissue";
        definition = "Tissue with cells dispersed in extracellular matrix",
        parents = ["UBERON:0000479"],
        xrefs = ["FMA:9640"]
    ),
    "UBERON:0006590" => OBOTerm("UBERON:0006590", "tendon";
        definition = "Dense connective tissue connecting muscle to bone",
        parents = ["UBERON:0002384"],
        xrefs = ["FMA:9721", "MESH:D013710"]
    ),
    "UBERON:0000211" => OBOTerm("UBERON:0000211", "ligament";
        definition = "Dense connective tissue connecting bone to bone",
        parents = ["UBERON:0002384"],
        xrefs = ["FMA:21496", "MESH:D008022"]
    ),

    # Organs
    "UBERON:0002107" => OBOTerm("UBERON:0002107", "liver";
        definition = "Largest internal organ involved in metabolism",
        parents = ["UBERON:0000062"],  # organ
        xrefs = ["FMA:7197", "MESH:D008099"]
    ),
    "UBERON:0002113" => OBOTerm("UBERON:0002113", "kidney";
        definition = "Organ that filters blood and produces urine",
        parents = ["UBERON:0000062"],
        xrefs = ["FMA:7203", "MESH:D007668"]
    ),
    "UBERON:0000948" => OBOTerm("UBERON:0000948", "heart";
        definition = "Hollow muscular organ that pumps blood",
        parents = ["UBERON:0000062"],
        xrefs = ["FMA:7088", "MESH:D006321"]
    )
)

#=============================================================================
  CL - CELL ONTOLOGY
  Cell types relevant to tissue engineering
=============================================================================#

const CL = Dict{String, OBOTerm}(
    # Stem cells
    "CL:0000034" => OBOTerm("CL:0000034", "stem cell";
        definition = "Relatively undifferentiated cell with capacity for self-renewal",
        parents = ["CL:0000000"],
        xrefs = ["FMA:63368"]
    ),
    "CL:0000222" => OBOTerm("CL:0000222", "mesenchymal stem cell";
        definition = "Multipotent stem cell of mesenchymal origin",
        synonyms = ["MSC", "mesenchymal stromal cell"],
        parents = ["CL:0000034"],
        xrefs = ["FMA:70546"]
    ),
    "CL:0002371" => OBOTerm("CL:0002371", "hematopoietic stem cell";
        definition = "Stem cell that can give rise to all blood cell types",
        synonyms = ["HSC"],
        parents = ["CL:0000034"],
        xrefs = ["FMA:70338"]
    ),
    "CL:0002322" => OBOTerm("CL:0002322", "embryonic stem cell";
        definition = "Pluripotent stem cell from inner cell mass",
        synonyms = ["ESC", "ES cell"],
        parents = ["CL:0000034"]
    ),
    "CL:0002248" => OBOTerm("CL:0002248", "induced pluripotent stem cell";
        definition = "Reprogrammed somatic cell with pluripotency",
        synonyms = ["iPSC", "iPS cell"],
        parents = ["CL:0000034"]
    ),

    # Bone cells
    "CL:0000062" => OBOTerm("CL:0000062", "osteoblast";
        definition = "Bone-forming cell derived from mesenchyme",
        parents = ["CL:0000055"],  # non-terminally differentiated cell
        xrefs = ["FMA:66780"]
    ),
    "CL:0000092" => OBOTerm("CL:0000092", "osteoclast";
        definition = "Multinucleated cell that resorbs bone",
        parents = ["CL:0000094"],  # granulocyte
        xrefs = ["FMA:66781"]
    ),
    "CL:0000137" => OBOTerm("CL:0000137", "osteocyte";
        definition = "Mature bone cell embedded in bone matrix",
        parents = ["CL:0000062"],
        xrefs = ["FMA:66779"]
    ),

    # Cartilage cells
    "CL:0000138" => OBOTerm("CL:0000138", "chondrocyte";
        definition = "Cell found in cartilage, produces ECM",
        parents = ["CL:0000055"],
        xrefs = ["FMA:66782"]
    ),
    "CL:0000743" => OBOTerm("CL:0000743", "hypertrophic chondrocyte";
        definition = "Enlarged chondrocyte undergoing terminal differentiation",
        parents = ["CL:0000138"]
    ),

    # Skin cells
    "CL:0000312" => OBOTerm("CL:0000312", "keratinocyte";
        definition = "Epidermal cell producing keratin",
        parents = ["CL:0000066"],  # epithelial cell
        xrefs = ["FMA:62879"]
    ),
    "CL:0000057" => OBOTerm("CL:0000057", "fibroblast";
        definition = "Connective tissue cell producing ECM",
        parents = ["CL:0000055"],
        xrefs = ["FMA:63877"]
    ),
    "CL:0002620" => OBOTerm("CL:0002620", "skin fibroblast";
        definition = "Fibroblast of skin dermis",
        parents = ["CL:0000057"]
    ),

    # Vascular cells
    "CL:0000115" => OBOTerm("CL:0000115", "endothelial cell";
        definition = "Cell lining blood vessels",
        parents = ["CL:0000066"],
        xrefs = ["FMA:66772"]
    ),
    "CL:0000192" => OBOTerm("CL:0000192", "smooth muscle cell";
        definition = "Muscle cell of blood vessels and organs",
        parents = ["CL:0000187"],  # muscle cell
        xrefs = ["FMA:14072"]
    ),
    "CL:0002139" => OBOTerm("CL:0002139", "vascular endothelial cell";
        definition = "Endothelial cell of blood vessel",
        synonyms = ["VEC"],
        parents = ["CL:0000115"]
    ),

    # Neural cells
    "CL:0000540" => OBOTerm("CL:0000540", "neuron";
        definition = "Electrically excitable cell of nervous system",
        synonyms = ["nerve cell"],
        parents = ["CL:0002319"],  # neural cell
        xrefs = ["FMA:54527"]
    ),
    "CL:0000127" => OBOTerm("CL:0000127", "astrocyte";
        definition = "Glial cell of CNS with star-shaped morphology",
        parents = ["CL:0000125"],  # glial cell
        xrefs = ["FMA:54537"]
    ),
    "CL:0000128" => OBOTerm("CL:0000128", "oligodendrocyte";
        definition = "Glial cell producing myelin in CNS",
        parents = ["CL:0000125"],
        xrefs = ["FMA:54540"]
    ),
    "CL:0002573" => OBOTerm("CL:0002573", "Schwann cell";
        definition = "Glial cell producing myelin in PNS",
        parents = ["CL:0000125"],
        xrefs = ["FMA:62121"]
    ),

    # Muscle cells
    "CL:0000187" => OBOTerm("CL:0000187", "muscle cell";
        definition = "Contractile cell of muscle tissue",
        synonyms = ["myocyte"],
        parents = ["CL:0000211"],  # electrically active cell
        xrefs = ["FMA:67099"]
    ),
    "CL:0000746" => OBOTerm("CL:0000746", "cardiac muscle cell";
        definition = "Muscle cell of heart",
        synonyms = ["cardiomyocyte"],
        parents = ["CL:0000187"],
        xrefs = ["FMA:14067"]
    ),
    "CL:0000188" => OBOTerm("CL:0000188", "skeletal muscle cell";
        definition = "Multinucleated cell of skeletal muscle",
        synonyms = ["myofiber"],
        parents = ["CL:0000187"],
        xrefs = ["FMA:82846"]
    ),

    # Immune cells (for inflammation response)
    "CL:0000235" => OBOTerm("CL:0000235", "macrophage";
        definition = "Phagocytic cell of mononuclear lineage",
        parents = ["CL:0000576"],  # monocyte
        xrefs = ["FMA:83585"]
    ),
    "CL:0000236" => OBOTerm("CL:0000236", "B cell";
        definition = "Lymphocyte producing antibodies",
        synonyms = ["B lymphocyte"],
        parents = ["CL:0000945"],  # lymphocyte
        xrefs = ["FMA:62869"]
    ),
    "CL:0000084" => OBOTerm("CL:0000084", "T cell";
        definition = "Lymphocyte of cell-mediated immunity",
        synonyms = ["T lymphocyte"],
        parents = ["CL:0000945"],
        xrefs = ["FMA:62870"]
    )
)

#=============================================================================
  CHEBI - CHEMICAL ENTITIES OF BIOLOGICAL INTEREST
  Biomaterials, drugs, and chemical compounds
=============================================================================#

const CHEBI = Dict{String, OBOTerm}(
    # Polymers - Synthetic biodegradable
    "CHEBI:53310" => OBOTerm("CHEBI:53310", "polycaprolactone";
        definition = "Biodegradable polyester, Tm ~60°C, slow degradation",
        synonyms = ["PCL", "poly(epsilon-caprolactone)"],
        parents = ["CHEBI:53311"],  # polyester
        xrefs = ["CAS:24980-41-4"]
    ),
    "CHEBI:53309" => OBOTerm("CHEBI:53309", "polylactic acid";
        definition = "Biodegradable thermoplastic from lactic acid",
        synonyms = ["PLA", "polylactide"],
        parents = ["CHEBI:53311"],
        xrefs = ["CAS:26100-51-6"]
    ),
    "CHEBI:53426" => OBOTerm("CHEBI:53426", "poly(lactic-co-glycolic acid)";
        definition = "Copolymer of PLA and PGA, tunable degradation",
        synonyms = ["PLGA"],
        parents = ["CHEBI:53311"],
        xrefs = ["CAS:26780-50-7"]
    ),
    "CHEBI:53312" => OBOTerm("CHEBI:53312", "polyglycolic acid";
        definition = "Simplest linear aliphatic polyester",
        synonyms = ["PGA", "polyglycolide"],
        parents = ["CHEBI:53311"],
        xrefs = ["CAS:26009-03-0"]
    ),
    "CHEBI:46793" => OBOTerm("CHEBI:46793", "polyethylene glycol";
        definition = "Polyether compound, hydrophilic polymer",
        synonyms = ["PEG", "polyethylene oxide", "PEO"],
        parents = ["CHEBI:36080"],  # ether
        xrefs = ["CAS:25322-68-3"]
    ),

    # Natural polymers
    "CHEBI:3815" => OBOTerm("CHEBI:3815", "collagen";
        definition = "Main structural protein of connective tissue",
        synonyms = ["type I collagen"],
        parents = ["CHEBI:36080"],
        xrefs = ["CAS:9007-34-5"]
    ),
    "CHEBI:18154" => OBOTerm("CHEBI:18154", "hyaluronic acid";
        definition = "Glycosaminoglycan of ECM",
        synonyms = ["hyaluronan", "HA"],
        parents = ["CHEBI:37395"],  # glycosaminoglycan
        xrefs = ["CAS:9004-61-9"]
    ),
    "CHEBI:16737" => OBOTerm("CHEBI:16737", "chitosan";
        definition = "Deacetylated chitin, antimicrobial polymer",
        parents = ["CHEBI:36973"],  # polysaccharide
        xrefs = ["CAS:9012-76-4"]
    ),
    "CHEBI:52747" => OBOTerm("CHEBI:52747", "alginate";
        definition = "Polysaccharide from brown algae",
        synonyms = ["alginic acid"],
        parents = ["CHEBI:36973"],
        xrefs = ["CAS:9005-38-3"]
    ),
    "CHEBI:18237" => OBOTerm("CHEBI:18237", "fibrin";
        definition = "Fibrous protein from fibrinogen, clotting",
        parents = ["CHEBI:36080"],
        xrefs = ["CAS:9001-31-4"]
    ),
    "CHEBI:28512" => OBOTerm("CHEBI:28512", "gelatin";
        definition = "Hydrolyzed collagen, gel-forming",
        parents = ["CHEBI:36080"],
        xrefs = ["CAS:9000-70-8"]
    ),

    # Ceramics
    "CHEBI:52251" => OBOTerm("CHEBI:52251", "hydroxyapatite";
        definition = "Calcium phosphate, main mineral of bone",
        synonyms = ["HA", "HAp", "Ca10(PO4)6(OH)2"],
        parents = ["CHEBI:37586"],  # calcium phosphate
        xrefs = ["CAS:1306-06-5"]
    ),
    "CHEBI:53480" => OBOTerm("CHEBI:53480", "tricalcium phosphate";
        definition = "Calcium phosphate ceramic, resorbable",
        synonyms = ["TCP", "Ca3(PO4)2"],
        parents = ["CHEBI:37586"],
        xrefs = ["CAS:7758-87-4"]
    ),
    "CHEBI:30563" => OBOTerm("CHEBI:30563", "silicon dioxide";
        definition = "Silica, component of bioactive glass",
        synonyms = ["silica", "SiO2"],
        parents = ["CHEBI:24836"],  # oxide
        xrefs = ["CAS:7631-86-9"]
    ),
    "CHEBI:52254" => OBOTerm("CHEBI:52254", "bioactive glass";
        definition = "Silica-based glass that bonds to bone",
        synonyms = ["bioglass", "45S5"],
        parents = ["CHEBI:33416"],  # glass
        xrefs = String[]
    ),

    # Metals
    "CHEBI:33341" => OBOTerm("CHEBI:33341", "titanium";
        definition = "Biocompatible transition metal",
        synonyms = ["Ti"],
        parents = ["CHEBI:33521"],  # transition metal
        xrefs = ["CAS:7440-32-6"]
    ),
    "CHEBI:37926" => OBOTerm("CHEBI:37926", "titanium dioxide";
        definition = "Titanium oxide, surface coating",
        synonyms = ["titania", "TiO2"],
        parents = ["CHEBI:24836"],
        xrefs = ["CAS:13463-67-7"]
    ),

    # Growth factors (as chemicals)
    "CHEBI:83658" => OBOTerm("CHEBI:83658", "bone morphogenetic protein 2";
        definition = "Osteogenic growth factor",
        synonyms = ["BMP-2", "rhBMP-2"],
        parents = ["CHEBI:36080"],
        xrefs = String[]
    ),
    "CHEBI:74037" => OBOTerm("CHEBI:74037", "vascular endothelial growth factor";
        definition = "Angiogenic growth factor",
        synonyms = ["VEGF"],
        parents = ["CHEBI:36080"],
        xrefs = String[]
    ),

    # Drugs and therapeutics
    "CHEBI:27732" => OBOTerm("CHEBI:27732", "dexamethasone";
        definition = "Corticosteroid anti-inflammatory",
        parents = ["CHEBI:36699"],  # corticosteroid
        xrefs = ["CAS:50-02-2", "DRUGBANK:DB01234"]
    ),
    "CHEBI:6801" => OBOTerm("CHEBI:6801", "methotrexate";
        definition = "Antimetabolite chemotherapy drug",
        synonyms = ["MTX"],
        parents = ["CHEBI:35222"],  # antimetabolite
        xrefs = ["CAS:59-05-2", "DRUGBANK:DB00563"]
    ),
    "CHEBI:16236" => OBOTerm("CHEBI:16236", "doxorubicin";
        definition = "Anthracycline chemotherapy drug",
        synonyms = ["adriamycin"],
        parents = ["CHEBI:22587"],  # anthracycline
        xrefs = ["CAS:23214-92-8", "DRUGBANK:DB00997"]
    ),
    "CHEBI:9754" => OBOTerm("CHEBI:9754", "vancomycin";
        definition = "Glycopeptide antibiotic",
        parents = ["CHEBI:35623"],  # antibiotic
        xrefs = ["CAS:1404-90-6", "DRUGBANK:DB00512"]
    ),
    "CHEBI:7507" => OBOTerm("CHEBI:7507", "gentamicin";
        definition = "Aminoglycoside antibiotic",
        parents = ["CHEBI:35623"],
        xrefs = ["CAS:1403-66-3", "DRUGBANK:DB00798"]
    )
)

#=============================================================================
  NCIT - NCI THESAURUS
  Diseases and conditions relevant to scaffold applications
=============================================================================#

const NCIT = Dict{String, OBOTerm}(
    # Bone conditions
    "NCIT:C3043" => OBOTerm("NCIT:C3043", "bone fracture";
        definition = "Break in the continuity of bone",
        synonyms = ["fracture"],
        parents = ["NCIT:C3061"],
        xrefs = ["MESH:D050723"]
    ),
    "NCIT:C26808" => OBOTerm("NCIT:C26808", "critical size bone defect";
        definition = "Bone defect that will not heal spontaneously",
        parents = ["NCIT:C3043"]
    ),
    "NCIT:C3298" => OBOTerm("NCIT:C3298", "osteoporosis";
        definition = "Systemic skeletal disease with low bone mass",
        parents = ["NCIT:C26879"],  # bone disease
        xrefs = ["MESH:D010024"]
    ),
    "NCIT:C3239" => OBOTerm("NCIT:C3239", "osteonecrosis";
        definition = "Death of bone tissue due to loss of blood supply",
        synonyms = ["avascular necrosis"],
        parents = ["NCIT:C26879"],
        xrefs = ["MESH:D010020"]
    ),
    "NCIT:C9263" => OBOTerm("NCIT:C9263", "osteosarcoma";
        definition = "Malignant bone tumor producing osteoid",
        parents = ["NCIT:C4863"],  # bone cancer
        xrefs = ["MESH:D012516"]
    ),

    # Cartilage conditions
    "NCIT:C26809" => OBOTerm("NCIT:C26809", "cartilage defect";
        definition = "Loss or damage to cartilage tissue",
        parents = ["NCIT:C4866"],
        xrefs = String[]
    ),
    "NCIT:C3089" => OBOTerm("NCIT:C3089", "osteoarthritis";
        definition = "Degenerative joint disease with cartilage loss",
        parents = ["NCIT:C26721"],  # arthritis
        xrefs = ["MESH:D010003"]
    ),

    # Skin conditions
    "NCIT:C50709" => OBOTerm("NCIT:C50709", "wound";
        definition = "Injury to tissue from trauma",
        parents = ["NCIT:C3671"],  # injury
        xrefs = ["MESH:D014947"]
    ),
    "NCIT:C26895" => OBOTerm("NCIT:C26895", "burn";
        definition = "Tissue injury from heat, chemicals, or radiation",
        parents = ["NCIT:C50709"],
        xrefs = ["MESH:D002056"]
    ),
    "NCIT:C50710" => OBOTerm("NCIT:C50710", "chronic wound";
        definition = "Wound that fails to heal in expected time",
        parents = ["NCIT:C50709"],
        xrefs = String[]
    ),
    "NCIT:C2930" => OBOTerm("NCIT:C2930", "diabetic ulcer";
        definition = "Chronic ulcer in diabetic patient",
        parents = ["NCIT:C50710"],
        xrefs = ["MESH:D017719"]
    ),

    # Vascular conditions
    "NCIT:C34504" => OBOTerm("NCIT:C34504", "peripheral vascular disease";
        definition = "Disease of blood vessels outside heart and brain",
        synonyms = ["PVD"],
        parents = ["NCIT:C2931"],  # vascular disease
        xrefs = ["MESH:D016491"]
    ),
    "NCIT:C95812" => OBOTerm("NCIT:C95812", "aneurysm";
        definition = "Localized dilation of blood vessel",
        parents = ["NCIT:C2931"],
        xrefs = ["MESH:D000783"]
    ),

    # Neural conditions
    "NCIT:C4809" => OBOTerm("NCIT:C4809", "spinal cord injury";
        definition = "Damage to spinal cord affecting function",
        synonyms = ["SCI"],
        parents = ["NCIT:C3671"],
        xrefs = ["MESH:D013119"]
    ),
    "NCIT:C26853" => OBOTerm("NCIT:C26853", "peripheral nerve injury";
        definition = "Damage to peripheral nervous system",
        parents = ["NCIT:C3671"],
        xrefs = ["MESH:D059348"]
    ),

    # Cardiac conditions
    "NCIT:C45390" => OBOTerm("NCIT:C45390", "myocardial infarction";
        definition = "Death of heart muscle due to ischemia",
        synonyms = ["heart attack", "MI"],
        parents = ["NCIT:C2947"],  # heart disease
        xrefs = ["MESH:D009203"]
    ),
    "NCIT:C50577" => OBOTerm("NCIT:C50577", "heart failure";
        definition = "Inability of heart to pump adequately",
        parents = ["NCIT:C2947"],
        xrefs = ["MESH:D006333"]
    )
)

#=============================================================================
  GO - GENE ONTOLOGY (Biological Processes)
  Relevant processes for scaffold-cell interactions
=============================================================================#

const GO = Dict{String, OBOTerm}(
    # Cell behavior
    "GO:0008283" => OBOTerm("GO:0008283", "cell population proliferation";
        definition = "Increase in cell population by division",
        synonyms = ["cell proliferation"],
        parents = ["GO:0009987"]  # cellular process
    ),
    "GO:0016477" => OBOTerm("GO:0016477", "cell migration";
        definition = "Movement of cell from one site to another",
        parents = ["GO:0048870"]  # cell motility
    ),
    "GO:0007155" => OBOTerm("GO:0007155", "cell adhesion";
        definition = "Attachment of cell to surface",
        parents = ["GO:0009987"]
    ),
    "GO:0030154" => OBOTerm("GO:0030154", "cell differentiation";
        definition = "Developmental process of acquiring specialized features",
        parents = ["GO:0048869"]  # cellular developmental process
    ),
    "GO:0012501" => OBOTerm("GO:0012501", "programmed cell death";
        definition = "Cell death resulting from activation of internal program",
        synonyms = ["apoptosis"],
        parents = ["GO:0008219"]  # cell death
    ),

    # Tissue processes
    "GO:0001503" => OBOTerm("GO:0001503", "ossification";
        definition = "Formation of bone tissue",
        synonyms = ["bone formation"],
        parents = ["GO:0060348"]  # bone development
    ),
    "GO:0051216" => OBOTerm("GO:0051216", "cartilage development";
        definition = "Progression of cartilage over time",
        parents = ["GO:0048856"]  # anatomical structure development
    ),
    "GO:0001525" => OBOTerm("GO:0001525", "angiogenesis";
        definition = "Formation of new blood vessels from existing vasculature",
        synonyms = ["blood vessel formation"],
        parents = ["GO:0048514"]  # blood vessel morphogenesis
    ),
    "GO:0042060" => OBOTerm("GO:0042060", "wound healing";
        definition = "Series of events restoring integrity to damaged tissue",
        parents = ["GO:0009987"]
    ),
    "GO:0030198" => OBOTerm("GO:0030198", "extracellular matrix organization";
        definition = "Assembly and arrangement of ECM",
        synonyms = ["ECM organization"],
        parents = ["GO:0043062"]  # ECM structure organization
    ),

    # Inflammatory response
    "GO:0006954" => OBOTerm("GO:0006954", "inflammatory response";
        definition = "Response to injury with increased blood flow and cytokines",
        parents = ["GO:0006950"]  # response to stress
    ),
    "GO:0002376" => OBOTerm("GO:0002376", "immune system process";
        definition = "Any process involved in immunity",
        parents = ["GO:0008150"]  # biological process
    ),

    # Mineralization
    "GO:0030282" => OBOTerm("GO:0030282", "bone mineralization";
        definition = "Deposition of calcium salts in bone matrix",
        parents = ["GO:0001503"]
    ),
    "GO:0046849" => OBOTerm("GO:0046849", "bone remodeling";
        definition = "Renewal and repair of bone",
        parents = ["GO:0060348"]
    )
)

#=============================================================================
  BTO - BRENDA TISSUE ONTOLOGY
  Cell lines commonly used in scaffold research
=============================================================================#

const BTO = Dict{String, OBOTerm}(
    # Osteoblast cell lines
    "BTO:0000968" => OBOTerm("BTO:0000968", "MC3T3-E1 cell";
        definition = "Murine calvaria osteoblast cell line",
        synonyms = ["MC3T3"],
        parents = ["BTO:0000944"]  # osteoblast
    ),
    "BTO:0001279" => OBOTerm("BTO:0001279", "Saos-2 cell";
        definition = "Human osteosarcoma cell line",
        parents = ["BTO:0000944"]
    ),
    "BTO:0001426" => OBOTerm("BTO:0001426", "MG-63 cell";
        definition = "Human osteosarcoma cell line",
        parents = ["BTO:0000944"]
    ),
    "BTO:0002922" => OBOTerm("BTO:0002922", "hFOB 1.19 cell";
        definition = "Human fetal osteoblast cell line",
        parents = ["BTO:0000944"]
    ),

    # Fibroblast cell lines
    "BTO:0001906" => OBOTerm("BTO:0001906", "NIH-3T3 cell";
        definition = "Murine embryonic fibroblast cell line",
        synonyms = ["NIH/3T3", "3T3"],
        parents = ["BTO:0000452"]  # fibroblast
    ),
    "BTO:0002335" => OBOTerm("BTO:0002335", "L929 cell";
        definition = "Murine fibroblast cell line",
        parents = ["BTO:0000452"]
    ),
    "BTO:0000224" => OBOTerm("BTO:0000224", "BJ cell";
        definition = "Human foreskin fibroblast cell line",
        parents = ["BTO:0000452"]
    ),

    # Stem cell lines
    "BTO:0002354" => OBOTerm("BTO:0002354", "human mesenchymal stem cell";
        definition = "Primary hMSC culture",
        synonyms = ["hMSC"],
        parents = ["BTO:0002358"]  # mesenchymal stem cell
    ),
    "BTO:0002906" => OBOTerm("BTO:0002906", "adipose-derived stem cell";
        definition = "MSC from adipose tissue",
        synonyms = ["ADSC", "ASC"],
        parents = ["BTO:0002358"]
    ),

    # Endothelial cell lines
    "BTO:0001529" => OBOTerm("BTO:0001529", "HUVEC";
        definition = "Human umbilical vein endothelial cell",
        synonyms = ["HUVEC cell"],
        parents = ["BTO:0000393"]  # endothelial cell
    ),
    "BTO:0003566" => OBOTerm("BTO:0003566", "EA.hy926 cell";
        definition = "Immortalized human endothelial cell line",
        parents = ["BTO:0000393"]
    ),

    # Chondrocyte cell lines
    "BTO:0000178" => OBOTerm("BTO:0000178", "ATDC5 cell";
        definition = "Murine chondrogenic cell line",
        parents = ["BTO:0000252"]  # chondrocyte
    ),
    "BTO:0003953" => OBOTerm("BTO:0003953", "C28/I2 cell";
        definition = "Human chondrocyte cell line",
        parents = ["BTO:0000252"]
    ),

    # Neural cell lines
    "BTO:0000921" => OBOTerm("BTO:0000921", "PC-12 cell";
        definition = "Rat pheochromocytoma cell line, neuronal differentiation",
        synonyms = ["PC12"],
        parents = ["BTO:0000938"]  # neural cell
    ),
    "BTO:0000938" => OBOTerm("BTO:0000938", "SH-SY5Y cell";
        definition = "Human neuroblastoma cell line",
        parents = ["BTO:0000938"]
    )
)

#=============================================================================
  DOID - DISEASE ONTOLOGY
=============================================================================#

const DOID = Dict{String, OBOTerm}(
    "DOID:0080600" => OBOTerm("DOID:0080600", "bone regeneration disorder";
        definition = "Disorder affecting bone healing",
        parents = ["DOID:0080016"]  # bone disease
    ),
    "DOID:8398" => OBOTerm("DOID:8398", "osteoarthritis";
        definition = "Chronic joint disease with cartilage degeneration",
        parents = ["DOID:7"],  # disease of anatomical entity
        xrefs = ["NCIT:C3089"]
    ),
    "DOID:11476" => OBOTerm("DOID:11476", "osteoporosis";
        definition = "Bone disease with decreased bone density",
        parents = ["DOID:0080016"],
        xrefs = ["NCIT:C3298"]
    )
)

#=============================================================================
  CONVENIENCE MAPPINGS
  Quick lookup tables for common scaffold terms
=============================================================================#

"""Tissue terms mapped to UBERON IDs"""
const TISSUE_TERMS = Dict{Symbol, String}(
    :bone => "UBERON:0002481",
    :trabecular_bone => "UBERON:0001474",
    :cortical_bone => "UBERON:0001475",
    :cartilage => "UBERON:0002418",
    :hyaline_cartilage => "UBERON:0001994",
    :fibrocartilage => "UBERON:0001995",
    :skin => "UBERON:0002097",
    :dermis => "UBERON:0002067",
    :blood_vessel => "UBERON:0001981",
    :artery => "UBERON:0001637",
    :vein => "UBERON:0001638",
    :nerve => "UBERON:0001021",
    :spinal_cord => "UBERON:0002240",
    :muscle => "UBERON:0002385",
    :cardiac_muscle => "UBERON:0001133",
    :skeletal_muscle => "UBERON:0001134",
    :tendon => "UBERON:0006590",
    :ligament => "UBERON:0000211",
    :liver => "UBERON:0002107",
    :kidney => "UBERON:0002113",
    :heart => "UBERON:0000948"
)

"""Cell type terms mapped to CL IDs"""
const CELL_TERMS = Dict{Symbol, String}(
    :stem_cell => "CL:0000034",
    :msc => "CL:0000222",
    :hsc => "CL:0002371",
    :esc => "CL:0002322",
    :ipsc => "CL:0002248",
    :osteoblast => "CL:0000062",
    :osteoclast => "CL:0000092",
    :osteocyte => "CL:0000137",
    :chondrocyte => "CL:0000138",
    :keratinocyte => "CL:0000312",
    :fibroblast => "CL:0000057",
    :endothelial => "CL:0000115",
    :smooth_muscle => "CL:0000192",
    :neuron => "CL:0000540",
    :astrocyte => "CL:0000127",
    :schwann => "CL:0002573",
    :cardiomyocyte => "CL:0000746",
    :macrophage => "CL:0000235",
    :t_cell => "CL:0000084",
    :b_cell => "CL:0000236"
)

"""Material terms mapped to CHEBI IDs"""
const MATERIAL_TERMS = Dict{Symbol, String}(
    :pcl => "CHEBI:53310",
    :pla => "CHEBI:53309",
    :plga => "CHEBI:53426",
    :pga => "CHEBI:53312",
    :peg => "CHEBI:46793",
    :collagen => "CHEBI:3815",
    :hyaluronic_acid => "CHEBI:18154",
    :chitosan => "CHEBI:16737",
    :alginate => "CHEBI:52747",
    :fibrin => "CHEBI:18237",
    :gelatin => "CHEBI:28512",
    :hydroxyapatite => "CHEBI:52251",
    :tcp => "CHEBI:53480",
    :silica => "CHEBI:30563",
    :bioglass => "CHEBI:52254",
    :titanium => "CHEBI:33341",
    :bmp2 => "CHEBI:83658",
    :vegf => "CHEBI:74037"
)

"""Drug terms mapped to CHEBI IDs"""
const DRUG_TERMS = Dict{Symbol, String}(
    :dexamethasone => "CHEBI:27732",
    :methotrexate => "CHEBI:6801",
    :doxorubicin => "CHEBI:16236",
    :vancomycin => "CHEBI:9754",
    :gentamicin => "CHEBI:7507"
)

#=============================================================================
  LOOKUP FUNCTIONS
=============================================================================#

"""
    lookup_term(id::String) -> Union{OBOTerm, Nothing}

Look up OBO term by ID across all ontologies.
"""
function lookup_term(id::String)
    prefix = split(id, ":")[1]

    ontology = if prefix == "UBERON"
        UBERON
    elseif prefix == "CL"
        CL
    elseif prefix == "CHEBI"
        CHEBI
    elseif prefix == "NCIT"
        NCIT
    elseif prefix == "GO"
        GO
    elseif prefix == "BTO"
        BTO
    elseif prefix == "DOID"
        DOID
    else
        return nothing
    end

    get(ontology, id, nothing)
end

"""
    lookup_term(symbol::Symbol, category::Symbol=:auto) -> Union{OBOTerm, Nothing}

Look up term by symbol name in the appropriate category.
Categories: :tissue, :cell, :material, :drug, :auto (tries all)
"""
function lookup_term(symbol::Symbol, category::Symbol=:auto)
    if category == :auto
        # Try each category
        for (mapping, lookup_func) in [(TISSUE_TERMS, UBERON),
                                        (CELL_TERMS, CL),
                                        (MATERIAL_TERMS, CHEBI),
                                        (DRUG_TERMS, CHEBI)]
            if haskey(mapping, symbol)
                return get(lookup_func, mapping[symbol], nothing)
            end
        end
        return nothing
    elseif category == :tissue
        id = get(TISSUE_TERMS, symbol, nothing)
        isnothing(id) ? nothing : get(UBERON, id, nothing)
    elseif category == :cell
        id = get(CELL_TERMS, symbol, nothing)
        isnothing(id) ? nothing : get(CL, id, nothing)
    elseif category == :material
        id = get(MATERIAL_TERMS, symbol, nothing)
        isnothing(id) ? nothing : get(CHEBI, id, nothing)
    elseif category == :drug
        id = get(DRUG_TERMS, symbol, nothing)
        isnothing(id) ? nothing : get(CHEBI, id, nothing)
    else
        nothing
    end
end

"""
    get_parents(term::OBOTerm) -> Vector{OBOTerm}

Get parent terms (is_a relationships).
"""
function get_parents(term::OBOTerm)
    [lookup_term(p) for p in term.parents if !isnothing(lookup_term(p))]
end

"""
    get_children(term::OBOTerm) -> Vector{OBOTerm}

Get child terms (reverse is_a).
"""
function get_children(term::OBOTerm)
    ontology = if term.ontology == :UBERON
        UBERON
    elseif term.ontology == :CL
        CL
    elseif term.ontology == :CHEBI
        CHEBI
    elseif term.ontology == :NCIT
        NCIT
    elseif term.ontology == :GO
        GO
    elseif term.ontology == :BTO
        BTO
    elseif term.ontology == :DOID
        DOID
    else
        return OBOTerm[]
    end

    children = OBOTerm[]
    for (id, t) in ontology
        if term.id in t.parents
            push!(children, t)
        end
    end
    children
end

"""
    get_related(term::OBOTerm) -> Dict{String, Vector{OBOTerm}}

Get all related terms organized by relationship type.
"""
function get_related(term::OBOTerm)
    Dict(
        "parents" => get_parents(term),
        "children" => get_children(term),
        "part_of" => [lookup_term(p) for p in term.part_of if !isnothing(lookup_term(p))],
        "xrefs" => term.xrefs
    )
end

"""
    validate_term(id::String) -> Bool

Check if term ID exists in OBO Foundry.
"""
function validate_term(id::String)
    !isnothing(lookup_term(id))
end

#=============================================================================
  SCAFFOLD-SPECIFIC HELPERS
=============================================================================#

"""
    get_tissue_for_scaffold(tissue_symbol::Symbol) -> OBOTerm

Get UBERON term for scaffold target tissue.
"""
function get_tissue_for_scaffold(tissue_symbol::Symbol)
    lookup_term(tissue_symbol, :tissue)
end

"""
    get_cells_for_tissue(tissue_id::String) -> Vector{OBOTerm}

Get cell types typically found in or seeded on scaffolds for this tissue.
"""
function get_cells_for_tissue(tissue_id::String)
    # Mapping of tissues to relevant cell types
    tissue_cells = Dict(
        "UBERON:0002481" => [:osteoblast, :osteocyte, :msc],  # bone
        "UBERON:0002418" => [:chondrocyte, :msc],  # cartilage
        "UBERON:0002097" => [:keratinocyte, :fibroblast],  # skin
        "UBERON:0001981" => [:endothelial, :smooth_muscle],  # blood vessel
        "UBERON:0001017" => [:neuron, :astrocyte, :schwann],  # CNS
        "UBERON:0002385" => [:cardiomyocyte, :smooth_muscle],  # muscle
    )

    cell_symbols = get(tissue_cells, tissue_id, Symbol[])
    [lookup_term(c, :cell) for c in cell_symbols if !isnothing(lookup_term(c, :cell))]
end

"""
    get_materials_for_tissue(tissue_id::String) -> Vector{OBOTerm}

Get recommended materials for scaffold targeting this tissue.
"""
function get_materials_for_tissue(tissue_id::String)
    tissue_materials = Dict(
        "UBERON:0002481" => [:pcl, :pla, :hydroxyapatite, :tcp, :bioglass, :collagen],  # bone
        "UBERON:0002418" => [:collagen, :hyaluronic_acid, :alginate, :plga],  # cartilage
        "UBERON:0002097" => [:collagen, :chitosan, :fibrin, :pcl],  # skin
        "UBERON:0001981" => [:pcl, :pla, :collagen, :peg],  # blood vessel
        "UBERON:0001017" => [:collagen, :hyaluronic_acid, :chitosan, :plga],  # neural
    )

    mat_symbols = get(tissue_materials, tissue_id, Symbol[])
    [lookup_term(m, :material) for m in mat_symbols if !isnothing(lookup_term(m, :material))]
end

"""
    annotate_scaffold(; tissue::Symbol, material::Symbol,
                       cells::Vector{Symbol}=Symbol[],
                       drugs::Vector{Symbol}=Symbol[]) -> Dict

Create OBO-annotated scaffold description.
"""
function annotate_scaffold(; tissue::Symbol,
                            material::Symbol,
                            cells::Vector{Symbol}=Symbol[],
                            drugs::Vector{Symbol}=Symbol[])
    Dict(
        "tissue" => lookup_term(tissue, :tissue),
        "material" => lookup_term(material, :material),
        "cells" => [lookup_term(c, :cell) for c in cells],
        "drugs" => [lookup_term(d, :drug) for d in drugs],
        "biological_processes" => [
            lookup_term("GO:0008283"),  # cell proliferation
            lookup_term("GO:0007155"),  # cell adhesion
            lookup_term("GO:0030154"),  # cell differentiation
        ]
    )
end

end # module
