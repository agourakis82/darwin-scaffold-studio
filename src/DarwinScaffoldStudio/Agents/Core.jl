module Core

using ..OllamaClient
using JSON
using UUIDs

export Agent, AgentTool, AgentWorkspace, execute_tool, run_agent

"""
    AgentTool

A tool that an agent can use (e.g., compute_kec, generate_scaffold).
"""
struct AgentTool
    name::String
    description::String
    parameters::Dict{String, String}  # name => description
    execute::Function  # Function to call with Dict{String, Any} args
end

"""
    AgentWorkspace

Shared context for all agents.
"""
mutable struct AgentWorkspace
    scaffolds::Vector{Any}  # Scaffold volumes/meshes
    metrics::Dict{String, Any}  # Latest analysis results
    chat_history::Vector{Dict{String, String}}
    code_sandbox::Vector{String}  # Generated code snippets
    
    AgentWorkspace() = new([], Dict(), [], [])
end

"""
    Agent

Base agent with LLM, tools, and memory.
"""
struct Agent
    id::String
    name::String
    role::String
    model::OllamaModel
    tools::Vector{AgentTool}
    system_prompt::String
    
    function Agent(name::String, role::String, model_name::String; tools::Vector{AgentTool}=AgentTool[])
        id = string(uuid4())
        model = OllamaModel(model_name)
        
        # Default system prompt
        system_prompt = """
        You are $(name), a specialized AI agent for tissue engineering scaffold research.
        Your role: $(role)
        
        You have access to the following tools:
        $(join(["\n- $(t.name): $(t.description)" for t in tools], ""))
        
        When you need to use a tool, respond with JSON:
        {"tool": "tool_name", "args": {"param": "value"}}
        
        Otherwise, respond conversationally with scientific rigor.
        """
        
        new(id, name, role, model, tools, system_prompt)
    end
end

"""
    execute_tool(tool::AgentTool, args::Dict)

Execute a tool with given arguments.
"""
function execute_tool(tool::AgentTool, args::Dict)
    try
        return tool.execute(args)
    catch e
        @error "Tool execution failed" tool=tool.name exception=e
        return Dict("error" => string(e))
    end
end

"""
    run_agent(agent::Agent, user_input::String, workspace::AgentWorkspace)

Run agent reasoning loop with tool use.
"""
function run_agent(agent::Agent, user_input::String, workspace::AgentWorkspace; max_iterations::Int=5)
    
    # Add user message to history
    push!(workspace.chat_history, Dict("role" => "user", "content" => user_input))
    
    for iteration in 1:max_iterations
        # Build messages for chat
        messages = [
            Dict("role" => "system", "content" => agent.system_prompt)
        ]
        append!(messages, workspace.chat_history)
        
        # Get agent response
        response = chat(agent.model, messages)
        
        # Add to history
        push!(workspace.chat_history, Dict("role" => "assistant", "content" => response))
        
        # Check if agent wants to use a tool
        if contains(response, "\"tool\":")
            # Parse tool call
            try
                tool_call = JSON.parse(response)
                tool_name = tool_call["tool"]
                tool_args = tool_call["args"]
                
                # Find and execute tool
                tool = findfirst(t -> t.name == tool_name, agent.tools)
                if !isnothing(tool)
                    tool_result = execute_tool(agent.tools[tool], tool_args)
                    
                    # Add tool result to history
                    push!(workspace.chat_history, 
                          Dict("role" => "user", 
                               "content" => "Tool result: $(JSON.json(tool_result))"))
                    
                    # Continue loop for agent to process result
                    continue
                else
                    @warn "Agent requested unknown tool" tool=tool_name
                end
            catch e
                @warn "Failed to parse tool call" exception=e
            end
        end
        
        # If no tool call, agent is done
        return response
    end
    
    return "Max iterations reached. Agent timed out."
end

end # module
