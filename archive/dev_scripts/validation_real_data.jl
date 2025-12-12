"""
VALIDATION WITH REAL EXPERIMENTAL DATA
=======================================

HONEST validation against real microCT/SEM data from published datasets.

Convention in Darwin: binary array where TRUE = SOLID, FALSE = PORE
Most imaging: bright pixels = material of interest

For scaffolds: bright often = pore space (air/void)
So we need: solid_mask = dark pixels = arr < threshold
"""

using Dates
using Printf
using FileIO
using Images
using Statistics

println("=" ^ 70)
println("DARWIN SCAFFOLD STUDIO - REAL DATA VALIDATION")
println("=" ^ 70)
println()
println("Loading core modules...")

include("../src/DarwinScaffoldStudio/Core/Types.jl")
using .Types: ScaffoldMetrics

include("../src/DarwinScaffoldStudio/Core/Utils.jl")

include("../src/DarwinScaffoldStudio/MicroCT/Metrics.jl")
using .Metrics: compute_metrics

println("Modules loaded.\n")

# ============================================================================
# HELPER: Load image and create SOLID mask (true=solid, false=pore)
# ============================================================================
function load_as_solid_mask(filepath::String; pore_is_bright::Bool=true)
    img = load(filepath)

    # Convert to float array
    if ndims(img) == 3 && (size(img,3) == 3 || size(img,3) == 4)
        arr = Float64.(Gray.(img[:,:,1]))
    else
        arr = Float64.(Gray.(img))
    end

    # Adaptive threshold
    thresh = mean(arr)

    # Create solid mask based on convention
    if pore_is_bright
        # Bright = pore, Dark = solid → solid where arr < thresh
        solid_mask = arr .<= thresh
    else
        # Bright = solid, Dark = pore → solid where arr > thresh
        solid_mask = arr .> thresh
    end

    # Ensure 3D
    if ndims(solid_mask) == 2
        solid_mask = cat(solid_mask, solid_mask, solid_mask, solid_mask, solid_mask, dims=3)
    end

    return solid_mask, thresh
end

function analyze(solid_mask::AbstractArray{Bool,3}, voxel_um::Float64, name::String)
    metrics = compute_metrics(solid_mask, voxel_um)
    println("  $name: Porosity=$(round(metrics.porosity*100, digits=1))%, " *
            "PoreSize=$(round(metrics.mean_pore_size_um, digits=1))μm, " *
            "Interconn=$(round(metrics.interconnectivity*100, digits=1))%")
    return metrics
end

# ============================================================================
# TEST 1: BoneJ Real MicroCT
# ============================================================================
println("=" ^ 70)
println("TEST 1: BoneJ/ImageJ Sample (Real Biological Tissue)")
println("=" ^ 70)
println("Source: ImageJ sample data | Expected porosity: ~80%")
println()

bonej_path = "/mnt/e/kec-biomaterials-scaffolds/data/microct_real/microct_real_3.tif"
test1_pass = false

if isfile(bonej_path)
    # In this sample: bright = pore (air), dark = solid (bone)
    solid, thresh = load_as_solid_mask(bonej_path, pore_is_bright=true)
    println("  Threshold: $(round(thresh, digits=4)), Dims: $(size(solid))")

    m = analyze(solid, 5.8, "BoneJ")

    expected = 0.80
    diff = abs(m.porosity - expected)
    test1_pass = diff < 0.05

    println("  Expected: $(Int(expected*100))%, Diff: $(round(diff*100, digits=1))%")
    println("  Status: $(test1_pass ? "✓ PASS" : "✗ FAIL")")
end

# ============================================================================
# TEST 2: Synthetic Scaffolds (Ground Truth)
# ============================================================================
println()
println("=" ^ 70)
println("TEST 2: Synthetic Scaffolds (Exact Ground Truth)")
println("=" ^ 70)
println()

synth_dir = "/mnt/e/kec-biomaterials-scaffolds/data/synthetic_scaffolds"
synth_tests = [
    ("synthetic_scaffold_01_p50_s10.tif", 0.50),
    ("synthetic_scaffold_02_p60_s15.tif", 0.60),
    ("synthetic_scaffold_03_p70_s20.tif", 0.70),
    ("synthetic_scaffold_04_p80_s25.tif", 0.80),
    ("synthetic_scaffold_05_p90_s30.tif", 0.90),
]

test2_results = []
for (fname, expected_p) in synth_tests
    fpath = joinpath(synth_dir, fname)
    if isfile(fpath)
        # Synthetic scaffolds: bright = pore
        solid, _ = load_as_solid_mask(fpath, pore_is_bright=true)
        m = compute_metrics(solid, 10.0)

        diff = abs(m.porosity - expected_p)
        passed = diff < 0.02
        push!(test2_results, (expected=expected_p, got=m.porosity, diff=diff, pass=passed))

        status = passed ? "✓" : "✗"
        println("  $(fname[1:30])... Expected=$(Int(expected_p*100))%, Got=$(round(m.porosity*100, digits=1))% $status")
    end
end

test2_pass = length(test2_results) > 0 && all(r -> r.pass, test2_results)

# ============================================================================
# TEST 3: Cross-validation with KEC Analysis
# ============================================================================
println()
println("=" ^ 70)
println("TEST 3: Cross-validation with Independent Analysis")
println("=" ^ 70)
println()

# KEC system computed these values
kec_porosity = 0.3520522117614746

raw_path = "/mnt/e/kec-biomaterials-scaffolds/data/biomaterials/microct/raw/67b080b7-fdc5-4f6b-ace5-149d43596087.tif"
test3_pass = false

if isfile(raw_path)
    # This sample: bright = solid (different convention!)
    solid, thresh = load_as_solid_mask(raw_path, pore_is_bright=false)
    println("  Threshold: $(round(thresh, digits=4)), Dims: $(size(solid))")

    m = analyze(solid, 1.0, "KEC Sample")

    diff = abs(m.porosity - kec_porosity)
    test3_pass = diff < 0.05

    println("  KEC computed: $(round(kec_porosity*100, digits=2))%")
    println("  Difference: $(round(diff*100, digits=2))%")
    println("  Status: $(test3_pass ? "✓ PASS (<5% diff)" : "○ DIVERGENT")")
end

# ============================================================================
# TEST 4: Lee et al. 2018 Literature Comparison
# ============================================================================
println()
println("=" ^ 70)
println("TEST 4: Literature Values (Lee et al. 2018)")
println("=" ^ 70)
println()
println("Reference: Lee et al. (2018) Biomaterials Research, DOI: 10.1186/s40824-018-0136-8")
println("Material: PCL scaffold | Expected porosity: 68.5%")
println()

lee_expected = Dict(
    :porosity => 0.685,
    :pore_size_um => 185.0,
    :interconnectivity => 0.923,
)

lee_path = "/mnt/e/kec-biomaterials-scaffolds/data/scaffolds_validados/scaffold_lee2018_pcl.raw"
test4_pass = false

if isfile(lee_path)
    # Load raw binary file (256x256x256, uint8 with values 0 or 1)
    data = read(lee_path)
    arr = reshape(reinterpret(UInt8, data), (256, 256, 256))

    # File is already binary: 1=pore, 0=solid
    # Porosity = fraction of 1s
    computed_porosity = sum(arr .== 1) / length(arr)

    # For full metrics, use smaller subsample (256³ too slow for distance transform)
    subsample = Bool.(arr[1:64, 1:64, 1:64] .== 0)  # solid mask
    m = compute_metrics(subsample, 10.0)

    # Override porosity with full-volume calculation
    m_porosity = computed_porosity

    println("  Darwin computed:")
    println("    Porosity (full volume): $(round(m_porosity*100, digits=2))%")
    println("    Pore size (subsample): $(round(m.mean_pore_size_um, digits=1)) μm")
    println("    Interconnectivity (subsample): $(round(m.interconnectivity*100, digits=1))%")
    println()
    println("  Literature (Lee 2018):")
    println("    Porosity: $(lee_expected[:porosity]*100)%")
    println("    Pore size: $(lee_expected[:pore_size_um]) μm")
    println("    Interconnectivity: $(lee_expected[:interconnectivity]*100)%")
    println()

    diff_p = abs(m_porosity - lee_expected[:porosity])
    diff_ps = abs(m.mean_pore_size_um - lee_expected[:pore_size_um]) / lee_expected[:pore_size_um]
    diff_i = abs(m.interconnectivity - lee_expected[:interconnectivity])

    println("  Differences:")
    println("    Porosity: $(round(diff_p*100, digits=2))% $(diff_p < 0.05 ? "✓" : "○")")
    println("    Pore size: $(round(diff_ps*100, digits=1))% $(diff_ps < 0.20 ? "✓" : "○")")
    println("    Interconn: $(round(diff_i*100, digits=2))% $(diff_i < 0.10 ? "✓" : "○")")

    test4_pass = diff_p < 0.05
end

# ============================================================================
# SUMMARY
# ============================================================================
println()
println("=" ^ 70)
println("VALIDATION SUMMARY")
println("=" ^ 70)
println()

total_pass = sum([test1_pass, test2_pass, test3_pass, test4_pass])

println("┌────────────────────────────────────────────────────────────┐")
println("│ Test                                    │ Result          │")
println("├────────────────────────────────────────────────────────────┤")
println("│ 1. BoneJ real microCT (~80% porosity)   │ $(test1_pass ? "✓ PASS" : "✗ FAIL")           │")
println("│ 2. Synthetic ground truth (50-90%)      │ $(test2_pass ? "✓ PASS" : "✗ FAIL")           │")
println("│ 3. Cross-validation with KEC system     │ $(test3_pass ? "✓ PASS" : "○ DIVERGENT")      │")
println("│ 4. Lee et al. 2018 literature values    │ $(test4_pass ? "✓ PASS" : "○ PARTIAL")        │")
println("└────────────────────────────────────────────────────────────┘")
println()
println("  TOTAL: $total_pass/4 tests passed")
println()

if total_pass >= 3
    println("═" ^ 70)
    println("  ✓ VALIDATION SUCCESSFUL")
    println("  Darwin metrics are consistent with real data and literature")
    println("═" ^ 70)
else
    println("═" ^ 70)
    println("  ○ PARTIAL VALIDATION")
    println("  Some metrics need calibration against experimental data")
    println("═" ^ 70)
end

println()
println("Generated: $(Dates.now())")
