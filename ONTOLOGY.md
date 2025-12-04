# ONTOLOGY — HYPERBOLIC SEMANTIC NETWORKS

## Purpose
Identify the intrinsic geometry of semantic meaning before modeling. This ontology governs embeddings, inference, and cross-domain reasoning.

## Entities
- **ConceptNode**: semantic entity embedded in hyperbolic space
- **RelationGeodesic**: minimal path connecting ConceptNodes
- **CurvatureProfile**: local sectional curvature describing semantic density
- **DiscourseManifold**: subspace induced by corpus/domain context
- **InferenceTrajectory**: geodesic motion representing reasoning step
- **ConflictSingularity**: point where competing ontologies intersect
- **Hypothesis**: statement mapping trajectories to truth values

## Relations
- `ConceptNode --connected_via--> RelationGeodesic`
- `RelationGeodesic --embedded_in--> DiscourseManifold`
- `CurvatureProfile --modulates--> InferenceTrajectory`
- `ConflictSingularity --resolves_to--> Hypothesis`
- `Hypothesis --validated_by--> Measurement`

## Geometry
- Base space is hyperbolic manifold **ℍⁿ** (Poincaré ball or Lorentz model).
- Semantic similarity corresponds to geodesic distance; clusters manifest as curvature wells.
- Contradictions correspond to positive curvature spikes (local spherical patches).
- Reasoning = navigation via geodesic flows with controlled temperature (exploration vs exploitation).
- Phase space **Σ = (node embedding, curvature, energy)** with energy capturing tension between ontologies.

## Invariants
- Triangle inequality in hyperbolic space (distance metric validity).
- Negative curvature ensures exponential volume expansion; used for hierarchical semantics.
- Parallel transport preserves concept orientation within DiscourseManifold.
- Dissent preservation: conflicting embeddings stored as multi-branch coordinates, not collapsed.

## Axes of Variation
- **Domain**: biomedical, legal, philosophical corpora
- **Scale**: term-level, paragraph-level, meta-knowledge
- **Temporal drift**: language evolution causing curvature shifts
- **Confidence**: epistemic uncertainty captured by geodesic spread

## Attractors
- Stable conceptual neighborhoods (low entropy)
- High mutual information between language modalities
- Alignment between ontology-encoded relations and empirical usage

## Singularities
- Collapsed hierarchy (curvature → 0) indicating loss of semantic structure
- Conflicting embeddings (distance oscillates upon retraining)
- Overly flat manifolds (Euclidean degeneration) implying inadequate model capacity

## Instrumentation linkage
- Qdrant stores embeddings with curvature metadata
- MLFlow logs curvature entropy, disagreement indexes, epistemic temperature
- Visualization renders Poincaré disk/ball with energy landscape overlays

## Implementation Guidance
- Provide `phase_space()` for every reasoning module with explicit coordinates.
- Enforce `@epistemically_logged` on experiments comparing embeddings.
- `eris_arbiter` modules manage conflicts; `mnemosyne_semantic` stores manifold snapshots.
- Ontology updated whenever new domains or embedding models introduced.
