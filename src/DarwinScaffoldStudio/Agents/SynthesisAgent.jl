module SynthesisAgent

using ..Core
using ..OllamaClient

export create_synthesis_agent

"""
Create a Synthesis Agent for literature search and knowledge integration.
"""
function create_synthesis_agent()
    
    tools = [
        AgentTool(
            "search_papers",
            "Search scientific literature for relevant papers",
            Dict(
                "query" => "Search query",
                "max_results" => "Maximum number of papers to return"
            ),
            args -> begin
                # Would integrate with ChromaDB/Semantic Scholar
                return Dict(
                    "results" => [
                        Dict(
                            "title" => "Bone tissue engineering scaffolds: Murphy et al. 2010",
                            "key_findings" => "Optimal pore size 100-500µm for bone",
                            "doi" => "10.1016/example"
                        )
                    ]
                )
            end
        ),
        
        AgentTool(
            "extract_method",
            "Extract experimental methods from a paper",
            Dict(
                "paper_id" => "DOI or ID of paper",
                "section" => "Which section to extract (methods, results, etc.)"
            ),
            args -> begin
                return Dict(
                    "method_description" => "Freeze-casting with ice templating at -20°C",
                    "parameters" => Dict(
                        "freezing_rate" => "10°C/min",
                        "solids_loading" => "20% w/v"
                    )
                )
            end
        ),
        
        AgentTool(
            "propose_experiment",
            "Suggest next experiments based on current results and literature gaps",
            Dict(
                "current_metrics" => "Current scaffold metrics",
                "research_goal" => "What you're trying to optimize"
            ),
            args -> begin
                return Dict(
                    "experiment_proposal" => "Test porosity range 70-80% with PCL to optimize viability",
                    "reasoning" => "Literature shows peak at 75%, but GNN predicts 77% optimal",
                    "expected_outcome" => "Viability increase from 0.82 to 0.90"
                )
            end
        ),
        
        AgentTool(
            "cite_source",
            "Find and format citation for a claim",
            Dict("claim" => "Scientific claim to cite"),
            args -> begin
                return Dict(
                    "citation" => "Murphy, C.M., et al. (2010). Biomaterials, 31(3), 461-466.",
                    "quote" => "Pore sizes of 100μm are required for bone formation"
                )
            end
        )
    ]
    
    Agent(
        "Synthesis Agent",
        "Search literature, extract methods, propose experiments, and provide scientific citations",
        "llama3.2:3b",
        tools=tools
    )
end

end # module
