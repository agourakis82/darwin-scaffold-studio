"""
entropic_causality_statistics.jl

COMPREHENSIVE STATISTICAL ANALYSIS

This script implements rigorous statistical methods:
1. Expanded dataset (25+ polymers)
2. Bootstrap confidence intervals
3. Hypothesis testing (t-tests, ANOVA, chi-squared)
4. Effect size calculations (Cohen's d, eta-squared)
5. Monte Carlo with large sample sizes (N=10,000+)
6. Bayesian parameter estimation
7. Cross-validation
"""

using Statistics: mean, std, var, cor, cov, median, quantile
using LinearAlgebra: norm, det, inv, eigvals
using Random: seed!, rand, randn, shuffle

# ============================================================================
# I. EXPANDED LITERATURE DATABASE
# ============================================================================

"""
Extended database of polymer degradation reproducibility data.

Sources:
1. PMC7611508: Poly(sebacic anhydride) studies
2. ScienceDirect 2022: 8-lab inter-laboratory study (5 polymers)
3. ScienceDirect 2023: Multi-laboratory evaluation (OECD 301F/301B)
4. Newton 2025: Polymer degradation database (41 polymers)
5. Literature meta-analysis: PLA, PLGA, PCL, chitosan studies
6. Biodegradation 2025: Device variability study
"""

struct PolymerReproducibilityData
    name::String
    source::String
    measurement_type::Symbol      # :rate_constant, :mineralization, :mass_loss, :mw_change
    mean_value::Float64
    std_dev::Float64
    n_replicates::Int
    n_laboratories::Int           # 1 = single lab, >1 = inter-laboratory
    omega_estimated::Float64      # configurational entropy estimate
    scission_mode::Symbol         # :chain_end, :random, :enzymatic, :mixed
    temperature_c::Float64
    ph::Float64
    notes::String
end

# Expanded dataset with 30+ entries
const EXPANDED_POLYMER_DATA = [
    # ==========================================================================
    # PMC7611508: Poly(sebacic anhydride) degradation studies
    # ==========================================================================
    PolymerReproducibilityData(
        "PSA overall", "PMC7611508", :rate_constant,
        0.07, 0.01, 3, 1, 100.0, :random, 37.0, 7.4, "FTIR measurement"
    ),
    PolymerReproducibilityData(
        "PSA sample 1", "PMC7611508", :rate_constant,
        0.029, 0.008, 3, 1, 100.0, :random, 37.0, 7.4, "Thin film"
    ),
    PolymerReproducibilityData(
        "PSA sample 2", "PMC7611508", :rate_constant,
        0.016, 0.005, 3, 1, 100.0, :random, 37.0, 7.4, "Thick film"
    ),
    PolymerReproducibilityData(
        "PSA sample 3", "PMC7611508", :rate_constant,
        0.010, 0.004, 3, 1, 100.0, :random, 37.0, 7.4, "Bulk"
    ),

    # ==========================================================================
    # ScienceDirect 2022/2023: Multi-laboratory studies (OECD 301F/301B)
    # ==========================================================================
    PolymerReproducibilityData(
        "PEG 35000", "Interlaboratory2023", :mineralization,
        0.89, 0.055, 24, 8, 1000.0, :random, 22.0, 7.0, "8 labs, 4 countries"
    ),
    PolymerReproducibilityData(
        "PVA 18-88", "Interlaboratory2023", :mineralization,
        0.85, 0.074, 24, 8, 500.0, :random, 22.0, 7.0, "8 labs, 4 countries"
    ),
    PolymerReproducibilityData(
        "CMC DS 0.6", "Interlaboratory2023", :mineralization,
        0.44, 0.13, 24, 8, 200.0, :random, 22.0, 7.0, "Carboxymethyl cellulose"
    ),
    PolymerReproducibilityData(
        "Modified guar gum", "Interlaboratory2023", :mineralization,
        0.48, 0.041, 24, 8, 150.0, :random, 22.0, 7.0, "Modified polysaccharide"
    ),
    PolymerReproducibilityData(
        "MCC reference", "Interlaboratory2023", :mineralization,
        0.88, 0.062, 24, 8, 2.0, :chain_end, 22.0, 7.0, "Microcrystalline cellulose"
    ),

    # ==========================================================================
    # PLA degradation studies (from kinetics literature)
    # ==========================================================================
    PolymerReproducibilityData(
        "PLA pH 2.0", "ScienceDirect2012", :rate_constant,
        0.015, 0.003, 3, 1, 150.0, :random, 40.0, 2.0, "Acidic hydrolysis"
    ),
    PolymerReproducibilityData(
        "PLA pH 7.4", "ScienceDirect2012", :rate_constant,
        0.0035, 0.0008, 3, 1, 150.0, :random, 37.0, 7.4, "Neutral hydrolysis"
    ),
    PolymerReproducibilityData(
        "PLA pH 12", "ScienceDirect2012", :rate_constant,
        0.045, 0.012, 3, 1, 150.0, :random, 37.0, 12.0, "Alkaline hydrolysis"
    ),
    PolymerReproducibilityData(
        "PLA 40C", "IECResearch2025", :rate_constant,
        0.0012, 0.0003, 5, 1, 150.0, :random, 40.0, 7.4, "Temperature study"
    ),
    PolymerReproducibilityData(
        "PLA 60C", "IECResearch2025", :rate_constant,
        0.0089, 0.0022, 5, 1, 150.0, :random, 60.0, 7.4, "Temperature study"
    ),
    PolymerReproducibilityData(
        "PLA 80C", "IECResearch2025", :rate_constant,
        0.058, 0.015, 5, 1, 150.0, :random, 80.0, 7.4, "Temperature study"
    ),

    # ==========================================================================
    # PLGA degradation studies
    # ==========================================================================
    PolymerReproducibilityData(
        "PLGA 50:50", "JBiomedMat2018", :rate_constant,
        0.023, 0.006, 6, 1, 300.0, :random, 37.0, 7.4, "Fastest degrading ratio"
    ),
    PolymerReproducibilityData(
        "PLGA 75:25", "JBiomedMat2018", :rate_constant,
        0.011, 0.003, 6, 1, 250.0, :random, 37.0, 7.4, "Intermediate ratio"
    ),
    PolymerReproducibilityData(
        "PLGA 85:15", "JBiomedMat2018", :rate_constant,
        0.0065, 0.0018, 6, 1, 200.0, :random, 37.0, 7.4, "Slowest PLGA"
    ),

    # ==========================================================================
    # PCL degradation studies
    # ==========================================================================
    PolymerReproducibilityData(
        "PCL bulk", "PolymerJ2003", :rate_constant,
        0.00015, 0.00004, 4, 1, 80.0, :random, 37.0, 7.4, "Very slow degradation"
    ),
    PolymerReproducibilityData(
        "PCL film", "PolymerJ2003", :rate_constant,
        0.00023, 0.00007, 4, 1, 80.0, :random, 37.0, 7.4, "Thin film, faster"
    ),

    # ==========================================================================
    # Chitosan degradation studies (PMC8145880)
    # ==========================================================================
    PolymerReproducibilityData(
        "Chitosan acetic", "PMC8145880", :rate_constant,
        0.0085, 0.0021, 3, 1, 50.0, :mixed, 25.0, 4.0, "Acetic acid solution"
    ),
    PolymerReproducibilityData(
        "Chitosan lactic", "PMC8145880", :rate_constant,
        0.0072, 0.0019, 3, 1, 50.0, :mixed, 25.0, 4.0, "Lactic acid solution"
    ),
    PolymerReproducibilityData(
        "Chitosan citric", "PMC8145880", :rate_constant,
        0.0095, 0.0028, 3, 1, 50.0, :mixed, 25.0, 4.0, "Citric acid solution"
    ),

    # ==========================================================================
    # Chain-end scission polymers (low omega)
    # ==========================================================================
    PolymerReproducibilityData(
        "Cellulose chain-end", "Newton2025", :mw_change,
        0.846, 0.05, 10, 1, 2.0, :chain_end, 37.0, 7.4, "Enzymatic"
    ),
    PolymerReproducibilityData(
        "Alginate chain-end", "Newton2025", :mw_change,
        0.792, 0.06, 10, 1, 2.0, :chain_end, 37.0, 7.4, "Enzymatic"
    ),
    PolymerReproducibilityData(
        "Dextran chain-end", "Newton2025", :mw_change,
        0.823, 0.048, 10, 1, 2.0, :chain_end, 37.0, 7.4, "Enzymatic"
    ),

    # ==========================================================================
    # Device variability study (Biodegradation 2025)
    # ==========================================================================
    PolymerReproducibilityData(
        "Cellulose OXITOP", "Biodeg2025", :mineralization,
        0.92, 0.045, 6, 2, 2.0, :chain_end, 20.0, 7.0, "OXITOP device"
    ),
    PolymerReproducibilityData(
        "Cellulose VELP", "Biodeg2025", :mineralization,
        0.78, 0.065, 6, 2, 2.0, :chain_end, 20.0, 7.0, "VELP device"
    ),

    # ==========================================================================
    # Additional random scission polymers
    # ==========================================================================
    PolymerReproducibilityData(
        "Hyaluronic acid", "Newton2025", :mw_change,
        0.988, 0.008, 10, 1, 2777.0, :random, 37.0, 7.4, "Very high omega"
    ),
    PolymerReproducibilityData(
        "Chondroitin sulfate", "Newton2025", :mw_change,
        0.965, 0.015, 10, 1, 1500.0, :random, 37.0, 7.4, "High omega"
    ),
]

# ============================================================================
# II. BASIC STATISTICAL FUNCTIONS
# ============================================================================

"""
Compute coefficient of variation.
"""
cv(data::PolymerReproducibilityData) = data.std_dev / data.mean_value

"""
Compute standard error of the mean.
"""
sem(data::PolymerReproducibilityData) = data.std_dev / sqrt(data.n_replicates)

"""
Compute 95% confidence interval (t-distribution).
"""
function ci95(data::PolymerReproducibilityData)
    # t-value for 95% CI with n-1 degrees of freedom
    # Approximation for small n
    n = data.n_replicates
    t_crit = n <= 2 ? 12.71 : (n <= 5 ? 2.78 : (n <= 10 ? 2.26 : 1.96))
    margin = t_crit * sem(data)
    return (data.mean_value - margin, data.mean_value + margin)
end

"""
Convert CV to causality measure.
"""
function cv_to_causality(cv_val::Float64; method::Symbol=:bounded)
    if method == :linear
        return max(0.0, 1.0 - cv_val)
    elseif method == :bounded
        return 1.0 / (1.0 + cv_val)
    elseif method == :exponential
        return exp(-cv_val)
    else
        error("Unknown method: $method")
    end
end

"""
Compute effective omega from observed causality.
"""
function omega_from_causality(C::Float64; lambda::Float64=log(2)/3)
    if C > 0 && C < 1
        return C^(-1/lambda)
    else
        return NaN
    end
end

# ============================================================================
# III. BOOTSTRAP CONFIDENCE INTERVALS
# ============================================================================

"""
Generate bootstrap samples from a dataset.
"""
function bootstrap_samples(data::Vector{Float64}, n_bootstrap::Int=10000)
    n = length(data)
    samples = Matrix{Float64}(undef, n, n_bootstrap)
    for b in 1:n_bootstrap
        indices = rand(1:n, n)
        samples[:, b] = data[indices]
    end
    return samples
end

"""
Bootstrap confidence interval for a statistic.
"""
function bootstrap_ci(data::Vector{Float64}, stat_func::Function;
                       n_bootstrap::Int=10000, ci_level::Float64=0.95)
    # Generate bootstrap statistics
    n = length(data)
    boot_stats = Float64[]

    for _ in 1:n_bootstrap
        indices = rand(1:n, n)
        boot_sample = data[indices]
        push!(boot_stats, stat_func(boot_sample))
    end

    # Percentile method
    alpha = 1 - ci_level
    lower = quantile(boot_stats, alpha/2)
    upper = quantile(boot_stats, 1 - alpha/2)

    return (lower, upper, mean(boot_stats), std(boot_stats))
end

"""
Bootstrap the CV -> Causality -> Omega_eff pipeline.
"""
function bootstrap_omega_eff(polymer::PolymerReproducibilityData;
                              n_bootstrap::Int=10000)
    # Simulate original measurements
    seed!(42)
    measurements = polymer.mean_value .+ polymer.std_dev .* randn(polymer.n_replicates)

    omega_effs = Float64[]

    for _ in 1:n_bootstrap
        # Resample
        indices = rand(1:polymer.n_replicates, polymer.n_replicates)
        boot_sample = measurements[indices]

        # Compute CV -> C -> Omega_eff
        boot_mean = mean(boot_sample)
        boot_std = std(boot_sample)
        boot_cv = boot_std / abs(boot_mean)
        boot_C = cv_to_causality(boot_cv)
        boot_omega = omega_from_causality(boot_C)

        if !isnan(boot_omega) && boot_omega > 0 && boot_omega < 1e6
            push!(omega_effs, boot_omega)
        end
    end

    if isempty(omega_effs)
        return (NaN, NaN, NaN, NaN)
    end

    return (
        quantile(omega_effs, 0.025),
        quantile(omega_effs, 0.975),
        mean(omega_effs),
        std(omega_effs)
    )
end

# ============================================================================
# IV. HYPOTHESIS TESTING
# ============================================================================

"""
Two-sample t-test (Welch's t-test for unequal variances).
"""
function welch_ttest(group1::Vector{Float64}, group2::Vector{Float64})
    n1, n2 = length(group1), length(group2)
    m1, m2 = mean(group1), mean(group2)
    s1, s2 = std(group1), std(group2)

    # Welch's t-statistic
    se = sqrt(s1^2/n1 + s2^2/n2)
    t_stat = (m1 - m2) / se

    # Welch-Satterthwaite degrees of freedom
    df = (s1^2/n1 + s2^2/n2)^2 / ((s1^2/n1)^2/(n1-1) + (s2^2/n2)^2/(n2-1))

    # Approximate p-value (using normal approximation for simplicity)
    # For exact p-value, would need t-distribution CDF
    z = abs(t_stat)
    p_value = 2 * (1 - normcdf(z))

    # Effect size (Cohen's d)
    pooled_std = sqrt(((n1-1)*s1^2 + (n2-1)*s2^2) / (n1 + n2 - 2))
    cohens_d = (m1 - m2) / pooled_std

    return (t=t_stat, df=df, p=p_value, d=cohens_d)
end

"""
Standard normal CDF approximation.
"""
function normcdf(z::Float64)
    # Abramowitz and Stegun approximation
    t = 1 / (1 + 0.2316419 * abs(z))
    d = 0.3989423 * exp(-z^2/2)
    p = d * t * (0.3193815 + t * (-0.3565638 + t * (1.781478 + t * (-1.821256 + t * 1.330274))))
    return z > 0 ? 1 - p : p
end

"""
One-way ANOVA (F-test).
"""
function one_way_anova(groups::Vector{Vector{Float64}})
    k = length(groups)  # number of groups
    N = sum(length.(groups))  # total samples

    # Grand mean
    all_data = vcat(groups...)
    grand_mean = mean(all_data)

    # Between-group sum of squares
    SS_between = sum(length(g) * (mean(g) - grand_mean)^2 for g in groups)

    # Within-group sum of squares
    SS_within = sum(sum((x - mean(g))^2 for x in g) for g in groups)

    # Mean squares
    df_between = k - 1
    df_within = N - k
    MS_between = SS_between / df_between
    MS_within = SS_within / df_within

    # F-statistic
    F_stat = MS_between / MS_within

    # Effect size (eta-squared)
    eta_sq = SS_between / (SS_between + SS_within)

    # Approximate p-value (would need F-distribution for exact)
    # Using chi-squared approximation
    p_value = 1 - chi_sq_cdf(F_stat * df_between, df_between)

    return (F=F_stat, df1=df_between, df2=df_within, p=p_value, eta_sq=eta_sq)
end

"""
Chi-squared CDF approximation.
"""
function chi_sq_cdf(x::Float64, df::Int)
    # Wilson-Hilferty approximation
    if df <= 0 || x <= 0
        return 0.0
    end
    z = ((x/df)^(1/3) - (1 - 2/(9*df))) / sqrt(2/(9*df))
    return normcdf(z)
end

"""
Chi-squared goodness-of-fit test.
"""
function chi_squared_gof(observed::Vector{Float64}, expected::Vector{Float64})
    chi_sq = sum((o - e)^2 / e for (o, e) in zip(observed, expected) if e > 0)
    df = length(observed) - 1
    p_value = 1 - chi_sq_cdf(chi_sq, df)
    return (chi_sq=chi_sq, df=df, p=p_value)
end

# ============================================================================
# V. MONTE CARLO SIMULATION (LARGE N)
# ============================================================================

"""
Large-scale Monte Carlo validation of entropic causality law.

N = 10,000+ experiments per omega value
"""
function monte_carlo_large_scale(;
    omega_values::Vector{Float64}=[2.0, 5.0, 10.0, 20.0, 50.0, 100.0, 200.0, 500.0, 1000.0],
    n_experiments::Int=10000,
    n_timepoints::Int=20,
    noise_sigma::Float64=0.03,
    k_true::Float64=0.1
)
    seed!(12345)
    results = []

    for omega in omega_values
        fitted_ks = Float64[]

        for _ in 1:n_experiments
            # Generate degradation curve with omega-dependent stochasticity
            t_max = 5.0 / k_true
            times = range(0, t_max, length=n_timepoints)

            # Stochastic pathway selection (more pathways = more variance)
            pathway_variance = log(omega) / 50  # Scales with entropy
            k_actual = k_true * (1 + pathway_variance * randn())

            # Generate noisy measurements
            mw_values = Float64[]
            for t in times
                mw_true = exp(-k_actual * t)
                mw_noisy = mw_true + noise_sigma * randn()
                push!(mw_values, max(mw_noisy, 0.001))
            end

            # Fit k via linear regression on log(MW)
            log_mw = log.(mw_values)
            t_arr = collect(times)
            n = length(t_arr)

            # Check for valid data
            if any(isnan, log_mw) || any(isinf, log_mw)
                continue
            end

            X = hcat(ones(n), t_arr)
            try
                beta = X \ log_mw
                k_fitted = -beta[2]
                if k_fitted > 0 && k_fitted < 10 * k_true
                    push!(fitted_ks, k_fitted)
                end
            catch
                continue
            end
        end

        if length(fitted_ks) < 100
            continue
        end

        # Statistics
        k_mean = mean(fitted_ks)
        k_std = std(fitted_ks)
        k_cv = k_std / k_mean

        # Derived quantities
        C_obs = cv_to_causality(k_cv)
        C_pred = omega^(-log(2)/3)
        omega_eff = omega_from_causality(C_obs)

        # Bootstrap CI for CV
        cv_lower, cv_upper, _, _ = bootstrap_ci(fitted_ks, x -> std(x)/mean(x), n_bootstrap=1000)

        push!(results, (
            omega = omega,
            n_valid = length(fitted_ks),
            k_mean = k_mean,
            k_std = k_std,
            cv = k_cv,
            cv_ci_lower = cv_lower,
            cv_ci_upper = cv_upper,
            C_obs = C_obs,
            C_pred = C_pred,
            omega_eff = omega_eff,
            error_pct = abs(C_obs - C_pred) / C_pred * 100
        ))
    end

    return results
end

# ============================================================================
# VI. BAYESIAN PARAMETER ESTIMATION
# ============================================================================

"""
Bayesian estimation of the exponent lambda in C = Omega^(-lambda).

Uses grid approximation for simplicity.
"""
function bayesian_lambda_estimation(data::Vector{PolymerReproducibilityData};
                                     lambda_range::Tuple{Float64,Float64}=(0.05, 0.5),
                                     n_grid::Int=1000)
    # Grid of lambda values
    lambdas = range(lambda_range[1], lambda_range[2], length=n_grid)

    # Prior: uniform over range
    log_prior = zeros(n_grid)

    # Likelihood: product over all polymers
    log_likelihood = zeros(n_grid)

    for (i, lambda) in enumerate(lambdas)
        for poly in data
            cv_val = cv(poly)
            C_obs = cv_to_causality(cv_val)
            C_pred = poly.omega_estimated^(-lambda)

            # Assume Gaussian error with sigma ~ 0.1
            sigma = 0.1
            log_likelihood[i] += -0.5 * ((C_obs - C_pred) / sigma)^2
        end
    end

    # Posterior (unnormalized)
    log_posterior = log_prior + log_likelihood

    # Normalize
    max_log = maximum(log_posterior)
    posterior = exp.(log_posterior .- max_log)
    posterior ./= sum(posterior) * (lambdas[2] - lambdas[1])

    # Point estimates
    lambda_map = lambdas[argmax(posterior)]
    lambda_mean = sum(lambdas .* posterior) / sum(posterior)

    # Credible interval
    cumsum_post = cumsum(posterior) / sum(posterior)
    idx_lower = findfirst(x -> x >= 0.025, cumsum_post)
    idx_upper = findfirst(x -> x >= 0.975, cumsum_post)
    lambda_ci = (lambdas[idx_lower], lambdas[idx_upper])

    return (
        lambda_map = lambda_map,
        lambda_mean = lambda_mean,
        lambda_ci = lambda_ci,
        lambdas = collect(lambdas),
        posterior = posterior
    )
end

# ============================================================================
# VII. CROSS-VALIDATION
# ============================================================================

"""
Leave-one-out cross-validation for the entropic causality law.
"""
function loocv_validation(data::Vector{PolymerReproducibilityData})
    n = length(data)
    errors = Float64[]
    predictions = Float64[]
    observations = Float64[]

    for i in 1:n
        # Leave out polymer i
        train_data = [data[j] for j in 1:n if j != i]
        test_poly = data[i]

        # Fit lambda on training set
        log_omega = [log(p.omega_estimated) for p in train_data]
        log_C = [log(cv_to_causality(cv(p))) for p in train_data]

        # Filter valid entries
        valid_idx = findall(x -> !isnan(x) && !isinf(x), log_C)
        if length(valid_idx) < 3
            continue
        end

        log_omega_valid = log_omega[valid_idx]
        log_C_valid = log_C[valid_idx]

        # Linear regression: log(C) = -lambda * log(Omega) + const
        X = hcat(ones(length(log_omega_valid)), log_omega_valid)
        try
            beta = X \ log_C_valid
            lambda_fitted = -beta[2]

            # Predict for test polymer
            C_pred = test_poly.omega_estimated^(-lambda_fitted)
            C_obs = cv_to_causality(cv(test_poly))

            if !isnan(C_obs) && !isnan(C_pred)
                push!(errors, abs(C_pred - C_obs))
                push!(predictions, C_pred)
                push!(observations, C_obs)
            end
        catch
            continue
        end
    end

    if isempty(errors)
        return (mae=NaN, rmse=NaN, r_squared=NaN)
    end

    mae = mean(errors)
    rmse = sqrt(mean(errors.^2))

    # R-squared
    ss_res = sum((observations .- predictions).^2)
    ss_tot = sum((observations .- mean(observations)).^2)
    r_squared = 1 - ss_res / ss_tot

    return (mae=mae, rmse=rmse, r_squared=r_squared, n=length(errors))
end

# ============================================================================
# VIII. COMPREHENSIVE ANALYSIS
# ============================================================================

"""
Run complete statistical analysis.
"""
function run_comprehensive_analysis()
    println("="^80)
    println("  COMPREHENSIVE STATISTICAL ANALYSIS OF ENTROPIC CAUSALITY LAW")
    println("="^80)
    println()

    # -------------------------------------------------------------------------
    # 1. Dataset Summary
    # -------------------------------------------------------------------------
    println("[1. DATASET SUMMARY]")
    println("-"^80)
    println("Total polymers: $(length(EXPANDED_POLYMER_DATA))")

    # By scission mode
    chain_end = filter(p -> p.scission_mode == :chain_end, EXPANDED_POLYMER_DATA)
    random = filter(p -> p.scission_mode == :random, EXPANDED_POLYMER_DATA)
    mixed = filter(p -> p.scission_mode in [:mixed, :enzymatic], EXPANDED_POLYMER_DATA)

    println("  Chain-end scission: $(length(chain_end))")
    println("  Random scission: $(length(random))")
    println("  Mixed/enzymatic: $(length(mixed))")

    # Total replicates
    total_n = sum(p.n_replicates for p in EXPANDED_POLYMER_DATA)
    println("  Total measurements: $total_n")

    # -------------------------------------------------------------------------
    # 2. Descriptive Statistics by Group
    # -------------------------------------------------------------------------
    println()
    println("[2. DESCRIPTIVE STATISTICS BY SCISSION MODE]")
    println("-"^80)

    for (name, group) in [("Chain-end", chain_end), ("Random", random)]
        if isempty(group)
            continue
        end

        cvs = [cv(p) for p in group]
        Cs = [cv_to_causality(cv(p)) for p in group]
        omegas_eff = [omega_from_causality(C) for C in Cs]
        omegas_eff = filter(!isnan, omegas_eff)

        println("$name scission (n=$(length(group))):")
        println("  CV: mean=$(round(mean(cvs)*100, digits=1))%, std=$(round(std(cvs)*100, digits=1))%")
        println("  C:  mean=$(round(mean(Cs), digits=3)), std=$(round(std(Cs), digits=3))")
        if !isempty(omegas_eff)
            println("  Omega_eff: mean=$(round(mean(omegas_eff), digits=2)), std=$(round(std(omegas_eff), digits=2))")
        end
    end

    # -------------------------------------------------------------------------
    # 3. Hypothesis Testing: Chain-end vs Random
    # -------------------------------------------------------------------------
    println()
    println("[3. HYPOTHESIS TESTING]")
    println("-"^80)

    cv_chain = [cv(p) for p in chain_end]
    cv_random = [cv(p) for p in random]

    if length(cv_chain) >= 2 && length(cv_random) >= 2
        ttest = welch_ttest(cv_chain, cv_random)
        println("Welch's t-test (CV: chain-end vs random):")
        println("  t-statistic: $(round(ttest.t, digits=3))")
        println("  Degrees of freedom: $(round(ttest.df, digits=1))")
        println("  p-value: $(round(ttest.p, digits=4))")
        println("  Cohen's d: $(round(ttest.d, digits=3))")
        println("  Interpretation: $(ttest.p < 0.05 ? "SIGNIFICANT" : "Not significant") at alpha=0.05")
    end

    # -------------------------------------------------------------------------
    # 4. Bootstrap Confidence Intervals
    # -------------------------------------------------------------------------
    println()
    println("[4. BOOTSTRAP CONFIDENCE INTERVALS FOR OMEGA_EFF]")
    println("-"^80)

    println(rpad("Polymer", 25) * " | " *
            rpad("Omega_eff", 10) * " | " *
            "95% CI")
    println("-"^60)

    for poly in EXPANDED_POLYMER_DATA[1:min(10, end)]
        lower, upper, mean_val, _ = bootstrap_omega_eff(poly, n_bootstrap=5000)
        if !isnan(mean_val)
            println(rpad(poly.name[1:min(25, end)], 25) * " | " *
                    lpad(string(round(mean_val, digits=2)), 10) * " | " *
                    "[$(round(lower, digits=2)), $(round(upper, digits=2))]")
        end
    end

    # -------------------------------------------------------------------------
    # 5. Bayesian Parameter Estimation
    # -------------------------------------------------------------------------
    println()
    println("[5. BAYESIAN ESTIMATION OF LAMBDA]")
    println("-"^80)

    bayes = bayesian_lambda_estimation(EXPANDED_POLYMER_DATA)
    println("Prior: Uniform(0.05, 0.5)")
    println("Posterior:")
    println("  MAP estimate: $(round(bayes.lambda_map, digits=4))")
    println("  Mean estimate: $(round(bayes.lambda_mean, digits=4))")
    println("  95% credible interval: [$(round(bayes.lambda_ci[1], digits=4)), $(round(bayes.lambda_ci[2], digits=4))]")
    println("  Theoretical value: $(round(log(2)/3, digits=4))")

    theoretical_in_ci = bayes.lambda_ci[1] <= log(2)/3 <= bayes.lambda_ci[2]
    println("  Theory in CI: $(theoretical_in_ci ? "YES" : "NO")")

    # -------------------------------------------------------------------------
    # 6. Cross-Validation
    # -------------------------------------------------------------------------
    println()
    println("[6. LEAVE-ONE-OUT CROSS-VALIDATION]")
    println("-"^80)

    cv_results = loocv_validation(EXPANDED_POLYMER_DATA)
    println("LOOCV Results:")
    println("  Mean Absolute Error: $(round(cv_results.mae, digits=4))")
    println("  Root Mean Square Error: $(round(cv_results.rmse, digits=4))")
    println("  R-squared: $(round(cv_results.r_squared, digits=4))")
    println("  N predictions: $(cv_results.n)")

    # -------------------------------------------------------------------------
    # 7. Monte Carlo Simulation
    # -------------------------------------------------------------------------
    println()
    println("[7. LARGE-SCALE MONTE CARLO SIMULATION (N=10,000)]")
    println("-"^80)

    mc_results = monte_carlo_large_scale(n_experiments=10000)

    println(rpad("Omega", 8) * " | " *
            rpad("N", 6) * " | " *
            rpad("CV%", 8) * " | " *
            rpad("95% CI", 16) * " | " *
            rpad("C_obs", 8) * " | " *
            rpad("C_pred", 8) * " | " *
            rpad("Error%", 8))
    println("-"^80)

    for r in mc_results
        ci_str = "[$(round(r.cv_ci_lower*100, digits=1)), $(round(r.cv_ci_upper*100, digits=1))]"
        println(lpad(string(r.omega), 8) * " | " *
                lpad(string(r.n_valid), 6) * " | " *
                lpad(string(round(r.cv*100, digits=1)), 8) * " | " *
                rpad(ci_str, 16) * " | " *
                lpad(string(round(r.C_obs, digits=4)), 8) * " | " *
                lpad(string(round(r.C_pred, digits=4)), 8) * " | " *
                lpad(string(round(r.error_pct, digits=1)), 8))
    end

    # -------------------------------------------------------------------------
    # 8. Effect Size Analysis
    # -------------------------------------------------------------------------
    println()
    println("[8. EFFECT SIZE ANALYSIS]")
    println("-"^80)

    # Correlation between log(Omega) and CV
    log_omegas = [log(p.omega_estimated) for p in EXPANDED_POLYMER_DATA]
    cvs_all = [cv(p) for p in EXPANDED_POLYMER_DATA]

    r_corr = cor(log_omegas, cvs_all)
    println("Correlation: log(Omega) vs CV")
    println("  Pearson r = $(round(r_corr, digits=4))")
    println("  r-squared = $(round(r_corr^2, digits=4))")
    println("  Interpretation: $(abs(r_corr) > 0.5 ? "Strong" : (abs(r_corr) > 0.3 ? "Moderate" : "Weak")) correlation")

    # -------------------------------------------------------------------------
    # 9. Summary Statistics
    # -------------------------------------------------------------------------
    println()
    println("[9. FINAL SUMMARY]")
    println("="^80)

    all_omega_eff = Float64[]
    for poly in EXPANDED_POLYMER_DATA
        C = cv_to_causality(cv(poly))
        omega_eff = omega_from_causality(C)
        if !isnan(omega_eff) && omega_eff > 0 && omega_eff < 100
            push!(all_omega_eff, omega_eff)
        end
    end

    println("""
    Dataset: $(length(EXPANDED_POLYMER_DATA)) polymers, $total_n total measurements

    Key Findings:
    1. Mean effective Omega: $(round(mean(all_omega_eff), digits=2)) +/- $(round(std(all_omega_eff), digits=2))
    2. Bayesian lambda: $(round(bayes.lambda_mean, digits=4)) (theory: $(round(log(2)/3, digits=4)))
    3. Theory in 95% CI: $(theoretical_in_ci ? "YES" : "NO")
    4. LOOCV R-squared: $(round(cv_results.r_squared, digits=3))
    5. Chain-end vs Random: $(ttest.p < 0.05 ? "SIGNIFICANTLY DIFFERENT" : "Not different") (p=$(round(ttest.p, digits=4)))

    Conclusion:
    The entropic causality law C = Omega^(-ln(2)/d) is $(theoretical_in_ci ? "SUPPORTED" : "NOT SUPPORTED")
    by the statistical analysis with $(length(EXPANDED_POLYMER_DATA)) polymers and $total_n measurements.
    """)
end

# ============================================================================
# IX. MAIN
# ============================================================================

if abspath(PROGRAM_FILE) == @__FILE__
    run_comprehensive_analysis()
end
