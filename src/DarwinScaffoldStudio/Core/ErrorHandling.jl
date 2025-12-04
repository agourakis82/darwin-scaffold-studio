"""
ErrorHandling.jl - Safe module loading and error utilities

Provides graceful fallbacks when advanced modules fail to load.
"""

module ErrorHandling

export @safe_include, log_module_status, ModuleStatus

"""
    ModuleStatus

Track which modules loaded successfully for debugging.
"""
mutable struct ModuleStatus
    loaded::Vector{String}
    failed::Vector{Tuple{String, String}}  # (module_name, error_message)
    
    ModuleStatus() = new(String[], Tuple{String, String}[])
end

const MODULE_STATUS = ModuleStatus()

"""
    @safe_include(path::String, module_name::String="")

Include a file with graceful error handling. If the file fails to load,
log the error but don't crash the entire system.

# Examples
```julia
@safe_include "DarwinScaffoldStudio/Advanced/QuantumOptimization.jl" "QuantumOptimization"
```
"""
macro safe_include(path, module_name="")
    quote
        try
            include($(esc(path)))
            mod_name = $(esc(module_name)) == "" ? $(esc(path)) : $(esc(module_name))
            push!(MODULE_STATUS.loaded, mod_name)
            @debug "✓ Loaded module: $mod_name"
        catch e
            error_msg = string(e)
            name = $(esc(module_name)) == "" ? $(esc(path)) : $(esc(module_name))
            push!(MODULE_STATUS.failed, (name, error_msg))
            @warn "✗ Failed to load module: $name" error=first(split(error_msg, '\n'))
        end
    end
end

"""
    log_module_status()

Print summary of which modules loaded successfully and which failed.
"""
function log_module_status()
    println("\n" * "="^60)
    println("DARWIN Scaffold Studio - Module Loading Summary")
    println("="^60)
    
    println("\n✅ Loaded Successfully ($(length(MODULE_STATUS.loaded)) modules):")
    for mod in MODULE_STATUS.loaded
        println("   ✓ $mod")
    end
    
    if !isempty(MODULE_STATUS.failed)
        println("\n⚠️  Failed to Load ($(length(MODULE_STATUS.failed)) modules):")
        for (mod, error) in MODULE_STATUS.failed
            println("   ✗ $mod")
            println("     Error: $(first(split(error, '\n')))")  # First line only
        end
        println("\n💡 Tip: Advanced modules are optional. Core functionality remains available.")
    else
        println("\n🎉 All modules loaded successfully!")
    end
    
    println("="^60 * "\n")
end

end # module
