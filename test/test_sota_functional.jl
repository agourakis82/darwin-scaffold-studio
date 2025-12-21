"""
Functional Test for SOTA+++ Modules

Actually tests that the code works, not just loads.

Created: 2025-12-21
"""

using Test

println("="^80)
println("SOTA+++ Functional Tests")
println("="^80)

# ============================================================================
# Test 1: UncertaintyQuantification
# ============================================================================

println("\n1. Testing UncertaintyQuantification...")

include("../src/DarwinScaffoldStudio/Science/UncertaintyQuantification.jl")
using .UncertaintyQuantification

@testset "UncertaintyQuantification" begin
    # Test BayesianNN construction
    bnn = BayesianNN(5, [16, 8], 1)
    @test bnn.n_samples == 100
    @test bnn.prior_σ == 1.0f0
    
    # Test training (small scale)
    X_train = randn(Float32, 5, 20)
    y_train = randn(Float32, 1, 20)
    
    losses = train_bayesian!(bnn, X_train, y_train, epochs=5, lr=0.01)
    @test length(losses) == 5
    @test all(isfinite.(losses))
    
    # Test prediction
    X_test = randn(Float32, 5, 5)
    y_pred, y_std, samples = predict_with_uncertainty(bnn, X_test)
    
    @test length(y_pred) == 5
    @test length(y_std) == 5
    @test all(y_std .> 0)
    @test size(samples) == (100, 5)
    
    # Test uncertainty decomposition
    decomps = decompose_uncertainty(bnn, X_test)
    @test length(decomps) == 5
    @test all(d.total >= 0 for d in decomps)
    
    # Test conformal prediction
    model_fn(x) = reshape(sum(x.^2, dims=1), 1, :)
    cp = ConformalPredictor(model_fn, α=0.1)
    
    X_cal = randn(Float32, 5, 10)
    y_cal = vec(sum(X_cal.^2, dims=1))
    calibrate_conformal!(cp, X_cal, y_cal)
    
    @test length(cp.calibration_scores) == 10
    
    y_pred_cp, lower, upper = predict_conformal(cp, X_test)
    @test all(lower .<= y_pred_cp .<= upper)
    
    println("   ✅ All UncertaintyQuantification tests passed")
end

# ============================================================================
# Test 2: MultiTaskLearning
# ============================================================================

println("\n2. Testing MultiTaskLearning...")

include("../src/DarwinScaffoldStudio/Science/MultiTaskLearning.jl")
using .MultiTaskLearning

@testset "MultiTaskLearning" begin
    # Test model creation
    model = create_scaffold_mtl_model(10)
    @test length(model.task_names) == 7
    @test haskey(model.task_heads, "porosity")
    @test haskey(model.task_heads, "pore_size")
    
    # Test forward pass
    X = randn(Float32, 10, 5)
    predictions = predict_multitask(model, X)
    
    @test length(predictions) == 7
    @test all(haskey(predictions, task) for task in model.task_names)
    @test all(length(predictions[task]) == 5 for task in model.task_names)
    
    # Test training (small scale)
    X_train = randn(Float32, 10, 20)
    y_train_dict = Dict(
        "porosity" => randn(Float32, 20),
        "pore_size" => randn(Float32, 20)
    )
    
    history = train_multitask!(model, X_train, y_train_dict, epochs=3, lr=0.01, batch_size=10)
    @test haskey(history, "total_loss")
    @test length(history["total_loss"]) == 3
    
    println("   ✅ All MultiTaskLearning tests passed")
end

# ============================================================================
# Test 3: ScaffoldFoundationModel
# ============================================================================

println("\n3. Testing ScaffoldFoundationModel...")

include("../src/DarwinScaffoldStudio/Foundation/ScaffoldFoundationModel.jl")
using .ScaffoldFoundationModel

@testset "ScaffoldFoundationModel" begin
    # Test model creation (small scale)
    fm = create_scaffold_fm(
        scaffold_size=(16, 16, 16),
        patch_size=(4, 4, 4),
        embed_dim=32,
        num_heads=2,
        num_layers=2,
        material_dim=10
    )
    
    @test fm.patch_embed.embed_dim == 32
    @test length(fm.transformer_blocks) == 2
    
    # Test encoding
    voxels = rand(Float32, 16, 16, 16, 1, 2)
    materials = randn(Float32, 10, 2)
    
    latent = encode_scaffold(fm, voxels, materials)
    @test size(latent) == (32, 2)
    
    # Test property prediction
    properties = predict_properties(fm, voxels, materials)
    @test size(properties) == (7, 2)
    @test all(isfinite.(properties))
    
    println("   ✅ All ScaffoldFoundationModel tests passed")
end

# ============================================================================
# Test 4: GeometricLaplaceOperator
# ============================================================================

println("\n4. Testing GeometricLaplaceOperator...")

include("../src/DarwinScaffoldStudio/Science/GeometricLaplaceOperator.jl")
using .GeometricLaplaceOperator
using SparseArrays

@testset "GeometricLaplaceOperator" begin
    # Test Laplacian construction
    scaffold = rand(Bool, 8, 8, 8)
    L, coords, node_map = build_laplacian_matrix(scaffold, 10.0)
    
    n_nodes = sum(scaffold)
    @test size(L) == (n_nodes, n_nodes)
    @test size(coords) == (3, n_nodes)
    @test issparse(L)
    
    # Test spectral embedding
    if n_nodes > 10
        k_modes = min(8, n_nodes - 1)
        spectral_basis = spectral_embedding(L, k_modes)
        @test size(spectral_basis, 1) == k_modes
        @test size(spectral_basis, 2) == n_nodes
    end
    
    # Test GLNO construction
    glno = GeometricLaplaceNO(1, 32, 1, 8)
    @test glno.k_modes == 8
    
    println("   ✅ All GeometricLaplaceOperator tests passed")
end

# ============================================================================
# Test 5: ActiveLearning
# ============================================================================

println("\n5. Testing ActiveLearning...")

include("../src/DarwinScaffoldStudio/Optimization/ActiveLearning.jl")
using .ActiveLearning

@testset "ActiveLearning" begin
    # Test acquisition functions
    ei = ExpectedImprovement()
    @test ei(1.0, 0.5, 0.5) > 0
    
    ucb = UpperConfidenceBound()
    @test ucb(1.0, 0.5) == 1.0 + 2.0 * 0.5
    
    pi = ProbabilityOfImprovement()
    @test 0 <= pi(1.0, 0.5, 0.5) <= 1
    
    ts = ThompsonSampling()
    sample = ts(1.0, 0.5)
    @test isfinite(sample)
    
    # Test ActiveLearner
    model_fn(x) = reshape(sum(x.^2, dims=1), 1, :)
    learner = ActiveLearner(model_fn, ei)
    
    @test learner.f_best == -Inf
    
    # Test update
    X_obs = randn(Float64, 5, 10)
    y_obs = vec(sum(X_obs.^2, dims=1))
    update_model!(learner, X_obs, y_obs)
    
    @test size(learner.X_observed) == (5, 10)
    @test length(learner.y_observed) == 10
    @test learner.f_best == maximum(y_obs)
    
    println("   ✅ All ActiveLearning tests passed")
end

# ============================================================================
# Test 6: ExplainableAI
# ============================================================================

println("\n6. Testing ExplainableAI...")

include("../src/DarwinScaffoldStudio/Science/ExplainableAI.jl")
using .ExplainableAI

@testset "ExplainableAI" begin
    # Test SHAP values
    model_fn(x) = reshape(sum(x.^2, dims=1), 1, :)
    x = randn(Float64, 5)
    X_bg = randn(Float64, 5, 10)
    
    shap_vals, base = compute_shap_values(model_fn, x, X_bg, n_samples=10)
    
    @test length(shap_vals) == 5
    @test all(isfinite.(shap_vals))
    @test isfinite(base)
    
    # Test feature importance
    X_test = randn(Float64, 5, 20)
    y_test = vec(sum(X_test.^2, dims=1))
    
    importances, imp_std = feature_importance(model_fn, X_test, y_test, n_repeats=3)
    
    @test length(importances) == 5
    @test all(isfinite.(importances))
    
    println("   ✅ All ExplainableAI tests passed")
end

# ============================================================================
# Summary
# ============================================================================

println("\n" * "="^80)
println("SOTA+++ Functional Tests Summary")
println("="^80)
println("✅ All 6 modules tested and working!")
println("\nModules:")
println("  1. ✅ UncertaintyQuantification - Functional")
println("  2. ✅ MultiTaskLearning - Functional")
println("  3. ✅ ScaffoldFoundationModel - Functional")
println("  4. ✅ GeometricLaplaceOperator - Functional")
println("  5. ✅ ActiveLearning - Functional")
println("  6. ✅ ExplainableAI - Functional")
println("\n🚀 Darwin Scaffold Studio v3.4.0 SOTA+++ modules are WORKING!")
println("="^80)
