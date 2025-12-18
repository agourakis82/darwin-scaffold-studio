"""
    CausalGraphs

Core data structures for causal inference: CausalGraph, SCM (Structural Causal Model).
Implements d-separation and graph traversal operations (Pearl 2009).
"""
module CausalGraphs

using LinearAlgebra
using Distributions

export CausalGraph, SCM
export add_edge!, remove_edge!, has_edge
export get_parents, get_children, get_ancestors, get_descendants
export is_d_separated, topological_sort
export set_equation!, sample, intervene

#=============================================================================
  CAUSAL GRAPH
=============================================================================#

"""
    CausalGraph

Directed Acyclic Graph for causal structure.
"""
mutable struct CausalGraph
    nodes::Vector{String}
    adjacency::Matrix{Int}  # 1 = edge, 0 = no edge, -1 = bidirected (latent)
    node_index::Dict{String, Int}
end

function CausalGraph(nodes::Vector{String})
    n = length(nodes)
    node_index = Dict(node => i for (i, node) in enumerate(nodes))
    CausalGraph(nodes, zeros(Int, n, n), node_index)
end

function add_edge!(g::CausalGraph, from::String, to::String; bidirected::Bool=false)
    i, j = g.node_index[from], g.node_index[to]
    g.adjacency[i, j] = bidirected ? -1 : 1
end

function remove_edge!(g::CausalGraph, from::String, to::String)
    i, j = g.node_index[from], g.node_index[to]
    g.adjacency[i, j] = 0
end

function has_edge(g::CausalGraph, from::String, to::String)
    i, j = g.node_index[from], g.node_index[to]
    return g.adjacency[i, j] != 0
end

function get_parents(g::CausalGraph, node::String)
    j = g.node_index[node]
    parent_indices = findall(g.adjacency[:, j] .== 1)
    return [g.nodes[i] for i in parent_indices]
end

function get_children(g::CausalGraph, node::String)
    i = g.node_index[node]
    child_indices = findall(g.adjacency[i, :] .== 1)
    return [g.nodes[j] for j in child_indices]
end

function get_ancestors(g::CausalGraph, node::String)
    ancestors = Set{String}()
    queue = get_parents(g, node)
    while !isempty(queue)
        parent = popfirst!(queue)
        if parent ∉ ancestors
            push!(ancestors, parent)
            append!(queue, get_parents(g, parent))
        end
    end
    return collect(ancestors)
end

function get_descendants(g::CausalGraph, node::String)
    descendants = Set{String}()
    queue = get_children(g, node)
    while !isempty(queue)
        child = popfirst!(queue)
        if child ∉ descendants
            push!(descendants, child)
            append!(queue, get_children(g, child))
        end
    end
    return collect(descendants)
end

"""
    is_d_separated(g, X, Y, Z)

Test d-separation: X ⊥_d Y | Z in graph g (Pearl 2009, Definition 1.2.3)
"""
function is_d_separated(g::CausalGraph, X::Vector{String}, Y::Vector{String},
                        Z::Vector{String})
    # Bayes-Ball algorithm (Shachter 1998)
    n = length(g.nodes)

    # Mark ancestors of Z
    Z_ancestors = Set{String}()
    for z in Z
        union!(Z_ancestors, Set(get_ancestors(g, z)))
        push!(Z_ancestors, z)
    end

    # BFS from X to Y
    visited_from_child = Set{String}()
    visited_from_parent = Set{String}()

    # (node, came_from_child)
    queue = [(x, false) for x in X]

    while !isempty(queue)
        node, from_child = popfirst!(queue)

        if node in Y
            return false  # Path found, not d-separated
        end

        is_conditioned = node in Z

        if from_child
            # Came from child
            if node ∉ visited_from_child
                push!(visited_from_child, node)

                if !is_conditioned
                    # Can go to parents
                    for parent in get_parents(g, node)
                        push!(queue, (parent, false))
                    end
                end

                if is_conditioned || node in Z_ancestors
                    # Can go to children (collider opened)
                    for child in get_children(g, node)
                        push!(queue, (child, true))
                    end
                end
            end
        else
            # Came from parent
            if node ∉ visited_from_parent
                push!(visited_from_parent, node)

                if !is_conditioned
                    # Can go to children
                    for child in get_children(g, node)
                        push!(queue, (child, true))
                    end
                    # Can go to parents (fork)
                    for parent in get_parents(g, node)
                        push!(queue, (parent, false))
                    end
                end
            end
        end
    end

    return true  # No path found, d-separated
end

"""
    topological_sort(g)

Return nodes in topological order.
"""
function topological_sort(g::CausalGraph)
    n = length(g.nodes)
    visited = falses(n)
    order = String[]

    function dfs(i)
        visited[i] = true
        for j in 1:n
            if g.adjacency[i, j] == 1 && !visited[j]
                dfs(j)
            end
        end
        pushfirst!(order, g.nodes[i])
    end

    for i in 1:n
        if !visited[i]
            dfs(i)
        end
    end

    return order
end

#=============================================================================
  STRUCTURAL CAUSAL MODEL
=============================================================================#

"""
    SCM (Structural Causal Model)

Full SCM with structural equations and exogenous noise.
"""
mutable struct SCM
    graph::CausalGraph
    structural_equations::Dict{String, Function}  # V = f(Pa(V), U_V)
    noise_distributions::Dict{String, Distribution}
    data::Union{Nothing, Matrix{Float64}}
    var_names::Vector{String}
end

function SCM(nodes::Vector{String})
    graph = CausalGraph(nodes)
    equations = Dict{String, Function}()
    noise = Dict{String, Distribution}(v => Normal(0, 1) for v in nodes)
    SCM(graph, equations, noise, nothing, nodes)
end

function set_equation!(scm::SCM, node::String,
                       equation::Function,
                       noise_dist::Distribution=Normal(0, 1))
    scm.structural_equations[node] = equation
    scm.noise_distributions[node] = noise_dist
end

"""
    sample(scm, n)

Sample from the SCM (observational distribution).
"""
function sample(scm::SCM, n::Int)
    nodes = topological_sort(scm.graph)
    data = Dict{String, Vector{Float64}}()

    # Sample exogenous noise
    U = Dict(v => rand(scm.noise_distributions[v], n) for v in nodes)

    for v in nodes
        parents = get_parents(scm.graph, v)
        if isempty(parents)
            # Exogenous variable
            if haskey(scm.structural_equations, v)
                data[v] = scm.structural_equations[v](U[v])
            else
                data[v] = U[v]
            end
        else
            # Endogenous variable
            parent_data = hcat([data[p] for p in parents]...)
            data[v] = scm.structural_equations[v](parent_data, U[v])
        end
    end

    return hcat([data[v] for v in scm.var_names]...)
end

"""
    intervene(scm, interventions)

Create interventional SCM by cutting edges and fixing values.
do(X = x) operation.
"""
function intervene(scm::SCM, interventions::Dict{String, Float64})
    # Create mutilated graph
    new_graph = CausalGraph(scm.graph.nodes)
    new_graph.adjacency = copy(scm.graph.adjacency)

    # Remove incoming edges to intervened variables
    for (var, _) in interventions
        j = new_graph.node_index[var]
        new_graph.adjacency[:, j] .= 0
    end

    # Create new equations (constants for intervened variables)
    new_equations = copy(scm.structural_equations)
    for (var, val) in interventions
        new_equations[var] = (args...) -> fill(val, length(args[end]))
    end

    return SCM(new_graph, new_equations, scm.noise_distributions, nothing, scm.var_names)
end

end # module
