"""
Example: Complete Scaffold Analysis Workflow

Demonstrates full workflow: Load → Preprocess → Segment → Analyze → Optimize
"""

using Pkg
Pkg.activate("..")

using DarwinScaffoldStudio
using Random

Random.seed!(42)

println("=" ^ 60)
println("DarwinScaffoldStudio - Complete Workflow Example")
println("=" ^ 60)

# Step 1: Create mock microCT image
println("\n📊 Step 1: Creating mock microCT image...")
image = rand(100, 100, 100)
println("   Image size: ", size(image))

# Step 2: Preprocess
println("\n🔧 Step 2: Preprocessing image...")
processed = preprocess_image(image; denoise=true, normalize=true, enhance_contrast=true)
println("   ✓ Preprocessing completed")

# Step 3: Segment
println("\n✂️  Step 3: Segmenting scaffold...")
binary = segment_scaffold(processed, "otsu")
porosity = 1.0 - (sum(binary) / length(binary))
println("   ✓ Segmentation completed")
println("   - Porosity: ", round(porosity * 100, digits=1), "%")

# Step 4: Compute metrics
println("\n📈 Step 4: Computing scaffold metrics...")
metrics = compute_metrics(binary, 10.0)  # 10 μm voxels

println("   ✓ Metrics computed:")
println("   - Porosity: ", round(metrics.porosity * 100, digits=1), "%")
println("   - Mean pore size: ", round(metrics.mean_pore_size_um, digits=1), " μm")
println("   - Interconnectivity: ", round(metrics.interconnectivity * 100, digits=1), "%")
println("   - Tortuosity: ", round(metrics.tortuosity, digits=2))
println("   - Elastic modulus: ", round(metrics.elastic_modulus, digits=1), " MPa")
println("   - Yield strength: ", round(metrics.yield_strength, digits=1), " MPa")

# Step 5: Detect problems
println("\n🔍 Step 5: Detecting design problems...")
optimizer = ScaffoldOptimizer(voxel_size_um=10.0)
problems = detect_problems(metrics)

if isempty(problems)
    println("   ✓ No problems detected - scaffold meets Q1 criteria!")
else
    println("   ⚠ Problems detected:")
    for (key, desc) in problems
        println("   - ", key, ": ", desc)
    end
end

# Step 6: Optimize (if needed)
if !isempty(problems)
    println("\n⚙️  Step 6: Optimizing scaffold...")
    target_params = ScaffoldParameters(
        0.92,   # porosity target
        150.0,  # pore size target
        0.95,   # interconnectivity target
        1.1,    # tortuosity target
        (1.0, 1.0, 1.0),  # volume mm³
        10.0    # resolution
    )
    
    results = optimize_scaffold(optimizer, binary, target_params)
    
    println("   ✓ Optimization completed")
    println("   - Fabrication method: ", results.fabrication_method)
    println("   - Porosity improvement: ", round(results.improvement_percent["porosity"], digits=1), "%")
end

# Step 7: Create mesh
println("\n🎨 Step 7: Creating 3D mesh...")
vertices, faces = create_mesh_simple(binary, 10.0)
println("   ✓ Mesh created")
println("   - Vertices: ", size(vertices, 1))
println("   - Faces: ", size(faces, 1))

println("\n✅ Complete workflow finished!")

