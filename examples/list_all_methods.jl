#!/usr/bin/env julia
"""
List all 43 fabrication methods organized by category
"""

include("../src/DarwinScaffoldStudio/Ontology/FabricationLibrary.jl")
using .FabricationLibrary

println("="^80)
println("FABRICATION LIBRARY - COMPLETE METHOD LIST")
println("="^80)

categories = [:printing, :electrospinning, :freeze_drying, :casting,
              :phase_separation, :surface_modification, :crosslinking,
              :self_assembly, :decellularization]

for cat in categories
    methods = get_methods_by_category(cat)
    if isempty(methods)
        continue
    end

    cat_name = uppercase(replace(string(cat), "_" => " "))
    println("\n$cat_name ($(length(methods)) methods)")
    println("-"^80)

    for method in methods
        println("  • $(method.name)")
        println("    ID: $(method.id)")
        println("    Pores: $(method.pore_size_range_um) μm | Porosity: $(method.porosity_range)")
        mat_list = join(method.compatible_materials[1:min(4,length(method.compatible_materials))], ", ")
        mat_suffix = length(method.compatible_materials) > 4 ? "..." : ""
        println("    Materials ($(length(method.compatible_materials))): $mat_list$mat_suffix")
        println()
    end
end

println("\n" * "="^80)
println("SUMMARY: $(length(FABRICATION_METHODS)) total fabrication methods")
println("="^80)
