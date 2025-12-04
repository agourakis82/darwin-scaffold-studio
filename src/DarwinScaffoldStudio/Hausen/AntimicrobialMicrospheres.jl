module AntimicrobialMicrospheres

using DifferentialEquations

export simulate_chlorhexidine_release, predict_inhibition_zone

"""
Hausen-Specialized Antimicrobial Module
Based on: "Chlorhexidine-loaded hydroxyapatite microspheres as an antimicrobial delivery system" (2015)

Models:
1. Dual-stage release kinetics (Burst + Sustained)
2. Diffusion through scaffold matrix
3. Bacterial inhibition zone (S. aureus, E. coli)
4. Cytotoxicity vs. Antimicrobial efficacy trade-off
"""

struct MicrosphereSystem
    drug_load::Float64      # mg/g
    microsphere_radius::Float64
    scaffold_porosity::Float64
    polymer_matrix::String  # "PLGA", "Collagen", "HA"
end

"""
    simulate_chlorhexidine_release(system, time_span)

Simulate release profile using Higuchi or Korsmeyer-Peppas model modified for microspheres.
"""
function simulate_chlorhexidine_release(system::MicrosphereSystem, hours::Float64)
    # Korsmeyer-Peppas: Mt/M∞ = k * t^n
    # For spheres, n ≈ 0.43 (Fickian) to 0.85 (Erosion)
    
    n = 0.45 # Diffusion dominant
    k = 0.1  # Rate constant
    
    times = 0.0:1.0:hours
    release = [system.drug_load * (k * t^n) for t in times]
    
    # Clamp to max load
    release = min.(release, system.drug_load)
    
    return Dict(
        "times" => collect(times),
        "cumulative_release" => release,
        "burst_release" => release[min(24, length(release))] # 24h burst
    )
end

"""
    predict_inhibition_zone(release_profile, bacteria_type)

Predict radius of inhibition zone based on drug diffusion and MIC (Minimum Inhibitory Concentration).
"""
function predict_inhibition_zone(release_profile, bacteria::String="S. aureus")
    # MIC values (µg/mL)
    mic = bacteria == "S. aureus" ? 2.0 : 4.0 # Higher for E. coli
    
    # Diffusion in agar/tissue (Fick's 2nd Law solution)
    # C(r,t) = (M / 4πDt) * exp(-r^2 / 4Dt)
    
    D_drug = 1e-6 # cm2/s
    t_check = 24.0 * 3600.0 # 24 hours in seconds
    M_released = release_profile["cumulative_release"][25] # at 24h
    
    # Solve for r where C(r) = MIC
    # r = sqrt( -4Dt * ln( C * 4πDt / M ) )
    
    term = (mic * 1e-3) * (4 * π * D_drug * t_check) / M_released
    
    if term >= 1.0
        return 0.0 # No inhibition (concentration too low)
    end
    
    r_zone = sqrt(-4 * D_drug * t_check * log(term))
    
    return r_zone * 10.0 # Convert cm to mm
end

"""
    optimize_loading_concentration(target_zone_mm, max_cytotoxicity)

Find optimal drug loading that kills bacteria but spares osteoblasts.
Ref: Hausen et al. (2015) - Balance between antimicrobial and osteoconductive properties.
"""
function optimize_loading_concentration(target_zone::Float64)
    loadings = 1.0:1.0:20.0 # % wt
    
    for load in loadings
        sys = MicrosphereSystem(load, 50.0, 0.5, "HA")
        rel = simulate_chlorhexidine_release(sys, 48.0)
        zone = predict_inhibition_zone(rel)
        
        # Cytotoxicity threshold (empirical)
        # >10% loading starts affecting osteoblast viability
        cytotoxicity = load > 10.0 ? "High" : "Low"
        
        if zone >= target_zone && cytotoxicity == "Low"
            return Dict(
                "optimal_load" => load,
                "predicted_zone" => zone,
                "cytotoxicity" => cytotoxicity
            )
        end
    end
    
    return Dict("error" => "No safe loading found for target zone")
end

end # module
