"""
    AnnotationValidation

Validation of scaffold annotations for biological consistency.

Validates:
- Cell-tissue compatibility
- Material-application suitability
- Process relevance
- Parameter ranges
"""
module AnnotationValidation

export AnnotationValidationResult, validate_annotation
export check_tissue_cell_compatibility, check_material_application
export check_process_relevance, validate_parameters

# Dependencies - set by OntologyManager
const _smart_lookup = Ref{Function}(id -> nothing)
const _get_scaffold_recommendations = Ref{Function}(id -> [])
const _get_cells_for_tissue = Ref{Function}(id -> [])
const _get_materials_for_application = Ref{Function}(id -> [])
const _get_biological_processes = Ref{Function}(id -> [])
const _semantic_similarity = Ref{Function}((id1, id2; method=nothing) -> 0.0)

# Placeholder similarity method
struct _WuPalmerSimilarity end
const _WuPalmer = Ref{Any}(_WuPalmerSimilarity())

"""Configure validation functions (called by OntologyManager)."""
function configure!(;
    smart_lookup::Function,
    get_scaffold_recommendations::Function,
    get_cells_for_tissue::Function,
    get_materials_for_application::Function,
    get_biological_processes::Function,
    semantic_similarity::Function,
    wu_palmer_method
)
    _smart_lookup[] = smart_lookup
    _get_scaffold_recommendations[] = get_scaffold_recommendations
    _get_cells_for_tissue[] = get_cells_for_tissue
    _get_materials_for_application[] = get_materials_for_application
    _get_biological_processes[] = get_biological_processes
    _semantic_similarity[] = semantic_similarity
    _WuPalmer[] = wu_palmer_method
end

#=============================================================================
  TYPES
=============================================================================#

"""
    AnnotationValidationResult

Result of validating a scaffold annotation.
"""
struct AnnotationValidationResult
    is_valid::Bool
    errors::Vector{String}
    warnings::Vector{String}
    suggestions::Vector{String}
    compatibility_scores::Dict{String,Float64}
end

#=============================================================================
  VALIDATION FUNCTIONS
=============================================================================#

"""
    validate_annotation(annotation::Dict) -> AnnotationValidationResult

Validate a scaffold annotation for biological consistency.

# Checks performed:
1. Cell-tissue compatibility (are these cells found in this tissue?)
2. Material-application suitability (is this material appropriate?)
3. Process relevance (are these processes related to the tissue?)
4. Parameter ranges (are metrics within recommended ranges?)
"""
function validate_annotation(annotation::Dict)::AnnotationValidationResult
    errors = String[]
    warnings = String[]
    suggestions = String[]
    scores = Dict{String,Float64}()

    tissue_id = get(annotation, "tissue_id", nothing)
    isnothing(tissue_id) && push!(errors, "Missing tissue specification")

    # Get tissue term
    tissue = !isnothing(tissue_id) ? _smart_lookup[](tissue_id) : nothing

    # Validate cells
    if haskey(annotation, "cells") && !isnothing(tissue)
        cell_ids = annotation["cells"]
        cell_score = check_tissue_cell_compatibility(tissue_id, cell_ids)
        scores["cell_compatibility"] = cell_score

        if cell_score < 0.3
            push!(warnings, "Low cell-tissue compatibility score ($(round(cell_score, digits=2)))")

            # Suggest better cells
            recommended = _get_cells_for_tissue[](tissue_id)
            if !isempty(recommended)
                rec_names = join([c.name for c in recommended[1:min(3, length(recommended))]], ", ")
                push!(suggestions, "Consider using: $(rec_names)")
            end
        end
    end

    # Validate materials
    if haskey(annotation, "materials") && !isnothing(tissue)
        mat_ids = annotation["materials"]
        mat_score = check_material_application(tissue_id, mat_ids)
        scores["material_suitability"] = mat_score

        if mat_score < 0.3
            push!(warnings, "Low material suitability score ($(round(mat_score, digits=2)))")

            recommended = _get_materials_for_application[](tissue_id)
            if !isempty(recommended)
                rec_names = join([m.name for m in recommended[1:min(3, length(recommended))]], ", ")
                push!(suggestions, "Consider using: $(rec_names)")
            end
        end
    end

    # Validate parameters
    if haskey(annotation, "metrics") && !isnothing(tissue)
        metrics = annotation["metrics"]
        param_issues = validate_parameters(tissue_id, metrics)
        append!(warnings, param_issues.warnings)
        append!(suggestions, param_issues.suggestions)
        scores["parameter_compliance"] = param_issues.score
    end

    # Check biological process relevance
    if haskey(annotation, "processes") && !isnothing(tissue)
        proc_ids = annotation["processes"]
        proc_score = check_process_relevance(tissue_id, proc_ids)
        scores["process_relevance"] = proc_score

        if proc_score < 0.3
            push!(warnings, "Selected processes may not be relevant to target tissue")
        end
    end

    # Overall validity
    is_valid = isempty(errors)

    return AnnotationValidationResult(is_valid, errors, warnings, suggestions, scores)
end

"""
    check_tissue_cell_compatibility(tissue_id::String, cell_ids::Vector{String}) -> Float64

Check if cells are compatible with target tissue.
Returns score 0-1 based on semantic similarity and known associations.
"""
function check_tissue_cell_compatibility(tissue_id::String, cell_ids::Vector{String})::Float64
    isempty(cell_ids) && return 0.0

    # Get recommended cells for this tissue
    recommended = _get_cells_for_tissue[](tissue_id)
    rec_ids = Set([c.id for c in recommended])

    scores = Float64[]
    for cell_id in cell_ids
        if cell_id in rec_ids
            # Exact match with recommendation
            push!(scores, 1.0)
        else
            # Check semantic similarity to recommended cells
            best_sim = 0.0
            for rec_id in rec_ids
                sim = _semantic_similarity[](cell_id, rec_id; method=_WuPalmer[])
                best_sim = max(best_sim, sim)
            end
            push!(scores, best_sim)
        end
    end

    return _mean(scores)
end

"""
    check_material_application(tissue_id::String, material_ids::Vector{String}) -> Float64

Check if materials are suitable for target application.
"""
function check_material_application(tissue_id::String, material_ids::Vector{String})::Float64
    isempty(material_ids) && return 0.0

    recommended = _get_materials_for_application[](tissue_id)
    rec_ids = Set([m.id for m in recommended])

    scores = Float64[]
    for mat_id in material_ids
        if mat_id in rec_ids
            push!(scores, 1.0)
        else
            best_sim = 0.0
            for rec_id in rec_ids
                sim = _semantic_similarity[](mat_id, rec_id; method=_WuPalmer[])
                best_sim = max(best_sim, sim)
            end
            push!(scores, best_sim)
        end
    end

    return _mean(scores)
end

"""Check relevance of biological processes to tissue."""
function check_process_relevance(tissue_id::String, process_ids::Vector{String})::Float64
    isempty(process_ids) && return 0.0

    recommended = _get_biological_processes[](tissue_id)
    rec_ids = Set([p.id for p in recommended])

    scores = Float64[]
    for proc_id in process_ids
        if proc_id in rec_ids
            push!(scores, 1.0)
        else
            best_sim = 0.0
            for rec_id in rec_ids
                sim = _semantic_similarity[](proc_id, rec_id; method=_WuPalmer[])
                best_sim = max(best_sim, sim)
            end
            push!(scores, best_sim)
        end
    end

    return _mean(scores)
end

"""Validate scaffold parameters against tissue-specific recommendations."""
function validate_parameters(tissue_id::String, metrics::Dict)
    warnings = String[]
    suggestions = String[]
    score = 1.0

    recs = _get_scaffold_recommendations[](tissue_id)
    param_recs = Dict(r.name => r for r in recs if r.category == :parameter)

    # Check pore size
    if haskey(metrics, "pore_size_um") && haskey(param_recs, "pore_size_um")
        rec = param_recs["pore_size_um"]
        value = metrics["pore_size_um"]
        min_val, max_val = rec.parameters["min"], rec.parameters["max"]
        optimal = rec.parameters["optimal"]

        if value < min_val
            push!(warnings, "Pore size $(value)um below recommended minimum $(min_val)um")
            score -= 0.2
        elseif value > max_val
            push!(warnings, "Pore size $(value)um above recommended maximum $(max_val)um")
            score -= 0.2
        end

        push!(suggestions, "Optimal pore size for this tissue: $(optimal)um")
    end

    # Check porosity
    if haskey(metrics, "porosity") && haskey(param_recs, "porosity_percent")
        rec = param_recs["porosity_percent"]
        value = metrics["porosity"] * 100  # Convert to percent
        min_val, max_val = rec.parameters["min"], rec.parameters["max"]

        if value < min_val
            push!(warnings, "Porosity $(round(value, digits=1))% below recommended $(min_val)%")
            score -= 0.2
        end
    end

    # Check elastic modulus
    if haskey(metrics, "elastic_modulus_mpa") && haskey(param_recs, "elastic_modulus_mpa")
        rec = param_recs["elastic_modulus_mpa"]
        value = metrics["elastic_modulus_mpa"]
        min_val, max_val = rec.parameters["min"], rec.parameters["max"]

        if value < min_val || value > max_val
            push!(warnings, "Elastic modulus $(value) MPa outside recommended range $(min_val)-$(max_val) MPa")
            score -= 0.15
        end
    end

    return (warnings=warnings, suggestions=suggestions, score=max(0.0, score))
end

#=============================================================================
  UTILITIES
=============================================================================#

"""Simple mean function."""
function _mean(x::Vector{Float64})::Float64
    isempty(x) && return 0.0
    return sum(x) / length(x)
end

"""Pretty print validation result."""
function Base.show(io::IO, result::AnnotationValidationResult)
    status = result.is_valid ? "VALID" : "INVALID"
    println(io, "AnnotationValidationResult: $(status)")

    if !isempty(result.errors)
        println(io, "  Errors:")
        for e in result.errors
            println(io, "    - $(e)")
        end
    end

    if !isempty(result.warnings)
        println(io, "  Warnings:")
        for w in result.warnings
            println(io, "    - $(w)")
        end
    end

    if !isempty(result.suggestions)
        println(io, "  Suggestions:")
        for s in result.suggestions
            println(io, "    - $(s)")
        end
    end

    if !isempty(result.compatibility_scores)
        println(io, "  Scores:")
        for (k, v) in result.compatibility_scores
            println(io, "    $(k): $(round(v, digits=2))")
        end
    end
end

end # module
