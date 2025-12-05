"""
Darwin Scaffold Studio - Complete Test Suite

Run all tests with: julia --project=. test/runtests.jl
Run specific test: julia --project=. -e 'include("test/test_core.jl")'

Test Categories:
- Core: Types, Config, Utils
- MicroCT: Image loading, preprocessing, segmentation, metrics
- Ontology: OBO Foundry integration, lookups
- TPMS: Synthetic scaffold generation and validation
- Optimization: Scaffold optimization
- Visualization: Mesh creation
- Science: Topology, percolation, ML
"""

using Pkg
Pkg.activate(".")

using Test
using Random

# Set random seed for reproducibility
Random.seed!(42)

println("=" ^ 60)
println("Darwin Scaffold Studio - Test Suite")
println("=" ^ 60)
println()

# Track test results
test_results = Dict{String, Bool}()

# Helper to run test file safely
function run_test_file(name::String, path::String)
    println("\n" * "-" ^ 40)
    println("Running: $name")
    println("-" ^ 40)

    try
        include(path)
        test_results[name] = true
        println("✅ $name: PASSED")
    catch e
        test_results[name] = false
        println("❌ $name: FAILED")
        println("   Error: ", e)
        if isa(e, LoadError)
            println("   File: ", e.file)
        end
    end
end

# Load main module
println("Loading DarwinScaffoldStudio...")
try
    using DarwinScaffoldStudio
    println("✅ Module loaded successfully")
catch e
    println("❌ Failed to load module: ", e)
    exit(1)
end

# Run test suites
run_test_file("Core", "test_core.jl")
run_test_file("MicroCT", "test_microct.jl")
run_test_file("TPMS", "test_tpms.jl")
run_test_file("Optimization", "test_optimization.jl")
run_test_file("Visualization", "test_visualization.jl")
run_test_file("Science", "test_science.jl")

# Ontology tests (may fail if modules not loaded)
try
    run_test_file("Ontology", "test_ontology.jl")
catch e
    println("⚠️  Ontology tests skipped: ", e)
    test_results["Ontology"] = false
end

# Legacy tests
run_test_file("ScaffoldStudio", "test_scaffold_studio.jl")

# Summary
println("\n" * "=" ^ 60)
println("TEST SUMMARY")
println("=" ^ 60)

passed = count(values(test_results))
total = length(test_results)

for (name, result) in sort(collect(test_results))
    status = result ? "✅ PASS" : "❌ FAIL"
    println("  $name: $status")
end

println()
println("Results: $passed / $total tests passed")
println("=" ^ 60)

if passed == total
    println("✅ ALL TESTS PASSED!")
else
    println("❌ Some tests failed")
    exit(1)
end
