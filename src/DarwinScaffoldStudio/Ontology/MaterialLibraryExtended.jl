"""
    MaterialLibraryExtended

Extended material library with 50+ advanced biomaterials for next-generation scaffolds.

Categories:
- Composite materials (PCL/HA, collagen/HA, PLGA/TCP, silk/HA)
- Nanomaterials (graphene oxide, CNTs, nano-HA, Ag nanoparticles)
- Specialized hydrogels (Matrigel, GelMA variants, self-assembling peptides)
- Conducting polymers (PEDOT, polypyrrole, polyaniline)
- Shape memory polymers
- Decellularized ECM (organ-specific dECM)
- Natural materials (coral, nacre, eggshell)
- Ion-doped ceramics (Sr-HA, Zn-TCP, Mg-HA)

# Author: Dr. Demetrios Agourakis
# Date: 2025
"""
module MaterialLibraryExtended

using ..OBOFoundry: OBOTerm

export EXTENDED_MATERIALS, EXTENDED_BY_CLASS
export get_extended_material, list_extended_materials
export COMPOSITE_PROPERTIES, NANOMATERIAL_PROPERTIES
export get_extended_properties

# Helper
M(id, name; def="", syn=String[], par=String[]) = OBOTerm(id, name; definition=def, synonyms=syn, parents=par)

#=============================================================================
  COMPOSITE MATERIALS (12 terms)
=============================================================================#
const COMPOSITES = Dict{String,OBOTerm}(
    # Polymer-ceramic composites
    "DSS:00001" => M("DSS:00001", "PCL/hydroxyapatite composite";
        def="Polycaprolactone reinforced with hydroxyapatite particles, tunable mechanics and bioactivity",
        syn=["PCL/HA", "PCL-HA", "HA-PCL composite"],
        par=["CHEBI:53310", "CHEBI:52251"]), "DSS:00002" => M("DSS:00002", "collagen/hydroxyapatite composite";
        def="Collagen matrix with HA nanocrystals, mimics natural bone composition",
        syn=["Col/HA", "mineralized collagen", "collagen-HA"],
        par=["CHEBI:3815", "CHEBI:52251"]), "DSS:00003" => M("DSS:00003", "PLGA/tricalcium phosphate composite";
        def="PLGA matrix with TCP particles for bone regeneration, fully resorbable",
        syn=["PLGA/TCP", "PLGA-TCP", "TCP-PLGA scaffold"],
        par=["CHEBI:53426", "CHEBI:53480"]), "DSS:00004" => M("DSS:00004", "silk fibroin/hydroxyapatite composite";
        def="Silk protein matrix with HA for bone tissue engineering, excellent mechanical properties",
        syn=["silk/HA", "SF/HA", "HA-silk composite"],
        par=["CHEBI:58534", "CHEBI:52251"]), "DSS:00005" => M("DSS:00005", "chitosan/bioactive glass composite";
        def="Chitosan matrix with bioactive glass particles, antibacterial and osteoconductive",
        syn=["chitosan/BG", "CS/BG", "BG-chitosan"],
        par=["CHEBI:16737", "CHEBI:52254"]), "DSS:00006" => M("DSS:00006", "gelatin/β-tricalcium phosphate composite";
        def="Gelatin hydrogel reinforced with β-TCP, injectable bone substitute",
        syn=["gelatin/β-TCP", "Gel/TCP"],
        par=["CHEBI:28512", "CHEBI:53480"]),

    # Advanced composites
    "DSS:00007" => M("DSS:00007", "PLA/wollastonite composite";
        def="PLA reinforced with wollastonite (CaSiO3) bioceramics, improved bioactivity",
        syn=["PLA/WS", "PLA-wollastonite"],
        par=["CHEBI:53309"]), "DSS:00008" => M("DSS:00008", "alginate/gelatin composite";
        def="Interpenetrating network of alginate and gelatin, tunable degradation",
        syn=["Alg/Gel", "alginate-gelatin IPN"],
        par=["CHEBI:52747", "CHEBI:28512"]), "DSS:00009" => M("DSS:00009", "collagen/elastin composite";
        def="Composite mimicking vascular ECM, elastic and compliant",
        syn=["Col/Eln", "collagen-elastin scaffold"],
        par=["CHEBI:3815", "CHEBI:17632"]), "DSS:00010" => M("DSS:00010", "PCL/collagen composite";
        def="PCL fibers with collagen coating, combines mechanical strength with bioactivity",
        syn=["PCL/Col", "collagen-coated PCL"],
        par=["CHEBI:53310", "CHEBI:3815"]), "DSS:00011" => M("DSS:00011", "biphasic calcium phosphate/collagen composite";
        def="BCP particles in collagen matrix for osteochondral repair",
        syn=["BCP/Col", "BCP-collagen"],
        par=["CHEBI:53481", "CHEBI:3815"]), "DSS:00012" => M("DSS:00012", "hyaluronic acid/fibrin composite";
        def="HA-fibrin hybrid gel for cartilage and soft tissue regeneration",
        syn=["HA/Fib", "HA-fibrin gel"],
        par=["CHEBI:18154", "CHEBI:18237"]),
)

#=============================================================================
  NANOMATERIALS (10 terms)
=============================================================================#
const NANOMATERIALS = Dict{String,OBOTerm}(
    "DSS:00101" => M("DSS:00101", "graphene oxide";
        def="2D carbon nanomaterial with oxygen functional groups, enhances mechanical properties and conductivity",
        syn=["GO", "oxidized graphene", "graphite oxide"],
        par=["CHEBI:36973"]), "DSS:00102" => M("DSS:00102", "reduced graphene oxide";
        def="Graphene oxide with partial oxygen removal, improved electrical conductivity",
        syn=["rGO", "reduced GO"],
        par=["DSS:00101"]), "DSS:00103" => M("DSS:00103", "carbon nanotubes";
        def="Cylindrical carbon nanostructures, exceptional mechanical and electrical properties",
        syn=["CNT", "SWCNT", "MWCNT", "carbon nanotube"],
        par=["CHEBI:33416"]), "DSS:00104" => M("DSS:00104", "multi-walled carbon nanotubes";
        def="Concentric graphene cylinders, reinforcement for polymer scaffolds",
        syn=["MWCNT", "multi-wall CNT"],
        par=["DSS:00103"]), "DSS:00105" => M("DSS:00105", "nano-hydroxyapatite";
        def="Hydroxyapatite nanoparticles (<100nm), enhanced bioactivity and osteoconductivity",
        syn=["nHA", "nano-HA", "nanocrystalline HA"],
        par=["CHEBI:52251"]), "DSS:00106" => M("DSS:00106", "silver nanoparticles";
        def="Metallic silver nanoparticles, antimicrobial agent for scaffolds",
        syn=["AgNP", "Ag NP", "nano-silver"],
        par=["CHEBI:30512"]), "DSS:00107" => M("DSS:00107", "gold nanoparticles";
        def="Colloidal gold nanoparticles for drug delivery and photothermal therapy",
        syn=["AuNP", "Au NP", "nano-gold"],
        par=["CHEBI:28694"]), "DSS:00108" => M("DSS:00108", "mesoporous silica nanoparticles";
        def="Ordered porous silica nanoparticles for drug loading and delivery",
        syn=["MSN", "MCM-41", "SBA-15"],
        par=["CHEBI:30563"]), "DSS:00109" => M("DSS:00109", "zinc oxide nanoparticles";
        def="ZnO nanoparticles with antimicrobial and wound healing properties",
        syn=["ZnO NP", "nano-ZnO"],
        par=["CHEBI:36560"]), "DSS:00110" => M("DSS:00110", "magnetic iron oxide nanoparticles";
        def="Superparamagnetic Fe3O4 or γ-Fe2O3 nanoparticles for magnetic field guidance",
        syn=["SPION", "magnetite NP", "maghemite NP"],
        par=["CHEBI:50819"]),
)

#=============================================================================
  SPECIALIZED HYDROGELS (12 terms)
=============================================================================#
const SPECIALIZED_HYDROGELS = Dict{String,OBOTerm}(
    "DSS:00201" => M("DSS:00201", "Matrigel";
        def="ECM extract from Engelbreth-Holm-Swarm mouse sarcoma, rich in laminin and collagen IV",
        syn=["basement membrane matrix", "BMM"],
        par=["CHEBI:36080"]), "DSS:00202" => M("DSS:00202", "gelatin methacrylate";
        def="Methacrylated gelatin, photocrosslinkable hydrogel with tunable stiffness",
        syn=["GelMA", "methacrylated gelatin", "GelMA hydrogel"],
        par=["CHEBI:28512"]), "DSS:00203" => M("DSS:00203", "gelatin methacryloyl";
        def="Alternative nomenclature for GelMA, UV-crosslinkable gelatin derivative",
        syn=["GelMOD", "methacryloyl gelatin"],
        par=["DSS:00202"]), "DSS:00204" => M("DSS:00204", "RADA16-I peptide";
        def="Self-assembling peptide (RADARADARADARADA), forms nanofiber hydrogel at physiological pH",
        syn=["RADA16", "PuraMatrix", "SAP"],
        par=["CHEBI:16670"]), "DSS:00205" => M("DSS:00205", "RADA16-II peptide";
        def="Self-assembling peptide variant with inverted sequence",
        syn=["RADA16-2"],
        par=["DSS:00204"]), "DSS:00206" => M("DSS:00206", "MAX8 peptide";
        def="Self-assembling β-hairpin peptide (VKVKVKVKVDPPTKVKVKVKV-NH2), shear-thinning hydrogel",
        syn=["MAX8 SAP"],
        par=["CHEBI:16670"]), "DSS:00207" => M("DSS:00207", "FEFEFKFK peptide";
        def="Self-assembling amphiphilic peptide forming nanofibers",
        syn=["Fmoc-FF peptide"],
        par=["CHEBI:16670"]), "DSS:00208" => M("DSS:00208", "hyaluronic acid methacrylate";
        def="Methacrylated hyaluronic acid, photocrosslinkable for cartilage engineering",
        syn=["HAMA", "MeHA", "methacrylated HA"],
        par=["CHEBI:18154"]), "DSS:00209" => M("DSS:00209", "tyramine-modified hyaluronic acid";
        def="HA with tyramine groups, enzymatically crosslinkable via HRP/H2O2",
        syn=["HA-Tyr", "tyramine-HA"],
        par=["CHEBI:18154"]), "DSS:00210" => M("DSS:00210", "poly(N-isopropylacrylamide-co-acrylic acid)";
        def="Thermoresponsive copolymer with pH sensitivity, dual-responsive hydrogel",
        syn=["P(NIPAAm-co-AAc)", "pNIPAAm-AAc"],
        par=["CHEBI:53443"]), "DSS:00211" => M("DSS:00211", "oxidized alginate";
        def="Alginate with aldehyde groups via periodate oxidation, forms Schiff base crosslinks",
        syn=["ADA", "alginate dialdehyde"],
        par=["CHEBI:52747"]), "DSS:00212" => M("DSS:00212", "PEG-fibrinogen hydrogel";
        def="PEG-fibrinogen conjugate forming protease-sensitive hydrogel",
        syn=["PEG-Fb", "PEGylated fibrinogen"],
        par=["CHEBI:46793"]),
)

#=============================================================================
  CONDUCTING POLYMERS (6 terms)
=============================================================================#
const CONDUCTING_POLYMERS = Dict{String,OBOTerm}(
    "DSS:00301" => M("DSS:00301", "poly(3,4-ethylenedioxythiophene)";
        def="Conducting polymer with high conductivity and stability, neural and cardiac applications",
        syn=["PEDOT", "PEDT"],
        par=["CHEBI:36080"]), "DSS:00302" => M("DSS:00302", "PEDOT:PSS";
        def="PEDOT doped with poly(styrene sulfonate), water-dispersible conducting polymer",
        syn=["PEDOT-PSS", "poly(3,4-ethylenedioxythiophene):polystyrene sulfonate"],
        par=["DSS:00301"]), "DSS:00303" => M("DSS:00303", "polypyrrole";
        def="Conducting polymer for electrical stimulation of cells, biocompatible",
        syn=["PPy", "PPY"],
        par=["CHEBI:36080"]), "DSS:00304" => M("DSS:00304", "polyaniline";
        def="Conducting polymer with pH-dependent conductivity, neural tissue engineering",
        syn=["PANI", "PANi"],
        par=["CHEBI:36080"]), "DSS:00305" => M("DSS:00305", "polythiophene";
        def="Conducting polymer with tunable electronic properties",
        syn=["PT", "PTh"],
        par=["CHEBI:36080"]), "DSS:00306" => M("DSS:00306", "poly(3-hexylthiophene)";
        def="Regioregular conducting polymer with improved processability",
        syn=["P3HT", "RR-P3HT"],
        par=["DSS:00305"]),
)

#=============================================================================
  SHAPE MEMORY POLYMERS (5 terms)
=============================================================================#
const SHAPE_MEMORY_POLYMERS = Dict{String,OBOTerm}(
    "DSS:00401" => M("DSS:00401", "shape memory polyurethane";
        def="Polyurethane with shape memory effect, minimally invasive deployment",
        syn=["SMPU", "SMP-PU"],
        par=["CHEBI:53437"]), "DSS:00402" => M("DSS:00402", "shape memory poly(ε-caprolactone)";
        def="PCL with shape memory properties, biodegradable and thermally-triggered",
        syn=["SM-PCL", "SMP-PCL"],
        par=["CHEBI:53310"]), "DSS:00403" => M("DSS:00403", "shape memory poly(lactic acid)";
        def="PLA-based shape memory polymer for self-expanding scaffolds",
        syn=["SM-PLA", "SMP-PLA"],
        par=["CHEBI:53309"]), "DSS:00404" => M("DSS:00404", "thiol-acrylate shape memory polymer";
        def="Photopolymerized thiol-ene network with shape memory, tunable Ttrans",
        syn=["thiol-ene SMP"],
        par=["CHEBI:36080"]), "DSS:00405" => M("DSS:00405", "poly(cyclooctene) shape memory polymer";
        def="Crosslinked poly(cyclooctene) with excellent shape memory and biocompatibility",
        syn=["PCO-SMP"],
        par=["CHEBI:36080"]),
)

#=============================================================================
  DECELLULARIZED ECM (8 terms)
=============================================================================#
const DECELLULARIZED_ECM = Dict{String,OBOTerm}(
    "DSS:00501" => M("DSS:00501", "decellularized dermis";
        def="Acellular dermal matrix preserving native ECM architecture, skin grafts",
        syn=["dECM-dermis", "ADM", "acellular dermis"],
        par=["UBERON:0002067"]), "DSS:00502" => M("DSS:00502", "decellularized heart tissue";
        def="Cardiac ECM with preserved vascular architecture for heart tissue engineering",
        syn=["dECM-heart", "decellularized myocardium"],
        par=["UBERON:0000948"]), "DSS:00503" => M("DSS:00503", "decellularized liver tissue";
        def="Hepatic ECM with microarchitecture for liver regeneration",
        syn=["dECM-liver", "decellularized hepatic tissue"],
        par=["UBERON:0002107"]), "DSS:00504" => M("DSS:00504", "decellularized lung tissue";
        def="Pulmonary ECM preserving alveolar and vascular structures",
        syn=["dECM-lung", "decellularized pulmonary tissue"],
        par=["UBERON:0002048"]), "DSS:00505" => M("DSS:00505", "decellularized bone matrix";
        def="Demineralized and decellularized bone ECM rich in collagen I and growth factors",
        syn=["dECM-bone", "DBM", "demineralized bone matrix"],
        par=["UBERON:0002481"]), "DSS:00506" => M("DSS:00506", "decellularized cartilage matrix";
        def="Cartilage ECM rich in collagen II and glycosaminoglycans",
        syn=["dECM-cartilage", "DAC", "decellularized articular cartilage"],
        par=["UBERON:0002418"]), "DSS:00507" => M("DSS:00507", "decellularized small intestinal submucosa";
        def="SIS-derived ECM scaffold, FDA-approved for various tissues",
        syn=["SIS", "dECM-SIS", "intestinal submucosa"],
        par=["UBERON:0001243"]), "DSS:00508" => M("DSS:00508", "decellularized adipose tissue";
        def="Adipose-derived ECM for soft tissue regeneration",
        syn=["dECM-adipose", "DAT", "decellularized fat"],
        par=["UBERON:0001013"]),
)

#=============================================================================
  NATURAL MATERIALS (6 terms)
=============================================================================#
const NATURAL_MATERIALS = Dict{String,OBOTerm}(
    "DSS:00601" => M("DSS:00601", "coral-derived hydroxyapatite";
        def="Natural coral (CaCO3) converted to HA via hydrothermal exchange, porous structure",
        syn=["coralline HA", "coral HA", "Biocoral"],
        par=["CHEBI:52251"]), "DSS:00602" => M("DSS:00602", "nacre";
        def="Mother-of-pearl from mollusks, layered aragonite (CaCO3) with organic matrix, osteogenic",
        syn=["mother of pearl", "aragonite nacre"],
        par=["CHEBI:3311"]), "DSS:00603" => M("DSS:00603", "eggshell membrane";
        def="Fibrous membrane from eggshell, rich in collagen and glycosaminoglycans",
        syn=["ESM", "avian eggshell membrane"],
        par=["CHEBI:36080"]), "DSS:00604" => M("DSS:00604", "cuttlebone-derived hydroxyapatite";
        def="Porous HA from cuttlefish bone with unique architecture",
        syn=["cuttlebone HA", "cuttlefish bone"],
        par=["CHEBI:52251"]), "DSS:00605" => M("DSS:00605", "bovine bone-derived hydroxyapatite";
        def="Xenograft HA from bovine bone, heat-treated to remove organics",
        syn=["BioOss", "bovine HA", "xenograft bone"],
        par=["CHEBI:52251"]), "DSS:00606" => M("DSS:00606", "wood-derived nanocellulose";
        def="Bacterial or plant-derived nanocellulose with high surface area",
        syn=["NFC", "nanofibrillated cellulose", "cellulose nanofiber"],
        par=["CHEBI:28815"]),
)

#=============================================================================
  ION-DOPED CERAMICS (8 terms)
=============================================================================#
const ION_DOPED_CERAMICS = Dict{String,OBOTerm}(
    "DSS:00701" => M("DSS:00701", "strontium-substituted hydroxyapatite";
        def="HA with Sr2+ substitution for Ca2+, enhanced osteogenesis and reduced osteoclastogenesis",
        syn=["Sr-HA", "strontium hydroxyapatite", "SrHA"],
        par=["CHEBI:52251"]), "DSS:00702" => M("DSS:00702", "magnesium-substituted hydroxyapatite";
        def="HA with Mg2+ substitution, accelerated resorption and bone remodeling",
        syn=["Mg-HA", "magnesium hydroxyapatite"],
        par=["CHEBI:52251"]), "DSS:00703" => M("DSS:00703", "zinc-substituted tricalcium phosphate";
        def="TCP with Zn2+ doping, antibacterial and osteogenic properties",
        syn=["Zn-TCP", "zinc TCP"],
        par=["CHEBI:53480"]), "DSS:00704" => M("DSS:00704", "silicon-substituted hydroxyapatite";
        def="HA with Si4+ substitution for PO43-, improved bioactivity and bone formation",
        syn=["Si-HA", "silicon hydroxyapatite", "SiHA"],
        par=["CHEBI:52251"]), "DSS:00705" => M("DSS:00705", "silver-doped hydroxyapatite";
        def="HA with Ag+ ions, antimicrobial properties for infection prevention",
        syn=["Ag-HA", "silver hydroxyapatite"],
        par=["CHEBI:52251"]), "DSS:00706" => M("DSS:00706", "copper-doped bioactive glass";
        def="Bioactive glass with Cu2+ ions, angiogenic and antibacterial",
        syn=["Cu-BG", "copper bioactive glass"],
        par=["CHEBI:52254"]), "DSS:00707" => M("DSS:00707", "cerium-doped bioactive glass";
        def="Bioactive glass with Ce3+/Ce4+ ions, antioxidant and anti-inflammatory",
        syn=["Ce-BG", "cerium bioactive glass"],
        par=["CHEBI:52254"]), "DSS:00708" => M("DSS:00708", "lithium-substituted wollastonite";
        def="Wollastonite (CaSiO3) with Li+ substitution, enhanced bioactivity",
        syn=["Li-WS", "lithium wollastonite"],
        par=["CHEBI:37586"]),
)

#=============================================================================
  COMBINED DATABASE
=============================================================================#

"""All 57 extended materials combined."""
const EXTENDED_MATERIALS = merge(
    COMPOSITES, NANOMATERIALS, SPECIALIZED_HYDROGELS,
    CONDUCTING_POLYMERS, SHAPE_MEMORY_POLYMERS,
    DECELLULARIZED_ECM, NATURAL_MATERIALS, ION_DOPED_CERAMICS
)

"""Extended materials organized by class."""
const EXTENDED_BY_CLASS = Dict{Symbol,Dict{String,OBOTerm}}(
    :composites => COMPOSITES,
    :nanomaterials => NANOMATERIALS,
    :specialized_hydrogels => SPECIALIZED_HYDROGELS,
    :conducting_polymers => CONDUCTING_POLYMERS,
    :shape_memory_polymers => SHAPE_MEMORY_POLYMERS,
    :decellularized_ecm => DECELLULARIZED_ECM,
    :natural_materials => NATURAL_MATERIALS,
    :ion_doped_ceramics => ION_DOPED_CERAMICS,
)

#=============================================================================
  MATERIAL PROPERTIES DATABASE
=============================================================================#

"""Composite material properties."""
const COMPOSITE_PROPERTIES = Dict{String,NamedTuple}(
    "DSS:00001" => (name="PCL/HA", elastic_modulus_mpa=1200, tensile_strength_mpa=35,
        ha_content_percent=20, degradation_months=30, bioactivity="high"),
    "DSS:00002" => (name="Col/HA", elastic_modulus_mpa=50, compressive_strength_mpa=5,
        ha_content_percent=70, mimics_bone=true, enzymatic_degradation=true),
    "DSS:00003" => (name="PLGA/TCP", elastic_modulus_mpa=2500, tensile_strength_mpa=50,
        tcp_content_percent=30, degradation_months=8, fully_resorbable=true),
    "DSS:00004" => (name="Silk/HA", elastic_modulus_mpa=800, tensile_strength_mpa=45,
        ha_content_percent=25, slow_degradation=true, high_strength=true),
    "DSS:00005" => (name="Chitosan/BG", elastic_modulus_mpa=150, compressive_strength_mpa=8,
        bg_content_percent=15, antibacterial=true, osteoconductive=true),
)

"""Nanomaterial properties."""
const NANOMATERIAL_PROPERTIES = Dict{String,NamedTuple}(
    "DSS:00101" => (name="GO", lateral_size_nm=500, thickness_nm=1.2,
        oxygen_content_percent=45, electrical_conductivity_sm=1e-3, enhances_mechanics=true),
    "DSS:00102" => (name="rGO", lateral_size_nm=500, thickness_nm=1.0,
        oxygen_content_percent=10, electrical_conductivity_sm=1e2, highly_conductive=true),
    "DSS:00103" => (name="CNT", diameter_nm=20, length_um=5,
        tensile_strength_gpa=50, elastic_modulus_gpa=1000, electrical=true),
    "DSS:00105" => (name="nHA", particle_size_nm=50, specific_surface_m2g=100,
        ca_p_ratio=1.67, enhanced_bioactivity=true, osteogenic=true),
    "DSS:00106" => (name="AgNP", particle_size_nm=20, antibacterial=true,
        mic_ecoli_ugml=5, cytotoxicity_threshold_ugml=10),
)

"""Hydrogel properties."""
const HYDROGEL_PROPERTIES = Dict{String,NamedTuple}(
    "DSS:00201" => (name="Matrigel", elastic_modulus_pa=400, gelation_temp_c=22,
        ecm_like=true, laminin_rich=true, tumor_derived=true),
    "DSS:00202" => (name="GelMA", elastic_modulus_kpa=5, gelation="photo",
        tunable_stiffness=true, degradation_enzymatic=true, crosslink_density_tunable=true),
    "DSS:00204" => (name="RADA16", fiber_diameter_nm=10, elastic_modulus_pa=200,
        self_assembling=true, ph_responsive=true, injectable=true),
    "DSS:00208" => (name="HAMA", elastic_modulus_kpa=10, gelation="photo",
        cartilage_application=true, cd44_binding=true),
)

"""Conducting polymer properties."""
const CONDUCTING_POLYMER_PROPERTIES = Dict{String,NamedTuple}(
    "DSS:00301" => (name="PEDOT", electrical_conductivity_sm=300,
        stability_high=true, optical_transparency_moderate=true),
    "DSS:00302" => (name="PEDOT:PSS", electrical_conductivity_sm=1000,
        water_dispersible=true, processability_easy=true),
    "DSS:00303" => (name="PPy", electrical_conductivity_sm=50,
        biocompatible=true, cell_stimulation=true),
    "DSS:00304" => (name="PANI", electrical_conductivity_sm=10,
        ph_sensitive=true, doping_tunable=true),
)

"""Shape memory polymer properties."""
const SMP_PROPERTIES = Dict{String,NamedTuple}(
    "DSS:00401" => (name="SMPU", transition_temp_c=37, shape_recovery_percent=95,
        elastic_modulus_mpa=200, biocompatible=true),
    "DSS:00402" => (name="SM-PCL", transition_temp_c=60, shape_recovery_percent=98,
        biodegradable=true, degradation_months=24),
    "DSS:00403" => (name="SM-PLA", transition_temp_c=58, shape_recovery_percent=90,
        biodegradable=true, self_expanding=true),
)

"""Decellularized ECM properties."""
const DECM_PROPERTIES = Dict{String,NamedTuple}(
    "DSS:00501" => (name="dECM-dermis", collagen_content_percent=80,
        maintains_architecture=true, immunogenicity_low=true),
    "DSS:00502" => (name="dECM-heart", vascular_channels_preserved=true,
        cardiac_specific_proteins=true, anisotropic=true),
    "DSS:00505" => (name="dECM-bone", growth_factors_preserved=true,
        osteoinductive=true, osteoconductive=true),
    "DSS:00507" => (name="SIS", tensile_strength_mpa=15,
        fda_approved=true, versatile=true),
)

"""Ion-doped ceramic properties."""
const ION_DOPED_PROPERTIES = Dict{String,NamedTuple}(
    "DSS:00701" => (name="Sr-HA", strontium_wt_percent=5,
        osteogenic_enhanced=true, anti_osteoclast=true),
    "DSS:00702" => (name="Mg-HA", magnesium_wt_percent=3,
        faster_resorption=true, bone_remodeling=true),
    "DSS:00703" => (name="Zn-TCP", zinc_wt_percent=2,
        antibacterial=true, osteogenic=true),
    "DSS:00704" => (name="Si-HA", silicon_wt_percent=1.5,
        bioactivity_enhanced=true, bone_formation_rate_high=true),
    "DSS:00705" => (name="Ag-HA", silver_wt_percent=1,
        antimicrobial=true, prevents_infection=true),
)

"""Natural material properties."""
const NATURAL_PROPERTIES = Dict{String,NamedTuple}(
    "DSS:00601" => (name="Coral-HA", porosity_percent=60,
        interconnected_pores=true, natural_architecture=true),
    "DSS:00602" => (name="Nacre", compressive_strength_mpa=540,
        layered_structure=true, osteogenic_factors=true),
    "DSS:00603" => (name="ESM", collagen_rich=true,
        wound_healing=true, anti_inflammatory=true),
)

#=============================================================================
  ALL PROPERTIES COMBINED
=============================================================================#

"""All extended material properties combined."""
const EXTENDED_PROPERTIES = merge(
    COMPOSITE_PROPERTIES, NANOMATERIAL_PROPERTIES,
    HYDROGEL_PROPERTIES, CONDUCTING_POLYMER_PROPERTIES,
    SMP_PROPERTIES, DECM_PROPERTIES,
    ION_DOPED_PROPERTIES, NATURAL_PROPERTIES
)

#=============================================================================
  LOOKUP FUNCTIONS
=============================================================================#

"""Get extended material by ID."""
get_extended_material(id::String) = get(EXTENDED_MATERIALS, id, nothing)

"""List extended materials by class."""
function list_extended_materials(mat_class::Symbol=:all)
    mat_class == :all ? collect(values(EXTENDED_MATERIALS)) :
    haskey(EXTENDED_BY_CLASS, mat_class) ? collect(values(EXTENDED_BY_CLASS[mat_class])) : OBOTerm[]
end

"""Get extended material properties."""
get_extended_properties(id::String) = get(EXTENDED_PROPERTIES, id, nothing)

"""Search extended materials by keyword."""
function search_extended_materials(keyword::String)
    keyword_lower = lowercase(keyword)
    matches = OBOTerm[]
    for (id, term) in EXTENDED_MATERIALS
        if occursin(keyword_lower, lowercase(term.name)) ||
           any(syn -> occursin(keyword_lower, lowercase(syn)), term.synonyms) ||
           occursin(keyword_lower, lowercase(term.definition))
            push!(matches, term)
        end
    end
    matches
end

"""Get all composites containing a specific base material."""
function get_composites_with_material(base_material_id::String)
    composites = OBOTerm[]
    for (id, term) in COMPOSITES
        if base_material_id in term.parents
            push!(composites, term)
        end
    end
    composites
end

"""Get materials by property criterion."""
function filter_by_property(property::Symbol, min_value::Real)
    matching = String[]
    for (id, props) in EXTENDED_PROPERTIES
        if haskey(props, property) && props[property] >= min_value
            push!(matching, id)
        end
    end
    [get_extended_material(id) for id in matching]
end

"""Generate material summary report."""
function material_summary()
    println("Darwin Scaffold Studio - Extended Material Library")
    println("="^60)
    println("Composites:              $(length(COMPOSITES)) materials")
    println("Nanomaterials:           $(length(NANOMATERIALS)) materials")
    println("Specialized Hydrogels:   $(length(SPECIALIZED_HYDROGELS)) materials")
    println("Conducting Polymers:     $(length(CONDUCTING_POLYMERS)) materials")
    println("Shape Memory Polymers:   $(length(SHAPE_MEMORY_POLYMERS)) materials")
    println("Decellularized ECM:      $(length(DECELLULARIZED_ECM)) materials")
    println("Natural Materials:       $(length(NATURAL_MATERIALS)) materials")
    println("Ion-Doped Ceramics:      $(length(ION_DOPED_CERAMICS)) materials")
    println("="^60)
    println("Total Extended Materials: $(length(EXTENDED_MATERIALS))")
    println("Total with Properties:    $(length(EXTENDED_PROPERTIES))")
end

end # module
