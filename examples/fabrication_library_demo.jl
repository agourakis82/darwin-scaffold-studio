#!/usr/bin/env julia
"""
FabricationLibrary Demo - Scaffold Fabrication Method Selection

This demo shows how to use the FabricationLibrary to:
1. Browse available fabrication methods
2. Filter by material compatibility
3. Filter by pore size requirements
4. Filter by porosity requirements
5. Compare methods for specific applications
"""

include("../src/DarwinScaffoldStudio/Ontology/FabricationLibrary.jl")
using .FabricationLibrary

println("="^70)
println("DARWIN SCAFFOLD STUDIO - Fabrication Library Demo")
println("="^70)

# 1. Overview
println("\n📊 LIBRARY OVERVIEW")
println(get_method_summary())

# 2. Bone Tissue Engineering Application
println("\n🦴 BONE TISSUE ENGINEERING (100-500 μm pores, >85% porosity)")
println("-"^70)

bone_pore_methods = get_methods_for_pore_range(100, 500)
bone_porosity_methods = get_methods_for_porosity_range(0.85, 1.0)

# Find methods that satisfy both criteria
bone_methods = [m for m in bone_pore_methods if m in bone_porosity_methods]

println("Found $(length(bone_methods)) suitable methods:")
for (i, method) in enumerate(bone_methods[1:min(5, length(bone_methods))])
    println("  $i. $(method.name)")
    println("     Category: $(method.category)")
    println("     Pore size: $(method.pore_size_range_um) μm")
    println("     Porosity: $(method.porosity_range)")
    println()
end

# 3. Material-specific fabrication
println("\n🧪 METHODS FOR PCL (Polycaprolactone)")
println("-"^70)

pcl_methods = get_compatible_methods("PCL")
println("Found $(length(pcl_methods)) methods compatible with PCL:\n")

# Group by category
by_category = Dict{Symbol, Vector{FabricationMethod}}()
for method in pcl_methods
    if !haskey(by_category, method.category)
        by_category[method.category] = []
    end
    push!(by_category[method.category], method)
end

for cat in sort(collect(keys(by_category)))
    methods = by_category[cat]
    println("  $(cat) ($(length(methods))):")
    for method in methods[1:min(3, length(methods))]
        println("    - $(method.name)")
    end
    if length(methods) > 3
        println("    ... and $(length(methods)-3) more")
    end
    println()
end

# 4. Detailed Method Comparison
println("\n📋 DETAILED COMPARISON: 3D Printing Methods")
println("-"^70)

printing_methods = get_methods_by_category(:printing)
bioprinting = [m for m in printing_methods if occursin("bio", lowercase(m.id))]

println("Comparing $(length(bioprinting)) bioprinting methods:\n")

for method in bioprinting
    println("🖨️  $(method.name)")
    println("   Pore size: $(method.pore_size_range_um) μm")
    println("   Porosity: $(method.porosity_range)")
    println("   Materials: $(join(method.compatible_materials[1:min(3, length(method.compatible_materials))], ", "))")
    println("   Top advantage: $(method.advantages[1])")
    println("   Main limitation: $(method.limitations[1])")
    println()
end

# 5. Electrospinning variants
println("\n🧵 ELECTROSPINNING METHODS")
println("-"^70)

espin_methods = get_methods_by_category(:electrospinning)
println("Found $(length(espin_methods)) electrospinning variants:\n")

for method in espin_methods
    println("  • $(method.name)")
    println("    Fiber diameter: $(method.pore_size_range_um) μm")
    println("    Key advantage: $(method.advantages[1])")
    println()
end

# 6. Method details inspection
println("\n🔬 DETAILED INSPECTION: Freeze-Drying (Lyophilization)")
println("-"^70)

lyophilization = get_method("lyophilization")
println("Name: $(lyophilization.name)")
println("Category: $(lyophilization.category)")
println("\nDescription:")
println("  $(lyophilization.description)")
println("\nProcess Parameters:")
for (param, range) in lyophilization.parameters
    println("  - $param: $range")
end
println("\nAchievable Structure:")
println("  - Pore size: $(lyophilization.pore_size_range_um) μm")
println("  - Porosity: $(lyophilization.porosity_range)")
println("\nCompatible Materials ($(length(lyophilization.compatible_materials))):")
println("  $(join(lyophilization.compatible_materials, ", "))")
println("\nAdvantages:")
for adv in lyophilization.advantages
    println("  ✓ $adv")
end
println("\nLimitations:")
for lim in lyophilization.limitations
    println("  ✗ $lim")
end

# 7. Crosslinking methods
println("\n🔗 CROSSLINKING METHODS")
println("-"^70)

crosslinking = get_methods_by_category(:crosslinking)
println("Found $(length(crosslinking)) crosslinking methods:\n")

for method in crosslinking[1:5]
    println("  $(method.name)")
    println("    Materials: $(join(method.compatible_materials[1:min(4, length(method.compatible_materials))], ", "))")
    println("    Key advantage: $(method.advantages[1])")
    println()
end

# 8. Application-specific recommendations
println("\n💡 APPLICATION-SPECIFIC RECOMMENDATIONS")
println("-"^70)

applications = [
    ("Nerve Regeneration", 1, 50, 0.70, 0.90, ["collagen", "gelatin", "PCL"]),
    ("Cartilage Repair", 50, 200, 0.75, 0.90, ["PLA", "PLGA", "collagen"]),
    ("Bone Regeneration", 100, 500, 0.85, 0.95, ["HA", "TCP", "PCL"]),
    ("Vascular Grafts", 10, 100, 0.70, 0.85, ["PCL", "PLA", "silk"])
]

for (app_name, pore_min, pore_max, por_min, por_max, materials) in applications
    println("\n$app_name:")
    println("  Requirements: $(pore_min)-$(pore_max) μm pores, $(por_min)-$(por_max) porosity")

    suitable = get_methods_for_pore_range(pore_min, pore_max)
    suitable = [m for m in suitable if m.porosity_range[2] >= por_min && m.porosity_range[1] <= por_max]
    suitable = [m for m in suitable if any(mat in m.compatible_materials for mat in materials)]

    println("  Recommended methods ($(length(suitable))):")
    for method in suitable[1:min(3, length(suitable))]
        println("    - $(method.name)")
    end
end

println("\n" * "="^70)
println("Demo completed successfully!")
println("="^70)
