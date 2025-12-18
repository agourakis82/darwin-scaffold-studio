"""
    SemanticSimilarity

Semantic similarity computation between ontology terms.

Implements three standard methods from computational linguistics:
- Wu-Palmer (1994): Path-based using LCA depth
- Resnik (1995): Information Content of LCA
- Lin (1998): Normalized IC similarity

References:
- Wu & Palmer, 1994. Verb semantics and lexical selection
- Resnik, 1995. Using information content to evaluate semantic similarity
- Lin, 1998. An information-theoretic definition of similarity
"""
module SemanticSimilarity

export SemanticSimilarityMethod, LinSimilarity, WuPalmerSimilarity, ResnikSimilarity
export semantic_similarity, find_similar_terms, compute_ic
export get_depth, get_lowest_common_ancestor

# Import from parent module for graph traversal
# These will be set by OntologyManager when it loads this module
const _get_ancestors = Ref{Function}((id; max_depth=10) -> [])
const _get_descendants = Ref{Function}((id; max_depth=3) -> [])

"""Configure the graph traversal functions (called by OntologyManager)."""
function configure!(get_ancestors_fn::Function, get_descendants_fn::Function)
    _get_ancestors[] = get_ancestors_fn
    _get_descendants[] = get_descendants_fn
end

#=============================================================================
  TYPES
=============================================================================#

"""Semantic similarity calculation methods."""
abstract type SemanticSimilarityMethod end
struct WuPalmerSimilarity <: SemanticSimilarityMethod end
struct ResnikSimilarity <: SemanticSimilarityMethod end
struct LinSimilarity <: SemanticSimilarityMethod end

#=============================================================================
  INFORMATION CONTENT
=============================================================================#

# Precomputed term frequencies for IC calculation (from OBO Foundry corpus statistics)
const TERM_FREQUENCIES = Dict{String,Float64}()
const TOTAL_ANNOTATIONS = Ref{Float64}(1_000_000.0)  # Approximate corpus size

"""
    get_depth(id::String) -> Int

Get depth of term in ontology hierarchy (distance from root).
"""
function get_depth(id::String)::Int
    ancestors = _get_ancestors[](id; max_depth=20)
    return length(ancestors)
end

"""
    get_lowest_common_ancestor(id1::String, id2::String) -> Union{String, Nothing}

Find the Lowest Common Ancestor (LCA) of two terms.
Returns the most specific term that is an ancestor of both.
"""
function get_lowest_common_ancestor(id1::String, id2::String)::Union{String,Nothing}
    # Get all ancestors for both terms
    ancestors1 = Set{String}([id1])
    for a in _get_ancestors[](id1; max_depth=15)
        push!(ancestors1, a.id)
    end

    ancestors2 = Set{String}([id2])
    for a in _get_ancestors[](id2; max_depth=15)
        push!(ancestors2, a.id)
    end

    # Find common ancestors
    common = intersect(ancestors1, ancestors2)
    isempty(common) && return nothing

    # Find the deepest (most specific) common ancestor
    max_depth = -1
    lca = nothing
    for anc_id in common
        d = get_depth(anc_id)
        if d > max_depth
            max_depth = d
            lca = anc_id
        end
    end

    return lca
end

"""
    compute_ic(id::String) -> Float64

Compute Information Content (IC) of a term.
IC(c) = -log(P(c)) where P(c) is probability of term occurrence.

Uses corpus-based frequency estimation with fallback to structure-based.
"""
function compute_ic(id::String)::Float64
    # Check if we have precomputed frequency
    if haskey(TERM_FREQUENCIES, id)
        freq = TERM_FREQUENCIES[id]
        return -log(freq / TOTAL_ANNOTATIONS[])
    end

    # Fallback: estimate IC from ontology structure
    # More specific terms (more descendants) have higher IC
    descendants = _get_descendants[](id; max_depth=5)
    n_descendants = length(descendants) + 1  # +1 for self

    # Estimate probability inversely proportional to specificity
    # Root terms have low IC, leaf terms have high IC
    depth = get_depth(id)

    # Heuristic: combine depth and descendants for IC estimate
    # Deeper terms with fewer descendants = higher IC
    estimated_prob = 1.0 / (depth + 1) * (n_descendants / 100.0 + 0.01)
    estimated_prob = clamp(estimated_prob, 1e-10, 0.99)

    return -log(estimated_prob)
end

#=============================================================================
  SIMILARITY COMPUTATION
=============================================================================#

"""
    semantic_similarity(id1::String, id2::String; method=WuPalmerSimilarity()) -> Float64

Compute semantic similarity between two ontology terms.

# Methods
- `WuPalmerSimilarity()`: 2*depth(LCA) / (depth(c1) + depth(c2))
- `ResnikSimilarity()`: IC(LCA)
- `LinSimilarity()`: 2*IC(LCA) / (IC(c1) + IC(c2))

# Returns
Similarity score in [0, 1] for Wu-Palmer and Lin, unbounded for Resnik.
"""
function semantic_similarity(id1::String, id2::String;
                             method::SemanticSimilarityMethod=WuPalmerSimilarity())::Float64
    # Same term = maximum similarity
    id1 == id2 && return 1.0

    # Find LCA
    lca = get_lowest_common_ancestor(id1, id2)
    isnothing(lca) && return 0.0

    return _compute_similarity(method, id1, id2, lca)
end

function _compute_similarity(::WuPalmerSimilarity, id1::String, id2::String, lca::String)::Float64
    depth1 = get_depth(id1)
    depth2 = get_depth(id2)
    depth_lca = get_depth(lca)

    denominator = depth1 + depth2
    denominator == 0 && return 0.0

    return 2.0 * depth_lca / denominator
end

function _compute_similarity(::ResnikSimilarity, id1::String, id2::String, lca::String)::Float64
    return compute_ic(lca)
end

function _compute_similarity(::LinSimilarity, id1::String, id2::String, lca::String)::Float64
    ic1 = compute_ic(id1)
    ic2 = compute_ic(id2)
    ic_lca = compute_ic(lca)

    denominator = ic1 + ic2
    denominator == 0.0 && return 0.0

    return 2.0 * ic_lca / denominator
end

"""
    find_similar_terms(id::String, candidates::Vector{String};
                       method=WuPalmerSimilarity(), top_k::Int=10) -> Vector{Tuple{String, Float64}}

Find most similar terms from a candidate set.

# Returns
Vector of (term_id, similarity_score) tuples, sorted by similarity descending.
"""
function find_similar_terms(id::String, candidates::Vector{String};
                            method::SemanticSimilarityMethod=WuPalmerSimilarity(),
                            top_k::Int=10)::Vector{Tuple{String,Float64}}
    similarities = Tuple{String,Float64}[]

    for cand in candidates
        cand == id && continue
        sim = semantic_similarity(id, cand; method=method)
        push!(similarities, (cand, sim))
    end

    # Sort by similarity descending
    sort!(similarities, by=x -> -x[2])

    return first(similarities, top_k)
end

end # module
