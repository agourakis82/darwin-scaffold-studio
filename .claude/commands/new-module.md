# Create New Module

Create a new Julia module for Darwin Scaffold Studio.

## Arguments
$ARGUMENTS format: `Category/ModuleName` (e.g., `Science/NewAnalysis` or `Agents/PlanningAgent`)

## Categories
- Core - Configuration, types, utilities
- MicroCT - Image processing and analysis
- Optimization - Scaffold optimization algorithms
- Visualization - Rendering and export
- Science - Scientific computing (TDA, ML, PINNs)
- Agents - AI agents for automation
- LLM - Language model integrations
- Advanced - Cutting-edge features
- Theory - Theoretical frameworks
- Foundation - Foundation model integrations
- Hausen - Specialized research modules

## Instructions

1. Parse category and module name from arguments
2. Create the module file with this template:

```julia
"""
    ModuleName

Brief description of what this module does.

# Exports
- `main_function`: Description

# Example
```julia
using ..ModuleName
result = main_function(args)
```
"""
module ModuleName

using ..Types
using ..Config

export main_function

# Implementation here

end # module
```

3. Add include statement to `src/DarwinScaffoldStudio.jl`
4. Add to appropriate loading section (core, optional, etc.)
5. Create basic test in `test/test_modulename.jl`
6. Verify module loads without errors
