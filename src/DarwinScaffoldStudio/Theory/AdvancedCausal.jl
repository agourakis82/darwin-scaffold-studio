"""
    AdvancedCausal

Advanced causal inference methods:
- Double/Debiased ML (Chernozhukov et al. 2018)
- Causal Forests (Wager & Athey 2018)
- Counterfactual inference (Pearl 2009)
- DoWhy-style interface (Sharma & Kiciman 2020)
"""
module AdvancedCausal

using LinearAlgebra
using Statistics
using Random
using Distributions

export DoubleML, causal_forest, heterogeneous_effects
export CausalTree, CausalForest, predict_cate
export counterfactual, twin_network_counterfactual
export DoWhyModel, identify, estimate, refute

# Dependencies - set by parent module
const _CausalGraph = Ref{DataType}()
const _SCM = Ref{DataType}()
const _topological_sort = Ref{Function}(g -> String[])
const _get_parents = Ref{Function}((g, n) -> String[])
const _get_children = Ref{Function}((g, n) -> String[])
const _get_ancestors = Ref{Function}((g, n) -> String[])
const _get_descendants = Ref{Function}((g, n) -> String[])
const _intervene = Ref{Function}((scm, i) -> nothing)
const _pc_algorithm = Ref{Function}((d, v) -> nothing)
const _estimate_ate = Ref{Function}((d, t, o) -> 0.0)
const _frontdoor_adjustment = Ref{Function}((d, t, m, o) -> 0.0)
const _instrumental_variables = Ref{Function}((d, t, o, i) -> 0.0)

"""Configure dependencies from other modules."""
function configure!(; CausalGraphType, SCMType, topological_sort_fn,
                    get_parents_fn, get_children_fn, get_ancestors_fn, get_descendants_fn,
                    intervene_fn, pc_algorithm_fn, estimate_ate_fn,
                    frontdoor_adjustment_fn, instrumental_variables_fn)
    _CausalGraph[] = CausalGraphType
    _SCM[] = SCMType
    _topological_sort[] = topological_sort_fn
    _get_parents[] = get_parents_fn
    _get_children[] = get_children_fn
    _get_ancestors[] = get_ancestors_fn
    _get_descendants[] = get_descendants_fn
    _intervene[] = intervene_fn
    _pc_algorithm[] = pc_algorithm_fn
    _estimate_ate[] = estimate_ate_fn
    _frontdoor_adjustment[] = frontdoor_adjustment_fn
    _instrumental_variables[] = instrumental_variables_fn
end

#=============================================================================
  DOUBLE/DEBIASED MACHINE LEARNING
=============================================================================#

"""
    DoubleML

Double/Debiased Machine Learning (Chernozhukov et al. 2018).
Cross-fitting procedure for semiparametric estimation.
"""
struct DoubleML
    n_folds::Int
    ml_method::Symbol  # :linear, :forest, :neural
end

DoubleML(; n_folds::Int=5, ml_method::Symbol=:linear) = DoubleML(n_folds, ml_method)

function (dml::DoubleML)(data::Matrix{Float64}, treatment_idx::Int,
                         outcome_idx::Int, confounder_indices::Vector{Int})
    n = size(data, 1)

    T = data[:, treatment_idx]
    Y = data[:, outcome_idx]
    X = data[:, confounder_indices]

    # Cross-fitting
    folds = create_folds(n, dml.n_folds)

    residuals_Y = zeros(n)
    residuals_T = zeros(n)

    for k in 1:dml.n_folds
        train_idx = vcat([folds[j] for j in 1:dml.n_folds if j != k]...)
        test_idx = folds[k]

        # Fit outcome model E[Y|X] on training data
        if dml.ml_method == :linear
            β_Y = X[train_idx, :] \ Y[train_idx]
            residuals_Y[test_idx] = Y[test_idx] - X[test_idx, :] * β_Y

            # Fit treatment model E[T|X] on training data
            β_T = X[train_idx, :] \ T[train_idx]
            residuals_T[test_idx] = T[test_idx] - X[test_idx, :] * β_T
        end
    end

    # Final estimate: regress residual_Y on residual_T
    ate = dot(residuals_T, residuals_Y) / dot(residuals_T, residuals_T)

    # Standard error
    n_eff = sum(residuals_T.^2)
    se = sqrt(var(residuals_Y - ate * residuals_T) / n_eff)

    return Dict(
        "ate" => ate,
        "se" => se,
        "ci_lower" => ate - 1.96 * se,
        "ci_upper" => ate + 1.96 * se
    )
end

function create_folds(n::Int, k::Int)
    indices = shuffle(1:n)
    fold_size = n ÷ k
    folds = Vector{Vector{Int}}()

    for i in 1:k
        start_idx = (i - 1) * fold_size + 1
        end_idx = i == k ? n : i * fold_size
        push!(folds, indices[start_idx:end_idx])
    end

    return folds
end

#=============================================================================
  CAUSAL FORESTS
=============================================================================#

"""Causal tree node."""
struct CausalTree
    split_var::Int
    split_val::Float64
    left::Union{CausalTree, Float64}  # Float64 for leaf (treatment effect)
    right::Union{CausalTree, Float64}
    is_leaf::Bool
end

"""Causal forest for heterogeneous treatment effects."""
struct CausalForest
    trees::Vector{CausalTree}
    feature_indices::Vector{Int}
end

"""
    causal_forest(data, treatment, outcome, confounders)

Causal Forests for heterogeneous treatment effects (Wager & Athey 2018).
"""
function causal_forest(data::Matrix{Float64},
                       treatment_idx::Int,
                       outcome_idx::Int,
                       confounder_indices::Vector{Int};
                       n_trees::Int=100,
                       min_leaf_size::Int=5)
    n = size(data, 1)

    T = data[:, treatment_idx]
    Y = data[:, outcome_idx]
    X = data[:, confounder_indices]

    # Build forest of causal trees
    trees = Vector{CausalTree}()

    for _ in 1:n_trees
        # Bootstrap sample
        boot_idx = sample(1:n, n, replace=true)

        tree = build_causal_tree(X[boot_idx, :], T[boot_idx], Y[boot_idx];
                                 min_leaf_size=min_leaf_size)
        push!(trees, tree)
    end

    return CausalForest(trees, confounder_indices)
end

function build_causal_tree(X::Matrix{Float64}, T::Vector{Float64}, Y::Vector{Float64};
                           min_leaf_size::Int=5, depth::Int=0, max_depth::Int=10)
    n = size(X, 1)

    # Check stopping conditions
    if n < 2 * min_leaf_size || depth >= max_depth
        # Leaf: estimate treatment effect
        treated = T .== 1
        if sum(treated) > 0 && sum(.!treated) > 0
            effect = mean(Y[treated]) - mean(Y[.!treated])
        else
            effect = 0.0
        end
        return CausalTree(0, 0.0, effect, effect, true)
    end

    # Find best split (maximize heterogeneity of treatment effects)
    best_gain = -Inf
    best_var = 1
    best_val = median(X[:, 1])

    d = size(X, 2)
    for var in 1:d
        vals = sort(unique(X[:, var]))
        for val in vals[1:end-1]
            left_mask = X[:, var] .<= val
            right_mask = .!left_mask

            if sum(left_mask) >= min_leaf_size && sum(right_mask) >= min_leaf_size
                τ_left = treatment_effect(Y[left_mask], T[left_mask])
                τ_right = treatment_effect(Y[right_mask], T[right_mask])

                # Gain: variance of effects
                gain = (sum(left_mask) * τ_left^2 + sum(right_mask) * τ_right^2) / n

                if gain > best_gain
                    best_gain = gain
                    best_var = var
                    best_val = val
                end
            end
        end
    end

    # Split
    left_mask = X[:, best_var] .<= best_val
    right_mask = .!left_mask

    left_tree = build_causal_tree(X[left_mask, :], T[left_mask], Y[left_mask];
                                  min_leaf_size=min_leaf_size, depth=depth+1)
    right_tree = build_causal_tree(X[right_mask, :], T[right_mask], Y[right_mask];
                                   min_leaf_size=min_leaf_size, depth=depth+1)

    return CausalTree(best_var, best_val, left_tree, right_tree, false)
end

function treatment_effect(Y::Vector{Float64}, T::Vector{Float64})
    treated = T .== 1
    if sum(treated) > 0 && sum(.!treated) > 0
        return mean(Y[treated]) - mean(Y[.!treated])
    else
        return 0.0
    end
end

function predict_cate(forest::CausalForest, x::Vector{Float64})
    effects = Float64[]

    for tree in forest.trees
        effect = traverse_tree(tree, x)
        push!(effects, effect)
    end

    return mean(effects)
end

function traverse_tree(tree::CausalTree, x::Vector{Float64})
    if tree.is_leaf
        return tree.left  # Effect stored in left for leaves
    end

    if x[tree.split_var] <= tree.split_val
        return traverse_tree(tree.left, x)
    else
        return traverse_tree(tree.right, x)
    end
end

"""
    heterogeneous_effects(data, treatment, outcome, confounders)

Analyze heterogeneity in treatment effects across subgroups.
"""
function heterogeneous_effects(data::Matrix{Float64},
                               treatment_idx::Int,
                               outcome_idx::Int,
                               confounder_indices::Vector{Int})
    forest = causal_forest(data, treatment_idx, outcome_idx, confounder_indices)
    X = data[:, confounder_indices]

    n = size(X, 1)
    cate = zeros(n)
    for i in 1:n
        cate[i] = predict_cate(forest, X[i, :])
    end

    return Dict(
        "mean_cate" => mean(cate),
        "std_cate" => std(cate),
        "min_cate" => minimum(cate),
        "max_cate" => maximum(cate),
        "cate_values" => cate
    )
end

#=============================================================================
  COUNTERFACTUAL INFERENCE
=============================================================================#

"""
    counterfactual(scm, evidence, intervention, query)

Compute counterfactual: P(Y_x | X=x', Y=y')

Three-step process (Pearl 2009):
1. Abduction: Compute P(U | evidence)
2. Action: Modify SCM with intervention
3. Prediction: Compute query in modified SCM
"""
function counterfactual(scm,
                        evidence::Dict{String, Float64},
                        intervention::Dict{String, Float64},
                        query::String;
                        n_samples::Int=1000)
    # Step 1: Abduction - infer exogenous noise given evidence
    U_posterior = abduction(scm, evidence, n_samples)

    # Step 2: Action - create interventional SCM
    scm_do = _intervene[](scm, intervention)

    # Step 3: Prediction - compute query under intervention with inferred U
    query_samples = Float64[]

    for u in U_posterior
        values = forward_sample(scm_do, u)
        push!(query_samples, values[query])
    end

    return (
        mean = mean(query_samples),
        std = std(query_samples),
        samples = query_samples
    )
end

function abduction(scm, evidence::Dict{String, Float64}, n_samples::Int)
    # Approximate posterior P(U | evidence) using rejection sampling
    U_samples = Vector{Dict{String, Float64}}()

    nodes = _topological_sort[](scm.graph)

    while length(U_samples) < n_samples
        # Sample U
        U = Dict(v => rand(scm.noise_distributions[v]) for v in nodes)

        # Check if evidence is satisfied (with tolerance)
        values = forward_sample(scm, U)

        match = true
        for (var, val) in evidence
            if abs(values[var] - val) > 0.5  # Tolerance
                match = false
                break
            end
        end

        if match
            push!(U_samples, U)
        end
    end

    return U_samples
end

function forward_sample(scm, U::Dict{String, Float64})
    nodes = _topological_sort[](scm.graph)
    values = Dict{String, Float64}()

    for v in nodes
        parents = _get_parents[](scm.graph, v)
        if isempty(parents)
            if haskey(scm.structural_equations, v)
                values[v] = scm.structural_equations[v](U[v])[1]
            else
                values[v] = U[v]
            end
        else
            parent_vals = [values[p] for p in parents]
            values[v] = scm.structural_equations[v](reshape(parent_vals, 1, :), [U[v]])[1]
        end
    end

    return values
end

"""
    twin_network_counterfactual(data, scm, factual_idx, intervention)

Twin network method for counterfactual estimation.
"""
function twin_network_counterfactual(data::Matrix{Float64},
                                     scm,
                                     factual_idx::Int,
                                     intervention::Dict{String, Float64},
                                     query::String)
    # Get factual observation
    factual = Dict(v => data[factual_idx, i] for (i, v) in enumerate(scm.var_names))

    # Infer noise for this observation
    U_factual = infer_noise(scm, factual)

    # Create counterfactual SCM
    scm_cf = _intervene[](scm, intervention)

    # Forward sample with same noise
    cf_values = forward_sample(scm_cf, U_factual)

    return cf_values[query]
end

function infer_noise(scm, observation::Dict{String, Float64})
    nodes = _topological_sort[](scm.graph)
    U = Dict{String, Float64}()

    for v in nodes
        parents = _get_parents[](scm.graph, v)
        if isempty(parents)
            U[v] = observation[v]
        else
            parent_vals = [observation[p] for p in parents]
            predicted = sum(parent_vals) * 0.5  # Simplified
            U[v] = observation[v] - predicted
        end
    end

    return U
end

#=============================================================================
  DOWHY-STYLE INTERFACE
=============================================================================#

"""
    DoWhyModel

DoWhy-style causal inference pipeline (Sharma & Kiciman 2020).
Four steps: Model → Identify → Estimate → Refute
"""
mutable struct DoWhyModel
    graph
    treatment::String
    outcome::String
    data::Matrix{Float64}
    var_names::Vector{String}
    identified_estimand::Union{Nothing, Dict}
    estimate::Union{Nothing, Float64}
end

function DoWhyModel(data::Matrix{Float64}, var_names::Vector{String},
                    treatment::String, outcome::String;
                    graph=nothing)
    if graph === nothing
        graph = _pc_algorithm[](data, var_names)
    end

    DoWhyModel(graph, treatment, outcome, data, var_names, nothing, nothing)
end

"""
    identify(model)

Identify causal effect using do-calculus rules.
"""
function identify(model::DoWhyModel)
    treatment_idx = findfirst(model.var_names .== model.treatment)
    outcome_idx = findfirst(model.var_names .== model.outcome)

    # Find backdoor paths
    backdoor_vars = find_backdoor_set(model.graph, model.treatment, model.outcome)

    # Check if backdoor criterion satisfied
    if !isempty(backdoor_vars)
        model.identified_estimand = Dict(
            "type" => "backdoor",
            "adjustment_set" => backdoor_vars,
            "formula" => "E[Y|do(T)] = sum_z E[Y|T,Z=z]P(Z=z)"
        )
    else
        # Try frontdoor
        mediators = find_mediators(model.graph, model.treatment, model.outcome)
        if !isempty(mediators)
            model.identified_estimand = Dict(
                "type" => "frontdoor",
                "mediator" => mediators[1],
                "formula" => "E[Y|do(T)] via frontdoor"
            )
        else
            # Try instrumental variable
            instruments = find_instruments(model.graph, model.treatment, model.outcome)
            if !isempty(instruments)
                model.identified_estimand = Dict(
                    "type" => "instrumental_variable",
                    "instrument" => instruments[1],
                    "formula" => "E[Y|do(T)] = Cov(Y,Z)/Cov(T,Z)"
                )
            else
                error("Effect not identifiable from given graph")
            end
        end
    end

    return model.identified_estimand
end

function find_backdoor_set(g, treatment::String, outcome::String)
    all_vars = setdiff(g.nodes, [treatment, outcome])
    descendants = _get_descendants[](g, treatment)
    backdoor = setdiff(all_vars, descendants)
    return backdoor
end

function find_mediators(g, treatment::String, outcome::String)
    children_t = _get_children[](g, treatment)
    parents_y = _get_parents[](g, outcome)
    return intersect(children_t, parents_y)
end

function find_instruments(g, treatment::String, outcome::String)
    parents_t = _get_parents[](g, treatment)
    ancestors_y = _get_ancestors[](g, outcome)

    instruments = String[]
    for p in parents_t
        if p ∉ ancestors_y || p == treatment
            push!(instruments, p)
        end
    end

    return instruments
end

"""
    estimate(model; method)

Estimate causal effect using identified estimand.
"""
function estimate(model::DoWhyModel; method::Symbol=:auto)
    if model.identified_estimand === nothing
        identify(model)
    end

    treatment_idx = findfirst(model.var_names .== model.treatment)
    outcome_idx = findfirst(model.var_names .== model.outcome)

    estimand_type = model.identified_estimand["type"]

    if estimand_type == "backdoor"
        adj_set = model.identified_estimand["adjustment_set"]
        adj_indices = [findfirst(model.var_names .== v) for v in adj_set]

        model.estimate = _estimate_ate[](model.data, treatment_idx, outcome_idx;
                                         confounder_indices=adj_indices,
                                         method=method == :auto ? :doubly_robust : method)

    elseif estimand_type == "frontdoor"
        mediator = model.identified_estimand["mediator"]
        mediator_idx = findfirst(model.var_names .== mediator)
        model.estimate = _frontdoor_adjustment[](model.data, treatment_idx,
                                                  mediator_idx, outcome_idx)

    elseif estimand_type == "instrumental_variable"
        instrument = model.identified_estimand["instrument"]
        instrument_idx = findfirst(model.var_names .== instrument)
        model.estimate = _instrumental_variables[](model.data, treatment_idx,
                                                   outcome_idx, instrument_idx)
    end

    return model.estimate
end

"""
    refute(model; method)

Refutation tests for robustness of causal estimate.
"""
function refute(model::DoWhyModel; method::Symbol=:placebo)
    if model.estimate === nothing
        estimate(model)
    end

    if method == :placebo
        return placebo_test(model)
    elseif method == :random_common_cause
        return random_common_cause_test(model)
    elseif method == :subset
        return subset_test(model)
    elseif method == :bootstrap
        return bootstrap_test(model)
    else
        error("Unknown refutation method: $method")
    end
end

function placebo_test(model::DoWhyModel)
    n = size(model.data, 1)
    placebo_data = copy(model.data)
    treatment_idx = findfirst(model.var_names .== model.treatment)
    placebo_data[:, treatment_idx] = rand(n)

    placebo_model = DoWhyModel(placebo_data, model.var_names,
                               model.treatment, model.outcome;
                               graph=model.graph)
    identify(placebo_model)
    placebo_effect = estimate(placebo_model)

    return Dict(
        "original_estimate" => model.estimate,
        "placebo_estimate" => placebo_effect,
        "passed" => abs(placebo_effect) < abs(model.estimate) * 0.1
    )
end

function random_common_cause_test(model::DoWhyModel)
    n = size(model.data, 1)
    random_confounder = randn(n)
    augmented_data = hcat(model.data, random_confounder)
    augmented_names = vcat(model.var_names, ["RandomConfounder"])

    treatment_idx = findfirst(model.var_names .== model.treatment)
    outcome_idx = findfirst(model.var_names .== model.outcome)
    confounder_idx = length(augmented_names)

    adj_indices = [confounder_idx]
    new_estimate = _estimate_ate[](augmented_data, treatment_idx, outcome_idx;
                                   confounder_indices=adj_indices)

    return Dict(
        "original_estimate" => model.estimate,
        "new_estimate" => new_estimate,
        "change" => abs(new_estimate - model.estimate) / abs(model.estimate),
        "passed" => abs(new_estimate - model.estimate) < 0.1 * abs(model.estimate)
    )
end

function subset_test(model::DoWhyModel; fraction::Float64=0.8)
    n = size(model.data, 1)
    subset_idx = sample(1:n, Int(floor(n * fraction)), replace=false)
    subset_data = model.data[subset_idx, :]

    subset_model = DoWhyModel(subset_data, model.var_names,
                              model.treatment, model.outcome;
                              graph=model.graph)
    identify(subset_model)
    subset_estimate = estimate(subset_model)

    return Dict(
        "original_estimate" => model.estimate,
        "subset_estimate" => subset_estimate,
        "passed" => abs(subset_estimate - model.estimate) < 0.2 * abs(model.estimate)
    )
end

function bootstrap_test(model::DoWhyModel; n_bootstrap::Int=100)
    n = size(model.data, 1)

    estimates = Float64[]

    for _ in 1:n_bootstrap
        boot_idx = sample(1:n, n, replace=true)
        boot_data = model.data[boot_idx, :]

        boot_model = DoWhyModel(boot_data, model.var_names,
                                model.treatment, model.outcome;
                                graph=model.graph)
        identify(boot_model)
        push!(estimates, estimate(boot_model))
    end

    ci_lower = quantile(estimates, 0.025)
    ci_upper = quantile(estimates, 0.975)

    return Dict(
        "estimate" => model.estimate,
        "ci_lower" => ci_lower,
        "ci_upper" => ci_upper,
        "std" => std(estimates)
    )
end

end # module
