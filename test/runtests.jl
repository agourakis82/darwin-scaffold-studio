"""
Test suite for DarwinScaffoldStudio

Run all tests with: julia --project=. test/runtests.jl
"""

using Pkg
Pkg.activate(".")
Pkg.instantiate()

using Test

include("test_scaffold_studio.jl")

println("✅ All tests completed!")

