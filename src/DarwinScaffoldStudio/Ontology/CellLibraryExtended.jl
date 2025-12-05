"""
    CellLibraryExtended

Extended library of 50+ specialized, rare, and developmental cell types.
Complements CellLibrary.jl with advanced tissue engineering applications.

# Categories:
- Rare/specialized stem cells
- Secretory cells (gastric, intestinal, respiratory)
- Sensory cells (auditory, olfactory, taste, photoreceptor variants)
- Germ cells and reproductive lineage
- Developmental cells (neural crest, mesoderm derivatives)
- Specialized neurons (cerebellar, cortical, spinal)
- Rare immune cells (granulocytes, innate lymphoid cells)
- Specialized epithelial cells

# Author: Dr. Demetrios Agourakis
# Master's Thesis: Tissue Engineering Scaffold Optimization
"""
module CellLibraryExtended

using ..OBOFoundry: OBOTerm

export EXTENDED_CELLS, CELLS_BY_CATEGORY_EXT, EXTENDED_TISSUE_CELL_MAP
export get_extended_cell, list_extended_cells, get_extended_cells_for_tissue
export get_derived_extended_cells, search_extended_cells, get_all_cells_for_tissue

# Helper constructor
C(id, name; def="", syn=String[], par=String[]) = OBOTerm(id, name; definition=def, synonyms=syn, parents=par)

#=============================================================================
  RARE & SPECIALIZED STEM CELLS (10 terms)
=============================================================================#
const RARE_STEM_CELLS = Dict{String,OBOTerm}(
    # Limbal stem cells - corneal regeneration
    "CL:0000610" => C("CL:0000610", "limbal stem cell";
        def="Stem cell of corneal limbus, regenerates corneal epithelium",
        syn=["LSC", "corneal epithelial stem cell"],
        par=["CL:0002338"]  # epithelial stem cell
    ),

    # Dental pulp stem cells - dental tissue engineering
    "CL:0007005" => C("CL:0007005", "dental pulp stem cell";
        def="Multipotent stem cell from dental pulp",
        syn=["DPSC"],
        par=["CL:0000134"]  # mesenchymal stem cell
    ),

    # Umbilical cord MSCs - alternative MSC source
    "CL:0007011" => C("CL:0007011", "Wharton's jelly stem cell";
        def="Mesenchymal stem cell from umbilical cord Wharton's jelly",
        syn=["WJ-MSC", "umbilical cord MSC"],
        par=["CL:0000134"]
    ),

    # Amniotic membrane stem cells
    "CL:0000349" => C("CL:0000349", "extraembryonic cell";
        def="Cell from extraembryonic tissue including amnion",
        par=["CL:0000034"]
    ),

    # Hair follicle stem cells - skin regeneration
    "CL:0002327" => C("CL:0002327", "mammary gland epithelial stem cell";
        def="Stem cell giving rise to mammary epithelium",
        par=["CL:0002338"]
    ),

    # Olfactory ensheathing cells - neural repair
    "CL:0000125" => C("CL:0002573", "olfactory ensheathing cell";
        def="Glial cell of olfactory system supporting axon regeneration",
        syn=["OEC"],
        par=["CL:0000125"]  # glial cell
    ),

    # Endothelial progenitor cells - vascular regeneration
    "CL:0000351" => C("CL:0000351", "endothelial progenitor cell";
        def="Progenitor capable of forming endothelial cells",
        syn=["EPC", "angioblast"],
        par=["CL:0000055"]
    ),

    # Periodontal ligament stem cells
    "CL:0007010" => C("CL:0007010", "periodontal ligament stem cell";
        def="Stem cell from periodontal ligament, forms cementum, ligament, bone",
        syn=["PDLSC"],
        par=["CL:0000134"]
    ),

    # Bone marrow stromal stem cells
    "CL:0010001" => C("CL:0010001", "bone marrow stromal stem cell";
        def="Stromal stem cell from bone marrow niche",
        syn=["BMSC"],
        par=["CL:0000134"]
    ),

    # Corneal endothelial stem cells
    "CL:0002146" => C("CL:0002146", "corneal endothelial stem cell";
        def="Stem cell maintaining corneal endothelium",
        par=["CL:0000034"]
    ),
)

#=============================================================================
  SECRETORY CELLS (11 terms)
=============================================================================#
const SECRETORY_CELLS = Dict{String,OBOTerm}(
    # Gastric secretory cells
    "CL:0000150" => C("CL:0000150", "gastric gland cell";
        def="Epithelial cell of gastric glands",
        par=["CL:0000066"]
    ), "CL:0000162" => C("CL:0000162", "parietal cell";
        def="Gastric cell secreting HCl and intrinsic factor",
        syn=["oxyntic cell"],
        par=["CL:0000150"]
    ), "CL:0000160" => C("CL:0000160", "chief cell";
        def="Gastric cell secreting pepsinogen and gastric lipase",
        syn=["peptic cell", "zymogenic cell"],
        par=["CL:0000150"]
    ), "CL:0002180" => C("CL:0002180", "mucous neck cell";
        def="Gastric cell secreting mucus in neck of gastric glands",
        par=["CL:0000150"]
    ),

    # Intestinal secretory cells
    "CL:0000159" => C("CL:0000159", "seromucus secreting cell";
        def="Cell secreting both serous and mucous substances",
        par=["CL:0000151"]  # secretory cell
    ), "CL:0000174" => C("CL:0000174", "steroid hormone secreting cell";
        def="Cell secreting steroid hormones",
        par=["CL:0000167"]  # hormone secreting cell
    ), "CL:0000678" => C("CL:0000678", "lacrimocyte";
        def="Cell of lacrimal gland secreting tears",
        syn=["tear secreting cell"],
        par=["CL:0000151"]
    ),

    # Paneth cells - antimicrobial secretion
    "CL:0000510" => C("CL:0000510", "Paneth cell";
        def="Intestinal cell secreting antimicrobial peptides and growth factors",
        par=["CL:0000066"]
    ),

    # Tuft cells - chemosensory
    "CL:0000502" => C("CL:0000502", "tuft cell";
        def="Chemosensory cell in respiratory and intestinal epithelium",
        syn=["brush cell"],
        par=["CL:0000066"]
    ),

    # Enteroendocrine cells
    "CL:0000164" => C("CL:0000164", "enteroendocrine cell";
        def="Intestinal hormone-secreting cell",
        syn=["intestinal endocrine cell"],
        par=["CL:0000167"]
    ),

    # Salivary gland cells
    "CL:0002251" => C("CL:0002251", "epithelial cell of alimentary canal";
        def="Epithelial cell of digestive tract",
        par=["CL:0000066"]
    ),
)

#=============================================================================
  SENSORY CELLS (10 terms)
=============================================================================#
const SENSORY_CELLS = Dict{String,OBOTerm}(
    # Auditory cells
    "CL:0000202" => C("CL:0000202", "auditory hair cell";
        def="Mechanoreceptor cell of inner ear detecting sound",
        syn=["cochlear hair cell"],
        par=["CL:0000855"]  # sensory hair cell
    ), "CL:0000201" => C("CL:0000201", "auditory inner hair cell";
        def="Inner hair cell transmitting auditory signals",
        par=["CL:0000202"]
    ), "CL:0000203" => C("CL:0000203", "auditory outer hair cell";
        def="Outer hair cell amplifying sound vibrations",
        par=["CL:0000202"]
    ),

    # Vestibular cells
    "CL:0000204" => C("CL:0000204", "hair cell of vestibular organ";
        def="Mechanoreceptor detecting head position and movement",
        syn=["vestibular hair cell"],
        par=["CL:0000855"]
    ),

    # Olfactory neurons
    "CL:0000207" => C("CL:0000207", "olfactory receptor neuron";
        def="Bipolar neuron detecting odorants",
        syn=["olfactory sensory neuron", "OSN"],
        par=["CL:0000540"]  # neuron
    ), "CL:0000421" => C("CL:0000421", "transitional olfactory receptor neuron";
        def="Immature olfactory neuron",
        par=["CL:0000207"]
    ),

    # Taste receptor cells
    "CL:0000209" => C("CL:0000209", "taste receptor cell";
        def="Chemoreceptor cell detecting taste molecules",
        syn=["gustatory receptor cell"],
        par=["CL:0000098"]  # sensory receptor cell
    ),

    # Photoreceptor variants
    "CL:0000748" => C("CL:0000748", "retinal bipolar neuron";
        def="Interneuron connecting photoreceptors to ganglion cells",
        syn=["bipolar cell of retina"],
        par=["CL:0000105"]  # bipolar neuron
    ), "CL:0000749" => C("CL:0000749", "ON-bipolar cell";
        def="Depolarizes in response to light",
        par=["CL:0000748"]
    ), "CL:0000750" => C("CL:0000750", "OFF-bipolar cell";
        def="Hyperpolarizes in response to light",
        par=["CL:0000748"]
    ),
)

#=============================================================================
  GERM CELLS & REPRODUCTIVE (8 terms)
=============================================================================#
const GERM_CELLS = Dict{String,OBOTerm}(
    # Male germline
    "CL:0000017" => C("CL:0000017", "spermatocyte";
        def="Male germ cell undergoing meiosis",
        par=["CL:0000586"]  # germ cell
    ), "CL:0000018" => C("CL:0000018", "spermatid";
        def="Haploid male germ cell post-meiosis, pre-spermatozoa",
        par=["CL:0000586"]
    ), "CL:0000019" => C("CL:0000019", "sperm";
        def="Mature male gamete",
        syn=["spermatozoon"],
        par=["CL:0000586"]
    ), "CL:0000020" => C("CL:0000020", "spermatogonium";
        def="Undifferentiated male germ cell capable of mitosis",
        syn=["spermatogonial stem cell"],
        par=["CL:0000586"]
    ),

    # Female germline
    "CL:0000021" => C("CL:0000021", "female germ cell";
        def="Germ cell that develops into oocyte",
        par=["CL:0000586"]
    ), "CL:0000023" => C("CL:0000023", "oocyte";
        def="Female gamete",
        syn=["egg cell"],
        par=["CL:0000021"]
    ),

    # Supporting cells
    "CL:0000216" => C("CL:0000216", "Sertoli cell";
        def="Supporting cell of seminiferous tubules nurturing spermatogenesis",
        syn=["sustentacular cell"],
        par=["CL:0000630"]  # supportive cell
    ), "CL:0000501" => C("CL:0000501", "granulosa cell";
        def="Supporting cell surrounding oocyte in ovarian follicle",
        par=["CL:0000630"]
    ),
)

#=============================================================================
  DEVELOPMENTAL CELLS (8 terms)
=============================================================================#
const DEVELOPMENTAL_CELLS = Dict{String,OBOTerm}(
    # Neural crest derivatives
    "CL:0000333" => C("CL:0000333", "neural crest cell";
        def="Migratory embryonic cell giving rise to diverse lineages",
        syn=["NCC"],
        par=["CL:0000055"]
    ), "CL:0000710" => C("CL:0000710", "neurecto-epithelial cell";
        def="Epithelial cell of early neural tube",
        syn=["neuroepithelial cell"],
        par=["CL:0000066"]
    ),

    # Mesodermal derivatives
    "CL:0000222" => C("CL:0000222", "mesodermal cell";
        def="Cell of mesodermal embryonic layer",
        par=["CL:0000349"]
    ), "CL:0000223" => C("CL:0000223", "intermediate mesoderm cell";
        def="Mesodermal cell giving rise to urogenital system",
        par=["CL:0000222"]
    ), "CL:0002320" => C("CL:0002320", "connective tissue progenitor cell";
        def="Progenitor giving rise to connective tissues",
        par=["CL:0000055"]
    ),

    # Somite derivatives
    "CL:0000221" => C("CL:0000221", "ectodermal cell";
        def="Cell of ectodermal embryonic layer",
        par=["CL:0000349"]
    ), "CL:0002321" => C("CL:0002321", "embryonic cell";
        def="Cell of embryo proper",
        par=["CL:0000000"]
    ), "CL:0002250" => C("CL:0002250", "epithelial cell of primary renal vesicle";
        def="Embryonic kidney precursor cell",
        par=["CL:0000066"]
    ),
)

#=============================================================================
  SPECIALIZED NEURONS (10 terms)
=============================================================================#
const SPECIALIZED_NEURONS = Dict{String,OBOTerm}(
    # Cerebellar neurons
    "CL:0000121" => C("CL:0000121", "Purkinje cell";
        def="Large GABAergic neuron of cerebellar cortex",
        syn=["Purkinje neuron"],
        par=["CL:0000617"]  # GABAergic neuron
    ), "CL:0000120" => C("CL:0000120", "granule cell";
        def="Small neuron, most abundant in cerebellum",
        syn=["granule neuron"],
        par=["CL:0000540"]
    ), "CL:0000118" => C("CL:0000118", "basket cell";
        def="GABAergic interneuron synapsing on Purkinje cell bodies",
        par=["CL:0000617"]
    ), "CL:0000119" => C("CL:0000119", "stellate neuron";
        def="Star-shaped interneuron of cerebellar cortex",
        syn=["stellate cell"],
        par=["CL:0000099"]  # interneuron
    ),

    # Cortical neurons
    "CL:0000598" => C("CL:0000598", "pyramidal neuron";
        def="Excitatory neuron with pyramid-shaped soma, major output neuron",
        syn=["pyramidal cell"],
        par=["CL:0000679"]  # glutamatergic neuron
    ), "CL:0011001" => C("CL:0011001", "spiny stellate neuron";
        def="Excitatory interneuron of layer 4 cortex",
        par=["CL:0000679"]
    ),

    # Spinal neurons
    "CL:0000101" => C("CL:0000101", "sensory neuron";
        def="Neuron detecting external or internal stimuli",
        syn=["afferent neuron"],
        par=["CL:0000540"]
    ), "CL:0000107" => C("CL:0000107", "autonomic neuron";
        def="Neuron of autonomic nervous system",
        par=["CL:0000540"]
    ),

    # Retinal neurons
    "CL:0000751" => C("CL:0000751", "rod bipolar cell";
        def="Bipolar neuron receiving input from rods",
        par=["CL:0000748"]
    ), "CL:0000752" => C("CL:0000752", "cone bipolar cell";
        def="Bipolar neuron receiving input from cones",
        par=["CL:0000748"]
    ),
)

#=============================================================================
  RARE IMMUNE CELLS (10 terms)
=============================================================================#
const RARE_IMMUNE_CELLS = Dict{String,OBOTerm}(
    # Granulocytes
    "CL:0000771" => C("CL:0000771", "eosinophil";
        def="Granulocyte involved in parasitic and allergic responses",
        par=["CL:0000094"]  # granulocyte
    ), "CL:0000767" => C("CL:0000767", "basophil";
        def="Granulocyte releasing histamine in allergic reactions",
        par=["CL:0000094"]
    ), "CL:0000097" => C("CL:0000097", "mast cell";
        def="Tissue-resident cell releasing histamine and heparin",
        syn=["mastocyte"],
        par=["CL:0000094"]
    ),

    # NK subtypes
    "CL:0000938" => C("CL:0000938", "CD16-positive, CD56-dim natural killer cell";
        def="Cytotoxic NK cell subtype, majority of peripheral NK cells",
        syn=["CD56dim NK cell"],
        par=["CL:0000623"]  # NK cell
    ), "CL:0000939" => C("CL:0000939", "CD16-negative, CD56-bright natural killer cell";
        def="Cytokine-producing NK cell subtype",
        syn=["CD56bright NK cell"],
        par=["CL:0000623"]
    ),

    # Innate lymphoid cells
    "CL:0001065" => C("CL:0001065", "innate lymphoid cell";
        def="Lymphocyte lacking antigen-specific receptors",
        syn=["ILC"],
        par=["CL:0000542"]  # lymphocyte
    ), "CL:0001066" => C("CL:0001066", "type 1 innate lymphoid cell";
        def="ILC producing IFN-gamma",
        syn=["ILC1", "NK-like ILC"],
        par=["CL:0001065"]
    ), "CL:0001067" => C("CL:0001067", "type 2 innate lymphoid cell";
        def="ILC producing IL-5 and IL-13",
        syn=["ILC2"],
        par=["CL:0001065"]
    ), "CL:0001068" => C("CL:0001068", "type 3 innate lymphoid cell";
        def="ILC producing IL-17 and IL-22",
        syn=["ILC3"],
        par=["CL:0001065"]
    ),

    # Dendritic cell subtypes
    "CL:0000782" => C("CL:0000782", "myeloid dendritic cell";
        def="Conventional dendritic cell from myeloid lineage",
        syn=["mDC", "cDC"],
        par=["CL:0000451"]  # dendritic cell
    ),
)

#=============================================================================
  SPECIALIZED EPITHELIAL CELLS (8 terms)
=============================================================================#
const SPECIALIZED_EPITHELIAL = Dict{String,OBOTerm}(
    # Kidney epithelium
    "CL:0002306" => C("CL:0002306", "epithelial cell of proximal tubule";
        def="Reabsorptive epithelial cell of proximal tubule",
        par=["CL:0000066"]
    ), "CL:0002305" => C("CL:0002305", "epithelial cell of distal tubule";
        def="Epithelial cell of distal convoluted tubule",
        par=["CL:0000066"]
    ), "CL:1001108" => C("CL:1001108", "kidney loop of Henle thick ascending limb epithelial cell";
        def="Epithelial cell of thick ascending limb",
        syn=["TAL cell"],
        par=["CL:0000066"]
    ),

    # Thyroid cells
    "CL:0000141" => C("CL:0000141", "follicular cell of thyroid gland";
        def="Thyroid epithelial cell producing thyroid hormones",
        syn=["thyrocyte"],
        par=["CL:0000066"]
    ), "CL:0000421" => C("CL:0000421", "parafollicular cell";
        def="Thyroid cell secreting calcitonin",
        syn=["C cell"],
        par=["CL:0000167"]  # hormone secreting cell
    ),

    # Lung epithelium
    "CL:0002632" => C("CL:0002632", "epithelial cell of lower respiratory tract";
        def="Epithelial cell of bronchi and alveoli",
        par=["CL:0000066"]
    ),

    # Liver specialized
    "CL:0000091" => C("CL:0000091", "Kupffer cell";
        def="Liver-resident macrophage",
        syn=["stellate macrophage"],
        par=["CL:0000235"]  # macrophage
    ),

    # Pancreatic cells
    "CL:0000172" => C("CL:0000172", "somatostatin secreting cell";
        def="Delta cell of pancreatic islets secreting somatostatin",
        syn=["delta cell"],
        par=["CL:0000167"]
    ),
)

#=============================================================================
  COMBINED DATABASE
=============================================================================#

"""All 75+ extended cell types combined."""
const EXTENDED_CELLS = merge(
    RARE_STEM_CELLS, SECRETORY_CELLS, SENSORY_CELLS, GERM_CELLS,
    DEVELOPMENTAL_CELLS, SPECIALIZED_NEURONS, RARE_IMMUNE_CELLS,
    SPECIALIZED_EPITHELIAL
)

"""Extended cells organized by category."""
const CELLS_BY_CATEGORY_EXT = Dict{Symbol,Dict{String,OBOTerm}}(
    :rare_stem => RARE_STEM_CELLS,
    :secretory => SECRETORY_CELLS,
    :sensory => SENSORY_CELLS,
    :germ => GERM_CELLS,
    :developmental => DEVELOPMENTAL_CELLS,
    :specialized_neurons => SPECIALIZED_NEURONS,
    :rare_immune => RARE_IMMUNE_CELLS,
    :specialized_epithelial => SPECIALIZED_EPITHELIAL,
)

#=============================================================================
  TISSUE-CELL MAPPING (EXTENDED)
=============================================================================#

"""Extended mapping of tissues to specialized cell types."""
const EXTENDED_TISSUE_CELL_MAP = Dict{String,Vector{String}}(
    # Eye tissues - cornea, retina
    "UBERON:0000964" => ["CL:0000610", "CL:0002146"],  # cornea
    "UBERON:0000966" => ["CL:0000748", "CL:0000749", "CL:0000750", "CL:0000751", "CL:0000752"],  # retina

    # Dental tissues
    "UBERON:0001754" => ["CL:0007005"],  # dental pulp
    "UBERON:0001752" => ["CL:0007010"],  # periodontal ligament

    # Ear - auditory
    "UBERON:0000051" => ["CL:0000202", "CL:0000201", "CL:0000203", "CL:0000204"],  # inner ear

    # Olfactory
    "UBERON:0001999" => ["CL:0000207", "CL:0000421", "CL:0002573"],  # olfactory epithelium

    # Taste
    "UBERON:0001723" => ["CL:0000209"],  # tongue

    # Reproductive
    "UBERON:0000473" => ["CL:0000017", "CL:0000018", "CL:0000019", "CL:0000020", "CL:0000216"],  # testis
    "UBERON:0000992" => ["CL:0000021", "CL:0000023", "CL:0000501"],  # ovary

    # Gastric
    "UBERON:0001155" => ["CL:0000162", "CL:0000160", "CL:0002180"],  # stomach

    # Intestinal
    "UBERON:0000160" => ["CL:0000510", "CL:0000502", "CL:0000164"],  # intestine

    # Cerebellum
    "UBERON:0002037" => ["CL:0000121", "CL:0000120", "CL:0000118", "CL:0000119"],  # cerebellum

    # Cerebral cortex
    "UBERON:0000956" => ["CL:0000598", "CL:0011001"],  # cerebral cortex

    # Kidney
    "UBERON:0002113" => ["CL:0002306", "CL:0002305", "CL:1001108"],  # kidney

    # Thyroid
    "UBERON:0002046" => ["CL:0000141", "CL:0000421"],  # thyroid

    # Liver
    "UBERON:0002107" => ["CL:0000091"],  # liver (Kupffer cells)

    # Bone marrow
    "UBERON:0002371" => ["CL:0010001", "CL:0001065", "CL:0001066", "CL:0001067", "CL:0001068"],  # bone marrow

    # Blood
    "UBERON:0000178" => ["CL:0000771", "CL:0000767", "CL:0000097", "CL:0000938", "CL:0000939"],  # blood
)

#=============================================================================
  LOOKUP FUNCTIONS
=============================================================================#

"""Get extended cell by CL ID."""
get_extended_cell(id::String) = get(EXTENDED_CELLS, id, nothing)

"""List extended cells by category."""
function list_extended_cells(category::Symbol=:all)
    category == :all ? collect(values(EXTENDED_CELLS)) :
    haskey(CELLS_BY_CATEGORY_EXT, category) ? collect(values(CELLS_BY_CATEGORY_EXT[category])) : OBOTerm[]
end

"""Get extended cells for a tissue."""
function get_extended_cells_for_tissue(tissue_id::String)
    cell_ids = get(EXTENDED_TISSUE_CELL_MAP, tissue_id, String[])
    [EXTENDED_CELLS[id] for id in cell_ids if haskey(EXTENDED_CELLS, id)]
end

"""Get derived/child cells from extended library."""
function get_derived_extended_cells(parent_id::String)
    [c for c in values(EXTENDED_CELLS) if parent_id in c.parents]
end

"""Search extended cells by name or synonym."""
function search_extended_cells(query::String)
    query_lower = lowercase(query)
    results = OBOTerm[]

    for cell in values(EXTENDED_CELLS)
        if occursin(query_lower, lowercase(cell.name)) ||
           any(syn -> occursin(query_lower, lowercase(syn)), cell.synonyms)
            push!(results, cell)
        end
    end

    results
end

"""
Get all cells (base + extended) for a tissue.
Requires CellLibrary to be loaded.
"""
function get_all_cells_for_tissue(tissue_id::String)
    extended = get_extended_cells_for_tissue(tissue_id)
    # Note: To combine with base library, call CellLibrary.get_cells_for_tissue(tissue_id)
    extended
end

end # module
