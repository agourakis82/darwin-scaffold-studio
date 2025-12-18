"""
    CausalEffectEstimation

Causal effect estimation methods (Pearl 2009, Hernan & Robins 2020):
- Backdoor adjustment
- Frontdoor adjustment
- Inverse Probability Weighting (IPW)
- Propensity Score Matching
- Doubly Robust (AIPW) estimator
"""
module CausalEffectEstimation

using LinearAlgebra
using Statistics

export backdoor_adjustment, frontdoor_adjustment
export estimate_ate, estimate_cate
export inverse_probability_weighting
export propensity_score_matching
export doubly_robust_estimator
export logistic_regression_predict

#=============================================================================
  BACKDOOR ADJUSTMENT
=============================================================================#

"""
    backdoor_adjustment(data, treatment, outcome, confounders)

Backdoor adjustment formula (Pearl 2009):
P(Y|do(X)) = Σ_z P(Y|X,Z) P(Z)
"""
function backdoor_adjustment(data::Matrix{Float64},
                             treatment_idx::Int,
                             outcome_idx::Int,
                             confounder_indices::Vector{Int};
                             treatment_value::Float64=1.0)
    n = size(data, 1)

    if isempty(confounder_indices)
        # No confounders - simple conditional mean
        mask = data[:, treatment_idx] .≈ treatment_value
        return mean(data[mask, outcome_idx])
    end

    # Stratified estimation
    Z = data[:, confounder_indices]

    # Use regression for continuous confounders
    # E[Y|do(X=x)] = E_Z[E[Y|X=x,Z]]
    X_full = hcat(data[:, treatment_idx], Z)
    y = data[:, outcome_idx]

    # OLS coefficients
    β = X_full \ y

    # Predict at treatment value with average confounders
    X_do = hcat(fill(treatment_value, n), Z)
    y_do = X_do * β

    return mean(y_do)
end

#=============================================================================
  FRONTDOOR ADJUSTMENT
=============================================================================#

"""
    frontdoor_adjustment(data, treatment, mediator, outcome)

Frontdoor adjustment formula (Pearl 2009):
P(Y|do(X)) = Σ_m P(M=m|X) Σ_x' P(Y|M=m,X=x') P(X=x')
"""
function frontdoor_adjustment(data::Matrix{Float64},
                              treatment_idx::Int,
                              mediator_idx::Int,
                              outcome_idx::Int)
    n = size(data, 1)

    X = data[:, treatment_idx]
    M = data[:, mediator_idx]
    Y = data[:, outcome_idx]

    # Step 1: P(M|X) - treatment effect on mediator
    β_XM = cov(X, M) / var(X)

    # Step 2: P(Y|M,X) weighted by P(X)
    XM = hcat(M, X)
    β_MY = XM \ Y

    # Frontdoor formula
    effect = β_XM * β_MY[1]  # Indirect effect through mediator

    return effect
end

#=============================================================================
  ATE ESTIMATION
=============================================================================#

"""
    estimate_ate(data, treatment_idx, outcome_idx; method)

Estimate Average Treatment Effect using various methods.
"""
function estimate_ate(data::Matrix{Float64},
                      treatment_idx::Int,
                      outcome_idx::Int;
                      confounder_indices::Vector{Int}=Int[],
                      method::Symbol=:backdoor)

    if method == :backdoor
        ate_1 = backdoor_adjustment(data, treatment_idx, outcome_idx,
                                    confounder_indices; treatment_value=1.0)
        ate_0 = backdoor_adjustment(data, treatment_idx, outcome_idx,
                                    confounder_indices; treatment_value=0.0)
        return ate_1 - ate_0

    elseif method == :ipw
        return inverse_probability_weighting(data, treatment_idx, outcome_idx,
                                             confounder_indices)

    elseif method == :matching
        return propensity_score_matching(data, treatment_idx, outcome_idx,
                                         confounder_indices)

    elseif method == :doubly_robust
        return doubly_robust_estimator(data, treatment_idx, outcome_idx,
                                       confounder_indices)
    else
        error("Unknown method: $method")
    end
end

#=============================================================================
  INVERSE PROBABILITY WEIGHTING
=============================================================================#

"""
    inverse_probability_weighting(data, treatment, outcome, confounders)

IPW estimator: weight observations by inverse of propensity score.
"""
function inverse_probability_weighting(data::Matrix{Float64},
                                       treatment_idx::Int,
                                       outcome_idx::Int,
                                       confounder_indices::Vector{Int})
    n = size(data, 1)
    T = data[:, treatment_idx]
    Y = data[:, outcome_idx]

    # Estimate propensity score e(X) = P(T=1|X)
    if isempty(confounder_indices)
        e = fill(mean(T), n)
    else
        X = data[:, confounder_indices]
        # Logistic regression
        e = logistic_regression_predict(X, T)
    end

    # Clip for numerical stability
    e = clamp.(e, 0.01, 0.99)

    # IPW estimator
    ate = mean(T .* Y ./ e) - mean((1 .- T) .* Y ./ (1 .- e))

    return ate
end

"""
    logistic_regression_predict(X, y)

Predict probabilities using logistic regression.
"""
function logistic_regression_predict(X::Matrix{Float64}, y::Vector{Float64})
    n, d = size(X)
    X_aug = hcat(ones(n), X)

    # Newton-Raphson for logistic regression
    β = zeros(d + 1)

    for _ in 1:50
        p = 1 ./ (1 .+ exp.(-X_aug * β))
        W = Diagonal(p .* (1 .- p))
        grad = X_aug' * (y - p)
        H = -X_aug' * W * X_aug

        if cond(H) > 1e10
            break
        end

        β -= H \ grad
    end

    return 1 ./ (1 .+ exp.(-X_aug * β))
end

#=============================================================================
  PROPENSITY SCORE MATCHING
=============================================================================#

"""
    propensity_score_matching(data, treatment, outcome, confounders)

Match treated/control units based on propensity scores.
"""
function propensity_score_matching(data::Matrix{Float64},
                                   treatment_idx::Int,
                                   outcome_idx::Int,
                                   confounder_indices::Vector{Int};
                                   n_neighbors::Int=1)
    n = size(data, 1)
    T = data[:, treatment_idx]
    Y = data[:, outcome_idx]

    # Estimate propensity scores
    if isempty(confounder_indices)
        e = fill(mean(T), n)
    else
        X = data[:, confounder_indices]
        e = logistic_regression_predict(X, T)
    end

    treated_idx = findall(T .== 1)
    control_idx = findall(T .== 0)

    # Match each treated unit to nearest control
    matched_effects = Float64[]

    for i in treated_idx
        # Find nearest control(s) by propensity score
        distances = abs.(e[control_idx] .- e[i])
        nearest = sortperm(distances)[1:min(n_neighbors, length(control_idx))]
        matched_controls = control_idx[nearest]

        # Treatment effect for this match
        effect = Y[i] - mean(Y[matched_controls])
        push!(matched_effects, effect)
    end

    # ATT (Average Treatment effect on Treated)
    return mean(matched_effects)
end

#=============================================================================
  DOUBLY ROBUST ESTIMATOR
=============================================================================#

"""
    doubly_robust_estimator(data, treatment, outcome, confounders)

Doubly robust (AIPW) estimator: consistent if either propensity OR outcome model is correct.
"""
function doubly_robust_estimator(data::Matrix{Float64},
                                 treatment_idx::Int,
                                 outcome_idx::Int,
                                 confounder_indices::Vector{Int})
    n = size(data, 1)
    T = data[:, treatment_idx]
    Y = data[:, outcome_idx]

    if isempty(confounder_indices)
        return mean(Y[T .== 1]) - mean(Y[T .== 0])
    end

    X = data[:, confounder_indices]

    # Propensity score model
    e = logistic_regression_predict(X, T)
    e = clamp.(e, 0.01, 0.99)

    # Outcome regression models
    treated_mask = T .== 1
    control_mask = T .== 0

    # E[Y|X, T=1]
    X_treated = X[treated_mask, :]
    Y_treated = Y[treated_mask]
    β_1 = X_treated \ Y_treated
    μ_1 = X * β_1

    # E[Y|X, T=0]
    X_control = X[control_mask, :]
    Y_control = Y[control_mask]
    β_0 = X_control \ Y_control
    μ_0 = X * β_0

    # AIPW estimator
    ate = mean(
        (T .* Y .- (T .- e) .* μ_1) ./ e .-
        ((1 .- T) .* Y .+ (T .- e) .* μ_0) ./ (1 .- e)
    )

    return ate
end

#=============================================================================
  CATE ESTIMATION
=============================================================================#

"""
    estimate_cate(forest, X)

Estimate Conditional Average Treatment Effects for each observation.
(Requires a CausalForest - see AdvancedCausal module)
"""
function estimate_cate(predict_fn::Function, X::Matrix{Float64})
    n = size(X, 1)
    cate = zeros(n)

    for i in 1:n
        cate[i] = predict_fn(X[i, :])
    end

    return cate
end

end # module
