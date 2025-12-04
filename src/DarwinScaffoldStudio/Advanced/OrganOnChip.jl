module OrganOnChip

using DifferentialEquations

export create_multi_organ_system, simulate_organ_crosstalk, predict_systemic_response

"""
Organ-on-Chip Multi-System Modeling (2025 SOTA)

Integrates multiple organ compartments:
- Liver (metabolism)
- Heart (circulation)
- Kidney (filtration)
- Lung (gas exchange)
- Scaffold/Target tissue

Models organ crosstalk and systemic drug response.
"""

struct OrganCompartment
    name::String
    volume::Float64  # mL
    flow_rate::Float64  # mL/min
    metabolic_function::Function
    cell_types::Vector{String}
end

"""
    create_multi_organ_system(scaffold_config)

Create interconnected multi-organ chip model.
Each organ = compartment with input/output flows.
"""
function create_multi_organ_system(scaffold_tissue::String="bone")
    # Physiologically realistic organ volumes (scaled for chip)
    organs = [
        OrganCompartment(
            "liver",
            0.5,  # mL (scaled down from 1800 mL)
            0.1,  # mL/min
            liver_metabolism,
            ["hepatocyte", "kupffer_cell"]
        ),
        OrganCompartment(
            "heart",
            0.2,
            0.3,  # Higher flow
            cardiac_function,
            ["cardiomyocyte", "endothelial"]
        ),
        OrganCompartment(
            "kidney",
            0.3,
            0.05,
            renal_filtration,
            ["podocyte", "tubular_cell"]
        ),
        OrganCompartment(
            "lung",
            0.4,
            0.2,
            gas_exchange,
            ["pneumocyte", "alveolar"]
        ),
        OrganCompartment(
            scaffold_tissue,
            0.1,
            0.02,
            tissue_response,
            [scaffold_tissue * "_cell", "osteoblast"]
        )
    ]
    
    # Define fluidic circuit (mimics circulation)
    circuit = Dict(
        "heart" => ["lung", "liver", "kidney", scaffold_tissue],
        "lung" => ["heart"],
        "liver" => ["kidney"],
        "kidney" => ["heart"],
        scaffold_tissue => ["heart"]
    )
    
    return Dict("organs" => organs, "circuit" => circuit)
end

"""
    simulate_organ_crosstalk(system, drug_dose, time_points)

Simulate drug distribution and metabolic crosstalk.
Uses coupled ODEs for each compartment.
"""
function simulate_organ_crosstalk(system::Dict, 
                                  drug_dose::Float64,  # mg
                                  time_points::Vector{Float64})
    
    organs = system["organs"]
    circuit = system["circuit"]
    n_organs = length(organs)
    
    # State variables: drug concentration in each organ
    # u = [C_liver, C_heart, C_kidney, C_lung, C_scaffold]
    
    function organ_odes!(du, u, p, t)
        # Extract parameters
        drug_dose_rate = p[1]
        
        for (i, organ) in enumerate(organs)
            # Inflow from connected organs
            inflow = 0.0
            for (j, source_organ) in enumerate(organs)
                if organ.name in get(circuit, source_organ.name, [])
                    # Flow from source to this organ
                    inflow += source_organ.flow_rate * u[j] / source_organ.volume
                end
            end
            
            # Outflow
            outflow = organ.flow_rate * u[i] / organ.volume
            
            # Metabolism/clearance
            metabolism = organ.metabolic_function(u[i], t)
            
            # Drug input (only for heart initially)
            drug_input = (organ.name == "heart" && t < 1.0) ? drug_dose_rate : 0.0
            
            # ODE: dC/dt = inflow - outflow - metabolism + drug_input
            du[i] = inflow - outflow - metabolism + drug_input
        end
    end
    
    # Initial conditions (zero drug)
    u0 = zeros(n_organs)
    
    # Parameters
    p = [drug_dose]  # mg/min infusion
    
    # Solve ODE
    tspan = (0.0, maximum(time_points))
    prob = ODEProblem(organ_odes!, u0, tspan, p)
    sol = solve(prob, Tsit5())
    
    # Extract concentrations at requested timepoints
    concentrations = Dict()
    for (i, organ) in enumerate(organs)
        concentrations[organ.name] = [sol(t)[i] for t in time_points]
    end
    
    return concentrations
end

"""
    predict_systemic_response(organ_concentrations, endpoints)

Predict systemic endpoints (toxicity, efficacy) from multi-organ data.
"""
function predict_systemic_response(organ_conc::Dict; 
                                   toxic_threshold::Float64=10.0)
    
    # Check for organ-specific toxicity
    liver_toxic = maximum(organ_conc["liver"]) > toxic_threshold
    kidney_toxic = maximum(organ_conc["kidney"]) > toxic_threshold * 0.8
    cardiac_toxic = maximum(organ_conc["heart"]) > toxic_threshold * 1.2
    
    # Therapeutic effect (in target tissue/scaffold)
    scaffold_exposure = mean(organ_conc[end])  # Assuming last is scaffold
    therapeutic_success = scaffold_exposure > 1.0 && scaffold_exposure < 5.0
    
    # Systemic prediction
    return Dict(
        "liver_toxicity" => liver_toxic,
        "kidney_toxicity" => kidney_toxic,
        "cardiac_toxicity" => cardiac_toxic,
        "therapeutic_window" => therapeutic_success,
        "max_scaffold_conc" => maximum(organ_conc[end]),
        "recommendation" => therapeutic_success && !liver_toxic ? "Safe and effective" : "Adjust dose"
    )
end

# Organ-specific metabolic functions
function liver_metabolism(C, t)
    # First-order elimination + Michaelis-Menten
    Km = 2.0  # mg/mL
    Vmax = 0.5  # mg/mL/min
    k_elim = 0.1  # 1/min
    
    return k_elim * C + (Vmax * C) / (Km + C)
end

function cardiac_function(C, t)
    # Minimal metabolism, mostly circulation
    return 0.01 * C
end

function renal_filtration(C, t)
    # Glomerular filtration rate dependent
    GFR_fraction = 0.2  # 20% filtered
    return GFR_fraction * C
end

function gas_exchange(C, t)
    # Minimal drug metabolism in lung
    return 0.05 * C
end

function tissue_response(C, t)
    # Scaffold/tissue: drug uptake
    k_uptake = 0.15
    return k_uptake * C
end

end # module
