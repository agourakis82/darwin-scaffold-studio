"""
    EpistemicAgents

Epistemic agents for knowledge management in Darwin Scaffold Studio.
Inspired by Demetrios language's agent architecture.

# Agent Types
- QueryAgent: Read-only access, answers questions about knowledge base
- ReviseAgent: Incorporates new evidence with supervision
- EvolveAgent: Adapts ontology semi-autonomously
- GenerateAgent: Creates knowledge from descriptions using LLM

# References
- Demetrios EPISTEMIC_AGENTS.md
- ONTOLOGY.md hyperbolic semantic networks
"""
module EpistemicAgents

using ..Ontology: Knowledge, Confidence, Provenance,
                  ScaffoldConcept, derive_from,
                  high_confidence, medium_confidence, low_confidence
using ..KnowledgeGraph: ScaffoldKG, KGNode, add_node!, add_edge!,
                        query_by_property, query_similar, detect_conflicts,
                        RelationType, SIMILAR_TO
using UUIDs
using Dates

export EpistemicAgent, QueryAgent, ReviseAgent, EvolveAgent, GenerateAgent
export submit_task!, process_tasks!, AgentTask, TaskResult

#=============================================================================
  AGENT INFRASTRUCTURE
=============================================================================#

"""
    AgentTask

A task submitted to an epistemic agent.
"""
struct AgentTask
    id::UUID
    agent_type::Symbol
    action::Symbol
    parameters::Dict{String, Any}
    priority::Int
    submitted::DateTime

    function AgentTask(agent_type::Symbol, action::Symbol, params::Dict{String, Any};
                      priority::Int=1)
        new(uuid4(), agent_type, action, params, priority, now())
    end
end

"""
    TaskResult

Result of an agent task execution.
"""
struct TaskResult
    task_id::UUID
    success::Bool
    result::Any
    confidence::Confidence
    execution_time::Float64
    errors::Vector{String}
end

"""
    EpistemicAgent

Base type for epistemic agents.
"""
abstract type EpistemicAgent end

# Agent state
mutable struct AgentState
    kg::ScaffoldKG
    pending_tasks::Vector{AgentTask}
    completed_tasks::Vector{TaskResult}
    is_running::Bool
end

#=============================================================================
  QUERY AGENT - Read-only knowledge access
=============================================================================#

"""
    QueryAgent

Answers questions about the knowledge base without modifying it.
"""
mutable struct QueryAgent <: EpistemicAgent
    state::AgentState

    function QueryAgent(kg::ScaffoldKG)
        new(AgentState(kg, AgentTask[], TaskResult[], false))
    end
end

function execute(agent::QueryAgent, task::AgentTask)::TaskResult
    start_time = time()

    try
        result = if task.action == :find_scaffolds
            # Find scaffolds matching criteria
            property = get(task.parameters, "property", :porosity)
            op_name = get(task.parameters, "operator", ">=")
            value = get(task.parameters, "value", 0.5)

            op = op_name == ">=" ? (>=) :
                 op_name == "<=" ? (<=) :
                 op_name == "==" ? (==) : (>=)

            query_by_property(agent.state.kg, property, op, value)

        elseif task.action == :find_similar
            # Find similar concepts
            node_id = UUID(task.parameters["node_id"])
            k = get(task.parameters, "k", 5)
            query_similar(agent.state.kg, node_id, k=k)

        elseif task.action == :get_statistics
            # Compute KG statistics
            Dict(
                "total_nodes" => length(agent.state.kg.nodes),
                "total_edges" => length(agent.state.kg.edges),
                "scaffolds" => length(get(agent.state.kg.by_type, :scaffold, [])),
                "materials" => length(get(agent.state.kg.by_type, :material, [])),
                "processes" => length(get(agent.state.kg.by_type, :process, []))
            )

        elseif task.action == :detect_conflicts
            detect_conflicts(agent.state.kg)

        else
            error("Unknown action: $(task.action)")
        end

        TaskResult(
            task.id, true, result, high_confidence(),
            time() - start_time, String[]
        )
    catch e
        TaskResult(
            task.id, false, nothing, low_confidence(),
            time() - start_time, [string(e)]
        )
    end
end

#=============================================================================
  REVISE AGENT - Incorporates new evidence
=============================================================================#

"""
    ReviseAgent

Incorporates new evidence into the knowledge base with supervision.
Uses Bayesian confidence updating.
"""
mutable struct ReviseAgent <: EpistemicAgent
    state::AgentState
    revision_strategy::Symbol  # :bayesian, :agm, :consensus

    function ReviseAgent(kg::ScaffoldKG; strategy::Symbol=:bayesian)
        new(AgentState(kg, AgentTask[], TaskResult[], false), strategy)
    end
end

function execute(agent::ReviseAgent, task::AgentTask)::TaskResult
    start_time = time()

    try
        result = if task.action == :add_measurement
            # Add new measurement with confidence update
            scaffold_id = UUID(task.parameters["scaffold_id"])
            property = Symbol(task.parameters["property"])
            new_value = task.parameters["value"]
            new_confidence = Confidence(
                task.parameters["confidence"],
                method=Symbol(get(task.parameters, "method", "measured"))
            )

            # Get existing node
            node = agent.state.kg.nodes[scaffold_id]
            scaffold = node.data::ScaffoldConcept

            # Bayesian update of confidence
            old_conf = if property == :porosity
                scaffold.porosity.confidence
            elseif property == :pore_size
                scaffold.pore_size_um.confidence
            else
                medium_confidence()
            end

            updated_conf = bayesian_update(old_conf, new_confidence)

            Dict(
                "previous_confidence" => old_conf.value,
                "new_evidence_confidence" => new_confidence.value,
                "updated_confidence" => updated_conf.value,
                "property" => property,
                "new_value" => new_value
            )

        elseif task.action == :merge_knowledge
            # Merge two knowledge items
            source1 = UUID(task.parameters["source1"])
            source2 = UUID(task.parameters["source2"])

            merge_knowledge(agent.state.kg, source1, source2, agent.revision_strategy)

        else
            error("Unknown action: $(task.action)")
        end

        TaskResult(
            task.id, true, result, medium_confidence(),
            time() - start_time, String[]
        )
    catch e
        TaskResult(
            task.id, false, nothing, low_confidence(),
            time() - start_time, [string(e)]
        )
    end
end

"""
    bayesian_update(prior::Confidence, evidence::Confidence) -> Confidence

Update confidence using Bayesian approach.
"""
function bayesian_update(prior::Confidence, evidence::Confidence)
    # Simple weighted average based on evidence counts
    total_evidence = prior.evidence_count + evidence.evidence_count

    weighted_value = (prior.value * prior.evidence_count +
                     evidence.value * evidence.evidence_count) / total_evidence

    Confidence(
        weighted_value,
        method=:inferred,
        evidence_count=total_evidence,
        uncertainty=min(prior.uncertainty, evidence.uncertainty) * 0.9
    )
end

"""
    merge_knowledge(kg, id1, id2, strategy) -> UUID

Merge two knowledge items using specified strategy.
"""
function merge_knowledge(kg::ScaffoldKG, id1::UUID, id2::UUID, strategy::Symbol)
    node1 = kg.nodes[id1]
    node2 = kg.nodes[id2]

    if strategy == :bayesian
        # Weighted merge by confidence
        w1 = node1.confidence.value
        w2 = node2.confidence.value
        total = w1 + w2

        # For scaffolds, merge properties
        if node1.concept_type == :scaffold && node2.concept_type == :scaffold
            s1 = node1.data::ScaffoldConcept
            s2 = node2.data::ScaffoldConcept

            merged_porosity = (s1.porosity.value * w1 + s2.porosity.value * w2) / total

            # Create merged knowledge with provenance tracking
            merged_knowledge = derive_from(
                merged_porosity,
                [s1.porosity, s2.porosity],
                "bayesian_merge"
            )

            return merged_knowledge
        end
    elseif strategy == :agm
        # AGM contraction/expansion - prefer more recent
        if node1.created > node2.created
            return id1
        else
            return id2
        end
    elseif strategy == :consensus
        # Average with equal weight if both high confidence
        if node1.confidence.value > 0.7 && node2.confidence.value > 0.7
            # Keep both as valid alternatives
            add_edge!(kg, id1, id2, SIMILAR_TO, confidence=high_confidence())
            return id1
        else
            # Prefer higher confidence
            return node1.confidence.value > node2.confidence.value ? id1 : id2
        end
    end

    id1
end

#=============================================================================
  EVOLVE AGENT - Semi-autonomous ontology adaptation
=============================================================================#

"""
    EvolveAgent

Adapts the ontology over time using MCMC-based evolution.
Proposes mutations and accepts based on fitness improvement.
"""
mutable struct EvolveAgent <: EpistemicAgent
    state::AgentState
    temperature::Float64  # Controls exploration vs exploitation
    mutation_rate::Float64

    function EvolveAgent(kg::ScaffoldKG; temperature::Float64=1.0, mutation_rate::Float64=0.1)
        new(AgentState(kg, AgentTask[], TaskResult[], false), temperature, mutation_rate)
    end
end

function execute(agent::EvolveAgent, task::AgentTask)::TaskResult
    start_time = time()

    try
        result = if task.action == :propose_mutation
            # Propose ontology mutation
            propose_mutation(agent)

        elseif task.action == :evaluate_fitness
            # Evaluate current ontology fitness
            evaluate_fitness(agent.state.kg)

        elseif task.action == :accept_mutation
            # Accept or reject proposed mutation using Metropolis-Hastings
            mutation = task.parameters["mutation"]
            accept_mutation_mh(agent, mutation)

        elseif task.action == :evolve_step
            # One step of ontology evolution
            evolve_step(agent)

        else
            error("Unknown action: $(task.action)")
        end

        TaskResult(
            task.id, true, result, medium_confidence(),
            time() - start_time, String[]
        )
    catch e
        TaskResult(
            task.id, false, nothing, low_confidence(),
            time() - start_time, [string(e)]
        )
    end
end

"""
    propose_mutation(agent::EvolveAgent) -> Dict

Propose a random mutation to the ontology.
"""
function propose_mutation(agent::EvolveAgent)
    mutations = [:add_relation, :adjust_confidence, :merge_concepts, :split_concept]
    mutation_type = mutations[rand(1:length(mutations))]

    Dict(
        "type" => mutation_type,
        "parameters" => Dict{String, Any}(),
        "expected_fitness_change" => rand() * 0.1 - 0.05
    )
end

"""
    evaluate_fitness(kg::ScaffoldKG) -> Float64

Evaluate ontology fitness based on:
- Consistency (no conflicts)
- Coverage (concepts have relations)
- Confidence distribution
"""
function evaluate_fitness(kg::ScaffoldKG)
    conflicts = detect_conflicts(kg)
    conflict_penalty = length(conflicts) * 0.1

    # Coverage: ratio of nodes with edges
    nodes_with_edges = Set{UUID}()
    for edge in kg.edges
        push!(nodes_with_edges, edge.source)
        push!(nodes_with_edges, edge.target)
    end
    coverage = length(nodes_with_edges) / max(length(kg.nodes), 1)

    # Average confidence
    avg_confidence = if isempty(kg.nodes)
        0.5
    else
        sum(node.confidence.value for (_, node) in kg.nodes) / length(kg.nodes)
    end

    # Fitness score
    coverage * 0.3 + avg_confidence * 0.5 - conflict_penalty
end

"""
    accept_mutation_mh(agent::EvolveAgent, mutation) -> Bool

Accept mutation using Metropolis-Hastings criterion.
"""
function accept_mutation_mh(agent::EvolveAgent, mutation)
    current_fitness = evaluate_fitness(agent.state.kg)
    delta = mutation["expected_fitness_change"]

    # Metropolis-Hastings acceptance
    if delta > 0
        true  # Always accept improvements
    else
        # Accept with probability exp(delta / T)
        acceptance_prob = exp(delta / agent.temperature)
        rand() < acceptance_prob
    end
end

"""
    evolve_step(agent::EvolveAgent) -> Dict

Perform one evolution step.
"""
function evolve_step(agent::EvolveAgent)
    mutation = propose_mutation(agent)
    accepted = accept_mutation_mh(agent, mutation)

    Dict(
        "mutation" => mutation,
        "accepted" => accepted,
        "fitness" => evaluate_fitness(agent.state.kg),
        "temperature" => agent.temperature
    )
end

#=============================================================================
  GENERATE AGENT - LLM-assisted knowledge creation
=============================================================================#

"""
    GenerateAgent

Creates knowledge from natural language descriptions using LLM.
"""
mutable struct GenerateAgent <: EpistemicAgent
    state::AgentState
    llm_model::String

    function GenerateAgent(kg::ScaffoldKG; model::String="llama3.2:3b")
        new(AgentState(kg, AgentTask[], TaskResult[], false), model)
    end
end

function execute(agent::GenerateAgent, task::AgentTask)::TaskResult
    start_time = time()

    try
        result = if task.action == :extract_scaffold
            # Extract scaffold properties from description
            description = task.parameters["description"]
            extract_scaffold_from_text(agent, description)

        elseif task.action == :generate_hypothesis
            # Generate research hypothesis
            context = task.parameters["context"]
            generate_hypothesis(agent, context)

        elseif task.action == :cite_source
            # Find citation for a claim
            claim = task.parameters["claim"]
            find_citation(agent, claim)

        else
            error("Unknown action: $(task.action)")
        end

        TaskResult(
            task.id, true, result,
            Confidence(0.6, method=:inferred),  # LLM-generated has lower confidence
            time() - start_time, String[]
        )
    catch e
        TaskResult(
            task.id, false, nothing, low_confidence(),
            time() - start_time, [string(e)]
        )
    end
end

"""
    extract_scaffold_from_text(agent, description) -> ScaffoldConcept

Use LLM to extract scaffold properties from text.
"""
function extract_scaffold_from_text(agent::GenerateAgent, description::String)
    # In real implementation, would call Ollama
    # For now, return placeholder

    # Parse common patterns
    porosity = if occursin(r"\d+%", description)
        m = match(r"(\d+)%", description)
        parse(Float64, m[1]) / 100
    else
        0.7  # default
    end

    pore_size = if occursin(r"(\d+)\s*[uμ]m", description)
        m = match(r"(\d+)\s*[uμ]m", description)
        parse(Float64, m[1])
    else
        200.0  # default
    end

    material = if occursin("PCL", uppercase(description))
        "PCL"
    elseif occursin("PLA", uppercase(description))
        "PLA"
    elseif occursin("HYDROGEL", uppercase(description))
        "Hydrogel"
    else
        "Unknown"
    end

    Dict(
        "extracted_porosity" => porosity,
        "extracted_pore_size" => pore_size,
        "extracted_material" => material,
        "confidence" => 0.6,
        "source" => "llm_extraction"
    )
end

"""
    generate_hypothesis(agent, context) -> String

Generate research hypothesis based on context.
"""
function generate_hypothesis(agent::GenerateAgent, context::String)
    # Placeholder - would use LLM
    "Based on the observed porosity-viability relationship, increasing interconnectivity may enhance nutrient transport and improve cell survival."
end

"""
    find_citation(agent, claim) -> Dict

Find relevant citation for a scientific claim.
"""
function find_citation(agent::GenerateAgent, claim::String)
    # Would search literature database
    Dict(
        "citation" => "Murphy, C.M., et al. (2010). Biomaterials, 31(3), 461-466.",
        "doi" => "10.1016/j.biomaterials.2009.09.063",
        "relevance" => 0.85
    )
end

#=============================================================================
  TASK MANAGEMENT
=============================================================================#

"""
    submit_task!(agent::EpistemicAgent, task::AgentTask)

Submit a task to an agent's queue.
"""
function submit_task!(agent::EpistemicAgent, task::AgentTask)
    push!(agent.state.pending_tasks, task)
    sort!(agent.state.pending_tasks, by=t->t.priority, rev=true)
end

"""
    process_tasks!(agent::EpistemicAgent; max_tasks=10) -> Vector{TaskResult}

Process pending tasks and return results.
"""
function process_tasks!(agent::EpistemicAgent; max_tasks::Int=10)
    results = TaskResult[]

    for _ in 1:min(max_tasks, length(agent.state.pending_tasks))
        task = popfirst!(agent.state.pending_tasks)
        result = execute(agent, task)
        push!(results, result)
        push!(agent.state.completed_tasks, result)
    end

    results
end

end # module
