"""
    KnowledgeGraph

Knowledge graph for scaffold research with epistemic tracking.
Implements hyperbolic semantic network from ONTOLOGY.md.

# Features
- Store scaffolds, materials, processes as nodes
- Track relationships with confidence
- Query by semantic similarity
- Export to RDF/JSON-LD
"""
module KnowledgeGraph

using ..Ontology: Knowledge, Confidence, Provenance, OntologyBinding,
                  ScaffoldConcept, MaterialConcept, ProcessConcept,
                  ConceptEmbedding, semantic_distance,
                  create_knowledge, high_confidence, medium_confidence, low_confidence,
                  to_schema_org
using Graphs
using UUIDs
using Dates

export ScaffoldKG, add_node!, add_edge!, query_similar, query_by_property
export KGNode, KGEdge, RelationType

#=============================================================================
  GRAPH STRUCTURE
=============================================================================#

"""Relation types between concepts"""
@enum RelationType begin
    MADE_OF          # scaffold -> material
    FABRICATED_BY    # scaffold -> process
    ANALYZED_WITH    # scaffold -> method
    DERIVED_FROM     # knowledge -> knowledge
    CITES            # any -> publication
    SIMILAR_TO       # semantic similarity
    CONTRADICTS      # conflicting findings
    VALIDATES        # supporting evidence
end

"""
    KGNode

Node in the knowledge graph with epistemic metadata.
"""
struct KGNode
    id::UUID
    concept_type::Symbol  # :scaffold, :material, :process, :measurement, :publication
    data::Any             # The actual concept (ScaffoldConcept, MaterialConcept, etc.)
    embedding::Union{ConceptEmbedding, Nothing}  # Hyperbolic embedding
    confidence::Confidence
    created::DateTime
end

"""
    KGEdge

Edge in the knowledge graph with relation metadata.
"""
struct KGEdge
    source::UUID
    target::UUID
    relation::RelationType
    confidence::Confidence
    properties::Dict{String, Any}
    provenance::Provenance
end

"""
    ScaffoldKG

Knowledge graph specialized for scaffold research.
"""
mutable struct ScaffoldKG
    nodes::Dict{UUID, KGNode}
    edges::Vector{KGEdge}
    graph::SimpleDiGraph{Int}  # For graph algorithms
    id_to_vertex::Dict{UUID, Int}
    vertex_to_id::Dict{Int, UUID}

    # Indexes for fast lookup
    by_type::Dict{Symbol, Vector{UUID}}
    by_material::Dict{String, Vector{UUID}}

    # Metadata
    name::String
    created::DateTime
    version::String

    function ScaffoldKG(name::String="DarwinKG")
        new(
            Dict{UUID, KGNode}(),
            KGEdge[],
            SimpleDiGraph{Int}(),
            Dict{UUID, Int}(),
            Dict{Int, UUID}(),
            Dict{Symbol, Vector{UUID}}(),
            Dict{String, Vector{UUID}}(),
            name,
            now(),
            "1.0.0"
        )
    end
end

#=============================================================================
  GRAPH OPERATIONS
=============================================================================#

"""
    add_node!(kg::ScaffoldKG, concept; embedding=nothing) -> UUID

Add a concept to the knowledge graph.
"""
function add_node!(kg::ScaffoldKG, concept::ScaffoldConcept;
                  embedding::Union{ConceptEmbedding, Nothing}=nothing)
    node = KGNode(
        concept.id,
        :scaffold,
        concept,
        embedding,
        concept.porosity.confidence,  # Use porosity confidence as node confidence
        now()
    )

    # Add to graph
    add_vertex!(kg.graph)
    v = nv(kg.graph)
    kg.id_to_vertex[concept.id] = v
    kg.vertex_to_id[v] = concept.id
    kg.nodes[concept.id] = node

    # Update indexes
    push!(get!(kg.by_type, :scaffold, UUID[]), concept.id)
    push!(get!(kg.by_material, concept.material.value, UUID[]), concept.id)

    concept.id
end

function add_node!(kg::ScaffoldKG, concept::MaterialConcept;
                  embedding::Union{ConceptEmbedding, Nothing}=nothing)
    node = KGNode(
        concept.id,
        :material,
        concept,
        embedding,
        concept.elastic_modulus_solid.confidence,
        now()
    )

    add_vertex!(kg.graph)
    v = nv(kg.graph)
    kg.id_to_vertex[concept.id] = v
    kg.vertex_to_id[v] = concept.id
    kg.nodes[concept.id] = node

    push!(get!(kg.by_type, :material, UUID[]), concept.id)

    concept.id
end

function add_node!(kg::ScaffoldKG, concept::ProcessConcept;
                  embedding::Union{ConceptEmbedding, Nothing}=nothing)
    node = KGNode(
        concept.id,
        :process,
        concept,
        embedding,
        medium_confidence(),
        now()
    )

    add_vertex!(kg.graph)
    v = nv(kg.graph)
    kg.id_to_vertex[concept.id] = v
    kg.vertex_to_id[v] = concept.id
    kg.nodes[concept.id] = node

    push!(get!(kg.by_type, :process, UUID[]), concept.id)

    concept.id
end

"""
    add_edge!(kg::ScaffoldKG, source, target, relation; confidence, properties)

Add a relationship between concepts.
"""
function add_edge!(kg::ScaffoldKG,
                  source::UUID,
                  target::UUID,
                  relation::RelationType;
                  confidence::Confidence=medium_confidence(),
                  properties::Dict{String, Any}=Dict{String, Any}())

    # Add to graph structure
    v_src = kg.id_to_vertex[source]
    v_tgt = kg.id_to_vertex[target]
    add_edge!(kg.graph, v_src, v_tgt)

    # Create edge with provenance
    edge = KGEdge(
        source, target, relation, confidence, properties,
        Provenance("edge_creation", transformation="add_edge")
    )
    push!(kg.edges, edge)

    edge
end

#=============================================================================
  QUERIES
=============================================================================#

"""
    query_by_property(kg::ScaffoldKG, property, op, value) -> Vector{KGNode}

Query nodes by property value.
"""
function query_by_property(kg::ScaffoldKG,
                          property::Symbol,
                          op::Function,
                          value)
    results = KGNode[]

    for (id, node) in kg.nodes
        if node.concept_type == :scaffold
            scaffold = node.data::ScaffoldConcept
            prop_value = if property == :porosity
                scaffold.porosity.value
            elseif property == :pore_size
                scaffold.pore_size_um.value
            elseif property == :interconnectivity
                scaffold.interconnectivity.value
            elseif property == :material
                scaffold.material.value
            else
                continue
            end

            if op(prop_value, value)
                push!(results, node)
            end
        end
    end

    results
end

"""
    query_similar(kg::ScaffoldKG, node_id::UUID; k=5) -> Vector{Tuple{UUID, Float64}}

Find k most similar nodes using hyperbolic distance.
"""
function query_similar(kg::ScaffoldKG, node_id::UUID; k::Int=5)
    source_node = kg.nodes[node_id]

    if isnothing(source_node.embedding)
        error("Source node has no embedding")
    end

    distances = Tuple{UUID, Float64}[]

    for (id, node) in kg.nodes
        if id != node_id && !isnothing(node.embedding)
            d = semantic_distance(source_node.embedding, node.embedding)
            push!(distances, (id, d))
        end
    end

    sort!(distances, by=x->x[2])
    distances[1:min(k, length(distances))]
end

"""
    query_high_confidence(kg::ScaffoldKG; threshold=0.8) -> Vector{KGNode}

Get all nodes with confidence above threshold.
"""
function query_high_confidence(kg::ScaffoldKG; threshold::Float64=0.8)
    [node for (_, node) in kg.nodes if node.confidence.value >= threshold]
end

"""
    query_by_provenance(kg::ScaffoldKG, source_pattern::String) -> Vector{KGNode}

Find nodes derived from a specific source.
"""
function query_by_provenance(kg::ScaffoldKG, source_pattern::String)
    results = KGNode[]
    for (_, node) in kg.nodes
        if node.concept_type == :scaffold
            scaffold = node.data::ScaffoldConcept
            if occursin(source_pattern, scaffold.porosity.provenance.source)
                push!(results, node)
            end
        end
    end
    results
end

#=============================================================================
  CONFLICT DETECTION - From ONTOLOGY.md ConflictSingularity
=============================================================================#

"""
    detect_conflicts(kg::ScaffoldKG) -> Vector{Tuple{KGNode, KGNode, String}}

Detect contradicting knowledge in the graph.
"""
function detect_conflicts(kg::ScaffoldKG)
    conflicts = Tuple{KGNode, KGNode, String}[]

    scaffolds = [node for (_, node) in kg.nodes if node.concept_type == :scaffold]

    for i in 1:length(scaffolds)
        for j in (i+1):length(scaffolds)
            s1 = scaffolds[i].data::ScaffoldConcept
            s2 = scaffolds[j].data::ScaffoldConcept

            # Check for conflicting measurements on same material
            if s1.material.value == s2.material.value
                # Large discrepancy in porosity for same material
                if abs(s1.porosity.value - s2.porosity.value) > 0.2
                    push!(conflicts, (scaffolds[i], scaffolds[j],
                          "Porosity discrepancy: $(s1.porosity.value) vs $(s2.porosity.value)"))
                end
            end
        end
    end

    conflicts
end

#=============================================================================
  EXPORT
=============================================================================#

"""
    to_rdf(kg::ScaffoldKG) -> String

Export knowledge graph as RDF/Turtle.
"""
function to_rdf(kg::ScaffoldKG)
    lines = [
        "@prefix schema: <https://schema.org/> .",
        "@prefix darwin: <https://darwin.scaffold.studio/ontology#> .",
        "@prefix xsd: <http://www.w3.org/2001/XMLSchema#> .",
        ""
    ]

    for (id, node) in kg.nodes
        if node.concept_type == :scaffold
            scaffold = node.data::ScaffoldConcept
            push!(lines, "<darwin:scaffold/$(id)> a schema:MedicalDevice ;")
            push!(lines, "    schema:name \"$(scaffold.name)\" ;")
            push!(lines, "    darwin:porosity \"$(scaffold.porosity.value)\"^^xsd:float ;")
            push!(lines, "    darwin:confidence \"$(scaffold.porosity.confidence.value)\"^^xsd:float .")
            push!(lines, "")
        end
    end

    join(lines, "\n")
end

"""
    export_schema_org(kg::ScaffoldKG) -> Dict

Export entire knowledge graph as Schema.org Dataset.
"""
function export_schema_org(kg::ScaffoldKG)
    scaffolds = [node.data for (_, node) in kg.nodes if node.concept_type == :scaffold]
    to_schema_org(kg.name, scaffolds)
end

end # module
