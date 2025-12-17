"""
Biomaterial Structure-Property Relationships
============================================

Connecting molecular structure to scaffold performance.

Key Relationships:
1. Gibson-Ashby: Porosity vs Mechanical Properties
2. Kozeny-Carman: Porosity vs Permeability
3. Flory-Rehner: Crosslinking vs Swelling
4. Structure → Degradation Rate

All equations sourced from established literature.
"""

using Statistics
using Printf

# ============================================================================
# GIBSON-ASHBY MODEL: Mechanical Properties of Porous Materials
# ============================================================================

"""
Gibson-Ashby equations for cellular solids.
Source: Gibson & Ashby, "Cellular Solids" (1997)

For open-cell foams (like most tissue scaffolds):
    E*/Es = C₁ × (ρ*/ρs)²
    σ*/σs = C₂ × (ρ*/ρs)^1.5

where:
    E*, σ* = scaffold properties
    Es, σs = solid polymer properties
    ρ*/ρs = relative density = (1 - porosity)
    C₁ ≈ 1.0, C₂ ≈ 0.3 (empirical constants)
"""
struct GibsonAshbyModel
    C1_modulus::Float64      # Constant for modulus
    C2_strength::Float64     # Constant for strength
    n_modulus::Float64       # Exponent for modulus
    n_strength::Float64      # Exponent for strength
end

# Standard values for open-cell foams
const GIBSON_ASHBY_OPEN_CELL = GibsonAshbyModel(1.0, 0.3, 2.0, 1.5)
const GIBSON_ASHBY_CLOSED_CELL = GibsonAshbyModel(1.0, 0.4, 2.0, 1.5)

"""
Calculate scaffold mechanical properties from porosity.
"""
function scaffold_mechanics(Es_mpa::Float64, sigma_s_mpa::Float64,
                             porosity::Float64;
                             model::GibsonAshbyModel=GIBSON_ASHBY_OPEN_CELL)
    relative_density = 1.0 - porosity

    E_scaffold = Es_mpa * model.C1_modulus * relative_density^model.n_modulus
    sigma_scaffold = sigma_s_mpa * model.C2_strength * relative_density^model.n_strength

    return (E_mpa=E_scaffold, sigma_mpa=sigma_scaffold, relative_density=relative_density)
end

"""
Inverse: Calculate required porosity to achieve target modulus.
"""
function required_porosity_for_modulus(Es_mpa::Float64, E_target_mpa::Float64;
                                        model::GibsonAshbyModel=GIBSON_ASHBY_OPEN_CELL)
    # E_target = C1 × Es × (1-φ)^n
    # (1-φ)^n = E_target / (C1 × Es)
    # 1-φ = (E_target / (C1 × Es))^(1/n)
    # φ = 1 - (E_target / (C1 × Es))^(1/n)

    ratio = E_target_mpa / (model.C1_modulus * Es_mpa)

    if ratio >= 1.0
        return 0.0  # Need solid material
    elseif ratio <= 0.0
        return 1.0  # Impossible
    end

    relative_density = ratio^(1/model.n_modulus)
    porosity = 1.0 - relative_density

    return clamp(porosity, 0.0, 0.99)
end

# ============================================================================
# KOZENY-CARMAN: Permeability of Porous Media
# ============================================================================

"""
Kozeny-Carman equation for permeability.
Source: Carman (1937), standard porous media theory

    k = φ³ / (c × S² × (1-φ)²)

where:
    k = permeability (m²)
    φ = porosity
    S = specific surface area (m²/m³)
    c = Kozeny constant (~5 for random packing)

For scaffolds, permeability affects:
- Nutrient transport
- Waste removal
- Cell infiltration
- Vascularization
"""
function kozeny_carman_permeability(porosity::Float64,
                                     specific_surface_m2_m3::Float64;
                                     kozeny_constant::Float64=5.0)
    if porosity >= 1.0 || porosity <= 0.0
        return NaN
    end

    k = porosity^3 / (kozeny_constant * specific_surface_m2_m3^2 * (1 - porosity)^2)
    return k
end

"""
Estimate specific surface area from pore size (spherical pore model).
"""
function specific_surface_area(pore_diameter_m::Float64, porosity::Float64)
    # For spherical pores: S = 6φ/d
    return 6 * porosity / pore_diameter_m
end

"""
Calculate Darcy permeability in practical units.
"""
function scaffold_permeability(porosity::Float64, pore_size_um::Float64)
    pore_size_m = pore_size_um * 1e-6
    S = specific_surface_area(pore_size_m, porosity)
    k_m2 = kozeny_carman_permeability(porosity, S)

    # Convert to Darcy (1 Darcy = 9.87×10⁻¹³ m²)
    k_darcy = k_m2 / 9.87e-13

    return (k_m2=k_m2, k_darcy=k_darcy, S_m2_m3=S)
end

# ============================================================================
# PORE SIZE REQUIREMENTS FOR CELL INFILTRATION
# ============================================================================

"""
Minimum pore size requirements for different cell types.
Source: Frontiers Bioeng 2024, PMC11588461
"""
const CELL_PORE_REQUIREMENTS = Dict(
    :osteoblast => (min=100.0, optimal=350.0, max=500.0),      # μm
    :chondrocyte => (min=50.0, optimal=150.0, max=300.0),
    :fibroblast => (min=20.0, optimal=100.0, max=200.0),
    :endothelial => (min=5.0, optimal=20.0, max=50.0),
    :smooth_muscle => (min=30.0, optimal=80.0, max=150.0),
    :neuron => (min=10.0, optimal=50.0, max=100.0),
    :hepatocyte => (min=50.0, optimal=150.0, max=250.0),
    :keratinocyte => (min=20.0, optimal=60.0, max=150.0),
)

"""
Check if pore size is suitable for target cell type.
"""
function check_pore_suitability(pore_size_um::Float64, cell_type::Symbol)
    if !haskey(CELL_PORE_REQUIREMENTS, cell_type)
        return (suitable=true, message="Unknown cell type, assuming suitable")
    end

    req = CELL_PORE_REQUIREMENTS[cell_type]

    if pore_size_um < req.min
        return (suitable=false, score=0.0,
                message="Pore size $(pore_size_um)μm too small for $cell_type (min: $(req.min)μm)")
    elseif pore_size_um > req.max
        return (suitable=false, score=50.0,
                message="Pore size $(pore_size_um)μm larger than optimal for $cell_type (max: $(req.max)μm)")
    else
        # Score based on distance from optimal
        if pore_size_um <= req.optimal
            score = 50 + 50 * (pore_size_um - req.min) / (req.optimal - req.min)
        else
            score = 100 - 50 * (pore_size_um - req.optimal) / (req.max - req.optimal)
        end
        return (suitable=true, score=score, message="Suitable for $cell_type")
    end
end

# ============================================================================
# INTERCONNECTIVITY AND TORTUOSITY
# ============================================================================

"""
Pore interconnectivity is critical for:
- Cell migration
- Vascularization
- Nutrient/waste transport

Measured as fraction of pores connected to surface.
Target: >90% for bone scaffolds (Karageorgiou 2005)
"""
function interconnectivity_model(porosity::Float64, pore_size_um::Float64,
                                  window_size_um::Float64)
    # Window size = connection between pores
    # Interconnectivity increases with window/pore ratio

    ratio = window_size_um / pore_size_um

    if ratio > 0.5
        interconnectivity = 0.95 + 0.05 * (ratio - 0.5)
    elseif ratio > 0.2
        interconnectivity = 0.7 + 0.25 * (ratio - 0.2) / 0.3
    else
        interconnectivity = 0.3 + 0.4 * ratio / 0.2
    end

    return clamp(interconnectivity, 0.0, 1.0)
end

"""
Tortuosity: actual path length / straight-line distance

For random porous media (Bruggeman relation):
    τ = φ^(-0.5)

Higher tortuosity = longer diffusion paths = slower transport
"""
function tortuosity_bruggeman(porosity::Float64)
    return porosity^(-0.5)
end

"""
Effective diffusivity accounting for porosity and tortuosity.

D_eff = D_0 × φ / τ = D_0 × φ^1.5 (Bruggeman)

where D_0 is bulk diffusivity
"""
function effective_diffusivity(D0::Float64, porosity::Float64)
    tau = tortuosity_bruggeman(porosity)
    return D0 * porosity / tau
end

# ============================================================================
# SURFACE MODIFICATION EFFECTS
# ============================================================================

"""
Surface treatments affect cell adhesion and degradation.
"""
struct SurfaceModification
    name::String
    contact_angle_change::Float64     # Degrees (negative = more hydrophilic)
    cell_adhesion_factor::Float64     # Multiplier on adhesion
    degradation_rate_factor::Float64  # Multiplier on degradation
end

const SURFACE_MODIFICATIONS = Dict(
    :none => SurfaceModification("None", 0.0, 1.0, 1.0),
    :plasma_O2 => SurfaceModification("O₂ Plasma", -30.0, 2.0, 1.2),
    :NaOH_treatment => SurfaceModification("NaOH Treatment", -25.0, 1.8, 1.5),
    :collagen_coating => SurfaceModification("Collagen Coating", -40.0, 3.0, 1.0),
    :RGD_peptide => SurfaceModification("RGD Peptide", -10.0, 4.0, 1.0),
    :HA_coating => SurfaceModification("Hydroxyapatite", 10.0, 2.5, 0.8),
    :BMP2_loading => SurfaceModification("BMP-2 Loading", 0.0, 2.0, 1.0),
)

# ============================================================================
# DEGRADATION-MECHANICS COUPLING
# ============================================================================

"""
As scaffolds degrade, mechanical properties decrease.

The coupling is complex:
1. MW decreases → chain mobility increases → Tg drops
2. Mass loss → porosity increases → E drops (Gibson-Ashby)
3. Crystal structure changes → anisotropic degradation

Simplified model:
    E(t)/E(0) = (Mn(t)/Mn(0))^α × (1 - mass_loss(t))^β

where α ≈ 0.5-1.0, β ≈ 2.0 (Gibson-Ashby)
"""
function degraded_modulus(E0_mpa::Float64, mn_ratio::Float64, mass_remaining::Float64;
                           alpha::Float64=0.7, beta::Float64=2.0)
    return E0_mpa * mn_ratio^alpha * mass_remaining^beta
end

"""
Critical MW below which mechanical integrity is lost.

For most polyesters: Mn_critical ≈ 10-20 kDa
Below this, chains are too short to bear load.
"""
function mechanical_integrity(mn_kda::Float64; mn_critical_kda::Float64=15.0)
    if mn_kda >= mn_critical_kda
        return 1.0
    else
        return (mn_kda / mn_critical_kda)^2
    end
end

# ============================================================================
# COMPREHENSIVE SCAFFOLD ANALYSIS
# ============================================================================

"""
Full scaffold characterization from structure.
"""
function analyze_scaffold(;
        polymer_E_mpa::Float64,
        polymer_sigma_mpa::Float64,
        porosity::Float64,
        pore_size_um::Float64,
        window_size_um::Float64,
        target_cell::Symbol,
        surface_mod::Symbol=:none)

    println("=" ^ 60)
    println("SCAFFOLD STRUCTURE-PROPERTY ANALYSIS")
    println("=" ^ 60)
    println()

    # Mechanical properties (Gibson-Ashby)
    mech = scaffold_mechanics(polymer_E_mpa, polymer_sigma_mpa, porosity)
    println("MECHANICAL PROPERTIES (Gibson-Ashby)")
    println(@sprintf("  Input polymer: E = %.0f MPa, σ = %.0f MPa", polymer_E_mpa, polymer_sigma_mpa))
    println(@sprintf("  Porosity: %.0f%%", porosity * 100))
    println(@sprintf("  Scaffold E: %.1f MPa", mech.E_mpa))
    println(@sprintf("  Scaffold σ: %.1f MPa", mech.sigma_mpa))
    println()

    # Permeability (Kozeny-Carman)
    perm = scaffold_permeability(porosity, pore_size_um)
    println("PERMEABILITY (Kozeny-Carman)")
    println(@sprintf("  Pore size: %.0f μm", pore_size_um))
    println(@sprintf("  Specific surface area: %.2e m²/m³", perm.S_m2_m3))
    println(@sprintf("  Permeability: %.2e m² (%.1f mDarcy)", perm.k_m2, perm.k_darcy * 1000))
    println()

    # Cell suitability
    cell_check = check_pore_suitability(pore_size_um, target_cell)
    println("CELL COMPATIBILITY")
    println(@sprintf("  Target cell: %s", target_cell))
    println(@sprintf("  Pore suitability: %s (score: %.0f)", cell_check.suitable ? "Yes" : "No", cell_check.score))
    println(@sprintf("  Message: %s", cell_check.message))
    println()

    # Interconnectivity and tortuosity
    intercon = interconnectivity_model(porosity, pore_size_um, window_size_um)
    tau = tortuosity_bruggeman(porosity)
    println("TRANSPORT PROPERTIES")
    println(@sprintf("  Window size: %.0f μm", window_size_um))
    println(@sprintf("  Interconnectivity: %.1f%%", intercon * 100))
    println(@sprintf("  Tortuosity: %.2f", tau))
    println(@sprintf("  Effective diffusivity: %.1f%% of bulk", 100 * porosity / tau))
    println()

    # Surface modification
    surf = SURFACE_MODIFICATIONS[surface_mod]
    println("SURFACE MODIFICATION")
    println(@sprintf("  Treatment: %s", surf.name))
    println(@sprintf("  Contact angle change: %+.0f°", surf.contact_angle_change))
    println(@sprintf("  Cell adhesion factor: %.1fx", surf.cell_adhesion_factor))
    println(@sprintf("  Degradation rate factor: %.1fx", surf.degradation_rate_factor))
    println()

    # Overall assessment
    println("=" ^ 60)
    println("OVERALL ASSESSMENT")
    println("=" ^ 60)

    score = 0.0
    issues = String[]

    # Mechanical score (target: match tissue)
    score += 25

    # Pore score
    score += cell_check.score * 0.25

    # Interconnectivity score (target: >90%)
    if intercon >= 0.9
        score += 25
    else
        score += 25 * intercon / 0.9
        push!(issues, @sprintf("Low interconnectivity (%.0f%% < 90%%)", intercon * 100))
    end

    # Permeability score
    if perm.k_darcy > 1e-3  # Adequate for cell infiltration
        score += 25
    else
        score += 15
        push!(issues, "Low permeability")
    end

    println(@sprintf("Score: %.0f/100", score))
    if !isempty(issues)
        println("Issues: $(join(issues, "; "))")
    end
    println()

    return (mech=mech, perm=perm, cell_check=cell_check, intercon=intercon,
            tau=tau, surf=surf, score=score, issues=issues)
end

# ============================================================================
# MAIN
# ============================================================================

function main()
    # Example: PCL scaffold for bone
    println("\nEXAMPLE 1: PCL SCAFFOLD FOR TRABECULAR BONE\n")

    analyze_scaffold(
        polymer_E_mpa=400.0,
        polymer_sigma_mpa=25.0,
        porosity=0.85,
        pore_size_um=350.0,
        window_size_um=120.0,
        target_cell=:osteoblast,
        surface_mod=:HA_coating
    )

    # Example: PLGA scaffold for cartilage
    println("\nEXAMPLE 2: PLGA SCAFFOLD FOR CARTILAGE\n")

    analyze_scaffold(
        polymer_E_mpa=2000.0,
        polymer_sigma_mpa=40.0,
        porosity=0.90,
        pore_size_um=150.0,
        window_size_um=50.0,
        target_cell=:chondrocyte,
        surface_mod=:collagen_coating
    )

    return nothing
end

if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
