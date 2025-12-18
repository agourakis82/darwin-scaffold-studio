module Core

using ..OllamaClient
using ..Types: ScaffoldMetrics
using JSON
using UUIDs

export Agent, AgentTool, AgentWorkspace, ChatMessage, ScaffoldData
export ToolResult, execute_tool, run_agent

# ============================================================================
# Type-Safe Data Structures
# ============================================================================

"""
    ChatMessage

Typed chat message for agent conversation history.
"""
struct ChatMessage
    role::String      # "user", "assistant", or "system"
    content::String
end

"""
    ScaffoldData

Type-safe container for scaffold geometry data.
Supports binary volumes (Bool arrays) or numeric density fields (Float arrays).
"""
struct ScaffoldData
    id::String
    name::String
    volume::Union{Array{Bool,3}, Array{Float64,3}}
    resolution_um::Float64  # Voxel size in micrometers
    metadata::Dict{String, String}

    function ScaffoldData(name::String, volume::Union{Array{Bool,3}, Array{Float64,3}};
                          resolution_um::Float64=10.0,
                          metadata::Dict{String,String}=Dict{String,String}())
        new(string(uuid4()), name, volume, resolution_um, metadata)
    end
end

"""
    ToolResult

Type-safe result from tool execution.
"""
struct ToolResult
    success::Bool
    data::Union{Dict{String, Any}, Nothing}
    error::Union{String, Nothing}

    ToolResult(data::Dict{String, Any}) = new(true, data, nothing)
    ToolResult(error::String) = new(false, nothing, error)
end

"""
    AgentTool

A tool that an agent can use (e.g., compute_kec, generate_scaffold).
"""
struct AgentTool
    name::String
    description::String
    parameters::Dict{String, String}  # param name => description
    execute::Function  # Function: Dict{String, Any} -> ToolResult
end

"""
    AgentWorkspace

Shared context for all agents with type-safe storage.

# Fields
- `scaffolds`: Named scaffold geometries (binary or density volumes)
- `metrics`: Analysis results keyed by scaffold ID
- `chat_history`: Typed conversation messages
- `code_sandbox`: Generated code snippets for review/execution
"""
mutable struct AgentWorkspace
    scaffolds::Vector{ScaffoldData}
    metrics::Dict{String, ScaffoldMetrics}
    chat_history::Vector{ChatMessage}
    code_sandbox::Vector{String}

    AgentWorkspace() = new(ScaffoldData[], Dict{String, ScaffoldMetrics}(), ChatMessage[], String[])
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
    execute_tool(tool::AgentTool, args::Dict{String, Any}) -> ToolResult

Execute a tool with given arguments. Returns a type-safe ToolResult.
"""
function execute_tool(tool::AgentTool, args::Dict{String, Any})::ToolResult
    try
        result = tool.execute(args)
        # Handle both old Dict returns and new ToolResult returns
        if result isa ToolResult
            return result
        elseif result isa Dict
            return ToolResult(convert(Dict{String, Any}, result))
        else
            return ToolResult(Dict{String, Any}("result" => result))
        end
    catch e
        @error "Tool execution failed" tool=tool.name exception=e
        return ToolResult(string(e))
    end
end

"""
    run_agent(agent::Agent, user_input::String, workspace::AgentWorkspace; max_iterations::Int=5) -> String

Run agent reasoning loop with tool use. Returns the final agent response.
"""
function run_agent(agent::Agent, user_input::String, workspace::AgentWorkspace;
                   max_iterations::Int=5)::String

    # Add user message to history
    push!(workspace.chat_history, ChatMessage("user", user_input))

    for _ in 1:max_iterations
        # Build messages for chat (convert ChatMessage to Dict for API)
        messages = Vector{Dict{String, String}}()
        push!(messages, Dict("role" => "system", "content" => agent.system_prompt))
        for msg in workspace.chat_history
            push!(messages, Dict("role" => msg.role, "content" => msg.content))
        end

        # Get agent response
        response = chat(agent.model, messages)

        # Add to history
        push!(workspace.chat_history, ChatMessage("assistant", response))

        # Check if agent wants to use a tool
        if contains(response, "\"tool\":")
            # Parse tool call
            try
                tool_call = JSON.parse(response)
                tool_name = tool_call["tool"]::String
                tool_args = convert(Dict{String, Any}, tool_call["args"])

                # Find and execute tool
                tool_idx = findfirst(t -> t.name == tool_name, agent.tools)
                if !isnothing(tool_idx)
                    tool_result = execute_tool(agent.tools[tool_idx], tool_args)

                    # Format result for chat history
                    result_str = if tool_result.success
                        "Tool result: $(JSON.json(tool_result.data))"
                    else
                        "Tool error: $(tool_result.error)"
                    end
                    push!(workspace.chat_history, ChatMessage("user", result_str))

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
