"""
    SensitivityAnalysis

Sensitivity analysis and quasi-experimental methods:
- Sensitivity analysis (Cinelli & Hazlett 2020)
- E-value (VanderWeele & Ding 2017)
- Instrumental Variables (2SLS)
- Regression Discontinuity Design
- Difference-in-Differences
"""
module SensitivityAnalysis

using LinearAlgebra
using Statistics
using Random

export sensitivity_analysis, e_value, robustness_value
export instrumental_variables, regression_discontinuity, difference_in_differences

#=============================================================================
  SENSITIVITY ANALYSIS
=============================================================================#

"""
    sensitivity_analysis(estimate, se, R2_Y, R2_T)

Sensitivity analysis for unobserved confounding (Cinelli & Hazlett 2020).
"""
function sensitivity_analysis(estimate::Float64, se::Float64, R2_Y::Float64, R2_T::Float64)
    # Bias factor
    bias = estimate * sqrt(R2_Y * R2_T) / (1 - R2_T)

    # Robustness value (RV)
    rv = sqrt(R2_Y * R2_T)

    # Adjusted estimate
    adjusted = estimate - bias

    return Dict(
        "original" => estimate,
        "bias" => bias,
        "adjusted" => adjusted,
        "robustness_value" => rv
    )
end

"""
    e_value(estimate; se)

E-value: minimum confounding strength to explain away effect (VanderWeele & Ding 2017).
"""
function e_value(estimate::Float64; se::Float64=0.0)
    # Convert to risk ratio scale (approximate)
    rr = exp(estimate)

    if rr >= 1
        e_val = rr + sqrt(rr * (rr - 1))
    else
        rr_inv = 1 / rr
        e_val = rr_inv + sqrt(rr_inv * (rr_inv - 1))
    end

    # E-value for CI bound
    if se > 0
        ci_bound = exp(estimate - 1.96 * se)
        if ci_bound >= 1
            e_val_ci = ci_bound + sqrt(ci_bound * (ci_bound - 1))
        else
            e_val_ci = 1.0
        end
    else
        e_val_ci = e_val
    end

    return Dict(
        "e_value" => e_val,
        "e_value_ci" => e_val_ci
    )
end

"""
    robustness_value(estimate, t_stat, df)

Robustness value: partial R² needed to explain away effect.
"""
function robustness_value(estimate::Float64, t_stat::Float64, df::Int)
    # RV = t² / (t² + df)
    rv = t_stat^2 / (t_stat^2 + df)
    return sqrt(rv)
end

#=============================================================================
  INSTRUMENTAL VARIABLES
=============================================================================#

"""
    instrumental_variables(data, treatment, outcome, instrument)

2SLS (Two-Stage Least Squares) IV estimation.
"""
function instrumental_variables(data::Matrix{Float64},
                                treatment_idx::Int,
                                outcome_idx::Int,
                                instrument_idx::Int)
    n = size(data, 1)

    T = data[:, treatment_idx]
    Y = data[:, outcome_idx]
    Z = data[:, instrument_idx]

    # Stage 1: Regress T on Z
    Z_aug = hcat(ones(n), Z)
    γ = Z_aug \ T
    T_hat = Z_aug * γ

    # Stage 2: Regress Y on T_hat
    T_hat_aug = hcat(ones(n), T_hat)
    β = T_hat_aug \ Y

    # IV estimate
    iv_estimate = β[2]

    # Standard error (simplified)
    residuals = Y - T_hat_aug * β
    σ² = sum(residuals.^2) / (n - 2)
    se = sqrt(σ² / sum((T_hat .- mean(T_hat)).^2))

    # Weak instrument test (first-stage F-statistic)
    T_resid = T - mean(T)
    Z_resid = Z - mean(Z)
    r² = cor(Z, T)^2
    f_stat = r² * (n - 2) / (1 - r²)

    return Dict(
        "estimate" => iv_estimate,
        "se" => se,
        "f_stat" => f_stat,
        "weak_instrument" => f_stat < 10
    )
end

#=============================================================================
  REGRESSION DISCONTINUITY
=============================================================================#

"""
    regression_discontinuity(data, running_var, cutoff, outcome; bandwidth)

Regression Discontinuity Design (RDD).
"""
function regression_discontinuity(data::Matrix{Float64},
                                  running_idx::Int,
                                  outcome_idx::Int,
                                  cutoff::Float64;
                                  bandwidth::Float64=0.5)
    R = data[:, running_idx]
    Y = data[:, outcome_idx]

    # Treatment indicator
    T = R .>= cutoff

    # Local linear regression within bandwidth
    in_bandwidth = abs.(R .- cutoff) .<= bandwidth
    R_local = R[in_bandwidth] .- cutoff
    Y_local = Y[in_bandwidth]
    T_local = T[in_bandwidth]

    # Separate regressions above/below cutoff
    below = R_local .< 0
    above = .!below

    if sum(below) > 2 && sum(above) > 2
        # Linear fit below
        X_below = hcat(ones(sum(below)), R_local[below])
        β_below = X_below \ Y_local[below]
        y_left = β_below[1]

        # Linear fit above
        X_above = hcat(ones(sum(above)), R_local[above])
        β_above = X_above \ Y_local[above]
        y_right = β_above[1]

        # RDD estimate: discontinuity at cutoff
        rd_estimate = y_right - y_left

        # Bootstrap SE
        se = bootstrap_rd_se(R_local, Y_local, cutoff=0.0)
    else
        rd_estimate = NaN
        se = NaN
    end

    return Dict(
        "estimate" => rd_estimate,
        "se" => se,
        "bandwidth" => bandwidth,
        "n_local" => sum(in_bandwidth)
    )
end

function bootstrap_rd_se(R, Y; cutoff::Float64=0.0, n_boot::Int=100)
    estimates = Float64[]
    n = length(R)

    for _ in 1:n_boot
        idx = sample(1:n, n, replace=true)
        R_boot = R[idx]
        Y_boot = Y[idx]

        below = R_boot .< cutoff
        above = .!below

        if sum(below) > 2 && sum(above) > 2
            y_left = mean(Y_boot[below])
            y_right = mean(Y_boot[above])
            push!(estimates, y_right - y_left)
        end
    end

    return std(estimates)
end

#=============================================================================
  DIFFERENCE-IN-DIFFERENCES
=============================================================================#

"""
    difference_in_differences(data, group, time, outcome)

Difference-in-Differences estimator.
"""
function difference_in_differences(data::Matrix{Float64},
                                   group_idx::Int,
                                   time_idx::Int,
                                   outcome_idx::Int)
    G = data[:, group_idx]  # 1 = treated group, 0 = control
    T = data[:, time_idx]   # 1 = post, 0 = pre
    Y = data[:, outcome_idx]

    # Four group means
    y_00 = mean(Y[(G .== 0) .& (T .== 0)])  # Control, Pre
    y_01 = mean(Y[(G .== 0) .& (T .== 1)])  # Control, Post
    y_10 = mean(Y[(G .== 1) .& (T .== 0)])  # Treated, Pre
    y_11 = mean(Y[(G .== 1) .& (T .== 1)])  # Treated, Post

    # DiD estimate
    did = (y_11 - y_10) - (y_01 - y_00)

    # SE via regression
    X = hcat(ones(length(Y)), G, T, G .* T)
    β = X \ Y
    residuals = Y - X * β
    σ² = sum(residuals.^2) / (length(Y) - 4)
    cov_β = σ² * inv(X' * X)
    se = sqrt(cov_β[4, 4])

    return Dict(
        "estimate" => did,
        "se" => se,
        "pre_trend" => y_10 - y_00,  # Should be ~0 for parallel trends
        "ci_lower" => did - 1.96 * se,
        "ci_upper" => did + 1.96 * se
    )
end

end # module
