"""
FabricationLibrary - Comprehensive database of scaffold fabrication methods

Based on literature from:
- Murphy & Atala 2014: 3D bioprinting of tissues and organs
- Sachlos & Czernuszka 2003: Making tissue engineering scaffolds work
- Li et al. 2018: Electrospinning for tissue engineering
- Zhang & Ma 1999: Porous poly(L-lactic acid)/apatite composites
- Guarino et al. 2008: Scaffold design in tissue engineering
"""
module FabricationLibrary

export FABRICATION_METHODS, get_method, get_compatible_methods
export FabricationMethod, get_methods_by_category, get_methods_for_pore_range, get_methods_for_porosity_range
export PRINTING_METHODS, ELECTROSPINNING_METHODS, FREEZE_METHODS
export CASTING_METHODS, PHASE_SEPARATION_METHODS, SURFACE_MODIFICATION_METHODS
export CROSSLINKING_METHODS, ASSEMBLY_METHODS, get_method_summary

"""
    FabricationMethod

Represents a scaffold fabrication method with its parameters and capabilities.

# Fields
- `id::String`: Unique identifier (e.g., "fdm_printing")
- `name::String`: Human-readable name
- `category::Symbol`: Method category (:printing, :electrospinning, etc.)
- `description::String`: Technical description
- `parameters::Dict{String,Any}`: Typical process parameters
- `pore_size_range_um::Tuple{Int,Int}`: Achievable pore size range in micrometers
- `porosity_range::Tuple{Float64,Float64}`: Achievable porosity range (0.0-1.0)
- `compatible_materials::Vector{String}`: Materials compatible with this method
- `advantages::Vector{String}`: Key benefits
- `limitations::Vector{String}`: Key drawbacks or constraints
"""
struct FabricationMethod
    id::String
    name::String
    category::Symbol
    description::String
    parameters::Dict{String,Any}
    pore_size_range_um::Tuple{Int,Int}
    porosity_range::Tuple{Float64,Float64}
    compatible_materials::Vector{String}
    advantages::Vector{String}
    limitations::Vector{String}
end

# ============================================================================
# 3D PRINTING METHODS
# ============================================================================

const PRINTING_METHODS = Dict{String,FabricationMethod}(
    "fdm_printing" => FabricationMethod(
        "fdm_printing",
        "Fused Deposition Modeling (FDM)",
        :printing,
        "Thermoplastic extrusion through heated nozzle with layer-by-layer deposition",
        Dict(
            "nozzle_temperature_C" => (180, 250),
            "bed_temperature_C" => (50, 110),
            "layer_height_um" => (50, 400),
            "print_speed_mm_s" => (10, 100),
            "nozzle_diameter_mm" => (0.2, 1.0),
            "infill_percentage" => (10, 100)
        ),
        (200, 2000),  # Pore size range
        (0.10, 0.90),  # Porosity range
        ["PCL", "PLA", "PLGA", "PGA", "ABS", "PEEK", "PVA"],
        [
            "Cost-effective and widely available",
            "Good mechanical strength",
            "Precise geometric control",
            "Multi-material capability",
            "Scalable for large scaffolds"
        ],
        [
            "Limited to thermoplastics",
            "High processing temperatures may denature biologics",
            "Relatively large minimum feature size",
            "Anisotropic mechanical properties",
            "Limited resolution compared to SLA"
        ]
    ),

    "sla_printing" => FabricationMethod(
        "sla_printing",
        "Stereolithography (SLA)",
        :printing,
        "UV laser-based photopolymerization of liquid resin with high resolution",
        Dict(
            "laser_power_mW" => (100, 500),
            "laser_spot_size_um" => (50, 150),
            "layer_thickness_um" => (25, 100),
            "scan_speed_mm_s" => (100, 1000),
            "exposure_time_ms" => (500, 5000),
            "wavelength_nm" => (355, 405)
        ),
        (50, 1000),
        (0.20, 0.85),
        ["PEGDA", "GelMA", "HEMA", "photopolymer_resins", "ceramics_suspension"],
        [
            "High resolution and accuracy (±25-50μm)",
            "Smooth surface finish",
            "Complex geometries with overhangs",
            "Biocompatible photoinitiators available",
            "Suitable for small detailed features"
        ],
        [
            "Limited material selection (photopolymers only)",
            "Potential cytotoxicity from unreacted monomers",
            "Requires post-processing (washing, curing)",
            "Relatively slow for large volumes",
            "UV exposure may damage sensitive biomolecules"
        ]
    ),

    "dlp_printing" => FabricationMethod(
        "dlp_printing",
        "Digital Light Processing (DLP)",
        :printing,
        "Layer-by-layer photopolymerization using projected light patterns",
        Dict(
            "exposure_time_s" => (1, 10),
            "layer_thickness_um" => (25, 100),
            "light_intensity_mW_cm2" => (5, 50),
            "pixel_size_um" => (30, 100),
            "wavelength_nm" => (385, 405),
            "build_speed_mm_h" => (10, 50)
        ),
        (50, 800),
        (0.25, 0.85),
        ["PEGDA", "GelMA", "alginate_methacrylate", "HA_methacrylate", "photoresins"],
        [
            "Faster than SLA (entire layer at once)",
            "High resolution",
            "Good for cell-laden bioinks",
            "Uniform light exposure per layer",
            "Cost-effective compared to SLA"
        ],
        [
            "Limited to photopolymerizable materials",
            "Light scattering in cell-laden constructs",
            "Potential photoinitiator toxicity",
            "Limited build volume",
            "Requires support structures"
        ]
    ),

    "sls_printing" => FabricationMethod(
        "sls_printing",
        "Selective Laser Sintering (SLS)",
        :printing,
        "Laser-based fusion of polymer or ceramic powder particles",
        Dict(
            "laser_power_W" => (10, 100),
            "scan_speed_mm_s" => (100, 5000),
            "layer_thickness_um" => (50, 150),
            "bed_temperature_C" => (80, 180),
            "powder_particle_size_um" => (20, 100),
            "hatch_spacing_um" => (50, 200)
        ),
        (100, 1500),
        (0.30, 0.70),
        ["PCL", "PEEK", "PA12", "PLLA", "HA_powder", "TCP_powder", "composite_powders"],
        [
            "No support structures needed",
            "Wide material selection (polymers, ceramics)",
            "Good mechanical properties",
            "Complex internal geometries",
            "Powder acts as support during building"
        ],
        [
            "High processing temperatures",
            "Rough surface finish",
            "Powder removal from small pores difficult",
            "Expensive equipment",
            "Not suitable for living cells"
        ]
    ),

    "binder_jetting" => FabricationMethod(
        "binder_jetting",
        "Binder Jetting",
        :printing,
        "Selective deposition of liquid binder onto powder bed",
        Dict(
            "binder_droplet_size_pL" => (10, 80),
            "layer_thickness_um" => (50, 200),
            "powder_particle_size_um" => (10, 100),
            "print_speed_mm_s" => (50, 200),
            "drying_time_s" => (5, 30),
            "saturation_level" => (0.5, 1.5)
        ),
        (100, 2000),
        (0.40, 0.75),
        ["HA", "TCP", "bioactive_glass", "PCL_powder", "PLGA_powder", "starch"],
        [
            "Room temperature process",
            "High porosity achievable",
            "Suitable for ceramics and composites",
            "Fast printing speed",
            "Multi-material capability"
        ],
        [
            "Weak green strength (requires post-sintering)",
            "Limited resolution",
            "Binder may affect biocompatibility",
            "Powder infiltration in pores",
            "Post-processing (debinding, sintering) required"
        ]
    ),

    "extrusion_bioprinting" => FabricationMethod(
        "extrusion_bioprinting",
        "Extrusion-based Bioprinting",
        :printing,
        "Pneumatic or mechanical extrusion of cell-laden bioinks",
        Dict(
            "extrusion_pressure_kPa" => (10, 500),
            "nozzle_diameter_um" => (100, 1000),
            "print_speed_mm_s" => (1, 20),
            "temperature_C" => (4, 37),
            "cell_density_million_mL" => (1, 20),
            "shear_stress_Pa" => (100, 5000)
        ),
        (200, 2000),
        (0.50, 0.90),
        ["alginate", "collagen", "GelMA", "agarose", "fibrin", "hyaluronic_acid", "Matrigel"],
        [
            "High cell densities possible (>10^7 cells/mL)",
            "Wide range of bioink viscosities",
            "Multi-material and multi-cellular printing",
            "Cost-effective",
            "Compatible with growth factors and ECM proteins"
        ],
        [
            "Shear stress may damage cells",
            "Limited resolution (>100μm)",
            "Weak mechanical properties initially",
            "Requires crosslinking post-printing",
            "Nozzle clogging with high cell densities"
        ]
    ),

    "inkjet_bioprinting" => FabricationMethod(
        "inkjet_bioprinting",
        "Inkjet Bioprinting",
        :printing,
        "Droplet-based deposition of cell-laden bioinks using thermal or piezoelectric actuation",
        Dict(
            "droplet_volume_pL" => (1, 100),
            "droplet_frequency_kHz" => (1, 20),
            "nozzle_diameter_um" => (30, 100),
            "bioink_viscosity_mPa_s" => (3, 12),
            "temperature_C" => (20, 37),
            "cell_density_million_mL" => (0.5, 10)
        ),
        (50, 500),
        (0.30, 0.80),
        ["alginate", "collagen", "fibrinogen", "GelMA", "PEG", "agarose"],
        [
            "High resolution and precision",
            "Fast printing speed",
            "Low cost",
            "High cell viability (>85%)",
            "Digital control of droplet placement"
        ],
        [
            "Limited to low viscosity bioinks (<12 mPa·s)",
            "Frequent nozzle clogging",
            "Limited material stacking ability",
            "Weak mechanical properties",
            "Thermal/acoustic stress on cells"
        ]
    ),

    "laser_bioprinting" => FabricationMethod(
        "laser_bioprinting",
        "Laser-Assisted Bioprinting (LAB)",
        :printing,
        "Laser-induced forward transfer of cell-laden bioink droplets",
        Dict(
            "laser_energy_mJ" => (0.1, 10),
            "pulse_duration_ns" => (1, 100),
            "spot_size_um" => (10, 100),
            "frequency_Hz" => (1, 5000),
            "ribbon_distance_um" => (100, 1000),
            "cell_density_million_mL" => (1, 100)
        ),
        (20, 300),
        (0.40, 0.85),
        ["Matrigel", "collagen", "alginate", "fibrin", "HA", "cell_suspensions"],
        [
            "Nozzle-free (no clogging)",
            "Very high cell densities possible",
            "High resolution (<50μm)",
            "High cell viability (>95%)",
            "Precise single-cell deposition"
        ],
        [
            "Expensive equipment",
            "Slow printing speed",
            "Requires specialized ribbon preparation",
            "Limited build volume",
            "Complex setup and calibration"
        ]
    )
)

# ============================================================================
# ELECTROSPINNING METHODS
# ============================================================================

const ELECTROSPINNING_METHODS = Dict{String,FabricationMethod}(
    "solution_electrospinning" => FabricationMethod(
        "solution_electrospinning",
        "Solution Electrospinning",
        :electrospinning,
        "Electrostatic fiber formation from polymer solution using high voltage",
        Dict(
            "voltage_kV" => (10, 30),
            "flow_rate_mL_h" => (0.1, 5.0),
            "distance_cm" => (10, 25),
            "needle_gauge" => (18, 27),
            "humidity_percent" => (30, 60),
            "temperature_C" => (20, 40),
            "polymer_concentration_wt" => (5, 20)
        ),
        (1, 10),  # Nanofibrous to microfibrous (50nm-10μm, rounded to 1μm min)
        (0.70, 0.95),
        ["PCL", "PLA", "PLGA", "PGA", "PEO", "PVA", "gelatin", "collagen", "chitosan", "silk_fibroin"],
        [
            "Very high surface area-to-volume ratio",
            "Mimics native ECM fiber structure",
            "High porosity with interconnected pores",
            "Fiber diameter control (50nm-10μm)",
            "Can incorporate drugs, growth factors, nanoparticles"
        ],
        [
            "Requires volatile organic solvents",
            "Small pore sizes limit cell infiltration",
            "Weak mechanical properties in perpendicular direction",
            "Difficult to create 3D thick scaffolds",
            "Limited control over pore size distribution"
        ]
    ),

    "melt_electrospinning" => FabricationMethod(
        "melt_electrospinning",
        "Melt Electrospinning",
        :electrospinning,
        "Solvent-free electrospinning using molten polymer",
        Dict(
            "temperature_C" => (60, 200),
            "voltage_kV" => (15, 40),
            "flow_rate_mg_min" => (10, 100),
            "distance_cm" => (5, 20),
            "pressure_bar" => (1, 5),
            "collector_speed_rpm" => (0, 5000)
        ),
        (1, 50),
        (0.60, 0.90),
        ["PCL", "PLA", "PLLA", "PEG", "PP"],
        [
            "No toxic solvents required",
            "Better mechanical properties",
            "Direct writing capability",
            "3D fiber deposition control",
            "Biocompatible process"
        ],
        [
            "Higher fiber diameters (>1μm)",
            "High processing temperatures",
            "Limited to thermoplastic polymers",
            "Lower porosity than solution electrospinning",
            "Difficult to incorporate biomolecules"
        ]
    ),

    "coaxial_electrospinning" => FabricationMethod(
        "coaxial_electrospinning",
        "Coaxial Electrospinning",
        :electrospinning,
        "Core-shell fiber formation using concentric needles with two solutions",
        Dict(
            "core_flow_rate_mL_h" => (0.05, 1.0),
            "shell_flow_rate_mL_h" => (0.5, 3.0),
            "voltage_kV" => (12, 25),
            "distance_cm" => (12, 20),
            "core_shell_ratio" => (0.1, 0.8),
            "humidity_percent" => (35, 55)
        ),
        (1, 15),  # 100nm-15μm (rounded to 1μm min)
        (0.65, 0.92),
        ["PCL_shell+gelatin_core", "PLGA_shell+BSA_core", "PLA_shell+collagen_core", "CS_shell+drug_core"],
        [
            "Controlled drug release (core-shell structure)",
            "Protection of bioactive molecules in core",
            "Tunable degradation rates",
            "Multi-functionality (shell + core properties)",
            "High encapsulation efficiency"
        ],
        [
            "Complex setup and optimization",
            "Difficult flow rate synchronization",
            "Limited to compatible core-shell materials",
            "Risk of core-shell separation",
            "Requires two pumps and specialized needle"
        ]
    ),

    "emulsion_electrospinning" => FabricationMethod(
        "emulsion_electrospinning",
        "Emulsion Electrospinning",
        :electrospinning,
        "Electrospinning of emulsified solutions to create porous fibers",
        Dict(
            "voltage_kV" => (10, 25),
            "flow_rate_mL_h" => (0.2, 3.0),
            "distance_cm" => (10, 20),
            "emulsion_water_ratio" => (0.05, 0.30),
            "surfactant_concentration_wt" => (0.5, 5.0),
            "sonication_time_min" => (5, 30)
        ),
        (1, 12),  # 100nm-12μm (rounded to 1μm min)
        (0.75, 0.95),
        ["PCL", "PLA", "PLGA", "PEO", "emulsion_systems"],
        [
            "Increased fiber porosity",
            "Enhanced drug loading capacity",
            "Improved hydrophilicity",
            "Controlled release from fiber pores",
            "Higher surface area"
        ],
        [
            "Emulsion stability challenges",
            "Complex preparation protocol",
            "Potential phase separation during spinning",
            "Reduced mechanical strength",
            "Difficult to reproduce consistently"
        ]
    ),

    "aligned_electrospinning" => FabricationMethod(
        "aligned_electrospinning",
        "Aligned Fiber Electrospinning",
        :electrospinning,
        "Electrospinning with rotating mandrel or parallel electrodes for fiber alignment",
        Dict(
            "voltage_kV" => (10, 25),
            "flow_rate_mL_h" => (0.5, 3.0),
            "rotation_speed_rpm" => (1000, 5000),
            "distance_cm" => (10, 20),
            "mandrel_diameter_cm" => (2, 15),
            "gap_width_cm" => (2, 8)
        ),
        (1, 10),  # 100nm-10μm (rounded to 1μm min)
        (0.60, 0.85),
        ["PCL", "PLA", "PLGA", "collagen", "silk", "PLLA"],
        [
            "Anisotropic mechanical properties",
            "Guides cell alignment (tendon, nerve, muscle)",
            "Enhanced tensile strength in fiber direction",
            "Mimics aligned tissue architecture",
            "Directional cell migration"
        ],
        [
            "Reduced porosity in alignment direction",
            "Limited pore interconnectivity",
            "Requires specialized collector",
            "Challenging to create 3D structures",
            "Mechanical weakness perpendicular to fibers"
        ]
    )
)

# ============================================================================
# FREEZE-DRYING AND ICE-TEMPLATING METHODS
# ============================================================================

const FREEZE_METHODS = Dict{String,FabricationMethod}(
    "lyophilization" => FabricationMethod(
        "lyophilization",
        "Freeze-Drying (Lyophilization)",
        :freeze_drying,
        "Ice crystal sublimation under vacuum to create porous scaffolds",
        Dict(
            "freezing_temperature_C" => (-80, -20),
            "freezing_rate_C_min" => (0.5, 10),
            "vacuum_pressure_mTorr" => (50, 500),
            "sublimation_temperature_C" => (-40, -10),
            "sublimation_time_h" => (12, 72),
            "polymer_concentration_wt" => (0.5, 10)
        ),
        (10, 500),
        (0.85, 0.99),
        ["collagen", "gelatin", "chitosan", "alginate", "HA", "silk_fibroin", "PLGA"],
        [
            "Very high porosity (>90%)",
            "Interconnected pore structure",
            "Mild process (suitable for biologics)",
            "Scalable and reproducible",
            "Can incorporate cells, proteins, growth factors"
        ],
        [
            "Poor mechanical properties",
            "Limited control over pore architecture",
            "Random pore orientation",
            "Long processing time",
            "Ice crystal formation may damage biomolecules"
        ]
    ),

    "directional_freezing" => FabricationMethod(
        "directional_freezing",
        "Directional Freeze-Casting",
        :freeze_drying,
        "Unidirectional ice crystal growth to create aligned channels",
        Dict(
            "freezing_velocity_um_s" => (1, 100),
            "temperature_gradient_C_cm" => (5, 50),
            "cold_finger_temperature_C" => (-196, -20),
            "suspension_concentration_wt" => (5, 40),
            "particle_size_um" => (0.1, 10),
            "freezing_time_min" => (10, 180)
        ),
        (10, 300),
        (0.70, 0.95),
        ["HA", "TCP", "bioactive_glass", "alumina", "chitosan", "gelatin", "collagen"],
        [
            "Aligned pore channels",
            "Controlled pore size via freezing rate",
            "High interconnectivity along channels",
            "Biomimetic lamellar structure",
            "Excellent for tissue ingrowth"
        ],
        [
            "Anisotropic properties",
            "Complex equipment setup",
            "Requires careful temperature control",
            "Limited to materials that form stable suspensions",
            "Pore size varies with depth"
        ]
    ),

    "ice_templating" => FabricationMethod(
        "ice_templating",
        "Ice-Templating (Freeze-Gelation)",
        :freeze_drying,
        "Ice crystal templating combined with in-situ gelation",
        Dict(
            "freezing_temperature_C" => (-80, -10),
            "gelation_time_min" => (5, 60),
            "crosslinker_concentration_mM" => (1, 100),
            "freezing_rate_C_min" => (0.1, 5),
            "sublimation_time_h" => (24, 96),
            "polymer_concentration_wt" => (1, 15)
        ),
        (20, 400),
        (0.80, 0.98),
        ["gelatin", "alginate", "chitosan", "collagen", "HA_composite", "silk"],
        [
            "Hierarchical pore structure",
            "Better mechanical properties than simple freeze-drying",
            "Control over macro and microporosity",
            "Can incorporate ceramics and nanoparticles",
            "Mimics trabecular bone architecture"
        ],
        [
            "Complex multi-step process",
            "Requires optimization of gelation and freezing",
            "Time-consuming",
            "Potential incomplete crosslinking",
            "Difficult to reproduce exact pore structure"
        ]
    ),

    "cryogelation" => FabricationMethod(
        "cryogelation",
        "Cryogelation",
        :freeze_drying,
        "Gelation and crosslinking at subzero temperatures with ice porogen",
        Dict(
            "cryogenic_temperature_C" => (-20, -5),
            "gelation_time_h" => (8, 24),
            "thawing_cycles" => (1, 5),
            "monomer_concentration_wt" => (5, 20),
            "crosslinker_ratio" => (0.01, 0.1),
            "ionic_strength_M" => (0, 0.5)
        ),
        (10, 200),
        (0.75, 0.95),
        ["PVA", "gelatin", "chitosan", "polyacrylamide", "HA", "alginate"],
        [
            "Macroporous interconnected structure",
            "Sponge-like elasticity and shape memory",
            "Fast mass transfer (large pores)",
            "Can be performed in molds for complex shapes",
            "Biocompatible process"
        ],
        [
            "Limited to hydrogel-forming materials",
            "Long processing time (12-48h)",
            "Pore size control less precise",
            "May require multiple freeze-thaw cycles",
            "Mechanical properties vary with ice crystal size"
        ]
    )
)

# ============================================================================
# SOLVENT CASTING AND LEACHING METHODS
# ============================================================================

const CASTING_METHODS = Dict{String,FabricationMethod}(
    "particulate_leaching" => FabricationMethod(
        "particulate_leaching",
        "Solvent Casting / Particulate Leaching (SCPL)",
        :casting,
        "Polymer dissolved in solvent mixed with porogen particles, then leached",
        Dict(
            "polymer_concentration_wt" => (5, 20),
            "porogen_size_um" => (50, 500),
            "porogen_loading_wt" => (70, 95),
            "solvent_evaporation_time_h" => (12, 72),
            "leaching_time_h" => (24, 168),
            "leaching_temperature_C" => (25, 60)
        ),
        (50, 500),
        (0.50, 0.95),
        ["PLGA", "PLA", "PCL", "PGA", "PLLA", "PDO"],
        [
            "Simple and inexpensive",
            "High porosity (up to 95%)",
            "Precise pore size control via porogen",
            "Good interconnectivity with high porogen loading",
            "Scalable for various scaffold sizes"
        ],
        [
            "Requires organic solvents",
            "Skin layer formation (less porous surface)",
            "Incomplete porogen removal risk",
            "Limited to thin scaffolds (<3mm)",
            "Long processing time (days)"
        ]
    ),

    "salt_leaching" => FabricationMethod(
        "salt_leaching",
        "Salt Leaching",
        :casting,
        "Salt particles as water-soluble porogen for pore formation",
        Dict(
            "salt_particle_size_um" => (100, 500),
            "salt_loading_wt" => (60, 90),
            "polymer_concentration_wt" => (5, 15),
            "leaching_water_volume_mL" => (100, 1000),
            "water_change_frequency_h" => (4, 24),
            "drying_time_h" => (12, 48)
        ),
        (100, 500),
        (0.60, 0.90),
        ["PLGA", "PLA", "PCL", "PGA", "chitosan"],
        [
            "Non-toxic porogen (salt)",
            "Complete porogen removal possible",
            "Controllable pore size via salt sieving",
            "High porosity achievable",
            "Simple and cost-effective"
        ],
        [
            "Pore shape limited (spherical/cubic)",
            "Potential salt residue issues",
            "Skin layer formation",
            "Limited mechanical strength",
            "Difficult for thick scaffolds"
        ]
    ),

    "sugar_leaching" => FabricationMethod(
        "sugar_leaching",
        "Sugar Sphere Leaching",
        :casting,
        "Sucrose or glucose spheres as porogen with controlled size distribution",
        Dict(
            "sugar_sphere_size_um" => (200, 800),
            "sugar_loading_wt" => (65, 85),
            "polymer_solution_viscosity_Pa_s" => (1, 50),
            "infiltration_time_min" => (10, 120),
            "leaching_time_h" => (12, 72),
            "water_temperature_C" => (25, 50)
        ),
        (200, 800),
        (0.65, 0.85),
        ["PLGA", "PLA", "PCL", "PLLA"],
        [
            "Spherical interconnected pores",
            "FDA-approved porogen",
            "Narrow pore size distribution possible",
            "Complete dissolution in water",
            "Better interconnectivity than salt"
        ],
        [
            "Limited pore size range",
            "Sugar sphere preparation needed",
            "Potential caramelization issues",
            "Expensive for large-scale production",
            "Hygroscopic nature of sugar"
        ]
    ),

    "gas_foaming" => FabricationMethod(
        "gas_foaming",
        "Gas Foaming",
        :casting,
        "CO2 saturation under pressure followed by rapid depressurization to nucleate pores",
        Dict(
            "pressure_MPa" => (5, 30),
            "saturation_time_h" => (24, 72),
            "temperature_C" => (25, 60),
            "depressurization_rate_MPa_min" => (0.5, 10),
            "polymer_particle_size_um" => (50, 500),
            "foaming_agent" => ["CO2", "N2", "ammonium_bicarbonate"]
        ),
        (50, 500),
        (0.70, 0.95),
        ["PLGA", "PLA", "PCL", "PLLA", "PDO"],
        [
            "No organic solvents required",
            "High porosity achievable",
            "Interconnected pore structure",
            "Suitable for incorporating bioactive molecules",
            "Closed-pore or open-pore control"
        ],
        [
            "Limited control over pore size",
            "Potential closed-pore formation",
            "Requires high-pressure equipment",
            "Skin layer formation common",
            "Pore size heterogeneity"
        ]
    ),

    "gas_foaming_leaching" => FabricationMethod(
        "gas_foaming_leaching",
        "Combined Gas Foaming / Particulate Leaching",
        :casting,
        "Gas foaming combined with salt leaching for enhanced porosity and interconnectivity",
        Dict(
            "CO2_pressure_MPa" => (5, 20),
            "saturation_time_h" => (48, 96),
            "salt_particle_size_um" => (100, 400),
            "salt_loading_wt" => (50, 75),
            "depressurization_rate_MPa_min" => (1, 5),
            "leaching_time_h" => (24, 96)
        ),
        (50, 400),
        (0.80, 0.98),
        ["PLGA", "PLA", "PCL", "PLLA"],
        [
            "Very high porosity (>90%)",
            "Excellent pore interconnectivity",
            "Multi-scale porosity (micro + macro)",
            "No organic solvents",
            "Better than gas foaming alone"
        ],
        [
            "Complex two-step process",
            "Time-consuming (several days)",
            "Requires pressure vessel",
            "Potential incomplete salt removal",
            "More expensive than single methods"
        ]
    )
)

# ============================================================================
# PHASE SEPARATION METHODS
# ============================================================================

const PHASE_SEPARATION_METHODS = Dict{String,FabricationMethod}(
    "tips" => FabricationMethod(
        "tips",
        "Thermally-Induced Phase Separation (TIPS)",
        :phase_separation,
        "Temperature-induced liquid-liquid phase separation followed by solvent extraction",
        Dict(
            "gelation_temperature_C" => (-80, 10),
            "polymer_concentration_wt" => (1, 10),
            "quenching_rate_C_min" => (1, 50),
            "solvent_system" => ["dioxane", "THF", "DMF", "DMSO"],
            "phase_separation_time_h" => (1, 24),
            "extraction_solvent" => ["ethanol", "water", "methanol"]
        ),
        (10, 200),
        (0.80, 0.98),
        ["PLLA", "PLGA", "PCL", "PLA", "PHBV"],
        [
            "Highly porous nanofibrous structure",
            "Interconnected pore network",
            "Mimics ECM ultrastructure",
            "Can create gradient structures",
            "High surface area"
        ],
        [
            "Requires toxic organic solvents",
            "Poor mechanical properties",
            "Difficult to control pore size precisely",
            "Long processing time",
            "Complex parameter optimization"
        ]
    ),

    "nips" => FabricationMethod(
        "nips",
        "Non-solvent Induced Phase Separation (NIPS)",
        :phase_separation,
        "Immersion precipitation via solvent/non-solvent exchange",
        Dict(
            "polymer_concentration_wt" => (10, 30),
            "immersion_temperature_C" => (4, 60),
            "coagulation_bath" => ["water", "ethanol", "methanol", "isopropanol"],
            "immersion_time_min" => (10, 1440),
            "additive_concentration_wt" => (0, 20),
            "casting_thickness_um" => (100, 2000)
        ),
        (1, 50),  # 100nm-50μm (rounded to 1μm min)
        (0.60, 0.90),
        ["PSf", "PES", "PVDF", "CA", "PLA", "chitosan"],
        [
            "Asymmetric pore structure (gradient)",
            "High surface porosity",
            "Fast processing (minutes to hours)",
            "Suitable for membranes and thin scaffolds",
            "Tunable via additives (PEG, PVP)"
        ],
        [
            "Mainly for 2D/thin structures",
            "Dense skin layer formation",
            "Limited to specific polymer-solvent systems",
            "Difficult for thick 3D scaffolds",
            "May require toxic solvents"
        ]
    ),

    "vips" => FabricationMethod(
        "vips",
        "Vapor-Induced Phase Separation (VIPS)",
        :phase_separation,
        "Non-solvent vapor absorption to induce phase separation",
        Dict(
            "relative_humidity_percent" => (40, 95),
            "exposure_time_min" => (5, 120),
            "temperature_C" => (15, 40),
            "polymer_concentration_wt" => (15, 30),
            "vapor_atmosphere" => ["water", "ethanol", "methanol"],
            "casting_thickness_um" => (50, 500)
        ),
        (1, 30),  # 500nm-30μm (rounded to 1μm min)
        (0.65, 0.88),
        ["PVDF", "PSf", "PES", "PLA", "PMMA"],
        [
            "Fine control over surface morphology",
            "Minimal solvent waste",
            "Cellular or sponge-like structure",
            "Good for surface patterning",
            "Environmentally friendlier"
        ],
        [
            "Slow process (hours)",
            "Mainly surface porosity",
            "Sensitive to ambient conditions",
            "Limited to thin films",
            "Requires controlled atmosphere"
        ]
    )
)

# ============================================================================
# SURFACE MODIFICATION METHODS
# ============================================================================

const SURFACE_MODIFICATION_METHODS = Dict{String,FabricationMethod}(
    "plasma_treatment" => FabricationMethod(
        "plasma_treatment",
        "Plasma Surface Treatment",
        :surface_modification,
        "Gas plasma to modify surface chemistry and energy",
        Dict(
            "power_W" => (50, 500),
            "pressure_mTorr" => (100, 1000),
            "treatment_time_s" => (10, 300),
            "gas_type" => ["O2", "Ar", "N2", "NH3", "air"],
            "frequency_kHz" => (13, 40),
            "flow_rate_sccm" => (10, 100)
        ),
        (0, 0),  # No pore creation, surface only
        (0.0, 0.0),  # No bulk porosity change
        ["PCL", "PLA", "PLGA", "PEEK", "silicone", "all_polymers"],
        [
            "Improved hydrophilicity",
            "Enhanced cell adhesion",
            "No bulk property change",
            "Fast process (<5 min)",
            "Sterilization simultaneously possible"
        ],
        [
            "Temporary effect (aging)",
            "Surface only (penetration <100nm)",
            "May cause surface degradation",
            "Requires vacuum equipment",
            "Effects lost during storage"
        ]
    ),

    "chemical_grafting" => FabricationMethod(
        "chemical_grafting",
        "Chemical Grafting",
        :surface_modification,
        "Covalent attachment of functional molecules to scaffold surface",
        Dict(
            "reaction_time_h" => (1, 24),
            "temperature_C" => (25, 80),
            "initiator_concentration_mM" => (1, 100),
            "monomer_concentration_wt" => (1, 20),
            "pH" => (4.0, 10.0),
            "grafting_method" => ["EDC_NHS", "click_chemistry", "thiol_ene", "Michael_addition"]
        ),
        (0, 0),
        (0.0, 0.0),
        ["PCL", "PLA", "PLGA", "collagen", "chitosan", "HA", "all_polymers"],
        [
            "Stable covalent bonds",
            "Long-lasting effect",
            "Specific functionalization (RGD, growth factors)",
            "Controlled grafting density",
            "Bioactive surface presentation"
        ],
        [
            "May require toxic reagents",
            "Complex chemistry",
            "Potential bulk property change",
            "Expensive reagents (peptides, proteins)",
            "Requires characterization to confirm grafting"
        ]
    ),

    "coating" => FabricationMethod(
        "coating",
        "Physical Coating",
        :surface_modification,
        "Physical adsorption or layer-by-layer deposition of biomolecules",
        Dict(
            "coating_concentration_ug_mL" => (10, 1000),
            "incubation_time_h" => (1, 24),
            "temperature_C" => (4, 37),
            "coating_material" => ["collagen", "fibronectin", "laminin", "gelatin", "chitosan", "HA"],
            "number_of_layers" => (1, 10),
            "drying_method" => ["air_dry", "vacuum", "freeze_dry"]
        ),
        (0, 0),
        (0.0, 0.0),
        ["all_scaffold_materials"],
        [
            "Simple and fast",
            "No chemical modification",
            "Preserves bioactivity",
            "Inexpensive",
            "Wide range of coating materials"
        ],
        [
            "Weak binding (may detach)",
            "Short-term effect",
            "Non-uniform coating possible",
            "Sterilization may remove coating",
            "Difficult to control thickness"
        ]
    ),

    "mineralization" => FabricationMethod(
        "mineralization",
        "Biomimetic Mineralization",
        :surface_modification,
        "Calcium phosphate deposition on scaffold surface via simulated body fluid",
        Dict(
            "SBF_concentration_x" => (1.0, 5.0),
            "immersion_time_days" => (1, 14),
            "temperature_C" => (37, 40),
            "pH" => (7.2, 7.6),
            "renewal_frequency_days" => (1, 3),
            "pre_treatment" => ["NaOH", "plasma", "Ca_chelation"]
        ),
        (0, 0),
        (0.0, 0.0),
        ["PCL", "PLA", "PLGA", "collagen", "chitosan", "silk", "PEEK"],
        [
            "Bone-like apatite layer",
            "Enhanced osteoconductivity",
            "Biomimetic process",
            "Improved cell response",
            "Gradual ion release"
        ],
        [
            "Long process time (1-2 weeks)",
            "Non-uniform coating",
            "May block pores",
            "Brittle mineral layer",
            "Requires frequent SBF renewal"
        ]
    ),

    "layer_by_layer" => FabricationMethod(
        "layer_by_layer",
        "Layer-by-Layer (LbL) Assembly",
        :surface_modification,
        "Sequential deposition of oppositely charged polyelectrolytes",
        Dict(
            "polycation_concentration_mg_mL" => (0.5, 5),
            "polyanion_concentration_mg_mL" => (0.5, 5),
            "incubation_time_min" => (5, 30),
            "number_of_bilayers" => (1, 50),
            "pH" => (4.0, 9.0),
            "ionic_strength_M" => (0, 0.5)
        ),
        (0, 0),
        (0.0, 0.0),
        ["all_scaffold_materials"],
        [
            "Nanometer-scale thickness control",
            "Multi-functionality (growth factors, drugs)",
            "Tunable degradation via layer composition",
            "Conformal coating (enters pores)",
            "Sequential release possible"
        ],
        [
            "Time-consuming (many layers)",
            "Requires charged polymers",
            "May alter scaffold properties",
            "Stability depends on ionic strength",
            "Complex optimization"
        ]
    )
)

# ============================================================================
# CROSSLINKING METHODS
# ============================================================================

const CROSSLINKING_METHODS = Dict{String,FabricationMethod}(
    "glutaraldehyde" => FabricationMethod(
        "glutaraldehyde",
        "Glutaraldehyde Crosslinking",
        :crosslinking,
        "Chemical crosslinking via aldehyde groups reacting with amines",
        Dict(
            "concentration_wt" => (0.1, 2.5),
            "reaction_time_h" => (4, 48),
            "temperature_C" => (4, 25),
            "pH" => (7.0, 8.0),
            "buffer" => ["PBS", "phosphate_buffer"],
            "quenching_agent" => ["glycine", "NaBH4"]
        ),
        (0, 0),
        (0.0, 0.0),
        ["collagen", "gelatin", "chitosan", "fibrin", "albumin"],
        [
            "Strong crosslinks",
            "Improved mechanical properties",
            "Reduced degradation rate",
            "Fast and efficient",
            "Widely used and established"
        ],
        [
            "Cytotoxic residues",
            "Requires extensive washing",
            "Calcification risk in vivo",
            "Reduces bioactivity",
            "Not suitable for cell-seeded scaffolds"
        ]
    ),

    "edc_nhs" => FabricationMethod(
        "edc_nhs",
        "EDC/NHS Crosslinking",
        :crosslinking,
        "Zero-length carbodiimide crosslinking forming amide bonds",
        Dict(
            "EDC_concentration_mM" => (5, 100),
            "NHS_concentration_mM" => (5, 100),
            "EDC_NHS_ratio" => (1, 5),
            "reaction_time_h" => (2, 24),
            "temperature_C" => (4, 25),
            "pH" => (4.5, 6.5),
            "buffer" => ["MES", "phosphate"]
        ),
        (0, 0),
        (0.0, 0.0),
        ["collagen", "gelatin", "chitosan", "HA", "alginate", "silk"],
        [
            "Zero-length crosslinks (no foreign residue)",
            "Biocompatible byproducts",
            "Tunable crosslinking density",
            "Suitable for cell-laden scaffolds",
            "No calcification risk"
        ],
        [
            "Expensive reagents",
            "Sensitive to pH",
            "Lower mechanical strength than glutaraldehyde",
            "Requires optimization",
            "EDC hydrolyzes rapidly in water"
        ]
    ),

    "genipin" => FabricationMethod(
        "genipin",
        "Genipin Crosslinking",
        :crosslinking,
        "Natural crosslinker from Gardenia fruit, reacts with amines",
        Dict(
            "concentration_mM" => (0.1, 10),
            "reaction_time_h" => (12, 72),
            "temperature_C" => (25, 37),
            "pH" => (7.0, 8.0),
            "buffer" => ["PBS", "HEPES"],
            "blue_pigment_formation" => true
        ),
        (0, 0),
        (0.0, 0.0),
        ["collagen", "gelatin", "chitosan", "fibrin", "silk"],
        [
            "Natural and biocompatible",
            "Low cytotoxicity (10000x less than glutaraldehyde)",
            "Good mechanical properties",
            "Anti-inflammatory properties",
            "Suitable for in-situ crosslinking"
        ],
        [
            "Expensive",
            "Very slow reaction (days)",
            "Blue color formation",
            "Limited availability",
            "pH and temperature sensitive"
        ]
    ),

    "enzymatic_crosslinking" => FabricationMethod(
        "enzymatic_crosslinking",
        "Enzymatic Crosslinking",
        :crosslinking,
        "Enzyme-catalyzed crosslinking (transglutaminase, tyrosinase, peroxidase)",
        Dict(
            "enzyme_concentration_U_mL" => (0.1, 10),
            "reaction_time_min" => (10, 180),
            "temperature_C" => (25, 37),
            "pH" => (6.0, 8.0),
            "enzyme_type" => ["transglutaminase", "tyrosinase", "HRP", "laccase"],
            "substrate_concentration_mM" => (0.1, 10)
        ),
        (0, 0),
        (0.0, 0.0),
        ["gelatin", "collagen", "fibrin", "casein", "soy_protein", "tyrosine_polymers"],
        [
            "Mild conditions (biocompatible)",
            "Specific crosslinking sites",
            "Suitable for cell encapsulation",
            "Fast reaction (minutes)",
            "No toxic byproducts"
        ],
        [
            "Expensive enzymes",
            "Limited substrate specificity",
            "Enzyme may remain in scaffold",
            "Storage and stability issues",
            "Limited mechanical strength"
        ]
    ),

    "photo_crosslinking" => FabricationMethod(
        "photo_crosslinking",
        "Photo-Crosslinking",
        :crosslinking,
        "UV or visible light-induced radical polymerization",
        Dict(
            "photoinitiator_concentration_wt" => (0.05, 1.0),
            "light_intensity_mW_cm2" => (1, 100),
            "exposure_time_s" => (10, 300),
            "wavelength_nm" => (365, 520),
            "photoinitiator" => ["Irgacure_2959", "LAP", "Eosin_Y", "riboflavin"],
            "oxygen_inhibition" => ["argon_purge", "nitrogen_atmosphere"]
        ),
        (0, 0),
        (0.0, 0.0),
        ["GelMA", "PEGDA", "HA_methacrylate", "alginate_methacrylate", "dextran_methacrylate"],
        [
            "Rapid crosslinking (seconds to minutes)",
            "Spatial and temporal control",
            "In-situ gelation possible",
            "Suitable for bioprinting",
            "Tunable mechanical properties"
        ],
        [
            "Photoinitiator toxicity",
            "UV may damage cells/DNA",
            "Limited penetration depth",
            "Requires methacrylate functionalization",
            "Oxygen inhibition of polymerization"
        ]
    ),

    "ionic_crosslinking" => FabricationMethod(
        "ionic_crosslinking",
        "Ionic Crosslinking",
        :crosslinking,
        "Electrostatic interactions via multivalent ions (Ca2+, Fe3+, etc.)",
        Dict(
            "crosslinker_concentration_mM" => (10, 500),
            "crosslinker_ion" => ["Ca2+", "Ba2+", "Sr2+", "Zn2+", "Fe3+"],
            "gelation_time_min" => (1, 60),
            "temperature_C" => (4, 37),
            "pH" => (6.0, 8.0),
            "diffusion_method" => ["immersion", "internal", "spray"]
        ),
        (0, 0),
        (0.0, 0.0),
        ["alginate", "chitosan", "pectin", "carrageenan", "xanthan"],
        [
            "Very mild conditions",
            "Fast gelation",
            "Reversible (stimuli-responsive)",
            "No toxic chemicals",
            "Suitable for cell encapsulation"
        ],
        [
            "Weak mechanical properties",
            "Unstable in physiological conditions",
            "Ion exchange may cause dissolution",
            "Not suitable for long-term implants",
            "Requires stabilization for in vivo use"
        ]
    ),

    "thermal_crosslinking" => FabricationMethod(
        "thermal_crosslinking",
        "Thermal Crosslinking",
        :crosslinking,
        "Temperature-induced physical crosslinking (hydrogen bonds, hydrophobic interactions)",
        Dict(
            "gelation_temperature_C" => (4, 90),
            "crosslinking_time_min" => (10, 240),
            "heating_cooling_rate_C_min" => (0.5, 10),
            "number_of_cycles" => (1, 10),
            "pH" => (6.5, 8.0),
            "polymer_concentration_wt" => (1, 20)
        ),
        (0, 0),
        (0.0, 0.0),
        ["collagen", "gelatin", "agarose", "chitosan", "Pluronic", "methylcellulose"],
        [
            "No chemical additives",
            "Reversible (thermosensitive)",
            "Simple process",
            "Biocompatible",
            "Injectable systems possible"
        ],
        [
            "Weak crosslinks",
            "Temperature sensitivity limits applications",
            "May denature proteins",
            "Unstable at body temperature (some materials)",
            "Poor mechanical strength"
        ]
    )
)

# ============================================================================
# SELF-ASSEMBLY AND ADVANCED METHODS
# ============================================================================

const ASSEMBLY_METHODS = Dict{String,FabricationMethod}(
    "peptide_self_assembly" => FabricationMethod(
        "peptide_self_assembly",
        "Peptide Self-Assembly",
        :self_assembly,
        "Molecular self-assembly of peptide amphiphiles into nanofibers",
        Dict(
            "peptide_concentration_wt" => (0.1, 5.0),
            "pH_trigger" => (3.0, 8.0),
            "ionic_strength_mM" => (10, 500),
            "temperature_C" => (25, 37),
            "assembly_time_min" => (5, 1440),
            "trigger_type" => ["pH", "ionic_strength", "temperature", "enzyme"]
        ),
        (1, 1),  # Nanofibrous (5-100nm, too small to represent in μm, using 1μm)
        (0.90, 0.99),
        ["peptide_amphiphiles", "self_assembling_peptides", "MAX_peptides"],
        [
            "Biomimetic nanofiber structure",
            "Bioactive epitope presentation",
            "Injectable and in-situ forming",
            "Stimuli-responsive",
            "High biocompatibility"
        ],
        [
            "Expensive peptide synthesis",
            "Very weak mechanical properties",
            "Small pore sizes limit cell infiltration",
            "Rapid degradation",
            "Difficult to handle and process"
        ]
    ),

    "microsphere_sintering" => FabricationMethod(
        "microsphere_sintering",
        "Microsphere Sintering",
        :self_assembly,
        "Thermal fusion of polymer or ceramic microspheres",
        Dict(
            "sintering_temperature_C" => (50, 150),
            "sintering_time_min" => (30, 480),
            "microsphere_size_um" => (50, 500),
            "heating_rate_C_min" => (1, 10),
            "pressure_MPa" => (0, 10),
            "atmosphere" => ["air", "argon", "vacuum"]
        ),
        (50, 500),
        (0.30, 0.70),
        ["PLGA", "PCL", "PLA", "HA", "TCP", "bioactive_glass"],
        [
            "Highly interconnected pores",
            "Controlled pore size via microsphere size",
            "Uniform pore distribution",
            "Good mechanical properties",
            "No organic solvents"
        ],
        [
            "High temperature process",
            "Microsphere preparation required",
            "Limited shape complexity",
            "Potential incomplete sintering",
            "Difficult to create thin structures"
        ]
    ),

    "fiber_bonding" => FabricationMethod(
        "fiber_bonding",
        "Fiber Bonding / Mesh Stacking",
        :self_assembly,
        "Mechanical interlocking or thermal bonding of fiber meshes",
        Dict(
            "bonding_temperature_C" => (40, 120),
            "bonding_pressure_MPa" => (0.1, 10),
            "bonding_time_min" => (5, 60),
            "fiber_diameter_um" => (10, 200),
            "mesh_spacing_um" => (100, 1000),
            "number_of_layers" => (2, 50)
        ),
        (100, 1000),
        (0.50, 0.85),
        ["PCL", "PLA", "PLGA", "PGA", "PEEK", "PP"],
        [
            "Anisotropic mechanical properties",
            "Tunable via layer stacking",
            "High strength in fiber direction",
            "Large pore sizes for cell infiltration",
            "Scalable production"
        ],
        [
            "Limited 3D architecture control",
            "Potential delamination between layers",
            "Requires fiber mesh preparation",
            "Mechanical weakness perpendicular to layers",
            "Limited to fibrous materials"
        ]
    ),

    "decellularization_physical" => FabricationMethod(
        "decellularization_physical",
        "Physical Decellularization",
        :decellularization,
        "Freeze-thaw cycles and mechanical agitation to remove cells from tissue",
        Dict(
            "freeze_thaw_cycles" => (3, 10),
            "freezing_temperature_C" => (-80, -20),
            "thawing_temperature_C" => (25, 37),
            "agitation_speed_rpm" => (50, 200),
            "agitation_time_h" => (12, 72),
            "sonication_power_W" => (0, 100)
        ),
        (1, 100),  # Maintains native ECM architecture
        (0.60, 0.90),
        ["tissue_derived_ECM"],
        [
            "Maintains ECM ultrastructure",
            "No chemical residues",
            "Preserves growth factors",
            "Native biomechanical properties",
            "Biocompatible"
        ],
        [
            "Incomplete cell removal",
            "May damage ECM",
            "Time-consuming",
            "Tissue-dependent efficacy",
            "Requires additional chemical treatment usually"
        ]
    ),

    "decellularization_chemical" => FabricationMethod(
        "decellularization_chemical",
        "Chemical Decellularization",
        :decellularization,
        "Detergent-based cell removal from native tissue matrices",
        Dict(
            "detergent_type" => ["SDS", "Triton_X100", "CHAPS", "deoxycholate"],
            "detergent_concentration_wt" => (0.1, 2.0),
            "treatment_time_h" => (12, 168),
            "temperature_C" => (4, 37),
            "agitation_speed_rpm" => (50, 150),
            "washing_cycles" => (5, 20)
        ),
        (1, 100),
        (0.65, 0.92),
        ["tissue_derived_ECM"],
        [
            "Efficient cell removal (<50 ng DNA/mg dry weight)",
            "Maintains 3D architecture",
            "Bioactive ECM components retained",
            "Tissue-specific ECM composition",
            "Clinical translation proven"
        ],
        [
            "Potential detergent residues (cytotoxic)",
            "Requires extensive washing",
            "May remove growth factors",
            "ECM damage possible (SDS)",
            "Time-consuming (days to weeks)"
        ]
    ),

    "decellularization_enzymatic" => FabricationMethod(
        "decellularization_enzymatic",
        "Enzymatic Decellularization",
        :decellularization,
        "Enzyme-mediated digestion of cellular components",
        Dict(
            "enzyme_type" => ["trypsin", "dispase", "DNase", "RNase", "lipase"],
            "enzyme_concentration_percent" => (0.01, 1.0),
            "digestion_time_min" => (30, 480),
            "temperature_C" => (4, 37),
            "pH" => (7.0, 8.5),
            "inhibitor_addition" => ["serum", "protease_inhibitor"]
        ),
        (1, 100),
        (0.60, 0.88),
        ["tissue_derived_ECM"],
        [
            "Specific cell component removal",
            "Mild conditions",
            "Preserves ECM structure better",
            "Can target specific components",
            "Complements other methods"
        ],
        [
            "May digest ECM proteins",
            "Expensive enzymes",
            "Requires enzyme inactivation",
            "Incomplete cell removal (used with others)",
            "Enzyme penetration limited in dense tissues"
        ]
    )
)

# ============================================================================
# COMBINED DICTIONARY AND UTILITY FUNCTIONS
# ============================================================================

"""
All fabrication methods combined into a single dictionary
"""
const FABRICATION_METHODS = merge(
    PRINTING_METHODS,
    ELECTROSPINNING_METHODS,
    FREEZE_METHODS,
    CASTING_METHODS,
    PHASE_SEPARATION_METHODS,
    SURFACE_MODIFICATION_METHODS,
    CROSSLINKING_METHODS,
    ASSEMBLY_METHODS
)

"""
    get_method(id::String) -> Union{FabricationMethod, Nothing}

Retrieve a fabrication method by its ID.

# Example
```julia
method = get_method("fdm_printing")
println(method.name)  # "Fused Deposition Modeling (FDM)"
```
"""
function get_method(id::String)
    return get(FABRICATION_METHODS, id, nothing)
end

"""
    get_compatible_methods(material_id::String) -> Vector{FabricationMethod}

Find all fabrication methods compatible with a given material.

# Example
```julia
methods = get_compatible_methods("PCL")
println(length(methods))  # Number of methods that can process PCL
```
"""
function get_compatible_methods(material_id::String)
    compatible = FabricationMethod[]
    for (id, method) in FABRICATION_METHODS
        if material_id in method.compatible_materials
            push!(compatible, method)
        end
    end
    return compatible
end

"""
    get_methods_by_category(category::Symbol) -> Vector{FabricationMethod}

Get all methods in a specific category.

# Example
```julia
printing_methods = get_methods_by_category(:printing)
electrospinning = get_methods_by_category(:electrospinning)
```
"""
function get_methods_by_category(category::Symbol)
    return [method for (id, method) in FABRICATION_METHODS if method.category == category]
end

"""
    get_methods_for_pore_range(min_pore_um::Int, max_pore_um::Int) -> Vector{FabricationMethod}

Find methods that can achieve pore sizes within the specified range.

# Example
```julia
# Find methods for bone tissue engineering (100-500 μm pores)
bone_methods = get_methods_for_pore_range(100, 500)
```
"""
function get_methods_for_pore_range(min_pore_um::Int, max_pore_um::Int)
    suitable = FabricationMethod[]
    for (id, method) in FABRICATION_METHODS
        method_min, method_max = method.pore_size_range_um
        # Check if ranges overlap
        if !(method_max < min_pore_um || method_min > max_pore_um)
            push!(suitable, method)
        end
    end
    return suitable
end

"""
    get_methods_for_porosity_range(min_porosity::Float64, max_porosity::Float64) -> Vector{FabricationMethod}

Find methods that can achieve porosity within the specified range.

# Example
```julia
# Find methods for high porosity scaffolds (>85%)
high_porosity_methods = get_methods_for_porosity_range(0.85, 0.99)
```
"""
function get_methods_for_porosity_range(min_porosity::Float64, max_porosity::Float64)
    suitable = FabricationMethod[]
    for (id, method) in FABRICATION_METHODS
        method_min, method_max = method.porosity_range
        # Check if ranges overlap
        if !(method_max < min_porosity || method_min > max_porosity)
            push!(suitable, method)
        end
    end
    return suitable
end

"""
    get_method_summary() -> String

Generate a summary of all available fabrication methods by category.
"""
function get_method_summary()
    categories = Dict{Symbol, Int}()
    for (id, method) in FABRICATION_METHODS
        categories[method.category] = get(categories, method.category, 0) + 1
    end

    summary = "Fabrication Methods Library Summary\n"
    summary *= "="^50 * "\n"
    summary *= "Total methods: $(length(FABRICATION_METHODS))\n\n"
    summary *= "By category:\n"
    for (cat, count) in sort(collect(categories))
        summary *= "  - $(cat): $(count) methods\n"
    end

    return summary
end

end # module FabricationLibrary
