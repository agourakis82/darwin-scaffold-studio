using Oxygen
using HTTP
using JSON
using DarwinScaffoldStudio

# Enable CORS
const CORS_HEADERS = [
    "Access-Control-Allow-Origin" => "*",
    "Access-Control-Allow-Methods" => "GET, POST, OPTIONS",
    "Access-Control-Allow-Headers" => "Content-Type"
]

function add_cors(handler)
    return function(req::HTTP.Request)
        if req.method == "OPTIONS"
            return HTTP.Response(200, CORS_HEADERS)
        end
        res = handler(req)
        for (k, v) in CORS_HEADERS
            HTTP.setheader(res, k => v)
        end
        return res
    end
end

# Middleware
serveparallel(false) # Disable parallel serving for now to avoid issues

# Health check
@get "/health" function()
    return Dict("status" => "ok", "version" => "1.0.0")
end

# Analyze Scaffold
@post "/analyze" function(req::HTTP.Request)
    try
        data = json(req)
        file_path = data["file_path"]
        voxel_size = get(data, "voxel_size", 10.0)
        
        # Load image
        volume = load_image(file_path)
        
        # Preprocess
        volume_clean = preprocess_image(volume)
        
        # Segment
        binary = segment_scaffold(volume_clean)
        
        # Compute metrics
        basic_metrics = compute_metrics(binary, voxel_size)
        
        # Thesis: Advanced Metrics
        kec_metrics = compute_kec_metrics(binary, voxel_size)
        perc_metrics = compute_percolation_metrics(binary, voxel_size)
        
        # Thesis: AI Prediction
        viability_score = predict_viability(binary)
        
        # Combine all metrics
        metrics = merge(basic_metrics, kec_metrics, perc_metrics)
        metrics["ai_viability_score"] = viability_score
        
        # Detect problems
        optimizer = Optimizer(voxel_size)
        problems = detect_problems(optimizer, basic_metrics)
        
        return Dict(
            "metrics" => metrics,
            "problems" => problems,
            "volume_shape" => size(volume),
            "status" => "success"
        )
    catch e
        @error "Analysis failed" exception=(e, catch_backtrace())
        return HTTP.Response(500, ["Content-Type" => "application/json"], body=JSON.json(Dict("error" => string(e))))
    end
end

# Optimize Scaffold
@post "/optimize" function(req::HTTP.Request)
    try
        data = json(req)
        
        # Parse parameters
        params = ScaffoldParameters(
            get(data, "porosity", 0.90),
            get(data, "pore_size", 150.0),
            get(data, "interconnectivity", 0.95),
            get(data, "tortuosity", 1.1),
            (2.0, 2.0, 2.0), # Fixed volume for demo
            get(data, "resolution", 10.0)
        )
        
        method = get(data, "method", "freeze-casting")
        material = get(data, "material", "PCL")
        use_case = get(data, "use_case", "Bone")
        
        # Run optimization (Thesis Loop)
        optimizer = Optimizer(params.resolution_um)
        
        # Create dummy original for comparison (or load if provided)
        original_vol = zeros(Bool, 100, 100, 100) # Placeholder
        
        # Use new thesis optimization
        results = optimize_scaffold_thesis(optimizer, original_vol, params, material, use_case)
        
        # Save optimized result to temp file
        output_path = "/tmp/optimized_scaffold_$(time()).stl"
        mesh = create_mesh(results.optimized_volume, params.resolution_um)
        export_stl(mesh, output_path)
        
        # Calculate improvements (Thesis metrics)
        # For demo, we just return the metrics directly
        
        return Dict(
            "optimized_metrics" => results.metrics,
            "stl_path" => output_path,
            "status" => "success"
        )
    catch e
        @error "Optimization failed" exception=(e, catch_backtrace())
        return HTTP.Response(500, ["Content-Type" => "application/json"], body=JSON.json(Dict("error" => string(e))))
    end
end

# Generate Mesh (for visualization)
@post "/mesh" function(req::HTTP.Request)
    try
        data = json(req)
        file_path = data["file_path"]
        voxel_size = get(data, "voxel_size", 10.0)
        quality = get(data, "quality", "standard")
        
        volume = load_image(file_path)
        binary = segment_scaffold(preprocess_image(volume))
        
        mesh = create_mesh(binary, voxel_size; quality=quality)
        
        output_path = "/tmp/mesh_$(time()).stl"
        export_stl(mesh, output_path)
        
        return Dict(
            "stl_path" => output_path,
            "vertices" => length(mesh.vertices),
            "faces" => length(mesh.faces)
        )
    catch e
        @error "Mesh generation failed" exception=(e, catch_backtrace())
        return HTTP.Response(500, ["Content-Type" => "application/json"], body=JSON.json(Dict("error" => string(e))))
    end
end

# Start server
port = 8081
@info "Starting Darwin Scaffold Engine on port $port"
serve(port=port, middleware=[add_cors])
