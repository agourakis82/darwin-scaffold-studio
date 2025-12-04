module OllamaClient

using HTTP
using JSON

export OllamaModel, generate, generate_stream, chat, list_models

"""
    OllamaModel

Client for interacting with local Ollama LLM server.
"""
struct OllamaModel
    base_url::String
    model_name::String
    
    function OllamaModel(model_name::String, base_url::String="http://localhost:11434")
        new(base_url, model_name)
    end
end

"""
    generate(model::OllamaModel, prompt::String; options...)

Generate a completion from the model.
"""
function generate(model::OllamaModel, prompt::String; 
                  temperature::Float64=0.7,
                  max_tokens::Int=2048,
                  system::Union{String,Nothing}=nothing)
    
    url = "$(model.base_url)/api/generate"
    
    payload = Dict(
        "model" => model.model_name,
        "prompt" => prompt,
        "stream" => false,
        "options" => Dict(
            "temperature" => temperature,
            "num_predict" => max_tokens
        )
    )
    
    if !isnothing(system)
        payload["system"] = system
    end
    
    try
        response = HTTP.post(url, 
                           ["Content-Type" => "application/json"],
                           JSON.json(payload))
        
        result = JSON.parse(String(response.body))
        return result["response"]
    catch e
        @error "Ollama generation failed" exception=e
        return "Error: Cannot connect to Ollama. Is it running? (ollama serve)"
    end
end

"""
    generate_stream(model::OllamaModel, prompt::String, callback::Function)

Generate with streaming output, calling callback for each token.
"""
function generate_stream(model::OllamaModel, prompt::String, callback::Function;
                        temperature::Float64=0.7)
    
    url = "$(model.base_url)/api/generate"
    
    payload = Dict(
        "model" => model.model_name,
        "prompt" => prompt,
        "stream" => true,
        "options" => Dict("temperature" => temperature)
    )
    
    try
        HTTP.open("POST", url, ["Content-Type" => "application/json"]) do io
            write(io, JSON.json(payload))
            
            while !eof(io)
                line = readline(io)
                if !isempty(line)
                    chunk = JSON.parse(line)
                    if haskey(chunk, "response")
                        callback(chunk["response"])
                    end
                    
                    if get(chunk, "done", false)
                        break
                    end
                end
            end
        end
    catch e
        @error "Ollama streaming failed" exception=e
    end
end

"""
    chat(model::OllamaModel, messages::Vector{Dict}; tools=nothing, temperature=0.7)

Chat completion with conversation history and optional tools.
"""
function chat(model::OllamaModel, messages::Vector{Dict{String, String}};
              tools::Union{Vector{Dict}, Nothing}=nothing,
              temperature::Float64=0.7)
    
    url = "$(model.base_url)/api/chat"
    
    payload = Dict(
        "model" => model.model_name,
        "messages" => messages,
        "stream" => false,
        "options" => Dict("temperature" => temperature)
    )
    
    if !isnothing(tools)
        payload["tools"] = tools
    end
    
    try
        response = HTTP.post(url,
                           ["Content-Type" => "application/json"],
                           JSON.json(payload))
        
        result = JSON.parse(String(response.body))
        return result["message"] # Return full message object to handle tool_calls
    catch e
        @error "Ollama chat failed" exception=e
        return Dict("role" => "assistant", "content" => "Error: Cannot connect to Ollama.")
    end
end

"""
    list_models(base_url::String="http://localhost:11434")

List available models in Ollama.
"""
function list_models(base_url::String="http://localhost:11434")
    url = "$(base_url)/api/tags"
    
    try
        response = HTTP.get(url)
        result = JSON.parse(String(response.body))
        return [m["name"] for m in result["models"]]
    catch e
        @error "Cannot list models" exception=e
        return String[]
    end
end

end # module
