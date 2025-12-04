module Optimization

using ..Types
using ..ScaffoldOptimizer: Optimizer
using ..Topology

export optimize_scaffold_thesis

"""
    optimize_scaffold_thesis(optimizer, original_volume, params, material, use_case)

Thesis-level optimization loop:
1. Generate candidate scaffolds (parametric)
2. Evaluate KEC metrics (Bio-activity)
3. Evaluate Mechanical properties (Stiffness/Strength)
4. Select optimal design based on Material + Use Case constraints
"""
function optimize_scaffold_thesis(
    optimizer::Optimizer,
    original_volume::AbstractArray,
    params::ScaffoldParameters,
    material::String,
    use_case::String
)
    # 1. Define Constraints based on Use Case
    constraints = get_constraints(use_case)

    # 2. Define Material Properties
    mat_props = get_material_properties(material)

    # 3. Optimization Search (Simplified Grid Search for Demo)
    # In a real thesis, this would be a Genetic Algorithm or Bayesian Optimization

    best_score = -Inf
    best_volume = original_volume
    best_metrics = Dict{String, Any}()

    # Search space: Pore Size +/- 50um, Porosity +/- 5%
    pore_sizes = [params.pore_size_target_um - 50, params.pore_size_target_um, params.pore_size_target_um + 50]
    porosities = [params.porosity_target - 0.05, params.porosity_target, params.porosity_target + 0.05]

    for p_size in pore_sizes
        for porosity in porosities
            if p_size < 50 || porosity > 0.99 continue end

            # Generate candidate
            candidate_params = ScaffoldParameters(
                porosity, p_size, params.interconnectivity_target,
                params.tortuosity_target, params.volume_mm3, params.resolution_um
            )

            # Generate using freeze-casting (default for now)
            candidate_vol = optimizer.generate_optimized_scaffold(candidate_params, "freeze-casting")

            # Evaluate Metrics
            basic_metrics = optimizer.analyze_scaffold(candidate_vol)
            kec_metrics = compute_kec_metrics(candidate_vol, params.resolution_um)

            # Calculate Mechanical Properties (Gibson-Ashby)
            E_scaffold = (1 - basic_metrics["porosity"])^2 * mat_props["E_solid"]

            # Score Candidate
            score = evaluate_candidate(
                basic_metrics, kec_metrics, E_scaffold, constraints
            )

            if score > best_score
                best_score = score
                best_volume = candidate_vol
                best_metrics = merge(basic_metrics, kec_metrics)
                best_metrics["elastic_modulus"] = E_scaffold
                best_metrics["score"] = score
            end
        end
    end

    return (
        optimized_volume = best_volume,
        metrics = best_metrics
    )
end

function get_constraints(use_case::String)
    if use_case == "Bone"
        return (
            min_modulus = 100.0, # MPa
            min_pore_size = 100.0, # um
            target_curvature = "low" # Flat surfaces for osteoblasts
        )
    elseif use_case == "Cartilage"
        return (
            min_modulus = 5.0, # MPa
            min_pore_size = 200.0, # um
            target_curvature = "high" # Curved for chondrocytes
        )
    else # General
        return (
            min_modulus = 1.0,
            min_pore_size = 100.0,
            target_curvature = "any"
        )
    end
end

function get_material_properties(material::String)
    if material == "PCL"
        return Dict("E_solid" => 400.0) # MPa
    elseif material == "PLA"
        return Dict("E_solid" => 3500.0) # MPa
    elseif material == "Hydrogel"
        return Dict("E_solid" => 0.1) # MPa
    else
        return Dict("E_solid" => 100.0) # Generic
    end
end

function evaluate_candidate(basic, kec, E, constraints)
    score = 0.0

    # 1. Mechanical Constraint (Hard Constraint)
    if E < constraints.min_modulus
        return -Inf
    end

    if basic["mean_pore_size_um"] < constraints.min_pore_size
        return -Inf
    end

    # 2. Bio-activity Objective (Soft Constraint)
    # Maximize Entropy (Complexity)
    score += kec["entropy_shannon"] * 10.0

    # Curvature objective
    if constraints.target_curvature == "high"
        score += kec["curvature_mean"] * 5.0
    elseif constraints.target_curvature == "low"
        score -= abs(kec["curvature_mean"]) * 5.0
    end

    return score
end

end # module
