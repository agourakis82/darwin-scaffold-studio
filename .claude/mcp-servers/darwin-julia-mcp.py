#!/usr/bin/env python3
"""
Darwin Scaffold Studio - Julia MCP Server

MCP server that provides direct Julia REPL integration for development.
Allows Claude Code to execute Julia code and interact with DarwinScaffoldStudio.
"""

import json
import subprocess
import sys
import os
from typing import Any

# MCP Protocol implementation
def send_response(id: str, result: Any):
    response = {"jsonrpc": "2.0", "id": id, "result": result}
    print(json.dumps(response), flush=True)

def send_error(id: str, code: int, message: str):
    response = {"jsonrpc": "2.0", "id": id, "error": {"code": code, "message": message}}
    print(json.dumps(response), flush=True)

def send_notification(method: str, params: Any):
    notification = {"jsonrpc": "2.0", "method": method, "params": params}
    print(json.dumps(notification), flush=True)

# Julia execution
DARWIN_PATH = os.environ.get("DARWIN_PATH", "/home/agourakis82/workspace/darwin-scaffold-studio")

def run_julia(code: str, timeout: int = 60) -> dict:
    """Execute Julia code in Darwin Scaffold Studio context."""
    wrapper = f'''
    cd("{DARWIN_PATH}")
    using Pkg
    Pkg.activate(".")

    try
        {code}
    catch e
        println("ERROR: ", e)
        for (exc, bt) in Base.catch_stack()
            showerror(stderr, exc, bt)
            println(stderr)
        end
    end
    '''

    try:
        result = subprocess.run(
            ["julia", "--project=" + DARWIN_PATH, "-e", wrapper],
            capture_output=True,
            text=True,
            timeout=timeout,
            cwd=DARWIN_PATH
        )
        return {
            "success": result.returncode == 0,
            "stdout": result.stdout,
            "stderr": result.stderr,
            "returncode": result.returncode
        }
    except subprocess.TimeoutExpired:
        return {"success": False, "error": f"Timeout after {timeout}s"}
    except Exception as e:
        return {"success": False, "error": str(e)}

def check_module_loads() -> dict:
    """Quick check if core modules load."""
    code = '''
    include("src/DarwinScaffoldStudio.jl")
    println("OK: Module loaded successfully")
    '''
    return run_julia(code, timeout=120)

def get_module_list() -> dict:
    """List all modules in DarwinScaffoldStudio."""
    code = '''
    modules = []
    for dir in readdir("src/DarwinScaffoldStudio")
        path = joinpath("src/DarwinScaffoldStudio", dir)
        if isdir(path)
            files = filter(f -> endswith(f, ".jl"), readdir(path))
            for f in files
                push!(modules, "$dir/$(replace(f, ".jl" => ""))")
            end
        end
    end
    println(join(sort(modules), "\\n"))
    '''
    return run_julia(code, timeout=30)

def get_exports(module_name: str) -> dict:
    """Get exported symbols from a module."""
    code = f'''
    include("src/DarwinScaffoldStudio.jl")
    using .DarwinScaffoldStudio

    # Get exports
    exports = names(DarwinScaffoldStudio.{module_name}, all=false)
    for e in exports
        println(e)
    end
    '''
    return run_julia(code, timeout=60)

def run_tests(test_type: str = "minimal") -> dict:
    """Run test suite."""
    if test_type == "minimal":
        return run_julia('include("test_minimal.jl")', timeout=60)
    elif test_type == "full":
        return run_julia('include("test/runtests.jl")', timeout=300)
    else:
        return {"success": False, "error": f"Unknown test type: {test_type}"}

# MCP Tool definitions
TOOLS = [
    {
        "name": "julia_eval",
        "description": "Execute Julia code in Darwin Scaffold Studio context",
        "inputSchema": {
            "type": "object",
            "properties": {
                "code": {"type": "string", "description": "Julia code to execute"},
                "timeout": {"type": "integer", "description": "Timeout in seconds", "default": 60}
            },
            "required": ["code"]
        }
    },
    {
        "name": "darwin_check",
        "description": "Check if Darwin Scaffold Studio modules load correctly",
        "inputSchema": {"type": "object", "properties": {}}
    },
    {
        "name": "darwin_modules",
        "description": "List all modules in Darwin Scaffold Studio",
        "inputSchema": {"type": "object", "properties": {}}
    },
    {
        "name": "darwin_test",
        "description": "Run Darwin Scaffold Studio tests",
        "inputSchema": {
            "type": "object",
            "properties": {
                "type": {"type": "string", "enum": ["minimal", "full"], "default": "minimal"}
            }
        }
    },
    {
        "name": "darwin_exports",
        "description": "Get exported symbols from a module",
        "inputSchema": {
            "type": "object",
            "properties": {
                "module": {"type": "string", "description": "Module name (e.g., 'Config', 'Types')"}
            },
            "required": ["module"]
        }
    }
]

def handle_tool_call(name: str, arguments: dict) -> Any:
    """Handle MCP tool calls."""
    if name == "julia_eval":
        return run_julia(arguments["code"], arguments.get("timeout", 60))
    elif name == "darwin_check":
        return check_module_loads()
    elif name == "darwin_modules":
        return get_module_list()
    elif name == "darwin_test":
        return run_tests(arguments.get("type", "minimal"))
    elif name == "darwin_exports":
        return get_exports(arguments["module"])
    else:
        return {"error": f"Unknown tool: {name}"}

def main():
    """Main MCP server loop."""
    # Send server info on stderr for debugging
    sys.stderr.write("Darwin Julia MCP Server started\n")
    sys.stderr.flush()

    for line in sys.stdin:
        try:
            request = json.loads(line.strip())
            method = request.get("method")
            id = request.get("id")
            params = request.get("params", {})

            if method == "initialize":
                send_response(id, {
                    "protocolVersion": "2024-11-05",
                    "capabilities": {"tools": {}},
                    "serverInfo": {
                        "name": "darwin-julia-mcp",
                        "version": "1.0.0"
                    }
                })

            elif method == "tools/list":
                send_response(id, {"tools": TOOLS})

            elif method == "tools/call":
                tool_name = params.get("name")
                arguments = params.get("arguments", {})
                result = handle_tool_call(tool_name, arguments)
                send_response(id, {
                    "content": [{"type": "text", "text": json.dumps(result, indent=2)}]
                })

            elif method == "notifications/initialized":
                pass  # Acknowledgment, no response needed

            else:
                if id:
                    send_error(id, -32601, f"Method not found: {method}")

        except json.JSONDecodeError as e:
            sys.stderr.write(f"JSON parse error: {e}\n")
        except Exception as e:
            sys.stderr.write(f"Error: {e}\n")
            if 'id' in dir() and id:
                send_error(id, -32603, str(e))

if __name__ == "__main__":
    main()
