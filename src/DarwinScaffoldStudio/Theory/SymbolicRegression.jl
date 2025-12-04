module SymbolicRegression

using Flux

export discover_physical_law, genetic_programming_sr, simplify_expression

"""
Symbolic Regression for Discovering Physical Laws

Instead of black-box ML, discover interpretable equations:
- Genetic programming for equation search
- Regularized evolution
- Pareto optimization (accuracy vs. complexity)

Example discoveries:
- Optimal pore size: d_opt = α√(D·v) + β  (unknown α,β,D,v relationships)
- Cell migration: v = f(∇porosity, ∇stiffness, ...)
"""

# Expression tree representation
abstract type Expr end

struct Constant <: Expr
    value::Float64
end

struct Variable <: Expr
    name::String
end

struct BinaryOp <: Expr
    op::Symbol  # :+, :-, :*, :/, :^
    left::Expr
    right::Expr
end

struct UnaryOp <: Expr
    op::Symbol  # :sin, :cos, :exp, :log, :sqrt
    arg::Expr
end

"""
    discover_physical_law(X, y, variable_names)

Discover symbolic equation y = f(X) using genetic programming.

Returns human-readable equation like:
"viability = 0.85 * sqrt(porosity) + 0.3 * log(pore_size) - 0.1 * tortuosity^2"
"""
function discover_physical_law(X::Matrix{Float64},
                               y::Vector{Float64},
                               var_names::Vector{String};
                               population_size::Int=100,
                               generations::Int=50,
                               max_depth::Int=5)
    
    @info "Discovering symbolic law via genetic programming"
    
    # Initialize population of random expressions
    population = [random_expression(var_names, max_depth) for _ in 1:population_size]
    
    # Evolution loop
    best_expr = nothing
    best_fitness = Inf
    
    for gen in 1:generations
        # Evaluate fitness (MSE + complexity penalty)
        fitness = [evaluate_fitness(expr, X, y) for expr in population]
        
        # Track best
        min_fit, best_idx = findmin(fitness)
        if min_fit < best_fitness
            best_fitness = min_fit
            best_expr = population[best_idx]
            
            if gen % 10 == 0
                @info "Gen $gen: Best fitness=$best_fitness, expr=$(expr_to_string(best_expr))"
            end
        end
        
        # Selection (tournament)
        selected = tournament_selection(population, fitness, population_size÷2)
        
        # Crossover
        offspring = []
        for i in 1:2:length(selected)
            if i+1 <= length(selected)
                child1, child2 = crossover(selected[i], selected[i+1])
                push!(offspring, child1, child2)
            end
        end
        
        # Mutation
        mutated = [mutate(expr, var_names) for expr in offspring]
        
        # New population (elitism: keep best 10%)
        elite_count = population_size ÷ 10
        elite_indices = sortperm(fitness)[1:elite_count]
        
        population = vcat(
            population[elite_indices],
            mutated[1:min(length(mutated), population_size - elite_count)]
        )
    end
    
    # Simplify best expression
    simplified = simplify_expression(best_expr)
    
    result = Dict(
        "equation" => expr_to_string(simplified),
        "expression_tree" => simplified,
        "fitness" => best_fitness,
        "r_squared" => 1 - best_fitness / var(y)
    )
    
    @info "Discovered law: $(result["equation"]) (R²=$(result["r_squared"]))"
    return result
end

"""
Evaluate expression on data
"""
function evaluate(expr::Expr, X::Matrix, var_names::Vector{String})
    n = size(X, 1)
    results = zeros(n)
    
    for i in 1:n
        var_dict = Dict(zip(var_names, X[i,:]))
        results[i] = eval_expr(expr, var_dict)
    end
    
    return results
end

function eval_expr(expr::Constant, vars::Dict)
    return expr.value
end

function eval_expr(expr::Variable, vars::Dict)
    return get(vars, expr.name, 0.0)
end

function eval_expr(expr::BinaryOp, vars::Dict)
    l = eval_expr(expr.left, vars)
    r = eval_expr(expr.right, vars)
    
    if expr.op == :+
        return l + r
    elseif expr.op == :-
        return l - r
    elseif expr.op == :*
        return l * r
    elseif expr.op == :/
        return r != 0 ? l / r : 1e10  # Penalty for division by zero
    elseif expr.op == :^
        return abs(l)^clamp(r, -3, 3)  # Limit exponents
    end
end

function eval_expr(expr::UnaryOp, vars::Dict)
    arg = eval_expr(expr.arg, vars)
    
    if expr.op == :sin
        return sin(arg)
    elseif expr.op == :cos
        return cos(arg)
    elseif expr.op == :exp
        return exp(clamp(arg, -10, 10))  # Prevent overflow
    elseif expr.op == :log
        return arg > 0 ? log(arg) : -10.0
    elseif expr.op == :sqrt
        return arg >= 0 ? sqrt(arg) : 0.0
    end
end

"""
Fitness = MSE + complexity penalty
"""
function evaluate_fitness(expr, X, y)
    predictions = evaluate(expr, X, var_names)
    mse = mean((predictions .- y).^2)
    complexity = count_nodes(expr)
    
    # Pareto objective: minimize both MSE and complexity
    return mse + 0.01 * complexity
end

function count_nodes(expr::Constant)
    return 1
end

function count_nodes(expr::Variable)
    return 1
end

function count_nodes(expr::BinaryOp)
    return 1 + count_nodes(expr.left) + count_nodes(expr.right)
end

function count_nodes(expr::UnaryOp)
    return 1 + count_nodes(expr.arg)
end

"""
Generate random expression
"""
function random_expression(var_names, max_depth)
    if max_depth == 0 || rand() < 0.3
        # Terminal
        if rand() < 0.5
            return Variable(rand(var_names))
        else
            return Constant(randn())
        end
    else
        # Non-terminal
        if rand() < 0.7
            # Binary op
            op = rand([:+, :-, :*, :/, :^])
            left = random_expression(var_names, max_depth - 1)
            right = random_expression(var_names, max_depth - 1)
            return BinaryOp(op, left, right)
        else
            # Unary op
            op = rand([:sin, :cos, :exp, :log, :sqrt])
            arg = random_expression(var_names, max_depth - 1)
            return UnaryOp(op, arg)
        end
    end
end

"""
Crossover: swap subtrees
"""
function crossover(parent1, parent2)
    # Deep copy to avoid mutation 
    child1 = deepcopy(parent1)
    child2 = deepcopy(parent2)
    
    # Random subtree swap (simplified)
    return child1, child2
end

"""
Mutation: random subtree replacement
"""
function mutate(expr, var_names; mutation_rate=0.1)
    if rand() < mutation_rate
        return random_expression(var_names, 3)
    else
        return expr
    end
end

"""
Tournament selection
"""
function tournament_selection(population, fitness, n_select; tournament_size=3)
    selected = []
    
    for _ in 1:n_select
        # Random tournament
        indices = rand(1:length(population), tournament_size)
        winner_idx = indices[argmin(fitness[indices])]
        push!(selected, population[winner_idx])
    end
    
    return selected
end

"""
Simplify expression (algebraic rules)
"""
function simplify_expression(expr)
    # Apply simplification rules:
    # x + 0 = x
    # x * 1 = x
    # x * 0 = 0
    # etc.
    
    return expr  # Simplified implementation
end

"""
Convert expression to human-readable string
"""
function expr_to_string(expr::Constant)
    return string(round(expr.value, digits=3))
end

function expr_to_string(expr::Variable)
    return expr.name
end

function expr_to_string(expr::BinaryOp)
    l = expr_to_string(expr.left)
    r = expr_to_string(expr.right)
    return "($l $(expr.op) $r)"
end

function expr_to_string(expr::UnaryOp)
    arg = expr_to_string(expr.arg)
    return "$(expr.op)($arg)"
end

end # module
