"""
Interactive Shell for Darwin Scaffold Studio
Provides a user-friendly REPL interface.
"""

println()
println("=" ^ 60)
println("  Darwin Scaffold Studio v0.2.0")
println("  Tissue Engineering Scaffold Analysis Platform")
println("=" ^ 60)
println()
println("Quick Start:")
println("  1. Load your MicroCT data:")
println("     julia> img = load_microct(\"path/to/data.raw\", (512,512,512))")
println()
println("  2. Segment the scaffold:")
println("     julia> binary = segment_scaffold(img, \"otsu\")")
println()
println("  3. Compute metrics:")
println("     julia> metrics = compute_metrics(binary, 10.0)  # 10um voxel size")
println()
println("  4. Optimize design:")
println("     julia> optimized = optimize_scaffold(binary, target_params)")
println()
println("Available Modules:")
println("  - MicroCT: load_microct, preprocess_image, segment_scaffold")
println("  - Metrics: compute_metrics, ScaffoldMetrics")
println("  - Optimization: ScaffoldOptimizer, optimize_scaffold")
println("  - Visualization: create_mesh_simple, export_stl")
println("  - Ontology: OntologyManager.lookup_tissue, lookup_cell, lookup_material")
println()
println("For help: ?function_name")
println("=" ^ 60)
println()

# Keep REPL running
if !isinteractive()
    println("Starting interactive mode...")
    Base.run_main_repl(true, true, false, true, false)
end
