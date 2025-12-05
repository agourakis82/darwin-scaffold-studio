"""
    TissueLibraryExtended

Extended tissue library with 50+ specialized tissues not in TissueLibrary.jl.
Focuses on organ substructures, dental tissues, endocrine tissues, 
reproductive tissues, specialized connective tissues, and embryonic derivatives.

# Coverage
- Dental tissues (enamel, dentin, pulp, cementum, periodontium)
- Endocrine tissues (thyroid, adrenal, pituitary substructures)
- Reproductive tissues (endometrium, placenta, corpus luteum, follicles)
- Organ substructures (liver lobule, nephron components, lung alveoli)
- Specialized connective tissues (synovium, periosteum, perichondrium)
- Embryonic tissues and derivatives

# Author: Dr. Demetrios Agourakis
"""
module TissueLibraryExtended

using ..OBOFoundry: OBOTerm

export EXTENDED_TISSUES, DENTAL_TISSUES, ENDOCRINE_TISSUES, REPRODUCTIVE_TISSUES
export ORGAN_SUBSTRUCTURES, SPECIALIZED_CONNECTIVE, EMBRYONIC_TISSUES
export get_extended_tissue, list_extended_tissues, count_extended_tissues

# Helper to create terms quickly
T(id, name; def="", syn=String[], par=String[]) = OBOTerm(id, name; definition=def, synonyms=syn, parents=par)

#=============================================================================
  DENTAL TISSUES (10 terms)
=============================================================================#
const DENTAL_TISSUES = Dict{String,OBOTerm}(
    "UBERON:0001752" => T("UBERON:0001752", "dental enamel";
        def="Hypermineralized substance covering tooth crown, hardest tissue in body",
        syn=["enamel", "tooth enamel", "enamelum"],
        par=["UBERON:0001091"]), "UBERON:0001091" => T("UBERON:0001091", "dentin";
        def="Calcified tissue forming bulk of tooth, beneath enamel and cementum",
        syn=["dentine", "tooth dentin"],
        par=["UBERON:0002481"]), "UBERON:0001754" => T("UBERON:0001754", "dental pulp";
        def="Soft connective tissue in tooth center with nerves and blood vessels",
        syn=["pulp", "tooth pulp"],
        par=["UBERON:0002384"]), "UBERON:0001753" => T("UBERON:0001753", "cementum";
        def="Calcified tissue covering tooth root surface",
        syn=["dental cementum", "tooth cementum"],
        par=["UBERON:0002481"]), "UBERON:0002046" => T("UBERON:0002046", "periodontal ligament";
        def="Dense connective tissue attaching tooth to alveolar bone",
        syn=["PDL", "periodontal membrane", "desmodontium"],
        par=["UBERON:0000211"]), "UBERON:0001981" => T("UBERON:0001981", "gingiva";
        def="Oral mucosa covering alveolar bone and surrounding teeth",
        syn=["gum tissue", "gums"],
        par=["UBERON:0002097"]), "UBERON:0001688" => T("UBERON:0001688", "alveolar bone";
        def="Bone supporting and surrounding teeth in maxilla and mandible",
        syn=["alveolar process"],
        par=["UBERON:0002481"]), "UBERON:0035943" => T("UBERON:0035943", "dental papilla";
        def="Embryonic tissue giving rise to dentin and pulp",
        syn=["tooth papilla"],
        par=["UBERON:0000479"]), "UBERON:0005176" => T("UBERON:0005176", "enamel organ";
        def="Epithelial tissue producing tooth enamel during development",
        syn=["dental organ"],
        par=["UBERON:0000479"]), "UBERON:0001750" => T("UBERON:0001750", "odontoblast layer";
        def="Layer of dentin-producing cells at pulp-dentin interface",
        syn=["odontoblastic layer"],
        par=["UBERON:0001754"]),
)

#=============================================================================
  ENDOCRINE TISSUES (12 terms)
=============================================================================#
const ENDOCRINE_TISSUES = Dict{String,OBOTerm}(
    "UBERON:0002046" => T("UBERON:0002046", "thyroid gland";
        def="Bilobed endocrine gland producing thyroid hormones T3, T4, and calcitonin",
        syn=["thyroid"],
        par=["UBERON:0000062"]), "UBERON:0001118" => T("UBERON:0001118", "thyroid lobe";
        def="One of two lobes comprising thyroid gland",
        syn=["lobe of thyroid"],
        par=["UBERON:0002046"]), "UBERON:0001174" => T("UBERON:0001174", "thyroid follicle";
        def="Functional unit of thyroid containing colloid and follicular cells",
        syn=["follicle of thyroid"],
        par=["UBERON:0002046"]), "UBERON:0002369" => T("UBERON:0002369", "adrenal gland";
        def="Endocrine gland producing steroids, catecholamines, and stress hormones",
        syn=["suprarenal gland"],
        par=["UBERON:0000062"]), "UBERON:0001235" => T("UBERON:0001235", "adrenal cortex";
        def="Outer steroid-producing layer of adrenal gland",
        syn=["cortex of adrenal gland"],
        par=["UBERON:0002369"]), "UBERON:0001236" => T("UBERON:0001236", "adrenal medulla";
        def="Inner catecholamine-producing layer of adrenal gland",
        syn=["medulla of adrenal gland"],
        par=["UBERON:0002369"]), "UBERON:0001913" => T("UBERON:0001913", "zona glomerulosa";
        def="Outermost adrenal cortex layer producing mineralocorticoids",
        syn=["glomerular zone"],
        par=["UBERON:0001235"]), "UBERON:0001915" => T("UBERON:0001915", "zona fasciculata";
        def="Middle adrenal cortex layer producing glucocorticoids",
        syn=["fascicular zone"],
        par=["UBERON:0001235"]), "UBERON:0001914" => T("UBERON:0001914", "zona reticularis";
        def="Inner adrenal cortex layer producing androgens",
        syn=["reticular zone"],
        par=["UBERON:0001235"]), "UBERON:0000007" => T("UBERON:0000007", "pituitary gland";
        def="Master endocrine gland regulating other endocrine organs",
        syn=["hypophysis"],
        par=["UBERON:0000062"]), "UBERON:0002196" => T("UBERON:0002196", "adenohypophysis";
        def="Anterior pituitary, produces growth hormone, ACTH, TSH, LH, FSH, prolactin",
        syn=["anterior pituitary"],
        par=["UBERON:0000007"]), "UBERON:0002198" => T("UBERON:0002198", "neurohypophysis";
        def="Posterior pituitary, releases oxytocin and ADH",
        syn=["posterior pituitary"],
        par=["UBERON:0000007"]),
)

#=============================================================================
  REPRODUCTIVE TISSUES (12 terms)
=============================================================================#
const REPRODUCTIVE_TISSUES = Dict{String,OBOTerm}(
    "UBERON:0001295" => T("UBERON:0001295", "endometrium";
        def="Glandular mucous membrane lining uterine cavity, hormonally responsive",
        syn=["uterine lining"],
        par=["UBERON:0000995"]), "UBERON:0000453" => T("UBERON:0000453", "decidua";
        def="Modified endometrium during pregnancy",
        syn=["decidual tissue"],
        par=["UBERON:0001295"]), "UBERON:0001987" => T("UBERON:0001987", "placenta";
        def="Organ of metabolic exchange between fetus and mother",
        syn=["placental tissue"],
        par=["UBERON:0000062"]), "UBERON:0001293" => T("UBERON:0001293", "chorionic villi";
        def="Finger-like projections of placenta for nutrient/gas exchange",
        syn=["placental villi"],
        par=["UBERON:0001987"]), "UBERON:0002512" => T("UBERON:0002512", "corpus luteum";
        def="Transient endocrine gland from postovulatory follicle, secretes progesterone",
        syn=["ovarian corpus luteum"],
        par=["UBERON:0000992"]), "UBERON:0001305" => T("UBERON:0001305", "ovarian follicle";
        def="Structure containing developing oocyte and supporting cells",
        syn=["follicle"],
        par=["UBERON:0000992"]), "UBERON:0003981" => T("UBERON:0003981", "primordial follicle";
        def="Earliest stage of follicle development with single layer of granulosa cells",
        syn=["primordial ovarian follicle"],
        par=["UBERON:0001305"]), "UBERON:0001305" => T("UBERON:0001305", "Graafian follicle";
        def="Mature preovulatory follicle with antrum and cumulus oophorus",
        syn=["mature follicle", "tertiary follicle"],
        par=["UBERON:0001305"]), "UBERON:0002367" => T("UBERON:0002367", "prostate gland";
        def="Male accessory gland producing seminal fluid components",
        syn=["prostate"],
        par=["UBERON:0000062"]), "UBERON:0001339" => T("UBERON:0001339", "seminiferous tubule";
        def="Tubular structure in testis where spermatogenesis occurs",
        syn=["tubuli seminiferi"],
        par=["UBERON:0000473"]), "UBERON:0001323" => T("UBERON:0001323", "seminal vesicle";
        def="Paired glands producing fructose-rich seminal fluid",
        syn=["vesicular gland"],
        par=["UBERON:0000062"]), "UBERON:0001348" => T("UBERON:0001348", "fallopian tube";
        def="Paired tubes transporting ova from ovary to uterus",
        syn=["oviduct", "uterine tube"],
        par=["UBERON:0000062"]),
)

#=============================================================================
  ORGAN SUBSTRUCTURES (14 terms)
=============================================================================#
const ORGAN_SUBSTRUCTURES = Dict{String,OBOTerm}(
    # Liver
    "UBERON:0004647" => T("UBERON:0004647", "liver lobule";
        def="Hexagonal functional unit of liver centered on central vein",
        syn=["hepatic lobule"],
        par=["UBERON:0002107"]), "UBERON:0001282" => T("UBERON:0001282", "hepatic acinus";
        def="Diamond-shaped functional unit based on blood flow from portal triad",
        syn=["acinus of Rappaport"],
        par=["UBERON:0002107"]), "UBERON:0001281" => T("UBERON:0001281", "hepatic sinusoid";
        def="Specialized capillary between hepatocyte plates",
        syn=["liver sinusoid"],
        par=["UBERON:0001982"]), "UBERON:0001280" => T("UBERON:0001280", "portal triad";
        def="Unit containing portal vein, hepatic artery, and bile duct",
        syn=["portal area", "portal canal"],
        par=["UBERON:0002107"]),

    # Kidney
    "UBERON:0001285" => T("UBERON:0001285", "nephron";
        def="Functional unit of kidney for blood filtration and urine formation",
        syn=["renal tubule"],
        par=["UBERON:0002113"]), "UBERON:0001286" => T("UBERON:0001286", "renal glomerulus";
        def="Capillary tuft for blood filtration in Bowman's capsule",
        syn=["glomerulus"],
        par=["UBERON:0001285"]), "UBERON:0001231" => T("UBERON:0001231", "loop of Henle";
        def="U-shaped tubule creating osmotic gradient for water reabsorption",
        syn=["Henle's loop", "nephron loop"],
        par=["UBERON:0001285"]), "UBERON:0001232" => T("UBERON:0001232", "collecting duct";
        def="Tubule collecting urine from multiple nephrons",
        syn=["renal collecting duct"],
        par=["UBERON:0002113"]), "UBERON:0001229" => T("UBERON:0001229", "proximal tubule";
        def="First segment after glomerulus, major site of reabsorption",
        syn=["proximal convoluted tubule", "PCT"],
        par=["UBERON:0001285"]),

    # Lung
    "UBERON:0002299" => T("UBERON:0002299", "pulmonary alveolus";
        def="Microscopic air sac for gas exchange in lungs",
        syn=["alveolus", "air sac"],
        par=["UBERON:0002048"]), "UBERON:0002186" => T("UBERON:0002186", "bronchiole";
        def="Small airway without cartilage, leads to alveolar ducts",
        syn=["bronchiolus"],
        par=["UBERON:0002048"]), "UBERON:0004890" => T("UBERON:0004890", "respiratory bronchiole";
        def="Transitional airway with few alveoli in walls",
        syn=["bronchiolus respiratorius"],
        par=["UBERON:0002186"]),

    # Pancreas
    "UBERON:0000006" => T("UBERON:0000006", "islet of Langerhans";
        def="Endocrine cell clusters in pancreas producing insulin and glucagon",
        syn=["pancreatic islet", "islet"],
        par=["UBERON:0001264"]), "UBERON:0001150" => T("UBERON:0001150", "pancreatic acinus";
        def="Grape-like cluster of exocrine cells producing digestive enzymes",
        syn=["acinus of pancreas"],
        par=["UBERON:0001264"]),
)

#=============================================================================
  SPECIALIZED CONNECTIVE TISSUES (8 terms)
=============================================================================#
const SPECIALIZED_CONNECTIVE = Dict{String,OBOTerm}(
    "UBERON:0001215" => T("UBERON:0001215", "synovium";
        def="Specialized connective tissue lining joint cavities, produces synovial fluid",
        syn=["synovial membrane", "synovial tissue"],
        par=["UBERON:0002384"]), "UBERON:0002515" => T("UBERON:0002515", "synovial fluid";
        def="Viscous joint lubricant produced by synovium",
        syn=["synovia"],
        par=["UBERON:0001215"]), "UBERON:0002105" => T("UBERON:0002105", "periosteum";
        def="Dense fibrous membrane covering outer bone surface",
        syn=["bone periosteum"],
        par=["UBERON:0002481"]), "UBERON:0002106" => T("UBERON:0002106", "endosteum";
        def="Thin vascular membrane lining inner bone surface",
        syn=["bone endosteum"],
        par=["UBERON:0002481"]), "UBERON:0002262" => T("UBERON:0002262", "perichondrium";
        def="Dense connective tissue surrounding cartilage",
        syn=["cartilage perichondrium"],
        par=["UBERON:0002418"]), "UBERON:0001207" => T("UBERON:0001207", "perineurium";
        def="Connective tissue sheath surrounding nerve fascicles",
        syn=["nerve perineurium"],
        par=["UBERON:0001021"]), "UBERON:0001208" => T("UBERON:0001208", "epineurium";
        def="Outermost connective tissue layer of peripheral nerve",
        syn=["nerve epineurium"],
        par=["UBERON:0001021"]), "UBERON:0000025" => T("UBERON:0000025", "bursa";
        def="Fluid-filled sac reducing friction between moving tissues",
        syn=["synovial bursa"],
        par=["UBERON:0002384"]),
)

#=============================================================================
  EMBRYONIC TISSUES AND DERIVATIVES (6 terms)
=============================================================================#
const EMBRYONIC_TISSUES = Dict{String,OBOTerm}(
    "UBERON:0000925" => T("UBERON:0000925", "mesoderm";
        def="Middle germ layer giving rise to muscle, bone, blood, connective tissue",
        syn=["mesodermal tissue"],
        par=["UBERON:0000479"]), "UBERON:0000924" => T("UBERON:0000924", "ectoderm";
        def="Outer germ layer giving rise to skin, nervous system, sensory organs",
        syn=["ectodermal tissue"],
        par=["UBERON:0000479"]), "UBERON:0000926" => T("UBERON:0000926", "endoderm";
        def="Inner germ layer giving rise to digestive and respiratory epithelium",
        syn=["endodermal tissue"],
        par=["UBERON:0000479"]), "UBERON:0003104" => T("UBERON:0003104", "mesenchyme";
        def="Embryonic connective tissue from mesoderm, precursor of many tissues",
        syn=["mesenchymal tissue", "embryonic connective tissue"],
        par=["UBERON:0000925"]), "UBERON:0002342" => T("UBERON:0002342", "neural crest";
        def="Transient embryonic cells giving rise to peripheral neurons, glia, pigment",
        syn=["crista neuralis"],
        par=["UBERON:0000924"]), "UBERON:0002539" => T("UBERON:0002539", "notochord";
        def="Embryonic axial structure inducing neural tube, becomes nucleus pulposus",
        syn=["chorda dorsalis"],
        par=["UBERON:0000925"]),
)

#=============================================================================
  COMBINED DATABASE
=============================================================================#

"""All 62 extended tissues combined."""
const EXTENDED_TISSUES = merge(
    DENTAL_TISSUES,
    ENDOCRINE_TISSUES,
    REPRODUCTIVE_TISSUES,
    ORGAN_SUBSTRUCTURES,
    SPECIALIZED_CONNECTIVE,
    EMBRYONIC_TISSUES
)

#=============================================================================
  LOOKUP FUNCTIONS
=============================================================================#

"""Get extended tissue by UBERON ID."""
get_extended_tissue(id::String) = get(EXTENDED_TISSUES, id, nothing)

"""List tissues by category."""
function list_extended_tissues(category::Symbol=:all)
    if category == :all
        return collect(values(EXTENDED_TISSUES))
    elseif category == :dental
        return collect(values(DENTAL_TISSUES))
    elseif category == :endocrine
        return collect(values(ENDOCRINE_TISSUES))
    elseif category == :reproductive
        return collect(values(REPRODUCTIVE_TISSUES))
    elseif category == :organ_substructures
        return collect(values(ORGAN_SUBSTRUCTURES))
    elseif category == :specialized_connective
        return collect(values(SPECIALIZED_CONNECTIVE))
    elseif category == :embryonic
        return collect(values(EMBRYONIC_TISSUES))
    else
        return OBOTerm[]
    end
end

"""Get count of tissues by category."""
function count_extended_tissues()
    Dict(
        :dental => length(DENTAL_TISSUES),
        :endocrine => length(ENDOCRINE_TISSUES),
        :reproductive => length(REPRODUCTIVE_TISSUES),
        :organ_substructures => length(ORGAN_SUBSTRUCTURES),
        :specialized_connective => length(SPECIALIZED_CONNECTIVE),
        :embryonic => length(EMBRYONIC_TISSUES),
        :total => length(EXTENDED_TISSUES)
    )
end

end # module
