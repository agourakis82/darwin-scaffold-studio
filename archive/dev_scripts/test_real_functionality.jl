"""
Test real functionality of DarwinScaffoldStudio
"""

println("=" ^ 60)
println("DARWIN SCAFFOLD STUDIO - FUNCTIONALITY TEST")
println("=" ^ 60)

include("../src/DarwinScaffoldStudio.jl")
using .DarwinScaffoldStudio

results = Dict{String, Bool}()

# 1. Criar scaffold sintético
println("\n1. Gerando scaffold TPMS (Gyroid)...")
try
    scaffold = zeros(Bool, 50, 50, 50)
    scale = 2π / 50
    for i in 1:50, j in 1:50, k in 1:50
        x, y, z = (i-1)*scale, (j-1)*scale, (k-1)*scale
        val = sin(x)*cos(y) + sin(y)*cos(z) + sin(z)*cos(x)
        scaffold[i,j,k] = val > 0.3
    end
    porosity = 1.0 - sum(scaffold) / length(scaffold)
    println("   ✓ Scaffold gerado: 50x50x50, porosity=$(round(porosity*100, digits=1))%")
    results["scaffold_generation"] = true
    global test_scaffold = scaffold
catch e
    println("   ✗ ERRO: $e")
    results["scaffold_generation"] = false
end

# 2. Tentar compute_metrics
println("\n2. Testando compute_metrics...")
try
    metrics = compute_metrics(test_scaffold, 10.0)
    println("   ✓ Porosidade: $(round(metrics.porosity * 100, digits=1))%")
    println("   ✓ Pore size: $(round(metrics.mean_pore_size_um, digits=1)) μm")
    println("   ✓ Interconnectivity: $(round(metrics.interconnectivity * 100, digits=1))%")
    results["compute_metrics"] = true
catch e
    println("   ✗ ERRO: $e")
    results["compute_metrics"] = false
end

# 3. Tentar create_mesh
println("\n3. Testando create_mesh_simple...")
try
    v, f = create_mesh_simple(test_scaffold, 10.0)
    println("   ✓ Vertices: $(size(v,1)), Faces: $(size(f,1))")
    results["create_mesh"] = true
catch e
    println("   ✗ ERRO: $e")
    results["create_mesh"] = false
end

# 4. Tentar otimização
println("\n4. Testando ScaffoldOptimizer...")
try
    optimizer = ScaffoldOptimizer(voxel_size_um=10.0)
    println("   ✓ Optimizer criado")
    results["optimizer_create"] = true
catch e
    println("   ✗ ERRO: $e")
    results["optimizer_create"] = false
end

println("\n5. Testando optimize_scaffold...")
try
    optimizer = ScaffoldOptimizer(voxel_size_um=10.0)
    target = ScaffoldParameters(0.85, 150.0, 0.90, 1.2, (5.0, 5.0, 5.0), 10.0)
    result = optimize_scaffold(optimizer, test_scaffold, target)
    println("   ✓ Otimização concluída")
    results["optimize_scaffold"] = true
catch e
    println("   ✗ ERRO: $e")
    results["optimize_scaffold"] = false
end

# 5. Tentar preprocess
println("\n6. Testando preprocess_image...")
try
    img = rand(Float64, 30, 30, 30)
    processed = preprocess_image(img; denoise=true, normalize=true)
    println("   ✓ Preprocessado: $(size(processed))")
    results["preprocess"] = true
catch e
    println("   ✗ ERRO: $e")
    results["preprocess"] = false
end

# 6. Tentar segmentação
println("\n7. Testando segment_scaffold...")
try
    img = rand(Float64, 30, 30, 30)
    binary = segment_scaffold(img, "otsu")
    println("   ✓ Segmentado: $(size(binary)), type=$(eltype(binary))")
    results["segment"] = true
catch e
    println("   ✗ ERRO: $e")
    results["segment"] = false
end

# Summary
println("\n" * "=" ^ 60)
println("SUMMARY")
println("=" ^ 60)

passed = count(values(results))
total = length(results)

for (name, ok) in sort(collect(results))
    status = ok ? "✓ PASS" : "✗ FAIL"
    println("  $name: $status")
end

println("\nResult: $passed / $total tests passed")

if passed == total
    println("\n✓ ALL CORE FUNCTIONS WORK!")
else
    println("\n✗ Some functions failed - NOT publication ready")
end
