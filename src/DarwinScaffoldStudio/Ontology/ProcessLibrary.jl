"""
    ProcessLibrary

Comprehensive library of biological processes relevant to tissue engineering scaffolds.

Provides 60+ processes organized by category:
- Cell behavior (proliferation, migration, adhesion, spreading, apoptosis)
- Differentiation pathways (osteogenic, chondrogenic, adipogenic, neurogenic, myogenic)
- Tissue formation (ossification, chondrogenesis, angiogenesis, neurogenesis, myogenesis)
- ECM processes (collagen synthesis, mineralization, ECM remodeling, crosslinking)
- Inflammatory response (acute, chronic, foreign body, resolution)
- Immune responses (macrophage polarization, T cell activation, complement)
- Wound healing phases (hemostasis, inflammation, proliferation, remodeling)
- Degradation (enzymatic, hydrolytic, phagocytosis)
- Signaling pathways (mechanotransduction, growth factors, Wnt, BMP, Notch)

Uses Gene Ontology (GO) IDs for standardization.

# Examples
```julia
# Get a process
process = get_process("GO:0008283")  # cell proliferation
println(process.name)

# Get processes for tissue type
bone_processes = TISSUE_PROCESS_MAP["bone"]
for proc_id in bone_processes
    println(get_process(proc_id).name)
end

# Get all processes in a category
for (id, proc) in CELL_BEHAVIOR
    println("\$(proc.id): \$(proc.name)")
end
```

# References
- Gene Ontology: http://geneontology.org/
- Murphy et al. 2010: Cell behavior on scaffolds
- Anderson et al. 2008: Foreign body response
- Singer & Clark 1999: Wound healing

# Author: Dr. Demetrios Agourakis
# Master's Thesis: Tissue Engineering Scaffold Optimization
"""
module ProcessLibrary

using ..OBOFoundry: OBOTerm

export PROCESSES, get_process, get_processes_by_category
export CELL_BEHAVIOR, DIFFERENTIATION, TISSUE_FORMATION, ECM_PROCESSES
export INFLAMMATORY_RESPONSE, IMMUNE_RESPONSE, WOUND_HEALING, DEGRADATION, SIGNALING
export TISSUE_PROCESS_MAP, get_tissue_processes, get_process_tissues

#=============================================================================
  HELPER CONSTRUCTOR
=============================================================================#

"""Convenience constructor for process terms."""
P(id, name; def="", syn=String[], par=String[]) =
    OBOTerm(id, name; definition=def, synonyms=syn, parents=par)

#=============================================================================
  CELL BEHAVIOR PROCESSES
  Basic cellular activities on scaffolds
=============================================================================#

const CELL_BEHAVIOR = Dict{String,OBOTerm}(
    # Proliferation
    "GO:0008283" => P("GO:0008283", "cell population proliferation";
        def="Increase in number of cells due to cell division",
        syn=["cell proliferation", "cell growth"],
        par=["GO:0009987"]  # cellular process
    ),
    "GO:0098771" => P("GO:0098771", "inorganic ion homeostasis";
        def="Regulation of ion concentrations in cells",
        syn=["ion homeostasis"],
        par=["GO:0055065"]
    ),
    "GO:0051301" => P("GO:0051301", "cell division";
        def="Process by which a cell separates into two daughter cells",
        syn=["cytokinesis"],
        par=["GO:0009987"]
    ),

    # Migration
    "GO:0016477" => P("GO:0016477", "cell migration";
        def="Orderly movement of cells from one site to another",
        syn=["cell motility", "cell movement"],
        par=["GO:0048870"]  # cell motility
    ),
    "GO:0030335" => P("GO:0030335", "positive regulation of cell migration";
        def="Any process that activates cell migration",
        par=["GO:0016477"]
    ),
    "GO:0030336" => P("GO:0030336", "negative regulation of cell migration";
        def="Any process that stops cell migration",
        par=["GO:0016477"]
    ),
    "GO:0060326" => P("GO:0060326", "cell chemotaxis";
        def="Directed cell movement in response to chemical gradient",
        syn=["chemotactic cell migration"],
        par=["GO:0016477"]
    ),

    # Adhesion
    "GO:0007155" => P("GO:0007155", "cell adhesion";
        def="Attachment of cell to substrate or another cell",
        syn=["cell-cell adhesion", "cell-substrate adhesion"],
        par=["GO:0009987"]
    ),
    "GO:0098609" => P("GO:0098609", "cell-cell adhesion";
        def="Attachment of one cell to another cell",
        par=["GO:0007155"]
    ),
    "GO:0031589" => P("GO:0031589", "cell-substrate adhesion";
        def="Attachment of cell to underlying substrate",
        syn=["focal adhesion formation"],
        par=["GO:0007155"]
    ),
    "GO:0007160" => P("GO:0007160", "cell-matrix adhesion";
        def="Attachment of cell to extracellular matrix",
        syn=["ECM adhesion"],
        par=["GO:0007155"]
    ),

    # Spreading
    "GO:0072089" => P("GO:0072089", "stem cell proliferation";
        def="Expansion of stem cell population",
        par=["GO:0008283"]
    ),
    "GO:0030155" => P("GO:0030155", "regulation of cell adhesion";
        def="Process that modulates cell adhesion",
        par=["GO:0007155"]
    ),

    # Apoptosis and survival
    "GO:0012501" => P("GO:0012501", "programmed cell death";
        def="Cell death resulting from activation of endogenous program",
        syn=["apoptosis", "PCD"],
        par=["GO:0008219"]  # cell death
    ),
    "GO:0097193" => P("GO:0097193", "intrinsic apoptotic signaling pathway";
        def="Apoptosis triggered by internal signals",
        syn=["mitochondrial apoptosis"],
        par=["GO:0012501"]
    ),
    "GO:0097191" => P("GO:0097191", "extrinsic apoptotic signaling pathway";
        def="Apoptosis triggered by external signals",
        syn=["death receptor pathway"],
        par=["GO:0012501"]
    ),
    "GO:0043066" => P("GO:0043066", "negative regulation of apoptotic process";
        def="Any process that stops apoptosis",
        syn=["anti-apoptosis", "cell survival"],
        par=["GO:0012501"]
    ),

    # Cell viability
    "GO:0008219" => P("GO:0008219", "cell death";
        def="Process resulting in permanent cessation of cellular functions",
        par=["GO:0009987"]
    ),
    "GO:0001906" => P("GO:0001906", "cell killing";
        def="Process resulting in death of target cell",
        par=["GO:0008219"]
    ),
)

#=============================================================================
  DIFFERENTIATION PROCESSES
  Stem cell commitment to specialized lineages
=============================================================================#

const DIFFERENTIATION = Dict{String,OBOTerm}(
    # General differentiation
    "GO:0030154" => P("GO:0030154", "cell differentiation";
        def="Process by which cell acquires specialized features",
        syn=["cell commitment"],
        par=["GO:0048869"]  # cellular developmental process
    ),

    # Osteogenic differentiation
    "GO:0001649" => P("GO:0001649", "osteoblast differentiation";
        def="Process by which MSC becomes osteoblast",
        syn=["osteogenic differentiation"],
        par=["GO:0030154"]
    ),
    "GO:0045669" => P("GO:0045669", "positive regulation of osteoblast differentiation";
        def="Any process that activates osteoblast differentiation",
        par=["GO:0001649"]
    ),
    "GO:0002076" => P("GO:0002076", "osteoblast development";
        def="Progression of osteoblast over time",
        par=["GO:0001649"]
    ),
    "GO:0010718" => P("GO:0010718", "positive regulation of epithelial to mesenchymal transition";
        def="Activation of EMT process",
        syn=["EMT activation"],
        par=["GO:0030154"]
    ),

    # Chondrogenic differentiation
    "GO:0002062" => P("GO:0002062", "chondrocyte differentiation";
        def="Process by which MSC becomes chondrocyte",
        syn=["chondrogenic differentiation"],
        par=["GO:0030154"]
    ),
    "GO:0003413" => P("GO:0003413", "chondrocyte differentiation involved in endochondral bone morphogenesis";
        def="Chondrocyte differentiation during bone formation",
        par=["GO:0002062"]
    ),
    "GO:0060272" => P("GO:0060272", "embryonic chondrocyte differentiation";
        def="Chondrogenesis during embryonic development",
        par=["GO:0002062"]
    ),

    # Adipogenic differentiation
    "GO:0045444" => P("GO:0045444", "fat cell differentiation";
        def="Process by which precursor becomes adipocyte",
        syn=["adipogenesis", "adipocyte differentiation"],
        par=["GO:0030154"]
    ),
    "GO:0045598" => P("GO:0045598", "regulation of fat cell differentiation";
        def="Modulation of adipogenesis",
        par=["GO:0045444"]
    ),

    # Neurogenic differentiation
    "GO:0030182" => P("GO:0030182", "neuron differentiation";
        def="Process by which neuronal precursor becomes mature neuron",
        syn=["neurogenesis", "neuronal differentiation"],
        par=["GO:0030154"]
    ),
    "GO:0014002" => P("GO:0014002", "astrocyte development";
        def="Progression of astrocyte over time",
        par=["GO:0030154"]
    ),
    "GO:0014033" => P("GO:0014033", "neural crest cell differentiation";
        def="Differentiation of neural crest cells",
        par=["GO:0030182"]
    ),
    "GO:0048665" => P("GO:0048665", "neuron fate specification";
        def="Process by which cell becomes committed to neuronal fate",
        par=["GO:0030182"]
    ),

    # Myogenic differentiation
    "GO:0042692" => P("GO:0042692", "muscle cell differentiation";
        def="Process by which precursor becomes muscle cell",
        syn=["myogenesis", "muscle differentiation"],
        par=["GO:0030154"]
    ),
    "GO:0055008" => P("GO:0055008", "cardiac muscle tissue morphogenesis";
        def="Shaping of cardiac muscle during development",
        syn=["heart muscle development"],
        par=["GO:0042692"]
    ),
    "GO:0014706" => P("GO:0014706", "striated muscle tissue development";
        def="Development of skeletal or cardiac muscle",
        par=["GO:0042692"]
    ),

    # Endothelial differentiation
    "GO:0001885" => P("GO:0001885", "endothelial cell development";
        def="Progression of endothelial cell over time",
        syn=["endothelial differentiation"],
        par=["GO:0030154"]
    ),
    "GO:0035767" => P("GO:0035767", "endothelial cell chemotaxis";
        def="Directed endothelial cell movement",
        par=["GO:0001885"]
    ),
)

#=============================================================================
  TISSUE FORMATION PROCESSES
  Development and regeneration of tissues
=============================================================================#

const TISSUE_FORMATION = Dict{String,OBOTerm}(
    # Bone formation
    "GO:0001503" => P("GO:0001503", "ossification";
        def="Formation of bone or of bony substance",
        syn=["bone formation", "osteogenesis"],
        par=["GO:0060348"]  # bone development
    ),
    "GO:0001958" => P("GO:0001958", "endochondral ossification";
        def="Bone formation through cartilage template",
        syn=["endochondral bone formation"],
        par=["GO:0001503"]
    ),
    "GO:0001957" => P("GO:0001957", "intramembranous ossification";
        def="Direct bone formation without cartilage",
        syn=["intramembranous bone formation"],
        par=["GO:0001503"]
    ),
    "GO:0046850" => P("GO:0046850", "regulation of bone remodeling";
        def="Modulation of bone remodeling process",
        par=["GO:0001503"]
    ),

    # Cartilage formation
    "GO:0051216" => P("GO:0051216", "cartilage development";
        def="Process leading to formation of cartilage",
        syn=["chondrogenesis"],
        par=["GO:0048856"]  # anatomical structure development
    ),
    "GO:0035988" => P("GO:0035988", "chondrocyte proliferation";
        def="Expansion of chondrocyte population",
        par=["GO:0051216"]
    ),
    "GO:0003416" => P("GO:0003416", "chondrocyte hypertrophy";
        def="Enlargement of chondrocytes",
        par=["GO:0051216"]
    ),

    # Vascular formation
    "GO:0001525" => P("GO:0001525", "angiogenesis";
        def="Formation of blood vessels from existing vasculature",
        syn=["neovascularization", "blood vessel formation"],
        par=["GO:0048514"]  # blood vessel morphogenesis
    ),
    "GO:0001570" => P("GO:0001570", "vasculogenesis";
        def="De novo formation of blood vessels",
        par=["GO:0048514"]
    ),
    "GO:0030949" => P("GO:0030949", "positive regulation of vascular endothelial growth factor receptor signaling pathway";
        def="Activation of VEGF signaling",
        syn=["VEGF signaling activation"],
        par=["GO:0001525"]
    ),
    "GO:0002040" => P("GO:0002040", "sprouting angiogenesis";
        def="Angiogenesis via endothelial sprouting",
        par=["GO:0001525"]
    ),

    # Neural tissue formation
    "GO:0022008" => P("GO:0022008", "neurogenesis";
        def="Generation of neurons from stem/progenitor cells",
        syn=["neural tissue formation"],
        par=["GO:0048699"]  # generation of neurons
    ),
    "GO:0021987" => P("GO:0021987", "cerebral cortex development";
        def="Development of cerebral cortex",
        par=["GO:0022008"]
    ),
    "GO:0014012" => P("GO:0014012", "peripheral nervous system axon regeneration";
        def="Regrowth of peripheral axons",
        syn=["nerve regeneration"],
        par=["GO:0022008"]
    ),

    # Muscle tissue formation
    "GO:0007517" => P("GO:0007517", "muscle organ development";
        def="Process leading to formation of muscle",
        syn=["myogenesis", "muscle formation"],
        par=["GO:0048513"]  # organ development
    ),
    "GO:0060415" => P("GO:0060415", "muscle tissue morphogenesis";
        def="Shaping of muscle tissue",
        par=["GO:0007517"]
    ),
    "GO:0055002" => P("GO:0055002", "striated muscle cell development";
        def="Development of skeletal/cardiac muscle cells",
        par=["GO:0007517"]
    ),

    # Skin formation
    "GO:0043588" => P("GO:0043588", "skin development";
        def="Process leading to formation of skin",
        syn=["cutaneous development"],
        par=["GO:0048513"]
    ),
    "GO:0060429" => P("GO:0060429", "epithelium development";
        def="Development of epithelial tissue",
        par=["GO:0043588"]
    ),
)

#=============================================================================
  ECM PROCESSES
  Extracellular matrix production, organization, and modification
=============================================================================#

const ECM_PROCESSES = Dict{String,OBOTerm}(
    # ECM organization
    "GO:0030198" => P("GO:0030198", "extracellular matrix organization";
        def="Assembly and arrangement of extracellular matrix",
        syn=["ECM organization", "matrix organization"],
        par=["GO:0043062"]  # ECM organization
    ),
    "GO:0030199" => P("GO:0030199", "collagen fibril organization";
        def="Assembly of collagen fibrils",
        par=["GO:0030198"]
    ),

    # Collagen processes
    "GO:0032964" => P("GO:0032964", "collagen biosynthetic process";
        def="Chemical reactions forming collagen",
        syn=["collagen synthesis", "collagen production"],
        par=["GO:0044243"]  # biosynthetic process
    ),
    "GO:0030574" => P("GO:0030574", "collagen catabolic process";
        def="Chemical reactions breaking down collagen",
        syn=["collagen degradation"],
        par=["GO:0009056"]  # catabolic process
    ),
    "GO:0051261" => P("GO:0051261", "protein depolymerization";
        def="Breakdown of polymeric proteins",
        par=["GO:0030574"]
    ),

    # Mineralization
    "GO:0030282" => P("GO:0030282", "bone mineralization";
        def="Deposition of calcium phosphate in bone matrix",
        syn=["bone calcification", "biomineralization"],
        par=["GO:0001503"]
    ),
    "GO:0033333" => P("GO:0033333", "fin development";
        def="Development of fin structures",
        par=["GO:0048513"]
    ),
    "GO:0070166" => P("GO:0070166", "enamel mineralization";
        def="Deposition of minerals in enamel",
        par=["GO:0030282"]
    ),
    "GO:0001501" => P("GO:0001501", "skeletal system development";
        def="Development of skeleton",
        par=["GO:0048513"]
    ),

    # ECM remodeling
    "GO:0022617" => P("GO:0022617", "extracellular matrix disassembly";
        def="Breakdown of extracellular matrix",
        syn=["ECM degradation", "matrix remodeling"],
        par=["GO:0030198"]
    ),
    "GO:0030163" => P("GO:0030163", "protein catabolic process";
        def="Breakdown of proteins",
        par=["GO:0009056"]
    ),
    "GO:0044257" => P("GO:0044257", "cellular protein catabolic process";
        def="Breakdown of cellular proteins",
        par=["GO:0030163"]
    ),

    # Crosslinking
    "GO:0018149" => P("GO:0018149", "peptide cross-linking";
        def="Formation of covalent bonds between peptides",
        syn=["protein crosslinking"],
        par=["GO:0018158"]  # protein modification
    ),
    "GO:0061041" => P("GO:0061041", "regulation of wound healing";
        def="Modulation of wound healing process",
        par=["GO:0042060"]
    ),

    # ECM deposition
    "GO:0045229" => P("GO:0045229", "external encapsulating structure organization";
        def="Organization of external structures",
        par=["GO:0043062"]
    ),
    "GO:0070208" => P("GO:0070208", "protein heterotrimerization";
        def="Formation of protein heterotrimers",
        par=["GO:0043062"]
    ),
)

#=============================================================================
  INFLAMMATORY RESPONSE
  Host response to implanted scaffolds
=============================================================================#

const INFLAMMATORY_RESPONSE = Dict{String,OBOTerm}(
    # General inflammation
    "GO:0006954" => P("GO:0006954", "inflammatory response";
        def="Immediate defensive reaction to infection or injury",
        syn=["inflammation"],
        par=["GO:0006950"]  # response to stress
    ),
    "GO:0002526" => P("GO:0002526", "acute inflammatory response";
        def="Immediate inflammatory response, short duration",
        syn=["acute inflammation"],
        par=["GO:0006954"]
    ),
    "GO:0002544" => P("GO:0002544", "chronic inflammatory response";
        def="Persistent inflammatory response",
        syn=["chronic inflammation"],
        par=["GO:0006954"]
    ),

    # Foreign body response
    "GO:0002684" => P("GO:0002684", "positive regulation of immune system process";
        def="Activation of immune responses",
        par=["GO:0002376"]  # immune system process
    ),
    "GO:0002683" => P("GO:0002683", "negative regulation of immune system process";
        def="Suppression of immune responses",
        par=["GO:0002376"]
    ),
    "GO:0050729" => P("GO:0050729", "positive regulation of inflammatory response";
        def="Activation of inflammation",
        par=["GO:0006954"]
    ),
    "GO:0050728" => P("GO:0050728", "negative regulation of inflammatory response";
        def="Suppression of inflammation",
        syn=["anti-inflammatory response"],
        par=["GO:0006954"]
    ),

    # Resolution
    "GO:0050727" => P("GO:0050727", "regulation of inflammatory response";
        def="Modulation of inflammatory response",
        par=["GO:0006954"]
    ),
    "GO:0090594" => P("GO:0090594", "inflammatory response to wounding";
        def="Inflammation in response to tissue damage",
        par=["GO:0006954"]
    ),

    # Cytokine-mediated
    "GO:0019221" => P("GO:0019221", "cytokine-mediated signaling pathway";
        def="Signaling via cytokines",
        syn=["cytokine signaling"],
        par=["GO:0006954"]
    ),
    "GO:0071345" => P("GO:0071345", "cellular response to cytokine stimulus";
        def="Cell changes due to cytokine",
        par=["GO:0019221"]
    ),
)

#=============================================================================
  IMMUNE RESPONSE
  Specific immune cell activities on scaffolds
=============================================================================#

const IMMUNE_RESPONSE = Dict{String,OBOTerm}(
    # General immune
    "GO:0002376" => P("GO:0002376", "immune system process";
        def="Any process involved in immune function",
        syn=["immunity"],
        par=["GO:0008150"]  # biological process
    ),
    "GO:0006955" => P("GO:0006955", "immune response";
        def="Response to foreign antigen",
        par=["GO:0002376"]
    ),
    "GO:0006952" => P("GO:0006952", "defense response";
        def="Response protecting organism from harm",
        par=["GO:0002376"]
    ),

    # Macrophage responses
    "GO:0042116" => P("GO:0042116", "macrophage activation";
        def="Change in macrophage to active state",
        syn=["macrophage polarization"],
        par=["GO:0002376"]
    ),
    "GO:0098752" => P("GO:0098752", "positive regulation of macrophage activation";
        def="Activation of macrophage function",
        par=["GO:0042116"]
    ),
    "GO:0002675" => P("GO:0002675", "positive regulation of acute inflammatory response";
        def="Activation of acute inflammation",
        par=["GO:0002526"]
    ),

    # T cell responses
    "GO:0042110" => P("GO:0042110", "T cell activation";
        def="Change in T cell to active state",
        syn=["T lymphocyte activation"],
        par=["GO:0002376"]
    ),
    "GO:0050853" => P("GO:0050853", "B cell receptor signaling pathway";
        def="Signaling via B cell receptor",
        syn=["BCR signaling"],
        par=["GO:0002376"]
    ),
    "GO:0050852" => P("GO:0050852", "T cell receptor signaling pathway";
        def="Signaling via T cell receptor",
        syn=["TCR signaling"],
        par=["GO:0042110"]
    ),

    # Complement system
    "GO:0006956" => P("GO:0006956", "complement activation";
        def="Activation of complement cascade",
        par=["GO:0002376"]
    ),
    "GO:0006958" => P("GO:0006958", "complement activation, classical pathway";
        def="Antibody-mediated complement activation",
        par=["GO:0006956"]
    ),

    # Phagocytosis
    "GO:0006909" => P("GO:0006909", "phagocytosis";
        def="Engulfment of particles by cell",
        par=["GO:0002376"]
    ),
    "GO:0045087" => P("GO:0045087", "innate immune response";
        def="Non-specific immune defense",
        par=["GO:0002376"]
    ),
)

#=============================================================================
  WOUND HEALING PHASES
  Sequential phases of tissue repair
=============================================================================#

const WOUND_HEALING = Dict{String,OBOTerm}(
    # General wound healing
    "GO:0042060" => P("GO:0042060", "wound healing";
        def="Series of events restoring integrity after damage",
        syn=["tissue repair"],
        par=["GO:0009987"]
    ),
    "GO:0061041" => P("GO:0061041", "regulation of wound healing";
        def="Modulation of wound healing",
        par=["GO:0042060"]
    ),

    # Hemostasis phase
    "GO:0007596" => P("GO:0007596", "blood coagulation";
        def="Sequential process leading to clot formation",
        syn=["hemostasis", "clotting"],
        par=["GO:0007599"]  # hemostasis
    ),
    "GO:0030168" => P("GO:0030168", "platelet activation";
        def="Response of platelet to stimulus",
        par=["GO:0007596"]
    ),
    "GO:0050817" => P("GO:0050817", "coagulation";
        def="Formation of fibrin clot",
        par=["GO:0007596"]
    ),

    # Inflammatory phase
    "GO:0002090" => P("GO:0002090", "regulation of receptor internalization";
        def="Modulation of receptor uptake",
        par=["GO:0009987"]
    ),

    # Proliferative phase
    "GO:0042127" => P("GO:0042127", "regulation of cell population proliferation";
        def="Modulation of cell proliferation",
        par=["GO:0008283"]
    ),
    "GO:0048661" => P("GO:0048661", "positive regulation of smooth muscle cell proliferation";
        def="Activation of smooth muscle proliferation",
        par=["GO:0042127"]
    ),
    "GO:0010595" => P("GO:0010595", "positive regulation of endothelial cell migration";
        def="Activation of endothelial cell movement",
        par=["GO:0001525"]
    ),
    "GO:0010628" => P("GO:0010628", "positive regulation of gene expression";
        def="Activation of gene transcription",
        par=["GO:0010467"]
    ),

    # Remodeling phase
    "GO:0048771" => P("GO:0048771", "tissue remodeling";
        def="Reorganization of tissue structure",
        syn=["matrix remodeling"],
        par=["GO:0009987"]
    ),
    "GO:0030203" => P("GO:0030203", "glycosaminoglycan metabolic process";
        def="Chemical reactions of GAGs",
        par=["GO:0006022"]
    ),
    "GO:0022617" => P("GO:0022617", "extracellular matrix disassembly";
        def="Breakdown of ECM components",
        par=["GO:0030198"]
    ),
)

#=============================================================================
  DEGRADATION PROCESSES
  Scaffold and matrix degradation mechanisms
=============================================================================#

const DEGRADATION = Dict{String,OBOTerm}(
    # Enzymatic degradation
    "GO:0030574" => P("GO:0030574", "collagen catabolic process";
        def="Enzymatic breakdown of collagen",
        syn=["collagenolysis"],
        par=["GO:0009056"]
    ),
    "GO:0022617" => P("GO:0022617", "extracellular matrix disassembly";
        def="Enzymatic breakdown of ECM",
        syn=["ECM degradation", "matrix degradation"],
        par=["GO:0030198"]
    ),
    "GO:0044257" => P("GO:0044257", "cellular protein catabolic process";
        def="Breakdown of cellular proteins",
        par=["GO:0030163"]
    ),
    "GO:0006508" => P("GO:0006508", "proteolysis";
        def="Hydrolysis of peptide bonds",
        syn=["protein degradation"],
        par=["GO:0030163"]
    ),

    # Hydrolytic degradation
    "GO:0016787" => P("GO:0016787", "hydrolase activity";
        def="Catalysis of hydrolysis reactions",
        par=["GO:0003824"]  # catalytic activity
    ),
    "GO:0004252" => P("GO:0004252", "serine-type endopeptidase activity";
        def="Serine protease activity",
        par=["GO:0006508"]
    ),
    "GO:0008237" => P("GO:0008237", "metallopeptidase activity";
        def="Metalloprotease activity",
        syn=["MMP activity"],
        par=["GO:0006508"]
    ),

    # Phagocytic degradation
    "GO:0006909" => P("GO:0006909", "phagocytosis";
        def="Engulfment and degradation by phagocytes",
        syn=["cellular uptake"],
        par=["GO:0002376"]
    ),
    "GO:0045087" => P("GO:0045087", "innate immune response";
        def="Non-specific immune clearance",
        par=["GO:0002376"]
    ),
    "GO:0006898" => P("GO:0006898", "receptor-mediated endocytosis";
        def="Uptake via receptor binding",
        par=["GO:0006897"]
    ),

    # Autophagy
    "GO:0006914" => P("GO:0006914", "autophagy";
        def="Self-degradation of cellular components",
        par=["GO:0009056"]
    ),
    "GO:0016236" => P("GO:0016236", "macroautophagy";
        def="Bulk degradation via autophagosome",
        par=["GO:0006914"]
    ),
)

#=============================================================================
  SIGNALING PATHWAYS
  Key signaling cascades in tissue engineering
=============================================================================#

const SIGNALING = Dict{String,OBOTerm}(
    # Mechanotransduction
    "GO:0050982" => P("GO:0050982", "detection of mechanical stimulus";
        def="Sensing of mechanical forces",
        syn=["mechanosensing"],
        par=["GO:0007600"]
    ),
    "GO:0071260" => P("GO:0071260", "cellular response to mechanical stimulus";
        def="Cell response to mechanical force",
        syn=["mechanotransduction"],
        par=["GO:0050982"]
    ),
    "GO:0034405" => P("GO:0034405", "response to fluid shear stress";
        def="Response to flow-induced forces",
        par=["GO:0071260"]
    ),

    # Growth factor signaling
    "GO:0008083" => P("GO:0008083", "growth factor activity";
        def="Signaling via growth factors",
        par=["GO:0007167"]  # receptor signaling
    ),
    "GO:0030510" => P("GO:0030510", "regulation of BMP signaling pathway";
        def="Modulation of BMP signaling",
        syn=["BMP pathway"],
        par=["GO:0008083"]
    ),
    "GO:0038095" => P("GO:0038095", "Fc-epsilon receptor signaling pathway";
        def="Signaling via Fc receptor",
        par=["GO:0007167"]
    ),

    # Wnt signaling
    "GO:0016055" => P("GO:0016055", "Wnt signaling pathway";
        def="Signal transduction via Wnt proteins",
        syn=["Wnt pathway"],
        par=["GO:0007167"]
    ),
    "GO:0090263" => P("GO:0090263", "positive regulation of canonical Wnt signaling pathway";
        def="Activation of canonical Wnt",
        par=["GO:0016055"]
    ),
    "GO:0060070" => P("GO:0060070", "canonical Wnt signaling pathway";
        def="Wnt signaling via beta-catenin",
        par=["GO:0016055"]
    ),

    # BMP signaling
    "GO:0030509" => P("GO:0030509", "BMP signaling pathway";
        def="Signal transduction via bone morphogenetic proteins",
        syn=["BMP pathway"],
        par=["GO:0007167"]
    ),
    "GO:0030501" => P("GO:0030501", "positive regulation of bone mineralization";
        def="Activation of bone mineralization",
        par=["GO:0030282"]
    ),

    # Notch signaling
    "GO:0007219" => P("GO:0007219", "Notch signaling pathway";
        def="Signal transduction via Notch receptors",
        syn=["Notch pathway"],
        par=["GO:0007167"]
    ),
    "GO:0008593" => P("GO:0008593", "regulation of Notch signaling pathway";
        def="Modulation of Notch signaling",
        par=["GO:0007219"]
    ),

    # TGF-beta signaling
    "GO:0007179" => P("GO:0007179", "transforming growth factor beta receptor signaling pathway";
        def="Signaling via TGF-beta receptors",
        syn=["TGF-beta pathway"],
        par=["GO:0007167"]
    ),
    "GO:0060389" => P("GO:0060389", "pathway-restricted SMAD protein phosphorylation";
        def="SMAD activation by TGF-beta",
        par=["GO:0007179"]
    ),

    # MAPK signaling
    "GO:0000165" => P("GO:0000165", "MAPK cascade";
        def="Signal transduction via MAP kinases",
        syn=["MAPK pathway", "ERK pathway"],
        par=["GO:0007167"]
    ),
    "GO:0043507" => P("GO:0043507", "positive regulation of JUN kinase activity";
        def="Activation of JNK pathway",
        par=["GO:0000165"]
    ),

    # Integrin signaling
    "GO:0007229" => P("GO:0007229", "integrin-mediated signaling pathway";
        def="Signal transduction via integrins",
        syn=["integrin signaling", "focal adhesion signaling"],
        par=["GO:0007167"]
    ),
    "GO:0034446" => P("GO:0034446", "substrate adhesion-dependent cell spreading";
        def="Cell spreading via integrin engagement",
        par=["GO:0007229"]
    ),
)

#=============================================================================
  COMBINED PROCESS LIBRARY
=============================================================================#

"""All biological processes organized by category."""
const PROCESSES = merge(
    CELL_BEHAVIOR,
    DIFFERENTIATION,
    TISSUE_FORMATION,
    ECM_PROCESSES,
    INFLAMMATORY_RESPONSE,
    IMMUNE_RESPONSE,
    WOUND_HEALING,
    DEGRADATION,
    SIGNALING
)

#=============================================================================
  TISSUE-PROCESS MAPPING
  Links tissue types to relevant processes
=============================================================================#

"""
Maps tissue types to relevant biological processes.

Format: tissue_name => [process_GO_IDs]
"""
const TISSUE_PROCESS_MAP = Dict{String,Vector{String}}(
    # Bone tissue
    "bone" => [
        "GO:0008283",  # cell proliferation
        "GO:0007155",  # cell adhesion
        "GO:0016477",  # cell migration
        "GO:0001649",  # osteoblast differentiation
        "GO:0001503",  # ossification
        "GO:0030282",  # bone mineralization
        "GO:0032964",  # collagen synthesis
        "GO:0030198",  # ECM organization
        "GO:0006954",  # inflammatory response
        "GO:0042060",  # wound healing
        "GO:0030509",  # BMP signaling
        "GO:0071260",  # mechanotransduction
        "GO:0001525",  # angiogenesis
    ],

    # Cartilage tissue
    "cartilage" => [
        "GO:0008283",  # cell proliferation
        "GO:0007155",  # cell adhesion
        "GO:0002062",  # chondrocyte differentiation
        "GO:0051216",  # cartilage development
        "GO:0032964",  # collagen synthesis
        "GO:0030198",  # ECM organization
        "GO:0006954",  # inflammatory response
        "GO:0042060",  # wound healing
        "GO:0007179",  # TGF-beta signaling
        "GO:0016055",  # Wnt signaling
    ],

    # Skin tissue
    "skin" => [
        "GO:0008283",  # cell proliferation
        "GO:0016477",  # cell migration
        "GO:0007155",  # cell adhesion
        "GO:0043588",  # skin development
        "GO:0030198",  # ECM organization
        "GO:0032964",  # collagen synthesis
        "GO:0042060",  # wound healing
        "GO:0007596",  # blood coagulation
        "GO:0006954",  # inflammatory response
        "GO:0048771",  # tissue remodeling
        "GO:0001525",  # angiogenesis
    ],

    # Vascular tissue
    "vascular" => [
        "GO:0008283",  # cell proliferation
        "GO:0016477",  # cell migration
        "GO:0001885",  # endothelial development
        "GO:0001525",  # angiogenesis
        "GO:0001570",  # vasculogenesis
        "GO:0007155",  # cell adhesion
        "GO:0030198",  # ECM organization
        "GO:0071260",  # mechanotransduction
        "GO:0034405",  # shear stress response
        "GO:0042060",  # wound healing
    ],

    # Neural tissue
    "neural" => [
        "GO:0008283",  # cell proliferation
        "GO:0016477",  # cell migration
        "GO:0030182",  # neuron differentiation
        "GO:0022008",  # neurogenesis
        "GO:0014012",  # axon regeneration
        "GO:0007155",  # cell adhesion
        "GO:0030198",  # ECM organization
        "GO:0007219",  # Notch signaling
        "GO:0006954",  # inflammatory response
        "GO:0042060",  # wound healing
    ],

    # Muscle tissue
    "muscle" => [
        "GO:0008283",  # cell proliferation
        "GO:0007155",  # cell adhesion
        "GO:0042692",  # muscle differentiation
        "GO:0007517",  # muscle development
        "GO:0030198",  # ECM organization
        "GO:0071260",  # mechanotransduction
        "GO:0001525",  # angiogenesis
        "GO:0042060",  # wound healing
        "GO:0006954",  # inflammatory response
    ],

    # Cardiac tissue
    "cardiac" => [
        "GO:0008283",  # cell proliferation
        "GO:0007155",  # cell adhesion
        "GO:0055008",  # cardiac morphogenesis
        "GO:0030198",  # ECM organization
        "GO:0071260",  # mechanotransduction
        "GO:0001525",  # angiogenesis
        "GO:0042060",  # wound healing
        "GO:0006954",  # inflammatory response
    ],

    # Tendon/ligament
    "tendon" => [
        "GO:0008283",  # cell proliferation
        "GO:0007155",  # cell adhesion
        "GO:0032964",  # collagen synthesis
        "GO:0030198",  # ECM organization
        "GO:0071260",  # mechanotransduction
        "GO:0042060",  # wound healing
        "GO:0048771",  # tissue remodeling
        "GO:0007179",  # TGF-beta signaling
    ],
)

#=============================================================================
  LOOKUP FUNCTIONS
=============================================================================#

"""
    get_process(id::String) -> Union{OBOTerm, Nothing}

Retrieve process by GO ID.

# Example
```julia
process = get_process("GO:0008283")
println(process.name)  # "cell population proliferation"
```
"""
get_process(id::String) = get(PROCESSES, id, nothing)

"""
    get_processes_by_category(category::Symbol) -> Dict{String,OBOTerm}

Get all processes in a category.

# Categories
- `:cell_behavior` - Cell proliferation, migration, adhesion, apoptosis
- `:differentiation` - Lineage-specific differentiation
- `:tissue_formation` - Tissue development and regeneration
- `:ecm` - ECM synthesis, organization, remodeling
- `:inflammation` - Inflammatory responses
- `:immune` - Immune cell responses
- `:wound_healing` - Wound healing phases
- `:degradation` - Scaffold and matrix degradation
- `:signaling` - Signaling pathways

# Example
```julia
cell_procs = get_processes_by_category(:cell_behavior)
for (id, proc) in cell_procs
    println("\$(proc.name): \$(proc.definition)")
end
```
"""
function get_processes_by_category(category::Symbol)
    if category == :cell_behavior
        CELL_BEHAVIOR
    elseif category == :differentiation
        DIFFERENTIATION
    elseif category == :tissue_formation
        TISSUE_FORMATION
    elseif category == :ecm
        ECM_PROCESSES
    elseif category == :inflammation
        INFLAMMATORY_RESPONSE
    elseif category == :immune
        IMMUNE_RESPONSE
    elseif category == :wound_healing
        WOUND_HEALING
    elseif category == :degradation
        DEGRADATION
    elseif category == :signaling
        SIGNALING
    else
        Dict{String,OBOTerm}()
    end
end

"""
    get_tissue_processes(tissue::String) -> Vector{OBOTerm}

Get all relevant processes for a tissue type.

# Arguments
- `tissue::String`: Tissue name (e.g., "bone", "cartilage", "skin")

# Returns
Vector of OBOTerm objects for relevant processes

# Example
```julia
bone_procs = get_tissue_processes("bone")
for proc in bone_procs
    println("\$(proc.id): \$(proc.name)")
end
```
"""
function get_tissue_processes(tissue::String)
    process_ids = get(TISSUE_PROCESS_MAP, tissue, String[])
    [get_process(id) for id in process_ids if !isnothing(get_process(id))]
end

"""
    get_process_tissues(process_id::String) -> Vector{String}

Find which tissues involve a given process.

# Arguments
- `process_id::String`: GO ID (e.g., "GO:0008283")

# Returns
Vector of tissue names where this process is relevant

# Example
```julia
tissues = get_process_tissues("GO:0001525")  # angiogenesis
println("Angiogenesis is relevant for: \$tissues")
```
"""
function get_process_tissues(process_id::String)
    tissues = String[]
    for (tissue, procs) in TISSUE_PROCESS_MAP
        if process_id in procs
            push!(tissues, tissue)
        end
    end
    tissues
end

end # module ProcessLibrary
