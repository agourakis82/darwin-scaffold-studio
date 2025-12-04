# Darwin Pipeline Demo
# Runs the complete end-to-end workflow

using DarwinScaffoldStudio

function run_pipeline_demo()
    println("🧬 Starting Darwin Unified Pipeline Demo...")
    
    # Configuration
    config = PipelineConfig(
        "Bone_Regen_Project_Alpha",
        "idea", # Start from text description
        "Design a highly porous scaffold for load-bearing bone defects",
        "bone",
        ["porosity", "strength", "bioactivity"],
        true,  # Use Quantum Optimization
        true   # Use Hausen Special Edition
    )
    
    # Execute
    result = run_darwin_pipeline(config)
    
    println("\n✅ Pipeline Finished Successfully!")
    println("ID: $(result.id)")
    println("Report: $(result.report_path)")
    println("Blockchain Hash: $(result.steps["provenance_hash"])")
    
    # Print Hausen Special details if used
    if config.use_hausen_special
        opt = result.steps["optimization"]
        println("\n👩‍🔬 Hausen Special Protocols Applied:")
        println("   - Material: $(opt["material"])")
        println("   - Microspheres: $(opt["microspheres"])")
    end
end

run_pipeline_demo()
