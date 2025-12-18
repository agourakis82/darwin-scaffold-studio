"""
    CausalDiscoveryAlgorithms

Causal structure learning algorithms:
- PC Algorithm (Spirtes, Glymour, Scheines 2000)
- FCI Algorithm for latent confounders
- GES (Greedy Equivalence Search)
- NOTEARS continuous optimization (Zheng et al. 2018)
"""
module CausalDiscoveryAlgorithms

using LinearAlgebra
using Statistics
using Distributions

export pc_algorithm, fci_algorithm, ges_algorithm, notears
export discover_causal_graph

# Dependencies - set by parent module
const _CausalGraph = Ref{DataType}()
const _get_parents = Ref{Function}((g, n) -> String[])
const _get_children = Ref{Function}((g, n) -> String[])

"""Configure dependencies from CausalGraphs module."""
function configure!(CausalGraphType::DataType,
                    get_parents_fn::Function,
                    get_children_fn::Function)
    _CausalGraph[] = CausalGraphType
    _get_parents[] = get_parents_fn
    _get_children[] = get_children_fn
end

#=============================================================================
  PC ALGORITHM
=============================================================================#

"""
    pc_algorithm(data, var_names; alpha, max_cond_size)

PC Algorithm for causal discovery (Spirtes, Glymour, Scheines 2000).
Constraint-based approach using conditional independence tests.
"""
function pc_algorithm(data::Matrix{Float64}, var_names::Vector{String};
                      alpha::Float64=0.05, max_cond_size::Int=3)
    n_vars = length(var_names)
    n_samples = size(data, 1)

    # Initialize complete undirected graph
    graph = _CausalGraph[](var_names)
    graph.adjacency = ones(Int, n_vars, n_vars) - I(n_vars)

    # Separation sets
    sep_sets = Dict{Tuple{Int,Int}, Vector{Int}}()

    # Phase I: Remove edges based on conditional independence
    for cond_size in 0:max_cond_size
        for i in 1:n_vars
            for j in (i+1):n_vars
                if graph.adjacency[i, j] == 0
                    continue
                end

                # Get adjacent nodes (potential conditioning sets)
                adj_i = findall(graph.adjacency[i, :] .!= 0)
                adj_i = setdiff(adj_i, [j])

                if length(adj_i) >= cond_size
                    # Test all subsets of size cond_size
                    for S in combinations(adj_i, cond_size)
                        if test_conditional_independence_fisher(
                            data, i, j, S; alpha=alpha, n=n_samples)
                            # Remove edge
                            graph.adjacency[i, j] = 0
                            graph.adjacency[j, i] = 0
                            sep_sets[(i, j)] = S
                            sep_sets[(j, i)] = S
                            break
                        end
                    end
                end
            end
        end
    end

    # Phase II: Orient edges (v-structures)
    for j in 1:n_vars
        # Find unshielded triples i - j - k where i and k not adjacent
        neighbors_j = findall(graph.adjacency[:, j] .!= 0)

        for (idx1, i) in enumerate(neighbors_j)
            for k in neighbors_j[(idx1+1):end]
                if graph.adjacency[i, k] == 0  # Unshielded
                    # Check if j is in separation set of (i, k)
                    S = get(sep_sets, (min(i,k), max(i,k)), Int[])
                    if j ∉ S
                        # Orient as v-structure: i → j ← k
                        graph.adjacency[i, j] = 1
                        graph.adjacency[j, i] = 0
                        graph.adjacency[k, j] = 1
                        graph.adjacency[j, k] = 0
                    end
                end
            end
        end
    end

    # Phase III: Apply Meek's orientation rules
    apply_meek_rules!(graph)

    return graph
end

"""Apply Meek's orientation rules (Meek 1995)."""
function apply_meek_rules!(g)
    n = length(g.nodes)
    changed = true

    while changed
        changed = false

        for i in 1:n, j in 1:n
            if g.adjacency[i, j] == 1 && g.adjacency[j, i] == 1  # Undirected
                # Rule 1: If i → j - k and i, k not adjacent, orient j → k
                for k in 1:n
                    if k != i && k != j
                        if g.adjacency[j, k] == 1 && g.adjacency[k, j] == 1  # j - k
                            if g.adjacency[i, k] == 0 && g.adjacency[k, i] == 0  # not adjacent
                                for m in 1:n
                                    if g.adjacency[m, j] == 1 && g.adjacency[j, m] == 0  # m → j
                                        if g.adjacency[m, k] == 0  # m, k not adjacent
                                            g.adjacency[j, k] = 1
                                            g.adjacency[k, j] = 0
                                            changed = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                # Rule 2: If i → k → j, orient i → j
                for k in 1:n
                    if k != i && k != j
                        if g.adjacency[i, k] == 1 && g.adjacency[k, i] == 0 &&
                           g.adjacency[k, j] == 1 && g.adjacency[j, k] == 0
                            g.adjacency[i, j] = 1
                            g.adjacency[j, i] = 0
                            changed = true
                        end
                    end
                end
            end
        end
    end
end

#=============================================================================
  FCI ALGORITHM
=============================================================================#

"""
    fci_algorithm(data, var_names; alpha)

FCI (Fast Causal Inference) Algorithm for graphs with latent confounders.
Outputs PAG (Partial Ancestral Graph) with bidirected edges.
"""
function fci_algorithm(data::Matrix{Float64}, var_names::Vector{String};
                       alpha::Float64=0.05)
    # Start with PC algorithm result
    graph = pc_algorithm(data, var_names; alpha=alpha)

    n = length(var_names)

    # Look for potential latent confounders
    for i in 1:n, j in (i+1):n
        if graph.adjacency[i, j] == 0 && graph.adjacency[j, i] == 0
            # Check for common effect pattern (collider)
            common_children = Int[]
            for k in 1:n
                if graph.adjacency[i, k] == 1 && graph.adjacency[j, k] == 1
                    push!(common_children, k)
                end
            end

            # If common children but no direct edge, might be latent confounder
            if length(common_children) > 0
                # Test if correlation remains after conditioning on common children
                if !test_conditional_independence_fisher(data, i, j, common_children; alpha=alpha)
                    # Add bidirected edge indicating latent confounder
                    graph.adjacency[i, j] = -1
                    graph.adjacency[j, i] = -1
                end
            end
        end
    end

    return graph
end

#=============================================================================
  NOTEARS ALGORITHM
=============================================================================#

"""
    notears(data; lambda, max_iter)

NOTEARS: Non-combinatorial Optimization for DAG Learning (Zheng et al. 2018).
Continuous optimization approach to structure learning.

min_W ||X - XW||²_F + λ||W||₁
s.t.  h(W) = tr(e^{W∘W}) - d = 0  (acyclicity constraint)
"""
function notears(data::Matrix{Float64};
                 lambda::Float64=0.1,
                 max_iter::Int=100,
                 h_tol::Float64=1e-8,
                 rho_max::Float64=1e16)
    n, d = size(data)

    # Standardize data
    X = (data .- mean(data, dims=1)) ./ std(data, dims=1)

    # Initialize
    W = zeros(d, d)
    rho = 1.0
    alpha = 0.0

    for iter in 1:max_iter
        # Solve augmented Lagrangian subproblem
        W_old = copy(W)

        for _ in 1:10  # Inner iterations
            # Gradient of least squares loss
            grad_loss = -2 * X' * X * (I - W) / n

            # Gradient of acyclicity constraint
            M = W .* W
            E = exp(M)
            grad_h = 2 * W .* (E' * ones(d, d))

            # Update
            grad = grad_loss + alpha * grad_h + rho * h_acyclicity(W) * grad_h

            # Proximal gradient step with L1 regularization
            W_new = W - 0.01 * grad
            W_new = sign.(W_new) .* max.(abs.(W_new) .- 0.01 * lambda, 0)

            # No self-loops
            W_new[diagind(W_new)] .= 0

            W = W_new
        end

        # Check acyclicity
        h_val = h_acyclicity(W)

        if h_val < h_tol
            break
        end

        # Update dual variable
        alpha += rho * h_val
        rho = min(2 * rho, rho_max)
    end

    # Threshold small values
    W[abs.(W) .< 0.3] .= 0

    # Convert to CausalGraph
    var_names = ["X$i" for i in 1:d]
    graph = _CausalGraph[](var_names)

    for i in 1:d, j in 1:d
        if abs(W[i, j]) > 0.3
            graph.adjacency[i, j] = 1
        end
    end

    return graph, W
end

"""Acyclicity constraint: tr(e^{W∘W}) - d = 0"""
function h_acyclicity(W)
    d = size(W, 1)
    M = W .* W
    return tr(exp(M)) - d
end

#=============================================================================
  GES ALGORITHM
=============================================================================#

"""
    ges_algorithm(data; penalty)

GES (Greedy Equivalence Search) for score-based causal discovery.
Searches over Markov equivalence classes.
"""
function ges_algorithm(data::Matrix{Float64};
                       penalty::Float64=1.0)
    n, d = size(data)
    var_names = ["X$i" for i in 1:d]

    # Start with empty graph
    graph = _CausalGraph[](var_names)
    current_score = bic_score(data, graph)

    # Phase I: Forward (add edges)
    improved = true
    while improved
        improved = false
        best_score = current_score
        best_edge = nothing

        for i in 1:d, j in 1:d
            if i != j && graph.adjacency[i, j] == 0
                # Try adding edge i → j
                graph.adjacency[i, j] = 1

                if is_dag(graph)
                    new_score = bic_score(data, graph; penalty=penalty)
                    if new_score > best_score
                        best_score = new_score
                        best_edge = (i, j, :add)
                    end
                end

                graph.adjacency[i, j] = 0
            end
        end

        if best_edge !== nothing
            i, j, _ = best_edge
            graph.adjacency[i, j] = 1
            current_score = best_score
            improved = true
        end
    end

    # Phase II: Backward (remove edges)
    improved = true
    while improved
        improved = false
        best_score = current_score
        best_edge = nothing

        for i in 1:d, j in 1:d
            if graph.adjacency[i, j] == 1
                # Try removing edge i → j
                graph.adjacency[i, j] = 0

                new_score = bic_score(data, graph; penalty=penalty)
                if new_score > best_score
                    best_score = new_score
                    best_edge = (i, j, :remove)
                end

                graph.adjacency[i, j] = 1
            end
        end

        if best_edge !== nothing
            i, j, _ = best_edge
            graph.adjacency[i, j] = 0
            current_score = best_score
            improved = true
        end
    end

    return graph
end

#=============================================================================
  UTILITY FUNCTIONS
=============================================================================#

function is_dag(g)
    # Check for cycles using DFS
    n = length(g.nodes)
    visited = zeros(Int, n)  # 0: unvisited, 1: in progress, 2: done

    function has_cycle(i)
        visited[i] = 1
        for j in 1:n
            if g.adjacency[i, j] == 1
                if visited[j] == 1
                    return true  # Back edge = cycle
                elseif visited[j] == 0
                    if has_cycle(j)
                        return true
                    end
                end
            end
        end
        visited[i] = 2
        return false
    end

    for i in 1:n
        if visited[i] == 0
            if has_cycle(i)
                return false
            end
        end
    end

    return true
end

function bic_score(data::Matrix{Float64}, g; penalty::Float64=1.0)
    n, d = size(data)
    score = 0.0

    for j in 1:d
        parents = findall(g.adjacency[:, j] .== 1)

        if isempty(parents)
            # Score for root node
            variance = var(data[:, j])
            score += -n/2 * log(2π * variance) - n/2
        else
            # Regression score
            X_pa = data[:, parents]
            y = data[:, j]

            # OLS
            β = X_pa \ y
            residuals = y - X_pa * β
            variance = var(residuals)

            k = length(parents) + 1
            score += -n/2 * log(2π * variance) - n/2 - penalty * k * log(n) / 2
        end
    end

    return score
end

function combinations(arr, k)
    if k == 0
        return [Int[]]
    elseif k > length(arr)
        return Vector{Int}[]
    else
        result = Vector{Int}[]
        for i in 1:length(arr)
            for combo in combinations(arr[(i+1):end], k-1)
                push!(result, vcat(arr[i], combo))
            end
        end
        return result
    end
end

function test_conditional_independence_fisher(data::Matrix{Float64},
                                              i::Int, j::Int, S::Vector{Int};
                                              alpha::Float64=0.05, n::Int=0)
    if n == 0
        n = size(data, 1)
    end

    if isempty(S)
        r = cor(data[:, i], data[:, j])
    else
        # Partial correlation
        r = partial_correlation(data, i, j, S)
    end

    # Fisher z-transform
    if abs(r) > 0.9999
        return false  # Not independent
    end

    z = 0.5 * log((1 + r) / (1 - r))
    se = 1 / sqrt(n - length(S) - 3)
    p_value = 2 * (1 - cdf(Normal(), abs(z) / se))

    return p_value > alpha
end

function partial_correlation(data::Matrix{Float64}, i::Int, j::Int, S::Vector{Int})
    if isempty(S)
        return cor(data[:, i], data[:, j])
    end

    # Regression-based partial correlation
    X = data[:, S]

    # Residualize i on S
    β_i = X \ data[:, i]
    res_i = data[:, i] - X * β_i

    # Residualize j on S
    β_j = X \ data[:, j]
    res_j = data[:, j] - X * β_j

    return cor(res_i, res_j)
end

# Alias
const discover_causal_graph = pc_algorithm

end # module
