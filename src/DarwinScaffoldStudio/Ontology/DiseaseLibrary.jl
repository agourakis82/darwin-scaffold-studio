"""
    DiseaseLibrary

Comprehensive library of diseases and conditions treatable with tissue engineering scaffolds.

Covers:
- Bone disorders (fractures, defects, osteoporosis, osteonecrosis, tumors)
- Cartilage disorders (OA, RA, osteochondral defects, meniscus tears)
- Skin conditions (burns, ulcers, chronic wounds, epidermolysis bullosa)
- Cardiac conditions (MI, heart failure, valve diseases, arrhythmias)
- Vascular diseases (PAD, aneurysms, atherosclerosis, varicose veins)
- Neural disorders (SCI, peripheral nerve injury, Parkinson's, stroke)
- Dental conditions (periodontitis, tooth loss, alveolar bone loss)
- Organ failure (liver, kidney, pancreas conditions)

Uses real Disease Ontology (DOID) and NCI Thesaurus (NCIT) identifiers.

# References
- Disease Ontology: https://disease-ontology.org/
- NCI Thesaurus: https://ncithesaurus.nci.nih.gov/

# Author: Dr. Demetrios Agourakis
# Master's Thesis: Tissue Engineering Scaffold Optimization
"""
module DiseaseLibrary

using ..OBOFoundry: OBOTerm

export DISEASES, get_disease, DISEASE_TISSUE_MAP, get_target_tissues
export BONE_DISORDERS, CARTILAGE_DISORDERS, SKIN_CONDITIONS, CARDIAC_CONDITIONS
export VASCULAR_DISEASES, NEURAL_DISORDERS, DENTAL_CONDITIONS, ORGAN_FAILURE
export get_diseases_by_category, get_diseases_for_tissue, recommend_scaffold_for_disease

# Helper constructor
D(id, name; def="", syn=String[], par=String[]) =
    OBOTerm(id, name; definition=def, synonyms=syn, parents=par)

#=============================================================================
  BONE DISORDERS
=============================================================================#

const BONE_DISORDERS = Dict{String,OBOTerm}(
    # Fractures and defects
    "NCIT:C3043" => D("NCIT:C3043", "bone fracture";
        def="Break in the continuity of bone structure requiring regeneration",
        syn=["fracture", "broken bone"],
        par=["DOID:0080015"]
    ),
    "NCIT:C26808" => D("NCIT:C26808", "critical size bone defect";
        def="Bone defect that will not heal spontaneously without intervention, typically >2cm in long bones",
        syn=["critical size defect", "CSD", "non-union defect"],
        par=["NCIT:C3043"]
    ),
    "DOID:630" => D("DOID:630", "genetic bone disorder";
        def="Inherited disorder affecting bone structure or metabolism",
        syn=["hereditary bone disease"],
        par=["DOID:0080015"]
    ),
    "NCIT:C3298" => D("NCIT:C3298", "osteoporosis";
        def="Systemic skeletal disease characterized by low bone mass and microarchitectural deterioration, leading to increased fracture risk",
        syn=["porous bone disease", "brittle bone disease"],
        par=["DOID:11476"]
    ),
    "NCIT:C3239" => D("NCIT:C3239", "osteonecrosis";
        def="Death of bone tissue due to insufficient blood supply, often in femoral head",
        syn=["avascular necrosis", "AVN", "aseptic necrosis", "ischemic bone necrosis"],
        par=["DOID:10159"]
    ),

    # Bone tumors
    "NCIT:C9263" => D("NCIT:C9263", "osteosarcoma";
        def="Malignant bone tumor producing osteoid, most common primary bone cancer",
        syn=["osteogenic sarcoma"],
        par=["DOID:3347"]
    ),
    "DOID:184" => D("DOID:184", "bone cancer";
        def="Cancer originating in bone tissue",
        syn=["malignant bone tumor", "osseous cancer"],
        par=["DOID:162"]
    ),
    "NCIT:C3349" => D("NCIT:C3349", "Ewing sarcoma";
        def="Malignant round cell tumor of bone and soft tissue",
        syn=["Ewing's sarcoma"],
        par=["DOID:3369"]
    ),
    "NCIT:C2945" => D("NCIT:C2945", "chondrosarcoma";
        def="Malignant tumor of cartilage cells",
        syn=["cartilaginous tumor"],
        par=["DOID:3371"]
    ),

    # Metabolic bone diseases
    "DOID:10573" => D("DOID:10573", "osteomalacia";
        def="Softening of bones due to vitamin D deficiency or phosphate deficiency",
        syn=["adult rickets"],
        par=["DOID:0080015"]
    ),
    "DOID:10159" => D("DOID:10159", "osteitis";
        def="Inflammation of bone tissue",
        syn=["bone inflammation"],
        par=["DOID:0080015"]
    ),
    "NCIT:C26854" => D("NCIT:C26854", "Paget disease of bone";
        def="Chronic bone disorder with excessive breakdown and formation causing enlarged and misshapen bones",
        syn=["Paget's disease", "osteitis deformans"],
        par=["DOID:10911"]
    ),
    "NCIT:C34562" => D("NCIT:C34562", "osteomyelitis";
        def="Infection of bone, often requiring debridement and bone grafting",
        syn=["bone infection"],
        par=["DOID:10159"]
    ),

    # Congenital bone disorders
    "DOID:12347" => D("DOID:12347", "osteogenesis imperfecta";
        def="Genetic disorder of collagen causing brittle bones",
        syn=["brittle bone disease", "OI"],
        par=["DOID:630"]
    ),
    "NCIT:C84558" => D("NCIT:C84558", "craniofacial defect";
        def="Congenital or acquired defect of skull or facial bones",
        syn=["skull defect", "facial bone defect"],
        par=["NCIT:C3043"]
    ),
    "DOID:0080005" => D("DOID:0080005", "bone development disorder";
        def="Disorder affecting normal bone growth and development",
        syn=["skeletal dysplasia"],
        par=["DOID:0080015"]
    )
)

#=============================================================================
  CARTILAGE DISORDERS
=============================================================================#

const CARTILAGE_DISORDERS = Dict{String,OBOTerm}(
    # Degenerative cartilage diseases
    "DOID:8398" => D("DOID:8398", "osteoarthritis";
        def="Degenerative joint disease with progressive cartilage loss, the most common form of arthritis",
        syn=["OA", "degenerative arthritis", "degenerative joint disease"],
        par=["DOID:0080006"]
    ),
    "DOID:7148" => D("DOID:7148", "rheumatoid arthritis";
        def="Autoimmune disease causing chronic inflammation and cartilage destruction in joints",
        syn=["RA", "rheumatoid disease"],
        par=["DOID:0080006"]
    ),
    "NCIT:C26809" => D("NCIT:C26809", "cartilage defect";
        def="Loss or damage to articular cartilage from trauma or disease",
        syn=["chondral defect", "articular cartilage lesion"],
        par=["DOID:0080006"]
    ),
    "NCIT:C84590" => D("NCIT:C84590", "osteochondral defect";
        def="Defect involving both cartilage and underlying subchondral bone",
        syn=["osteochondral lesion", "OCL"],
        par=["NCIT:C26809"]
    ),

    # Joint injuries
    "NCIT:C26869" => D("NCIT:C26869", "meniscus tear";
        def="Tear in meniscal cartilage of knee joint",
        syn=["meniscal tear", "torn meniscus"],
        par=["DOID:0080006"]
    ),
    "NCIT:C26870" => D("NCIT:C26870", "anterior cruciate ligament tear";
        def="Rupture of ACL often with associated cartilage damage",
        syn=["ACL tear", "ACL rupture"],
        par=["DOID:0080006"]
    ),
    "NCIT:C35082" => D("NCIT:C35082", "chondromalacia";
        def="Softening and degeneration of articular cartilage",
        syn=["chondromalacia patellae"],
        par=["DOID:0080006"]
    ),

    # Inflammatory cartilage diseases
    "DOID:848" => D("DOID:848", "arthritis";
        def="Joint inflammation with cartilage damage",
        syn=["joint inflammation"],
        par=["DOID:0080006"]
    ),
    "DOID:13378" => D("DOID:13378", "juvenile arthritis";
        def="Arthritis in children under 16 years",
        syn=["juvenile rheumatoid arthritis", "JRA"],
        par=["DOID:848"]
    ),
    "DOID:1506" => D("DOID:1506", "psoriatic arthritis";
        def="Inflammatory arthritis associated with psoriasis",
        syn=["psoriatic arthropathy"],
        par=["DOID:848"]
    ),

    # Cartilage tumors
    "DOID:3371" => D("DOID:3371", "chondroma";
        def="Benign tumor of cartilage",
        syn=["cartilaginous tumor"],
        par=["DOID:0060119"]
    )
)

#=============================================================================
  SKIN CONDITIONS
=============================================================================#

const SKIN_CONDITIONS = Dict{String,OBOTerm}(
    # Burns
    "NCIT:C26895" => D("NCIT:C26895", "burn";
        def="Tissue injury from heat, chemicals, electricity, or radiation",
        syn=["thermal injury", "burn injury"],
        par=["DOID:0080009"]
    ),
    "NCIT:C50711" => D("NCIT:C50711", "third degree burn";
        def="Full thickness burn destroying epidermis and dermis",
        syn=["full thickness burn"],
        par=["NCIT:C26895"]
    ),
    "NCIT:C50712" => D("NCIT:C50712", "second degree burn";
        def="Partial thickness burn affecting epidermis and dermis",
        syn=["partial thickness burn"],
        par=["NCIT:C26895"]
    ),

    # Chronic wounds
    "NCIT:C50710" => D("NCIT:C50710", "chronic wound";
        def="Wound that fails to progress through normal healing phases in expected timeframe (>3 months)",
        syn=["non-healing wound"],
        par=["DOID:0080009"]
    ),
    "NCIT:C2930" => D("NCIT:C2930", "diabetic foot ulcer";
        def="Chronic wound in diabetic patients, often with neuropathy and ischemia",
        syn=["diabetic ulcer", "neuropathic ulcer"],
        par=["NCIT:C50710"]
    ),
    "NCIT:C35018" => D("NCIT:C35018", "pressure ulcer";
        def="Localized injury to skin and underlying tissue from prolonged pressure",
        syn=["pressure sore", "bedsore", "decubitus ulcer"],
        par=["NCIT:C50710"]
    ),
    "NCIT:C34809" => D("NCIT:C34809", "venous leg ulcer";
        def="Chronic wound caused by venous insufficiency",
        syn=["venous stasis ulcer", "varicose ulcer"],
        par=["NCIT:C50710"]
    ),

    # Traumatic wounds
    "NCIT:C50709" => D("NCIT:C50709", "wound";
        def="Injury to tissue from external force or disease",
        syn=["tissue injury"],
        par=["DOID:0080009"]
    ),
    "NCIT:C26940" => D("NCIT:C26940", "laceration";
        def="Irregular tear-type wound",
        syn=["cut", "tear"],
        par=["NCIT:C50709"]
    ),
    "NCIT:C26918" => D("NCIT:C26918", "abrasion";
        def="Superficial wound from scraping",
        syn=["scrape", "graze"],
        par=["NCIT:C50709"]
    ),

    # Genetic skin disorders
    "DOID:2730" => D("DOID:2730", "epidermolysis bullosa";
        def="Genetic disorder causing fragile skin that blisters easily",
        syn=["EB", "butterfly skin"],
        par=["DOID:0080009"]
    ),
    "DOID:2723" => D("DOID:2723", "ichthyosis";
        def="Genetic disorder causing dry, scaly skin",
        syn=["fish scale disease"],
        par=["DOID:0080009"]
    ),

    # Skin loss conditions
    "NCIT:C50713" => D("NCIT:C50713", "skin defect";
        def="Loss of skin tissue requiring reconstruction",
        syn=["soft tissue defect"],
        par=["DOID:0080009"]
    ),
    "NCIT:C35491" => D("NCIT:C35491", "necrotizing fasciitis";
        def="Rapidly spreading infection destroying soft tissue",
        syn=["flesh-eating disease"],
        par=["DOID:0080009"]
    ),
    "NCIT:C34825" => D("NCIT:C34825", "scar";
        def="Fibrous tissue replacing normal skin after injury",
        syn=["cicatrix", "keloid"],
        par=["DOID:0080009"]
    )
)

#=============================================================================
  CARDIAC CONDITIONS
=============================================================================#

const CARDIAC_CONDITIONS = Dict{String,OBOTerm}(
    # Ischemic heart disease
    "NCIT:C45390" => D("NCIT:C45390", "myocardial infarction";
        def="Death of heart muscle due to ischemia, causing loss of contractile tissue",
        syn=["heart attack", "MI", "acute MI"],
        par=["DOID:5844"]
    ),
    "DOID:3393" => D("DOID:3393", "coronary artery disease";
        def="Narrowing of coronary arteries reducing blood flow to heart",
        syn=["CAD", "ischemic heart disease"],
        par=["DOID:0080005"]
    ),
    "NCIT:C35050" => D("NCIT:C35050", "ischemic cardiomyopathy";
        def="Heart muscle disease from coronary artery disease",
        syn=["ischemic heart failure"],
        par=["DOID:0060036"]
    ),

    # Heart failure
    "NCIT:C50577" => D("NCIT:C50577", "heart failure";
        def="Inability of heart to pump sufficient blood to meet body's needs",
        syn=["congestive heart failure", "CHF", "cardiac failure"],
        par=["DOID:6000"]
    ),
    "NCIT:C84728" => D("NCIT:C84728", "dilated cardiomyopathy";
        def="Heart muscle disease with chamber dilation and reduced contractility",
        syn=["DCM"],
        par=["DOID:0060036"]
    ),
    "DOID:0060036" => D("DOID:0060036", "hypertrophic cardiomyopathy";
        def="Genetic disorder causing heart muscle thickening",
        syn=["HCM"],
        par=["DOID:0060049"]
    ),

    # Valve diseases
    "NCIT:C34819" => D("NCIT:C34819", "mitral valve disease";
        def="Disorder of mitral heart valve",
        syn=["mitral valve disorder"],
        par=["DOID:1115"]
    ),
    "NCIT:C26762" => D("NCIT:C26762", "aortic valve stenosis";
        def="Narrowing of aortic valve opening",
        syn=["aortic stenosis", "AS"],
        par=["DOID:1115"]
    ),
    "NCIT:C34812" => D("NCIT:C34812", "valve regurgitation";
        def="Leaking heart valve allowing backflow",
        syn=["valve insufficiency"],
        par=["DOID:1115"]
    ),

    # Arrhythmias and conduction
    "DOID:0060224" => D("DOID:0060224", "atrial fibrillation";
        def="Irregular rapid heart rhythm from disorganized electrical signals",
        syn=["AFib", "AF"],
        par=["DOID:0060224"]
    ),
    "NCIT:C84546" => D("NCIT:C84546", "ventricular arrhythmia";
        def="Abnormal heart rhythm originating in ventricles",
        syn=["ventricular dysrhythmia"],
        par=["DOID:0060224"]
    ),
    "NCIT:C34820" => D("NCIT:C34820", "heart block";
        def="Impaired electrical conduction in heart",
        syn=["atrioventricular block", "AV block"],
        par=["DOID:0060224"]
    ),

    # Congenital heart defects
    "DOID:1682" => D("DOID:1682", "congenital heart disease";
        def="Structural heart abnormality present at birth",
        syn=["CHD", "congenital heart defect"],
        par=["DOID:0080005"]
    ),
    "NCIT:C35018" => D("NCIT:C35018", "ventricular septal defect";
        def="Hole in wall between heart ventricles",
        syn=["VSD"],
        par=["DOID:1682"]
    )
)

#=============================================================================
  VASCULAR DISEASES
=============================================================================#

const VASCULAR_DISEASES = Dict{String,OBOTerm}(
    # Peripheral vascular disease
    "NCIT:C34504" => D("NCIT:C34504", "peripheral vascular disease";
        def="Circulatory disorder affecting blood vessels outside heart and brain",
        syn=["PVD", "peripheral arterial disease", "PAD"],
        par=["DOID:178"]
    ),
    "DOID:0050828" => D("DOID:0050828", "critical limb ischemia";
        def="Advanced peripheral artery disease with severe reduction in blood flow",
        syn=["CLI"],
        par=["NCIT:C34504"]
    ),
    "NCIT:C34663" => D("NCIT:C34663", "thromboangiitis obliterans";
        def="Inflammatory disease of small and medium arteries and veins",
        syn=["Buerger's disease"],
        par=["DOID:178"]
    ),

    # Aneurysms
    "NCIT:C95812" => D("NCIT:C95812", "aneurysm";
        def="Localized dilation of blood vessel wall",
        syn=["vascular aneurysm"],
        par=["DOID:0050830"]
    ),
    "NCIT:C26692" => D("NCIT:C26692", "aortic aneurysm";
        def="Bulging of aortic wall",
        syn=["aortic dilatation"],
        par=["DOID:0050830"]
    ),
    "NCIT:C26699" => D("NCIT:C26699", "cerebral aneurysm";
        def="Weak bulging in brain artery",
        syn=["brain aneurysm", "intracranial aneurysm"],
        par=["DOID:0050830"]
    ),

    # Atherosclerosis
    "DOID:1936" => D("DOID:1936", "atherosclerosis";
        def="Buildup of plaque in arterial walls",
        syn=["arteriosclerosis", "hardening of arteries"],
        par=["DOID:0050828"]
    ),
    "NCIT:C26698" => D("NCIT:C26698", "carotid artery stenosis";
        def="Narrowing of carotid arteries",
        syn=["carotid stenosis"],
        par=["DOID:1936"]
    ),

    # Venous diseases
    "NCIT:C34826" => D("NCIT:C34826", "varicose veins";
        def="Enlarged, twisted veins, usually in legs",
        syn=["varicosities"],
        par=["DOID:178"]
    ),
    "NCIT:C34827" => D("NCIT:C34827", "chronic venous insufficiency";
        def="Impaired venous return from legs",
        syn=["CVI", "venous stasis"],
        par=["DOID:178"]
    ),
    "NCIT:C26715" => D("NCIT:C26715", "deep vein thrombosis";
        def="Blood clot in deep vein, usually leg",
        syn=["DVT"],
        par=["DOID:12798"]
    ),

    # Vascular trauma
    "NCIT:C26941" => D("NCIT:C26941", "vascular injury";
        def="Traumatic damage to blood vessel",
        syn=["vessel trauma"],
        par=["DOID:178"]
    )
)

#=============================================================================
  NEURAL DISORDERS
=============================================================================#

const NEURAL_DISORDERS = Dict{String,OBOTerm}(
    # Spinal cord injuries
    "NCIT:C4809" => D("NCIT:C4809", "spinal cord injury";
        def="Damage to spinal cord affecting motor and sensory function",
        syn=["SCI", "spinal trauma"],
        par=["DOID:0080009"]
    ),
    "NCIT:C34822" => D("NCIT:C34822", "paraplegia";
        def="Paralysis of lower body from spinal cord injury",
        syn=["lower body paralysis"],
        par=["NCIT:C4809"]
    ),
    "NCIT:C34821" => D("NCIT:C34821", "quadriplegia";
        def="Paralysis of all four limbs from spinal cord injury",
        syn=["tetraplegia"],
        par=["NCIT:C4809"]
    ),

    # Peripheral nerve injuries
    "NCIT:C26853" => D("NCIT:C26853", "peripheral nerve injury";
        def="Damage to peripheral nervous system nerves",
        syn=["PNI", "nerve trauma"],
        par=["DOID:0080009"]
    ),
    "NCIT:C34857" => D("NCIT:C34857", "brachial plexus injury";
        def="Damage to network of nerves controlling arm",
        syn=["brachial plexus trauma"],
        par=["NCIT:C26853"]
    ),
    "NCIT:C26931" => D("NCIT:C26931", "sciatic nerve injury";
        def="Damage to sciatic nerve",
        syn=["sciatica"],
        par=["NCIT:C26853"]
    ),

    # Degenerative neural diseases
    "DOID:14330" => D("DOID:14330", "Parkinson's disease";
        def="Progressive neurodegenerative disorder affecting movement",
        syn=["PD", "Parkinson disease"],
        par=["DOID:0080009"]
    ),
    "DOID:10652" => D("DOID:10652", "Alzheimer's disease";
        def="Progressive neurodegenerative disease causing dementia",
        syn=["AD", "Alzheimer disease"],
        par=["DOID:0080009"]
    ),
    "DOID:2378" => D("DOID:2378", "Huntington's disease";
        def="Inherited neurodegenerative disorder",
        syn=["HD", "Huntington disease"],
        par=["DOID:0080009"]
    ),
    "DOID:332" => D("DOID:332", "amyotrophic lateral sclerosis";
        def="Progressive motor neuron disease",
        syn=["ALS", "Lou Gehrig's disease"],
        par=["DOID:0080009"]
    ),

    # Stroke and brain injury
    "DOID:6713" => D("DOID:6713", "cerebrovascular disease";
        def="Disorder of blood vessels supplying brain",
        syn=["stroke"],
        par=["DOID:0080009"]
    ),
    "NCIT:C3390" => D("NCIT:C3390", "ischemic stroke";
        def="Stroke caused by blocked blood vessel in brain",
        syn=["cerebral infarction"],
        par=["DOID:6713"]
    ),
    "NCIT:C26988" => D("NCIT:C26988", "traumatic brain injury";
        def="Brain dysfunction from external force",
        syn=["TBI", "head injury"],
        par=["DOID:0080009"]
    ),

    # Demyelinating diseases
    "DOID:2377" => D("DOID:2377", "multiple sclerosis";
        def="Autoimmune disease damaging myelin sheath",
        syn=["MS"],
        par=["DOID:0080009"]
    )
)

#=============================================================================
  DENTAL CONDITIONS
=============================================================================#

const DENTAL_CONDITIONS = Dict{String,OBOTerm}(
    # Periodontal diseases
    "DOID:3388" => D("DOID:3388", "periodontal disease";
        def="Inflammatory disease affecting tissues supporting teeth",
        syn=["periodontitis", "gum disease"],
        par=["DOID:0080009"]
    ),
    "NCIT:C35104" => D("NCIT:C35104", "gingivitis";
        def="Inflammation of gums",
        syn=["gum inflammation"],
        par=["DOID:3388"]
    ),
    "NCIT:C35103" => D("NCIT:C35103", "alveolar bone loss";
        def="Loss of bone supporting teeth",
        syn=["alveolar resorption"],
        par=["DOID:3388"]
    ),

    # Tooth loss
    "NCIT:C35105" => D("NCIT:C35105", "tooth loss";
        def="Missing teeth from extraction, trauma, or disease",
        syn=["edentulism", "missing teeth"],
        par=["DOID:0080009"]
    ),
    "NCIT:C35106" => D("NCIT:C35106", "dental caries";
        def="Tooth decay from bacterial acid",
        syn=["cavities", "tooth decay"],
        par=["DOID:77"]
    ),

    # Craniofacial defects
    "DOID:0111351" => D("DOID:0111351", "cleft palate";
        def="Congenital opening in roof of mouth",
        syn=["palatoschisis"],
        par=["DOID:0080009"]
    ),
    "DOID:0060324" => D("DOID:0060324", "cleft lip";
        def="Congenital opening in upper lip",
        syn=["cheiloschisis"],
        par=["DOID:0080009"]
    ),
    "NCIT:C35107" => D("NCIT:C35107", "maxillary defect";
        def="Loss of upper jaw bone",
        syn=["maxilla defect"],
        par=["DOID:0080009"]
    ),
    "NCIT:C35108" => D("NCIT:C35108", "mandibular defect";
        def="Loss of lower jaw bone",
        syn=["mandible defect"],
        par=["DOID:0080009"]
    )
)

#=============================================================================
  ORGAN FAILURE
=============================================================================#

const ORGAN_FAILURE = Dict{String,OBOTerm}(
    # Liver diseases
    "DOID:5082" => D("DOID:5082", "liver cirrhosis";
        def="Chronic liver damage with scarring and dysfunction",
        syn=["hepatic cirrhosis"],
        par=["DOID:409"]
    ),
    "NCIT:C3359" => D("NCIT:C3359", "liver failure";
        def="Loss of liver function",
        syn=["hepatic failure", "end-stage liver disease"],
        par=["DOID:409"]
    ),
    "NCIT:C34787" => D("NCIT:C34787", "hepatocellular carcinoma";
        def="Primary liver cancer",
        syn=["HCC", "liver cancer"],
        par=["DOID:684"]
    ),

    # Kidney diseases
    "DOID:784" => D("DOID:784", "chronic kidney disease";
        def="Progressive loss of kidney function",
        syn=["CKD", "chronic renal disease"],
        par=["DOID:1579"]
    ),
    "NCIT:C50602" => D("NCIT:C50602", "end-stage renal disease";
        def="Complete or near-complete kidney failure",
        syn=["ESRD", "kidney failure"],
        par=["DOID:784"]
    ),
    "DOID:1579" => D("DOID:1579", "kidney disease";
        def="Disease affecting kidney structure or function",
        syn=["renal disease"],
        par=["DOID:0080009"]
    ),

    # Pancreas diseases
    "DOID:9351" => D("DOID:9351", "diabetes mellitus";
        def="Metabolic disorder with high blood sugar",
        syn=["diabetes"],
        par=["DOID:0080009"]
    ),
    "DOID:5375" => D("DOID:5375", "diabetes mellitus type 1";
        def="Autoimmune destruction of insulin-producing beta cells",
        syn=["T1D", "juvenile diabetes"],
        par=["DOID:9351"]
    ),
    "NCIT:C26744" => D("NCIT:C26744", "chronic pancreatitis";
        def="Long-term pancreatic inflammation with tissue damage",
        syn=["pancreatic insufficiency"],
        par=["DOID:4989"]
    ),
    "NCIT:C8921" => D("NCIT:C8921", "pancreatic cancer";
        def="Malignant tumor of pancreas",
        syn=["pancreatic carcinoma"],
        par=["DOID:1793"]
    ),

    # Bladder diseases
    "NCIT:C50619" => D("NCIT:C50619", "bladder dysfunction";
        def="Impaired bladder function",
        syn=["neurogenic bladder"],
        par=["DOID:0080009"]
    ),

    # Lung diseases
    "DOID:3083" => D("DOID:3083", "chronic obstructive pulmonary disease";
        def="Progressive lung disease limiting airflow",
        syn=["COPD", "emphysema"],
        par=["DOID:0080009"]
    ),
    "DOID:799" => D("DOID:799", "pulmonary fibrosis";
        def="Scarring and thickening of lung tissue",
        syn=["interstitial lung disease"],
        par=["DOID:0080009"]
    )
)

#=============================================================================
  CONSOLIDATED DISEASE DICTIONARY
=============================================================================#

"""All diseases consolidated"""
const DISEASES = merge(
    BONE_DISORDERS,
    CARTILAGE_DISORDERS,
    SKIN_CONDITIONS,
    CARDIAC_CONDITIONS,
    VASCULAR_DISEASES,
    NEURAL_DISORDERS,
    DENTAL_CONDITIONS,
    ORGAN_FAILURE
)

#=============================================================================
  DISEASE-TISSUE MAPPING

  Maps each disease to target tissues (UBERON IDs) relevant for scaffold design.
=============================================================================#

const DISEASE_TISSUE_MAP = Dict{String,Vector{String}}(
    # Bone disorders -> bone tissue
    "NCIT:C3043" => ["UBERON:0002481"],  # bone fracture -> bone tissue
    "NCIT:C26808" => ["UBERON:0002481"],  # critical size defect -> bone tissue
    "DOID:630" => ["UBERON:0002481"],  # genetic bone disorder -> bone tissue
    "NCIT:C3298" => ["UBERON:0002481", "UBERON:0001474"],  # osteoporosis -> bone, trabecular bone
    "NCIT:C3239" => ["UBERON:0002481"],  # osteonecrosis -> bone tissue
    "NCIT:C9263" => ["UBERON:0002481"],  # osteosarcoma -> bone tissue
    "DOID:184" => ["UBERON:0002481"],  # bone cancer -> bone tissue
    "NCIT:C3349" => ["UBERON:0002481"],  # Ewing sarcoma -> bone tissue
    "NCIT:C2945" => ["UBERON:0002418"],  # chondrosarcoma -> cartilage
    "DOID:10573" => ["UBERON:0002481"],  # osteomalacia -> bone tissue
    "DOID:10159" => ["UBERON:0002481"],  # osteitis -> bone tissue
    "NCIT:C26854" => ["UBERON:0002481"],  # Paget disease -> bone tissue
    "NCIT:C34562" => ["UBERON:0002481"],  # osteomyelitis -> bone tissue
    "DOID:12347" => ["UBERON:0002481"],  # osteogenesis imperfecta -> bone tissue
    "NCIT:C84558" => ["UBERON:0002481"],  # craniofacial defect -> bone tissue
    "DOID:0080005" => ["UBERON:0002481"],  # bone development disorder -> bone tissue

    # Cartilage disorders -> cartilage tissue
    "DOID:8398" => ["UBERON:0002418", "UBERON:0001994"],  # OA -> cartilage, hyaline cartilage
    "DOID:7148" => ["UBERON:0002418"],  # RA -> cartilage
    "NCIT:C26809" => ["UBERON:0002418"],  # cartilage defect -> cartilage
    "NCIT:C84590" => ["UBERON:0002418", "UBERON:0002481"],  # osteochondral defect -> cartilage + bone
    "NCIT:C26869" => ["UBERON:0002418", "UBERON:0001995"],  # meniscus tear -> fibrocartilage
    "NCIT:C26870" => ["UBERON:0002418", "UBERON:0000211"],  # ACL tear -> cartilage + ligament
    "NCIT:C35082" => ["UBERON:0002418"],  # chondromalacia -> cartilage
    "DOID:848" => ["UBERON:0002418"],  # arthritis -> cartilage
    "DOID:13378" => ["UBERON:0002418"],  # juvenile arthritis -> cartilage
    "DOID:1506" => ["UBERON:0002418"],  # psoriatic arthritis -> cartilage
    "DOID:3371" => ["UBERON:0002418"],  # chondroma -> cartilage

    # Skin conditions -> skin/dermis
    "NCIT:C26895" => ["UBERON:0002097", "UBERON:0002067"],  # burn -> skin, dermis
    "NCIT:C50711" => ["UBERON:0002097", "UBERON:0002067"],  # 3rd degree burn -> skin, dermis
    "NCIT:C50712" => ["UBERON:0002097", "UBERON:0002067"],  # 2nd degree burn -> skin, dermis
    "NCIT:C50710" => ["UBERON:0002097", "UBERON:0002067"],  # chronic wound -> skin, dermis
    "NCIT:C2930" => ["UBERON:0002097", "UBERON:0002067"],  # diabetic ulcer -> skin, dermis
    "NCIT:C35018" => ["UBERON:0002097", "UBERON:0002067"],  # pressure ulcer -> skin, dermis
    "NCIT:C34809" => ["UBERON:0002097", "UBERON:0002067"],  # venous ulcer -> skin, dermis
    "NCIT:C50709" => ["UBERON:0002097"],  # wound -> skin
    "NCIT:C26940" => ["UBERON:0002097"],  # laceration -> skin
    "NCIT:C26918" => ["UBERON:0002097"],  # abrasion -> skin
    "DOID:2730" => ["UBERON:0002097", "UBERON:0002067"],  # epidermolysis bullosa -> skin, dermis
    "DOID:2723" => ["UBERON:0002097"],  # ichthyosis -> skin
    "NCIT:C50713" => ["UBERON:0002097", "UBERON:0002067"],  # skin defect -> skin, dermis
    "NCIT:C35491" => ["UBERON:0002097", "UBERON:0002067", "UBERON:0002384"],  # necrotizing fasciitis -> skin, connective
    "NCIT:C34825" => ["UBERON:0002097", "UBERON:0002067"],  # scar -> skin, dermis

    # Cardiac conditions -> heart/cardiac muscle
    "NCIT:C45390" => ["UBERON:0001133", "UBERON:0000948"],  # MI -> cardiac muscle, heart
    "DOID:3393" => ["UBERON:0001637", "UBERON:0000948"],  # CAD -> artery, heart
    "NCIT:C35050" => ["UBERON:0001133", "UBERON:0000948"],  # ischemic cardiomyopathy -> cardiac muscle, heart
    "NCIT:C50577" => ["UBERON:0001133", "UBERON:0000948"],  # heart failure -> cardiac muscle, heart
    "NCIT:C84728" => ["UBERON:0001133", "UBERON:0000948"],  # dilated cardiomyopathy -> cardiac muscle, heart
    "DOID:0060036" => ["UBERON:0001133", "UBERON:0000948"],  # hypertrophic cardiomyopathy -> cardiac muscle, heart
    "NCIT:C34819" => ["UBERON:0000948"],  # mitral valve -> heart
    "NCIT:C26762" => ["UBERON:0000948"],  # aortic stenosis -> heart
    "NCIT:C34812" => ["UBERON:0000948"],  # valve regurgitation -> heart
    "DOID:0060224" => ["UBERON:0001133", "UBERON:0000948"],  # AFib -> cardiac muscle, heart
    "NCIT:C84546" => ["UBERON:0001133"],  # ventricular arrhythmia -> cardiac muscle
    "NCIT:C34820" => ["UBERON:0001133"],  # heart block -> cardiac muscle
    "DOID:1682" => ["UBERON:0000948"],  # congenital heart disease -> heart

    # Vascular diseases -> blood vessels
    "NCIT:C34504" => ["UBERON:0001981", "UBERON:0001637"],  # PVD -> blood vessel, artery
    "DOID:0050828" => ["UBERON:0001637"],  # critical limb ischemia -> artery
    "NCIT:C34663" => ["UBERON:0001981", "UBERON:0001637"],  # Buerger's -> vessel, artery
    "NCIT:C95812" => ["UBERON:0001981", "UBERON:0001637"],  # aneurysm -> vessel, artery
    "NCIT:C26692" => ["UBERON:0001637"],  # aortic aneurysm -> artery
    "NCIT:C26699" => ["UBERON:0001637"],  # cerebral aneurysm -> artery
    "DOID:1936" => ["UBERON:0001637"],  # atherosclerosis -> artery
    "NCIT:C26698" => ["UBERON:0001637"],  # carotid stenosis -> artery
    "NCIT:C34826" => ["UBERON:0001638"],  # varicose veins -> vein
    "NCIT:C34827" => ["UBERON:0001638"],  # chronic venous insufficiency -> vein
    "NCIT:C26715" => ["UBERON:0001638"],  # DVT -> vein
    "NCIT:C26941" => ["UBERON:0001981"],  # vascular injury -> blood vessel

    # Neural disorders -> nerve/CNS
    "NCIT:C4809" => ["UBERON:0002240", "UBERON:0001017"],  # SCI -> spinal cord, CNS
    "NCIT:C34822" => ["UBERON:0002240"],  # paraplegia -> spinal cord
    "NCIT:C34821" => ["UBERON:0002240"],  # quadriplegia -> spinal cord
    "NCIT:C26853" => ["UBERON:0001021"],  # peripheral nerve injury -> nerve
    "NCIT:C34857" => ["UBERON:0001021"],  # brachial plexus -> nerve
    "NCIT:C26931" => ["UBERON:0001021"],  # sciatic nerve -> nerve
    "DOID:14330" => ["UBERON:0001017"],  # Parkinson's -> CNS
    "DOID:10652" => ["UBERON:0001017"],  # Alzheimer's -> CNS
    "DOID:2378" => ["UBERON:0001017"],  # Huntington's -> CNS
    "DOID:332" => ["UBERON:0001017"],  # ALS -> CNS
    "DOID:6713" => ["UBERON:0001017"],  # cerebrovascular disease -> CNS
    "NCIT:C3390" => ["UBERON:0001017"],  # ischemic stroke -> CNS
    "NCIT:C26988" => ["UBERON:0001017"],  # TBI -> CNS
    "DOID:2377" => ["UBERON:0001017"],  # MS -> CNS

    # Dental conditions -> bone/teeth
    "DOID:3388" => ["UBERON:0002481"],  # periodontal disease -> bone
    "NCIT:C35104" => ["UBERON:0002097"],  # gingivitis -> skin/gum
    "NCIT:C35103" => ["UBERON:0002481"],  # alveolar bone loss -> bone
    "NCIT:C35105" => ["UBERON:0002481"],  # tooth loss -> bone
    "NCIT:C35106" => ["UBERON:0002481"],  # dental caries -> bone
    "DOID:0111351" => ["UBERON:0002481"],  # cleft palate -> bone
    "DOID:0060324" => ["UBERON:0002481"],  # cleft lip -> bone
    "NCIT:C35107" => ["UBERON:0002481"],  # maxillary defect -> bone
    "NCIT:C35108" => ["UBERON:0002481"],  # mandibular defect -> bone

    # Organ failure -> specific organs
    "DOID:5082" => ["UBERON:0002107"],  # liver cirrhosis -> liver
    "NCIT:C3359" => ["UBERON:0002107"],  # liver failure -> liver
    "NCIT:C34787" => ["UBERON:0002107"],  # HCC -> liver
    "DOID:784" => ["UBERON:0002113"],  # CKD -> kidney
    "NCIT:C50602" => ["UBERON:0002113"],  # ESRD -> kidney
    "DOID:1579" => ["UBERON:0002113"],  # kidney disease -> kidney
    "DOID:9351" => ["UBERON:0001264"],  # diabetes -> pancreas (using general organ term)
    "DOID:5375" => ["UBERON:0001264"],  # T1D -> pancreas
    "NCIT:C26744" => ["UBERON:0001264"],  # chronic pancreatitis -> pancreas
    "NCIT:C8921" => ["UBERON:0001264"],  # pancreatic cancer -> pancreas
    "NCIT:C50619" => ["UBERON:0001255"],  # bladder dysfunction -> urinary bladder (using general term)
    "DOID:3083" => ["UBERON:0002048"],  # COPD -> lung (using general term)
    "DOID:799" => ["UBERON:0002048"],  # pulmonary fibrosis -> lung
)

#=============================================================================
  LOOKUP FUNCTIONS
=============================================================================#

"""
    get_disease(id::String) -> Union{OBOTerm, Nothing}

Get disease term by ID (DOID or NCIT).
"""
function get_disease(id::String)
    get(DISEASES, id, nothing)
end

"""
    get_target_tissues(disease_id::String) -> Vector{String}

Get target tissue UBERON IDs for scaffold design for this disease.
Returns empty vector if no mapping exists.
"""
function get_target_tissues(disease_id::String)
    get(DISEASE_TISSUE_MAP, disease_id, String[])
end

"""
    get_diseases_by_category(category::Symbol) -> Dict{String, OBOTerm}

Get all diseases in a specific category.

# Categories
- :bone
- :cartilage
- :skin
- :cardiac
- :vascular
- :neural
- :dental
- :organ

# Example
```julia
bone_diseases = get_diseases_by_category(:bone)
```
"""
function get_diseases_by_category(category::Symbol)
    if category == :bone
        BONE_DISORDERS
    elseif category == :cartilage
        CARTILAGE_DISORDERS
    elseif category == :skin
        SKIN_CONDITIONS
    elseif category == :cardiac
        CARDIAC_CONDITIONS
    elseif category == :vascular
        VASCULAR_DISEASES
    elseif category == :neural
        NEURAL_DISORDERS
    elseif category == :dental
        DENTAL_CONDITIONS
    elseif category == :organ
        ORGAN_FAILURE
    else
        Dict{String,OBOTerm}()
    end
end

"""
    get_diseases_for_tissue(tissue_id::String) -> Vector{OBOTerm}

Get all diseases that target a specific tissue.

# Arguments
- `tissue_id`: UBERON tissue ID (e.g., "UBERON:0002481" for bone tissue)

# Returns
Vector of disease OBOTerms that can be treated with scaffolds targeting this tissue.

# Example
```julia
bone_diseases = get_diseases_for_tissue("UBERON:0002481")
```
"""
function get_diseases_for_tissue(tissue_id::String)
    diseases = OBOTerm[]

    for (disease_id, tissues) in DISEASE_TISSUE_MAP
        if tissue_id in tissues
            disease = get_disease(disease_id)
            if !isnothing(disease)
                push!(diseases, disease)
            end
        end
    end

    return diseases
end

"""
    recommend_scaffold_for_disease(disease_id::String) -> NamedTuple

Get scaffold design recommendations based on disease.

# Returns
NamedTuple with:
- disease: OBOTerm of the disease
- target_tissues: Vector of tissue UBERON IDs
- recommendations: String with scaffold design guidance

# Example
```julia
rec = recommend_scaffold_for_disease("NCIT:C26808")  # critical size bone defect
println(rec.recommendations)
```
"""
function recommend_scaffold_for_disease(disease_id::String)
    disease = get_disease(disease_id)
    if isnothing(disease)
        return (disease=nothing, target_tissues=String[], recommendations="Disease not found")
    end

    tissues = get_target_tissues(disease_id)

    # Generate recommendations based on tissue types
    recommendations = "Scaffold recommendations for $(disease.name):\n"

    if "UBERON:0002481" in tissues  # bone
        recommendations *= "- Target tissue: Bone\n"
        recommendations *= "- Pore size: 100-300 μm (optimal: 150 μm)\n"
        recommendations *= "- Porosity: 70-95% (optimal: 90%)\n"
        recommendations *= "- Materials: Hydroxyapatite, TCP, PLGA, PCL\n"
        recommendations *= "- Cells: Osteoblasts, MSCs\n"
    end

    if "UBERON:0002418" in tissues  # cartilage
        recommendations *= "- Target tissue: Cartilage\n"
        recommendations *= "- Pore size: 50-200 μm (optimal: 100 μm)\n"
        recommendations *= "- Porosity: 70-95% (optimal: 85%)\n"
        recommendations *= "- Materials: Collagen, Hyaluronic acid, Alginate\n"
        recommendations *= "- Cells: Chondrocytes, MSCs\n"
    end

    if "UBERON:0002097" in tissues || "UBERON:0002067" in tissues  # skin/dermis
        recommendations *= "- Target tissue: Skin/Dermis\n"
        recommendations *= "- Pore size: 20-200 μm (optimal: 100 μm)\n"
        recommendations *= "- Porosity: 60-90% (optimal: 80%)\n"
        recommendations *= "- Materials: Collagen, Fibrin, Chitosan\n"
        recommendations *= "- Cells: Fibroblasts, Keratinocytes\n"
    end

    if "UBERON:0001133" in tissues || "UBERON:0000948" in tissues  # cardiac/heart
        recommendations *= "- Target tissue: Cardiac/Heart\n"
        recommendations *= "- Elastic modulus: 10-100 kPa (optimal: 50 kPa)\n"
        recommendations *= "- Materials: Fibrin, Collagen, Alginate\n"
        recommendations *= "- Cells: Cardiomyocytes, MSCs, Cardiac fibroblasts\n"
        recommendations *= "- Special: Requires electrical conductivity\n"
    end

    if "UBERON:0001981" in tissues || "UBERON:0001637" in tissues  # vessels
        recommendations *= "- Target tissue: Blood Vessel\n"
        recommendations *= "- Materials: PCL, PLA, Collagen\n"
        recommendations *= "- Cells: Endothelial cells, Smooth muscle cells\n"
        recommendations *= "- Special: Tubular structure, burst pressure >1500 mmHg\n"
    end

    if "UBERON:0001017" in tissues || "UBERON:0001021" in tissues  # neural
        recommendations *= "- Target tissue: Neural/Nerve\n"
        recommendations *= "- Elastic modulus: 0.1-10 kPa (optimal: 1 kPa, very soft)\n"
        recommendations *= "- Pore size: 10-100 μm (optimal: 50 μm)\n"
        recommendations *= "- Materials: Hyaluronic acid, Collagen, Chitosan\n"
        recommendations *= "- Cells: Neurons, Astrocytes, Schwann cells\n"
    end

    return (disease=disease, target_tissues=tissues, recommendations=recommendations)
end

end # module DiseaseLibrary
