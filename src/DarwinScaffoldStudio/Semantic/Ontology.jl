"""
    Ontology

Epistemic ontology system for Darwin Scaffold Studio.
Integrates Demetrios-style Knowledge types with Schema.org vocabulary.

# Architecture
Based on the 4-Layer Ontology from Demetrios language:
- Layer 0: Primitives (850 terms) - BFO, Schema.org core
- Layer 1: Domain (tissue engineering, biomaterials)
- Layer 2: Application (scaffold analysis, optimization)
- Layer 3: Instance (specific experiments, datasets)

# Epistemic Types
Every piece of knowledge carries:
- τ (temporal): when it was known, context
- ε (epistemic): confidence, evidence sources
- δ (ontological): mapping to standard ontologies
- Φ (provenance): derivation chain

# References
- Demetrios Language: github.com/chiuratto-AI/demetrios
- Schema.org: schema.org
- BFO: Basic Formal Ontology
"""
module Ontology

using Dates
using UUIDs

export Knowledge, Confidence, Provenance, OntologyBinding
export ScaffoldConcept, MaterialConcept, ProcessConcept
export create_knowledge, with_confidence, derive_from
export to_schema_org, to_jsonld

#=============================================================================
  EPISTEMIC TYPES - Inspired by Demetrios Knowledge[τ, ε, δ, Φ]
=============================================================================#

"""
    Confidence

Epistemic confidence with multiple dimensions.
"""
struct Confidence
    value::Float64          # 0.0-1.0 confidence score
    method::Symbol          # :measured, :computed, :inferred, :assumed
    evidence_count::Int     # Number of supporting observations
    uncertainty::Float64    # Standard deviation or error margin

    function Confidence(value::Float64;
                       method::Symbol=:computed,
                       evidence_count::Int=1,
                       uncertainty::Float64=0.0)
        @assert 0.0 <= value <= 1.0 "Confidence must be in [0,1]"
        new(value, method, evidence_count, uncertainty)
    end
end

# Confidence constructors (no duplicate - inner constructor already handles single Float64)
high_confidence() = Confidence(0.95, method=:measured, evidence_count=10)
medium_confidence() = Confidence(0.75, method=:computed, evidence_count=3)
low_confidence() = Confidence(0.50, method=:inferred, evidence_count=1)
assumed() = Confidence(0.30, method=:assumed, evidence_count=0)

"""
    Provenance

Track the derivation chain of knowledge.
"""
struct Provenance
    id::UUID
    source::String              # Original source (paper DOI, measurement, computation)
    derived_from::Vector{UUID}  # Parent knowledge IDs
    transformation::String      # How it was derived
    timestamp::DateTime
    agent::String               # Who/what created this (human, AI, algorithm)

    function Provenance(source::String;
                       derived_from::Vector{UUID}=UUID[],
                       transformation::String="original",
                       agent::String="DarwinScaffoldStudio")
        new(uuid4(), source, derived_from, transformation, now(), agent)
    end
end

"""
    OntologyBinding

Maps to standard ontologies (Schema.org, BFO, domain-specific).
"""
struct OntologyBinding
    schema_org::Union{String, Nothing}    # Schema.org type (e.g., "Dataset", "MedicalDevice")
    bfo::Union{String, Nothing}           # BFO class (e.g., "material entity", "process")
    domain::Dict{String, String}          # Domain-specific mappings

    function OntologyBinding(;
                            schema_org::Union{String, Nothing}=nothing,
                            bfo::Union{String, Nothing}=nothing,
                            domain::Dict{String, String}=Dict())
        new(schema_org, bfo, domain)
    end
end

"""
    Knowledge{T}

Epistemic wrapper for any value, tracking confidence and provenance.
Implements Demetrios-style Knowledge[τ, ε, δ, Φ] pattern.

# Fields
- `value::T`: The actual knowledge content
- `temporal::DateTime`: When this knowledge was established (τ)
- `confidence::Confidence`: Epistemic status (ε)
- `binding::OntologyBinding`: Ontological mappings (δ)
- `provenance::Provenance`: Derivation chain (Φ)
"""
struct Knowledge{T}
    value::T
    temporal::DateTime          # τ - temporal context
    confidence::Confidence      # ε - epistemic properties
    binding::OntologyBinding    # δ - ontological bindings
    provenance::Provenance      # Φ - provenance chain
end

# Convenience constructors
function create_knowledge(value::T;
                         confidence::Confidence=medium_confidence(),
                         source::String="computation",
                         schema_org::Union{String, Nothing}=nothing) where T
    Knowledge{T}(
        value,
        now(),
        confidence,
        OntologyBinding(schema_org=schema_org),
        Provenance(source)
    )
end

function with_confidence(k::Knowledge{T}, conf::Confidence) where T
    Knowledge{T}(k.value, k.temporal, conf, k.binding, k.provenance)
end

function derive_from(value::T, parents::Vector{Knowledge},
                    transformation::String;
                    confidence::Confidence=medium_confidence()) where T
    parent_ids = [p.provenance.id for p in parents]
    avg_confidence = mean([p.confidence.value for p in parents])

    # Derived confidence is capped by parent confidence
    derived_conf = Confidence(
        min(confidence.value, avg_confidence),
        method=:inferred,
        evidence_count=length(parents)
    )

    Knowledge{T}(
        value,
        now(),
        derived_conf,
        OntologyBinding(),
        Provenance("derived", derived_from=parent_ids, transformation=transformation)
    )
end

#=============================================================================
  DOMAIN CONCEPTS - Tissue Engineering Ontology
=============================================================================#

"""
    ScaffoldConcept

Ontological representation of a scaffold.
Maps to Schema.org MedicalDevice + custom properties.
"""
struct ScaffoldConcept
    id::UUID
    name::String
    description::String

    # Morphological properties (with epistemic tracking)
    porosity::Knowledge{Float64}
    pore_size_um::Knowledge{Float64}
    interconnectivity::Knowledge{Float64}

    # Material
    material::Knowledge{String}

    # Mechanical
    elastic_modulus_mpa::Union{Knowledge{Float64}, Nothing}

    # Biological
    cell_viability::Union{Knowledge{Float64}, Nothing}

    # Provenance
    created::DateTime
    source_dataset::Union{String, Nothing}
end

"""
    MaterialConcept

Ontological representation of a biomaterial.
"""
struct MaterialConcept
    id::UUID
    name::String
    material_class::Symbol  # :polymer, :ceramic, :metal, :composite, :hydrogel

    # Properties
    elastic_modulus_solid::Knowledge{Float64}  # MPa
    degradation_rate::Union{Knowledge{Float64}, Nothing}
    biocompatibility::Knowledge{Symbol}  # :excellent, :good, :moderate, :poor

    # Standards
    iso_class::Union{String, Nothing}
    fda_status::Union{String, Nothing}
end

"""
    ProcessConcept

Ontological representation of a fabrication process.
"""
struct ProcessConcept
    id::UUID
    name::String
    method::Symbol  # :freeze_casting, :bioprinting, :electrospinning, :salt_leaching

    # Parameters
    parameters::Dict{String, Knowledge}

    # Capabilities
    min_pore_size_um::Float64
    max_pore_size_um::Float64
    porosity_range::Tuple{Float64, Float64}

    # References
    literature_refs::Vector{String}
end

#=============================================================================
  SCHEMA.ORG EXPORT - Interoperability Layer
=============================================================================#

"""
    to_schema_org(scaffold::ScaffoldConcept) -> Dict

Export scaffold as Schema.org compatible JSON-LD structure.
"""
function to_schema_org(scaffold::ScaffoldConcept)
    Dict(
        "@context" => "https://schema.org",
        "@type" => "MedicalDevice",
        "identifier" => string(scaffold.id),
        "name" => scaffold.name,
        "description" => scaffold.description,

        # Custom properties using PropertyValue
        "additionalProperty" => [
            Dict(
                "@type" => "PropertyValue",
                "name" => "porosity",
                "value" => scaffold.porosity.value,
                "unitCode" => "P1",  # percent
                "measurementTechnique" => string(scaffold.porosity.confidence.method),
                "valueReference" => Dict(
                    "@type" => "QuantitativeValue",
                    "value" => scaffold.porosity.confidence.value,
                    "name" => "confidence"
                )
            ),
            Dict(
                "@type" => "PropertyValue",
                "name" => "poreSize",
                "value" => scaffold.pore_size_um.value,
                "unitText" => "micrometer",
                "measurementTechnique" => string(scaffold.pore_size_um.confidence.method)
            ),
            Dict(
                "@type" => "PropertyValue",
                "name" => "interconnectivity",
                "value" => scaffold.interconnectivity.value,
                "unitCode" => "P1"
            )
        ],

        # Material as substance
        "material" => Dict(
            "@type" => "Substance",
            "name" => scaffold.material.value
        ),

        # Temporal
        "dateCreated" => string(scaffold.created)
    )
end

"""
    to_schema_org(dataset_name::String, scaffolds::Vector{ScaffoldConcept}) -> Dict

Export scaffold collection as Schema.org Dataset.
"""
function to_schema_org(dataset_name::String, scaffolds::Vector{ScaffoldConcept};
                      creator::String="Darwin Scaffold Studio",
                      description::String="Scaffold analysis dataset")
    Dict(
        "@context" => "https://schema.org",
        "@type" => "Dataset",
        "name" => dataset_name,
        "description" => description,
        "creator" => Dict(
            "@type" => "Organization",
            "name" => creator
        ),
        "dateCreated" => string(now()),
        "variableMeasured" => [
            "porosity", "poreSize", "interconnectivity",
            "tortuosity", "elasticModulus", "cellViability"
        ],
        "measurementTechnique" => "MicroCT imaging and computational analysis",
        "distribution" => Dict(
            "@type" => "DataDownload",
            "encodingFormat" => "application/json"
        ),
        "hasPart" => [to_schema_org(s) for s in scaffolds]
    )
end

"""
    to_jsonld(obj) -> String

Convert to JSON-LD string.
"""
function to_jsonld(obj)
    # Would use JSON.json in real implementation
    string(to_schema_org(obj))
end

#=============================================================================
  HYPERBOLIC EMBEDDING INTERFACE - Links to ONTOLOGY.md
=============================================================================#

"""
    ConceptEmbedding

Embedding in hyperbolic space (Poincaré ball model).
Links to the hyperbolic semantic network in ONTOLOGY.md.
"""
struct ConceptEmbedding
    coordinates::Vector{Float64}  # Poincaré ball coordinates
    curvature::Float64            # Local sectional curvature
    energy::Float64               # Tension with other concepts
    discourse_manifold::Symbol    # Which domain/corpus
end

"""
    semantic_distance(a::ConceptEmbedding, b::ConceptEmbedding) -> Float64

Compute geodesic distance in hyperbolic space.
"""
function semantic_distance(a::ConceptEmbedding, b::ConceptEmbedding)
    # Poincaré distance formula
    # d(x,y) = arcosh(1 + 2||x-y||² / ((1-||x||²)(1-||y||²)))
    diff = a.coordinates .- b.coordinates
    norm_a = sum(a.coordinates .^ 2)
    norm_b = sum(b.coordinates .^ 2)
    norm_diff = sum(diff .^ 2)

    acosh(1 + 2 * norm_diff / ((1 - norm_a) * (1 - norm_b)))
end

end # module
