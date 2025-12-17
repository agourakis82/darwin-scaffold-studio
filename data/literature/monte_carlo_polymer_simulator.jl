"""
Monte Carlo Polymer Degradation Simulator
==========================================

Validates the entropic causality law C = Omega^(-ln(2)/d) through computational simulation.

This simulator:
1. Creates virtual polymer chains with configurable bond types
2. Simulates degradation by stochastic bond breaking
3. Tracks molecular weight distributions over time
4. Computes coefficient of variation (CV) as a function of Omega
5. Compares simulation results with theoretical predictions
"""

using Random
using Statistics
using Printf

# ============================================================================
# POLYMER DATA STRUCTURES
# ============================================================================

"""
Bond type enumeration for polymer chains
"""
@enum BondType begin
    CHAIN_END      # Terminal bonds (easily accessible)
    RANDOM_BULK    # Random bulk bonds
    CROSSLINK      # Crosslink bonds in networks
    BRANCH_POINT   # Branch points in star polymers
end

"""
Single bond in a polymer chain
"""
struct Bond
    id::Int
    type::BondType
    energy::Float64      # Activation energy (kJ/mol)
    accessibility::Float64  # 0-1, how exposed to water/enzyme
end

"""
Polymer chain representation
"""
mutable struct PolymerChain
    id::Int
    bonds::Vector{Bond}
    molecular_weight::Float64
    monomer_mass::Float64
    is_degraded::Bool
end

"""
Polymer ensemble (collection of chains)
"""
mutable struct PolymerEnsemble
    chains::Vector{PolymerChain}
    temperature::Float64
    pH::Float64
    time::Float64
end

# ============================================================================
# POLYMER CONSTRUCTION
# ============================================================================

"""
Create a linear polymer chain with n monomers

Parameters:
- n_monomers: Number of monomer units
- monomer_mass: Mass of each monomer (Da)
- end_accessibility: Accessibility of chain-end bonds (0-1)
- bulk_accessibility: Accessibility of bulk bonds (0-1)
"""
function create_linear_chain(id::Int, n_monomers::Int;
                              monomer_mass::Float64=100.0,
                              end_accessibility::Float64=0.8,
                              bulk_accessibility::Float64=0.05)
    bonds = Bond[]
    n_bonds = n_monomers - 1

    for i in 1:n_bonds
        if i <= 2 || i >= n_bonds - 1
            # Chain-end bonds
            push!(bonds, Bond(i, CHAIN_END, 80.0, end_accessibility))
        else
            # Bulk bonds
            push!(bonds, Bond(i, RANDOM_BULK, 100.0, bulk_accessibility))
        end
    end

    return PolymerChain(id, bonds, n_monomers * monomer_mass, monomer_mass, false)
end

"""
Create a crosslinked polymer network
"""
function create_crosslinked_network(id::Int, n_monomers::Int, crosslink_density::Float64;
                                     monomer_mass::Float64=100.0)
    bonds = Bond[]
    n_bonds = n_monomers - 1
    n_crosslinks = round(Int, crosslink_density * n_monomers)

    for i in 1:n_bonds
        if i <= 2 || i >= n_bonds - 1
            push!(bonds, Bond(i, CHAIN_END, 80.0, 0.6))
        else
            push!(bonds, Bond(i, RANDOM_BULK, 100.0, 0.02))
        end
    end

    # Add crosslinks
    for i in 1:n_crosslinks
        push!(bonds, Bond(n_bonds + i, CROSSLINK, 120.0, 0.01))
    end

    return PolymerChain(id, bonds, n_monomers * monomer_mass, monomer_mass, false)
end

"""
Create an ensemble of polymer chains
"""
function create_ensemble(n_chains::Int, n_monomers::Int;
                          temperature::Float64=37.0,
                          pH::Float64=7.4,
                          chain_type::Symbol=:linear,
                          kwargs...)
    chains = PolymerChain[]

    for i in 1:n_chains
        if chain_type == :linear
            push!(chains, create_linear_chain(i, n_monomers; kwargs...))
        elseif chain_type == :crosslinked
            push!(chains, create_crosslinked_network(i, n_monomers, 0.05; kwargs...))
        end
    end

    return PolymerEnsemble(chains, temperature, pH, 0.0)
end

# ============================================================================
# DEGRADATION KINETICS
# ============================================================================

"""
Compute Arrhenius rate constant for bond breaking
"""
function arrhenius_rate(bond::Bond, temperature::Float64;
                        A::Float64=1e13,  # Pre-exponential factor (s^-1)
                        R::Float64=8.314)  # Gas constant (J/mol/K)
    T_kelvin = temperature + 273.15
    k = A * exp(-bond.energy * 1000 / (R * T_kelvin))
    return k * bond.accessibility
end

"""
Compute total reaction rate for a chain (sum of all bond rates)
"""
function total_rate(chain::PolymerChain, temperature::Float64)
    if chain.is_degraded || isempty(chain.bonds)
        return 0.0
    end
    return sum(arrhenius_rate(b, temperature) for b in chain.bonds)
end

"""
Select which bond breaks (weighted by rate)
"""
function select_bond_to_break(chain::PolymerChain, temperature::Float64)
    if isempty(chain.bonds)
        return nothing
    end

    rates = [arrhenius_rate(b, temperature) for b in chain.bonds]
    total = sum(rates)

    if total <= 0
        return nothing
    end

    # Weighted random selection
    r = rand() * total
    cumsum_rate = 0.0

    for (i, rate) in enumerate(rates)
        cumsum_rate += rate
        if r <= cumsum_rate
            return i
        end
    end

    return length(chain.bonds)  # Fallback
end

# ============================================================================
# MONTE CARLO SIMULATION
# ============================================================================

"""
Perform one degradation step using Gillespie algorithm
"""
function degradation_step!(ensemble::PolymerEnsemble)
    # Compute total rates for all chains
    chain_rates = [total_rate(c, ensemble.temperature) for c in ensemble.chains]
    total_ensemble_rate = sum(chain_rates)

    if total_ensemble_rate <= 0
        return false  # No more degradation possible
    end

    # Time to next reaction (exponential distribution)
    dt = -log(rand()) / total_ensemble_rate
    ensemble.time += dt

    # Select which chain reacts
    r = rand() * total_ensemble_rate
    cumsum_rate = 0.0
    selected_chain_idx = 1

    for (i, rate) in enumerate(chain_rates)
        cumsum_rate += rate
        if r <= cumsum_rate
            selected_chain_idx = i
            break
        end
    end

    chain = ensemble.chains[selected_chain_idx]

    # Select which bond breaks
    bond_idx = select_bond_to_break(chain, ensemble.temperature)

    if bond_idx === nothing
        return false
    end

    # Break the bond - reduce molecular weight
    broken_bond = chain.bonds[bond_idx]

    if broken_bond.type == CHAIN_END
        # Chain-end scission - lose one monomer
        chain.molecular_weight -= chain.monomer_mass
    else
        # Random/crosslink scission - split chain roughly in half
        # For simplicity, assume uniform position -> lose ~50% on average
        split_fraction = rand()
        chain.molecular_weight *= min(split_fraction, 1 - split_fraction) * 2
    end

    # Remove the broken bond
    deleteat!(chain.bonds, bond_idx)

    # Mark as fully degraded if MW too low
    if chain.molecular_weight < 2 * chain.monomer_mass
        chain.is_degraded = true
    end

    return true
end

"""
Run full degradation simulation

Parameters:
- ensemble: Polymer ensemble
- target_mw_fraction: Stop when average MW drops to this fraction (0-1)
- max_steps: Maximum number of degradation steps
"""
function simulate_degradation!(ensemble::PolymerEnsemble;
                                target_mw_fraction::Float64=0.5,
                                max_steps::Int=100000)
    initial_mw = mean([c.molecular_weight for c in ensemble.chains])
    target_mw = initial_mw * target_mw_fraction

    mw_history = [(0.0, initial_mw)]
    step = 0

    while step < max_steps
        success = degradation_step!(ensemble)

        if !success
            break
        end

        step += 1

        # Record MW every 100 steps
        if step % 100 == 0
            current_mw = mean([c.molecular_weight for c in ensemble.chains])
            push!(mw_history, (ensemble.time, current_mw))

            if current_mw <= target_mw
                break
            end
        end
    end

    return mw_history
end

# ============================================================================
# REPRODUCIBILITY ANALYSIS
# ============================================================================

"""
Run multiple replicate simulations and compute CV

This is the key function that validates the entropic causality law.
"""
function compute_reproducibility(n_replicates::Int, n_chains::Int, n_monomers::Int;
                                  chain_type::Symbol=:linear,
                                  end_accessibility::Float64=0.8,
                                  bulk_accessibility::Float64=0.05,
                                  target_mw_fraction::Float64=0.5,
                                  temperature::Float64=37.0)

    # Run multiple replicates
    final_mws = Float64[]
    degradation_times = Float64[]

    for rep in 1:n_replicates
        ensemble = create_ensemble(n_chains, n_monomers;
                                    temperature=temperature,
                                    chain_type=chain_type,
                                    end_accessibility=end_accessibility,
                                    bulk_accessibility=bulk_accessibility)

        mw_history = simulate_degradation!(ensemble; target_mw_fraction=target_mw_fraction)

        final_mw = mean([c.molecular_weight for c in ensemble.chains])
        push!(final_mws, final_mw)
        push!(degradation_times, ensemble.time)
    end

    # Compute CV
    mean_mw = mean(final_mws)
    std_mw = std(final_mws)
    cv_mw = std_mw / mean_mw * 100

    mean_time = mean(degradation_times)
    std_time = std(degradation_times)
    cv_time = std_time / mean_time * 100

    return (
        cv_mw=cv_mw,
        cv_time=cv_time,
        mean_mw=mean_mw,
        std_mw=std_mw,
        mean_time=mean_time,
        std_time=std_time,
        final_mws=final_mws,
        degradation_times=degradation_times
    )
end

"""
Estimate effective Omega from simulation parameters

Omega = number of reactive configurations
For chain-end: Omega_eff ~ 2 (both ends)
For random: Omega_eff ~ n_bonds * accessibility
"""
function estimate_omega(n_monomers::Int, chain_type::Symbol;
                         end_accessibility::Float64=0.8,
                         bulk_accessibility::Float64=0.05)
    n_bonds = n_monomers - 1

    if chain_type == :linear
        # Chain-end bonds: 4 bonds (2 on each end)
        chain_end_contribution = 4 * end_accessibility

        # Bulk bonds
        bulk_bonds = n_bonds - 4
        bulk_contribution = bulk_bonds * bulk_accessibility

        return chain_end_contribution + bulk_contribution
    elseif chain_type == :crosslinked
        # More complex - crosslinks add more reactive sites
        return n_bonds * 0.1  # Rough estimate
    end

    return n_bonds * 0.05  # Default
end

"""
Theoretical CV prediction from entropic causality law

C = Omega^(-ln(2)/3)
CV_theory ~ (1 - C) * baseline
"""
function theoretical_cv(omega::Float64; baseline_cv::Float64=30.0)
    lambda = log(2) / 3
    C = omega^(-lambda)
    # Higher causality = lower CV
    return baseline_cv * (1 - C)
end

# ============================================================================
# VALIDATION EXPERIMENTS
# ============================================================================

"""
Run systematic validation of entropic causality law
"""
function validate_entropic_causality_law(;
        n_replicates::Int=50,
        n_chains::Int=100,
        monomer_range::Vector{Int}=[50, 100, 200, 500, 1000],
        accessibility_range::Vector{Float64}=[0.01, 0.05, 0.1, 0.2, 0.5])

    println("=" ^ 70)
    println("MONTE CARLO VALIDATION OF ENTROPIC CAUSALITY LAW")
    println("=" ^ 70)
    println()
    println("Parameters:")
    println("  N replicates: $n_replicates")
    println("  N chains/ensemble: $n_chains")
    println("  Monomer counts: $monomer_range")
    println("  Accessibility range: $accessibility_range")
    println()

    results = []

    # Experiment 1: Chain-end vs random scission
    println("-" ^ 70)
    println("EXPERIMENT 1: Chain-end vs Random Scission")
    println("-" ^ 70)

    for n_monomers in [100, 500]
        println("\nN monomers = $n_monomers")

        # Chain-end dominant
        chain_end_result = compute_reproducibility(n_replicates, n_chains, n_monomers;
                                                     chain_type=:linear,
                                                     end_accessibility=0.9,
                                                     bulk_accessibility=0.01)

        omega_chain_end = estimate_omega(n_monomers, :linear;
                                          end_accessibility=0.9,
                                          bulk_accessibility=0.01)

        println(@sprintf("  Chain-end (Omega=%.1f): CV = %.1f%% (theory: %.1f%%)",
                         omega_chain_end, chain_end_result.cv_mw,
                         theoretical_cv(omega_chain_end)))

        push!(results, (type=:chain_end, n=n_monomers, omega=omega_chain_end,
                        cv_sim=chain_end_result.cv_mw,
                        cv_theory=theoretical_cv(omega_chain_end)))

        # Random scission dominant
        random_result = compute_reproducibility(n_replicates, n_chains, n_monomers;
                                                  chain_type=:linear,
                                                  end_accessibility=0.1,
                                                  bulk_accessibility=0.5)

        omega_random = estimate_omega(n_monomers, :linear;
                                       end_accessibility=0.1,
                                       bulk_accessibility=0.5)

        println(@sprintf("  Random (Omega=%.1f): CV = %.1f%% (theory: %.1f%%)",
                         omega_random, random_result.cv_mw,
                         theoretical_cv(omega_random)))

        push!(results, (type=:random, n=n_monomers, omega=omega_random,
                        cv_sim=random_result.cv_mw,
                        cv_theory=theoretical_cv(omega_random)))
    end

    # Experiment 2: CV vs Omega systematic sweep
    println()
    println("-" ^ 70)
    println("EXPERIMENT 2: CV vs Omega Systematic Sweep")
    println("-" ^ 70)

    omega_values = Float64[]
    cv_values = Float64[]

    for bulk_acc in accessibility_range
        result = compute_reproducibility(n_replicates, n_chains, 200;
                                          chain_type=:linear,
                                          end_accessibility=0.5,
                                          bulk_accessibility=bulk_acc)

        omega = estimate_omega(200, :linear;
                                end_accessibility=0.5,
                                bulk_accessibility=bulk_acc)

        push!(omega_values, omega)
        push!(cv_values, result.cv_mw)

        println(@sprintf("  Bulk accessibility=%.2f, Omega=%.1f: CV=%.1f%%",
                         bulk_acc, omega, result.cv_mw))
    end

    # Compute correlation between log(Omega) and CV
    log_omega = log.(omega_values)
    correlation = cor(log_omega, cv_values)

    println()
    println(@sprintf("Correlation(log(Omega), CV) = %.3f", correlation))

    # Experiment 3: Temperature dependence
    println()
    println("-" ^ 70)
    println("EXPERIMENT 3: Temperature Dependence")
    println("-" ^ 70)

    for temp in [25.0, 37.0, 50.0]
        result = compute_reproducibility(n_replicates, n_chains, 200;
                                          chain_type=:linear,
                                          temperature=temp)

        println(@sprintf("  T = %.0f C: CV = %.1f%%", temp, result.cv_mw))
    end

    # Summary
    println()
    println("=" ^ 70)
    println("SUMMARY")
    println("=" ^ 70)

    chain_end_cvs = [r.cv_sim for r in results if r.type == :chain_end]
    random_cvs = [r.cv_sim for r in results if r.type == :random]

    println(@sprintf("Mean CV (chain-end): %.1f%% +/- %.1f%%",
                     mean(chain_end_cvs), std(chain_end_cvs)))
    println(@sprintf("Mean CV (random): %.1f%% +/- %.1f%%",
                     mean(random_cvs), std(random_cvs)))

    # Compare with theory
    theory_errors = [abs(r.cv_sim - r.cv_theory) for r in results]
    println(@sprintf("Mean theory error: %.1f%%", mean(theory_errors)))

    return results
end

# ============================================================================
# LARGE-SCALE SIMULATION
# ============================================================================

"""
Run large-scale Monte Carlo with 10,000 replicates
"""
function large_scale_validation(;n_replicates::Int=10000, n_chains::Int=50)
    println("=" ^ 70)
    println("LARGE-SCALE MONTE CARLO VALIDATION (N=$n_replicates)")
    println("=" ^ 70)
    println()

    # Chain-end scission (low Omega)
    println("Running chain-end scission simulation...")
    chain_end = compute_reproducibility(n_replicates, n_chains, 100;
                                          chain_type=:linear,
                                          end_accessibility=0.9,
                                          bulk_accessibility=0.01)

    omega_ce = estimate_omega(100, :linear; end_accessibility=0.9, bulk_accessibility=0.01)

    println(@sprintf("\nChain-end scission (Omega_eff = %.1f):", omega_ce))
    println(@sprintf("  CV = %.2f%% +/- %.2f%%", chain_end.cv_mw,
                     std(chain_end.final_mws)/mean(chain_end.final_mws)/sqrt(n_replicates)*100*1.96))
    println(@sprintf("  Theory prediction: %.2f%%", theoretical_cv(omega_ce)))

    # Random scission (high Omega)
    println("\nRunning random scission simulation...")
    random = compute_reproducibility(n_replicates, n_chains, 100;
                                       chain_type=:linear,
                                       end_accessibility=0.1,
                                       bulk_accessibility=0.5)

    omega_r = estimate_omega(100, :linear; end_accessibility=0.1, bulk_accessibility=0.5)

    println(@sprintf("\nRandom scission (Omega_eff = %.1f):", omega_r))
    println(@sprintf("  CV = %.2f%% +/- %.2f%%", random.cv_mw,
                     std(random.final_mws)/mean(random.final_mws)/sqrt(n_replicates)*100*1.96))
    println(@sprintf("  Theory prediction: %.2f%%", theoretical_cv(omega_r)))

    # Statistical comparison
    println()
    println("-" ^ 70)
    println("STATISTICAL COMPARISON")
    println("-" ^ 70)

    # Welch's t-test
    n1, n2 = length(chain_end.final_mws), length(random.final_mws)
    m1, m2 = mean(chain_end.final_mws), mean(random.final_mws)
    s1, s2 = std(chain_end.final_mws), std(random.final_mws)

    se = sqrt(s1^2/n1 + s2^2/n2)
    t_stat = (m1 - m2) / se

    # Cohen's d
    pooled_std = sqrt(((n1-1)*s1^2 + (n2-1)*s2^2) / (n1+n2-2))
    cohens_d = abs(m1 - m2) / pooled_std

    println(@sprintf("Welch's t-statistic: %.2f", t_stat))
    println(@sprintf("Cohen's d: %.2f", cohens_d))
    println(@sprintf("Effect size: %s", cohens_d < 0.2 ? "SMALL" : cohens_d < 0.8 ? "MEDIUM" : "LARGE"))

    return (chain_end=chain_end, random=random, omega_ce=omega_ce, omega_r=omega_r)
end

# ============================================================================
# MAIN EXECUTION
# ============================================================================

"""
Run all validation experiments
"""
function main()
    println()
    println("*" ^ 70)
    println("*  MONTE CARLO POLYMER DEGRADATION SIMULATOR")
    println("*  Validating Entropic Causality: C = Omega^(-ln(2)/d)")
    println("*" ^ 70)
    println()

    # Quick validation
    results = validate_entropic_causality_law(n_replicates=30, n_chains=50)

    println()
    println("Validation complete!")
    println()

    return results
end

# Run if executed directly
if abspath(PROGRAM_FILE) == @__FILE__
    main()
end
