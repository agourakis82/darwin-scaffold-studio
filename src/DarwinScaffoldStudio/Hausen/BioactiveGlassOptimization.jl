module BioactiveGlassOptimization

using DifferentialEquations

export optimize_niobium_doping, predict_bioactivity_index

"""
Hausen-Specialized Bioactive Glass Module
Based on: "In vitro and in vivo osteogenic potential of niobium‐doped 45S5 bioactive glass" (2020)

Models the effect of Niobium (Nb) substitution in 45S5 Bioglass on:
1. Dissolution rate (Si, Ca, P release)
2. pH changes
3. HCA (Hydroxycarbonate Apatite) layer formation kinetics
4. Osteogenic gene expression (ALP, OCN)
"""

struct BioactiveGlass
    composition::Dict{Symbol, Float64}  # SiO2, Na2O, CaO, P2O5, Nb2O5
    surface_area::Float64
    porosity::Float64
end

"""
    optimize_niobium_doping(base_glass, target_properties)

Find optimal Nb concentration (e.g., 1%, 2.5%, 5%) to maximize osteogenesis
while maintaining bioactivity.
"""
function optimize_niobium_doping(target_dissolution_rate::Float64)
    # Nb substitution range (0 - 5 mol%)
    nb_concentrations = 0.0:0.5:5.0
    results = []
    
    for nb in nb_concentrations
        glass = create_nb_doped_glass(nb)
        
        # Simulate dissolution
        dissolution = simulate_dissolution(glass, 14.0) # 14 days
        
        # Simulate HCA formation
        hca_layer = simulate_hca_formation(glass, dissolution)
        
        # Simulate Osteogenesis (ALP activity)
        alp_activity = predict_osteogenesis(glass, hca_layer)
        
        push!(results, Dict(
            "nb_conc" => nb,
            "dissolution_rate" => dissolution["rate"],
            "hca_thickness" => hca_layer["thickness"],
            "alp_activity" => alp_activity
        ))
    end
    
    # Find optimal
    best = sort(results, by=x->x["alp_activity"], rev=true)[1]
    
    @info "Optimal Nb doping found: $(best["nb_conc"]) mol%"
    return best
end

function create_nb_doped_glass(nb_conc::Float64)
    # Base 45S5: 45% SiO2, 24.5% Na2O, 24.5% CaO, 6% P2O5
    # Nb replaces SiO2 or CaO depending on network connectivity model
    # Here we assume partial replacement of SiO2 for network modification
    
    return BioactiveGlass(
        Dict(
            :SiO2 => 45.0 - nb_conc,
            :Na2O => 24.5,
            :CaO => 24.5,
            :P2O5 => 6.0,
            :Nb2O5 => nb_conc
        ),
        100.0, # m2/g
        0.0    # powder
    )
end

function simulate_dissolution(glass::BioactiveGlass, days::Float64)
    # Nb stabilizes the glass network -> slower dissolution
    # Rate k ~ 1 / (1 + α * [Nb])
    nb = glass.composition[:Nb2O5]
    k_base = 1.0
    k_eff = k_base / (1.0 + 0.5 * nb)
    
    return Dict("rate" => k_eff, "total_si_release" => k_eff * days * 10.0)
end

function simulate_hca_formation(glass::BioactiveGlass, dissolution)
    # HCA formation depends on Ca/P release and surface nucleation sites
    # Nb enhances surface biocompatibility despite slower ion release
    nb = glass.composition[:Nb2O5]
    
    # Empirical model from Hausen et al. findings
    # "Nb-doped glasses showed enhanced cell viability"
    nucleation_factor = 1.0 + 0.2 * nb
    thickness = dissolution["total_si_release"] * 0.5 * nucleation_factor
    
    return Dict("thickness" => thickness)
end

function predict_osteogenesis(glass::BioactiveGlass, hca)
    # ALP activity peaks at specific Nb concentrations (usually ~1-2.5%)
    nb = glass.composition[:Nb2O5]
    
    # Gaussian peak around 2.5% Nb
    alp_stimulation = 100.0 + 50.0 * exp(-((nb - 2.5)^2) / 2.0)
    
    return alp_stimulation
end

end # module
