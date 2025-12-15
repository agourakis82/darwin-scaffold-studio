using Oxygen
using HTTP
using JSON
using UUIDs
using Dates
using DarwinScaffoldStudio

# Enable CORS
const CORS_HEADERS = [
    "Access-Control-Allow-Origin" => "*",
    "Access-Control-Allow-Methods" => "GET, POST, PUT, DELETE, OPTIONS",
    "Access-Control-Allow-Headers" => "Content-Type, Authorization"
]

# ============================================================================
# Workspace Storage (in-memory for demo, would use Redis/DB in production)
# ============================================================================
struct WorkspaceState
    id::String
    created_at::DateTime
    material::String
    tissue::String
    volume::Union{Array{Bool,3}, Nothing}
    metrics::Union{Dict, Nothing}
    history::Vector{Array{Bool,3}}
    history_index::Int
end

const WORKSPACES = Dict{String, WorkspaceState}()

function create_workspace_state(material::String, tissue::String)
    id = string(uuid4())
    state = WorkspaceState(
        id,
        now(),
        material,
        tissue,
        nothing,
        nothing,
        Vector{Array{Bool,3}}(),
        0
    )
    WORKSPACES[id] = state
    return state
end

function get_workspace(id::String)
    get(WORKSPACES, id, nothing)
end

function update_workspace_volume!(id::String, volume::Array{Bool,3})
    ws = WORKSPACES[id]
    # Add to history for undo
    new_history = ws.history_index < length(ws.history) ?
        ws.history[1:ws.history_index] : copy(ws.history)
    push!(new_history, volume)

    WORKSPACES[id] = WorkspaceState(
        ws.id, ws.created_at, ws.material, ws.tissue,
        volume, ws.metrics, new_history, length(new_history)
    )
end

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

# ============================================================================
# Phase 2: Workspace Management Endpoints
# ============================================================================

@post "/workspace/create" function(req::HTTP.Request)
    try
        data = json(req)
        material = get(data, "material", "PCL")
        tissue = get(data, "tissue", "bone")

        ws = create_workspace_state(material, tissue)

        return Dict(
            "id" => ws.id,
            "created_at" => string(ws.created_at),
            "material" => ws.material,
            "tissue" => ws.tissue,
            "has_volume" => false
        )
    catch e
        @error "Workspace creation failed" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON.json(Dict("error" => string(e))))
    end
end

@get "/workspace/{id}/metrics" function(req::HTTP.Request, id::String)
    try
        ws = get_workspace(id)
        if isnothing(ws)
            return HTTP.Response(404, JSON.json(Dict("error" => "Workspace not found")))
        end

        if isnothing(ws.volume)
            return Dict(
                "workspace_id" => id,
                "has_volume" => false,
                "metrics" => nothing
            )
        end

        # Compute metrics
        voxel_size = 10.0  # Default voxel size
        metrics = compute_metrics(ws.volume, voxel_size)

        return Dict(
            "workspace_id" => id,
            "has_volume" => true,
            "metrics" => metrics
        )
    catch e
        @error "Get metrics failed" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON.json(Dict("error" => string(e))))
    end
end

@post "/workspace/{id}/edit" function(req::HTTP.Request, id::String)
    try
        ws = get_workspace(id)
        if isnothing(ws)
            return HTTP.Response(404, JSON.json(Dict("error" => "Workspace not found")))
        end

        data = json(req)
        operation = data["operation"]
        params = get(data, "params", Dict())

        volume = isnothing(ws.volume) ? zeros(Bool, 100, 100, 100) : copy(ws.volume)

        if operation == "add"
            # Add material at position
            pos = params["position"]
            radius = get(params, "radius", 5)
            # Simple spherical brush
            for dx in -radius:radius, dy in -radius:radius, dz in -radius:radius
                if dx^2 + dy^2 + dz^2 <= radius^2
                    x, y, z = clamp.(pos .+ (dx, dy, dz), 1, size(volume))
                    volume[x, y, z] = true
                end
            end
        elseif operation == "remove"
            pos = params["position"]
            radius = get(params, "radius", 5)
            for dx in -radius:radius, dy in -radius:radius, dz in -radius:radius
                if dx^2 + dy^2 + dz^2 <= radius^2
                    x, y, z = clamp.(pos .+ (dx, dy, dz), 1, size(volume))
                    volume[x, y, z] = false
                end
            end
        elseif operation == "smooth"
            # Apply Gaussian smoothing
            volume = smooth_volume(volume)
        end

        update_workspace_volume!(id, volume)

        return Dict("success" => true)
    catch e
        @error "Edit failed" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON.json(Dict("error" => string(e))))
    end
end

@post "/workspace/{id}/undo" function(req::HTTP.Request, id::String)
    try
        ws = get_workspace(id)
        if isnothing(ws) || ws.history_index <= 1
            return Dict("success" => false, "message" => "Nothing to undo")
        end

        new_index = ws.history_index - 1
        volume = ws.history[new_index]

        WORKSPACES[id] = WorkspaceState(
            ws.id, ws.created_at, ws.material, ws.tissue,
            volume, ws.metrics, ws.history, new_index
        )

        return Dict("success" => true, "history_index" => new_index)
    catch e
        @error "Undo failed" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON.json(Dict("error" => string(e))))
    end
end

@post "/workspace/{id}/redo" function(req::HTTP.Request, id::String)
    try
        ws = get_workspace(id)
        if isnothing(ws) || ws.history_index >= length(ws.history)
            return Dict("success" => false, "message" => "Nothing to redo")
        end

        new_index = ws.history_index + 1
        volume = ws.history[new_index]

        WORKSPACES[id] = WorkspaceState(
            ws.id, ws.created_at, ws.material, ws.tissue,
            volume, ws.metrics, ws.history, new_index
        )

        return Dict("success" => true, "history_index" => new_index)
    catch e
        @error "Redo failed" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON.json(Dict("error" => string(e))))
    end
end

# ============================================================================
# Phase 2: TPMS Generation Endpoints
# ============================================================================

@post "/tpms/generate" function(req::HTTP.Request)
    try
        data = json(req)

        surface_type = Symbol(get(data, "surface_type", "gyroid"))
        porosity = get(data, "porosity", 0.75)
        unit_cell_size = get(data, "unit_cell_size", 2.0)
        resolution = get(data, "grid_resolution", 64)
        iso_value = get(data, "iso_value", 0.0)

        # Generate TPMS scaffold
        volume = generate_tpms_scaffold(
            surface_type,
            porosity,
            unit_cell_size,
            resolution,
            iso_value
        )

        # Create mesh
        voxel_size = unit_cell_size * 1000 / resolution  # Convert to um
        mesh = create_mesh(volume, voxel_size)

        # Save to temp file
        output_path = "/tmp/tpms_$(time()).stl"
        export_stl(mesh, output_path)

        # Compute metrics
        metrics = compute_metrics(volume, voxel_size)

        return Dict(
            "mesh_url" => output_path,
            "metrics" => metrics,
            "status" => "success"
        )
    catch e
        @error "TPMS generation failed" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON.json(Dict("error" => string(e))))
    end
end

@post "/tpms/preview" function(req::HTTP.Request)
    try
        data = json(req)

        surface_type = Symbol(get(data, "surface_type", "gyroid"))
        porosity = get(data, "porosity", 0.75)
        unit_cell_size = get(data, "unit_cell_size", 2.0)
        resolution = get(data, "grid_resolution", 16)  # Lower res for preview

        # Generate preview at lower resolution
        volume = generate_tpms_scaffold(
            surface_type,
            porosity,
            unit_cell_size,
            resolution,
            0.0
        )

        voxel_size = unit_cell_size * 1000 / resolution
        mesh = create_mesh(volume, voxel_size)

        output_path = "/tmp/tpms_preview_$(time()).stl"
        export_stl(mesh, output_path)

        # Estimate metrics
        estimated_metrics = Dict(
            "porosity" => porosity * 100,
            "estimated_pore_size" => unit_cell_size * porosity * 500  # Rough estimate
        )

        return Dict(
            "preview_url" => output_path,
            "estimated_metrics" => estimated_metrics
        )
    catch e
        @error "TPMS preview failed" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON.json(Dict("error" => string(e))))
    end
end

# ============================================================================
# Phase 2: Heatmap Endpoints
# ============================================================================

@get "/workspace/{id}/heatmap/{type}" function(req::HTTP.Request, id::String, type::String)
    try
        ws = get_workspace(id)
        if isnothing(ws) || isnothing(ws.volume)
            return HTTP.Response(404, JSON.json(Dict("error" => "No volume data")))
        end

        heatmap_type = Symbol(type)
        voxel_size = 10.0

        # Compute heatmap based on type
        heatmap_data = if heatmap_type == :porosity
            compute_local_porosity(ws.volume, 5)
        elseif heatmap_type == :stress
            # Simplified stress distribution
            compute_stress_distribution(ws.volume)
        elseif heatmap_type == :permeability
            compute_local_permeability(ws.volume, voxel_size)
        elseif heatmap_type == :wall_thickness
            compute_wall_thickness(ws.volume, voxel_size)
        else
            ws.volume .* 1.0  # Default: just return volume as float
        end

        return Dict(
            "data" => vec(heatmap_data),
            "shape" => size(heatmap_data),
            "min" => minimum(heatmap_data),
            "max" => maximum(heatmap_data),
            "colormap" => "viridis"
        )
    catch e
        @error "Heatmap computation failed" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON.json(Dict("error" => string(e))))
    end
end

# ============================================================================
# Phase 2: Image Import Endpoints
# ============================================================================

@post "/import/image" function(req::HTTP.Request)
    try
        data = json(req)
        file_path = data["file_path"]

        volume = load_image(file_path)

        # Generate preview slice
        mid_slice = div(size(volume, 3), 2)
        preview = volume[:, :, mid_slice]

        # Save preview as PNG
        preview_path = "/tmp/preview_$(time()).png"
        # save_image(preview_path, preview)  # Would need Images.jl

        return Dict(
            "preview_url" => preview_path,
            "dimensions" => collect(size(volume)),
            "voxel_size" => 10.0,  # Default, would read from metadata
            "status" => "success"
        )
    catch e
        @error "Image import failed" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON.json(Dict("error" => string(e))))
    end
end

@post "/import/preprocess" function(req::HTTP.Request)
    try
        data = json(req)
        file_path = data["file_path"]
        denoise = get(data, "denoise", true)
        normalize = get(data, "normalize", true)

        volume = load_image(file_path)

        if denoise
            volume = denoise_volume(volume)
        end

        if normalize
            volume = normalize_volume(volume)
        end

        preview_path = "/tmp/preprocessed_$(time()).png"

        return Dict(
            "preview_url" => preview_path,
            "status" => "success"
        )
    catch e
        @error "Preprocessing failed" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON.json(Dict("error" => string(e))))
    end
end

@post "/import/segment" function(req::HTTP.Request)
    try
        data = json(req)
        file_path = data["file_path"]
        threshold = get(data, "threshold", 128)
        method = get(data, "method", "otsu")

        volume = load_image(file_path)
        volume = preprocess_image(volume)

        binary = if method == "otsu"
            segment_scaffold(volume)
        elseif method == "adaptive"
            adaptive_threshold(volume)
        else
            volume .> threshold
        end

        # Create workspace with segmented volume
        ws = create_workspace_state("unknown", "bone")
        update_workspace_volume!(ws.id, binary)

        voxel_size = 10.0
        metrics = compute_metrics(binary, voxel_size)

        return Dict(
            "volume_id" => ws.id,
            "metrics" => metrics,
            "status" => "success"
        )
    catch e
        @error "Segmentation failed" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON.json(Dict("error" => string(e))))
    end
end

# ============================================================================
# Phase 2: Validation Endpoints
# ============================================================================

@post "/validation/check" function(req::HTTP.Request)
    try
        data = json(req)
        workspace_id = data["workspace_id"]
        tissue = get(data, "tissue", "bone")

        ws = get_workspace(workspace_id)
        if isnothing(ws) || isnothing(ws.volume)
            return HTTP.Response(404, JSON.json(Dict("error" => "No volume data")))
        end

        voxel_size = 10.0
        metrics = compute_metrics(ws.volume, voxel_size)

        # Get tissue-specific targets from literature
        targets = get_tissue_targets(tissue)

        # Validate each metric
        validation = validate_metrics(metrics, targets)

        # Generate recommendations
        recommendations = generate_recommendations(metrics, targets)

        return Dict(
            "overall_score" => validation["overall_score"],
            "metrics" => validation["metrics"],
            "recommendations" => recommendations,
            "citations" => get_tissue_citations(tissue)
        )
    catch e
        @error "Validation failed" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON.json(Dict("error" => string(e))))
    end
end

@get "/literature/{tissue}" function(req::HTTP.Request, tissue::String)
    try
        citations = get_tissue_citations(tissue)
        targets = get_tissue_targets(tissue)

        return Dict(
            "references" => citations,
            "targets" => targets
        )
    catch e
        @error "Literature lookup failed" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON.json(Dict("error" => string(e))))
    end
end

# ============================================================================
# Phase 2: AI Agent Endpoints
# ============================================================================

@post "/agents/chat" function(req::HTTP.Request)
    try
        data = json(req)
        agent_type = get(data, "agent", "design")
        message = data["message"]
        context = get(data, "context", Dict())

        # Get response from agent
        response = chat_with_agent(agent_type, message, context)

        return Dict(
            "response" => response["text"],
            "suggestions" => get(response, "suggestions", String[]),
            "actions" => get(response, "actions", [])
        )
    catch e
        @error "Agent chat failed" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON.json(Dict("error" => string(e))))
    end
end

@post "/agents/text-to-scaffold" function(req::HTTP.Request)
    try
        data = json(req)
        prompt = data["prompt"]
        constraints = get(data, "constraints", Dict())

        # Use TextToScaffold module
        result = text_to_scaffold(prompt, constraints)

        # Create workspace
        ws = create_workspace_state(
            get(constraints, "material", "PCL"),
            get(constraints, "tissue", "bone")
        )
        update_workspace_volume!(ws.id, result["volume"])

        # Generate mesh
        voxel_size = 10.0
        mesh = create_mesh(result["volume"], voxel_size)
        output_path = "/tmp/generated_$(time()).stl"
        export_stl(mesh, output_path)

        metrics = compute_metrics(result["volume"], voxel_size)

        return Dict(
            "workspace_id" => ws.id,
            "mesh_url" => output_path,
            "metrics" => metrics,
            "explanation" => result["explanation"]
        )
    catch e
        @error "Text-to-scaffold failed" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON.json(Dict("error" => string(e))))
    end
end

# ============================================================================
# Phase 2: Export Endpoints
# ============================================================================

@post "/export/stl" function(req::HTTP.Request)
    try
        data = json(req)
        workspace_id = data["workspace_id"]
        quality = get(data, "quality", "medium")
        smoothing = get(data, "smoothing", true)
        binary_format = get(data, "binary", true)

        ws = get_workspace(workspace_id)
        if isnothing(ws) || isnothing(ws.volume)
            return HTTP.Response(404, JSON.json(Dict("error" => "No volume data")))
        end

        volume = ws.volume
        if smoothing
            volume = smooth_volume(volume)
        end

        voxel_size = 10.0
        mesh = create_mesh(volume, voxel_size; quality=quality)

        output_path = "/tmp/export_$(ws.id)_$(time()).stl"
        export_stl(mesh, output_path; binary=binary_format)

        file_size = filesize(output_path)

        return Dict(
            "file_path" => output_path,
            "size_bytes" => file_size
        )
    catch e
        @error "STL export failed" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON.json(Dict("error" => string(e))))
    end
end

@post "/export/gcode" function(req::HTTP.Request)
    try
        data = json(req)
        workspace_id = data["workspace_id"]
        printer = get(data, "printer", "generic")
        layer_height = get(data, "layer_height", 0.2)
        infill = get(data, "infill_percent", 20)
        nozzle = get(data, "nozzle_diameter", 0.4)
        temp = get(data, "temperature", 200)
        bed_temp = get(data, "bed_temperature", 60)

        ws = get_workspace(workspace_id)
        if isnothing(ws) || isnothing(ws.volume)
            return HTTP.Response(404, JSON.json(Dict("error" => "No volume data")))
        end

        # Generate G-code
        gcode_params = Dict(
            "layer_height" => layer_height,
            "infill_percent" => infill,
            "nozzle_diameter" => nozzle,
            "print_temperature" => temp,
            "bed_temperature" => bed_temp,
            "printer_profile" => printer
        )

        gcode_id = string(uuid4())
        output_path = "/tmp/gcode_$(gcode_id).gcode"

        result = generate_gcode(ws.volume, output_path, gcode_params)

        return Dict(
            "gcode_id" => gcode_id,
            "file_path" => output_path,
            "layer_count" => result["layer_count"],
            "estimated_time_minutes" => result["estimated_time"]
        )
    catch e
        @error "G-code generation failed" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON.json(Dict("error" => string(e))))
    end
end

@get "/export/gcode/{id}/preview" function(req::HTTP.Request, id::String)
    try
        layer = parse(Int, get(HTTP.queryparams(req.target), "layer", "1"))

        gcode_path = "/tmp/gcode_$(id).gcode"
        if !isfile(gcode_path)
            return HTTP.Response(404, JSON.json(Dict("error" => "G-code not found")))
        end

        # Parse G-code and extract layer
        paths = parse_gcode_layer(gcode_path, layer)

        return Dict(
            "paths" => paths,
            "layer_height" => layer * 0.2  # Assuming 0.2mm layer height
        )
    catch e
        @error "G-code preview failed" exception=(e, catch_backtrace())
        return HTTP.Response(500, JSON.json(Dict("error" => string(e))))
    end
end

# ============================================================================
# Helper Functions (stubs - would be implemented in DarwinScaffoldStudio)
# ============================================================================

function generate_tpms_scaffold(surface_type::Symbol, porosity::Float64,
                                 unit_cell_size::Float64, resolution::Int,
                                 iso_value::Float64)
    # This would call the actual TPMSGenerators module
    # For now, return a simple gyroid-like structure
    volume = zeros(Bool, resolution, resolution, resolution)

    for i in 1:resolution, j in 1:resolution, k in 1:resolution
        x = 2π * (i-1) / resolution * 2
        y = 2π * (j-1) / resolution * 2
        z = 2π * (k-1) / resolution * 2

        # Gyroid implicit function
        val = sin(x) * cos(y) + sin(y) * cos(z) + sin(z) * cos(x)

        # Threshold based on porosity
        threshold = 2 * (porosity - 0.5) + iso_value
        volume[i, j, k] = val > threshold
    end

    return volume
end

function smooth_volume(volume::Array{Bool,3})
    # Simple smoothing - would use proper Gaussian in production
    return volume
end

function compute_local_porosity(volume::Array{Bool,3}, kernel_size::Int)
    # Compute local porosity map
    result = zeros(Float64, size(volume))
    for i in 1:size(volume, 1), j in 1:size(volume, 2), k in 1:size(volume, 3)
        # Simple local porosity calculation
        result[i, j, k] = 1.0 - Float64(volume[i, j, k])
    end
    return result
end

function compute_stress_distribution(volume::Array{Bool,3})
    # Simplified stress distribution
    return Float64.(volume)
end

function compute_local_permeability(volume::Array{Bool,3}, voxel_size::Float64)
    return Float64.(.!volume) .* 1e-10  # Simplified
end

function compute_wall_thickness(volume::Array{Bool,3}, voxel_size::Float64)
    return Float64.(volume) .* voxel_size  # Simplified
end

function denoise_volume(volume)
    return volume  # Stub
end

function normalize_volume(volume)
    return volume  # Stub
end

function adaptive_threshold(volume)
    return volume .> 0.5  # Stub
end

function get_tissue_targets(tissue::String)
    targets = Dict(
        "bone" => Dict(
            "porosity" => (70.0, 95.0),
            "pore_size" => (100.0, 500.0),
            "interconnectivity" => (90.0, 100.0)
        ),
        "cartilage" => Dict(
            "porosity" => (80.0, 95.0),
            "pore_size" => (150.0, 300.0),
            "interconnectivity" => (85.0, 100.0)
        ),
        "skin" => Dict(
            "porosity" => (85.0, 98.0),
            "pore_size" => (50.0, 200.0),
            "interconnectivity" => (80.0, 100.0)
        )
    )
    return get(targets, tissue, targets["bone"])
end

function get_tissue_citations(tissue::String)
    return [
        Dict(
            "id" => "murphy2010",
            "authors" => "Murphy et al.",
            "year" => 2010,
            "title" => "The effect of mean pore size on cell attachment, proliferation and migration in collagen-glycosaminoglycan scaffolds for bone tissue engineering",
            "journal" => "Biomaterials"
        ),
        Dict(
            "id" => "karageorgiou2005",
            "authors" => "Karageorgiou & Kaplan",
            "year" => 2005,
            "title" => "Porosity of 3D biomaterial scaffolds and osteogenesis",
            "journal" => "Biomaterials"
        )
    ]
end

function validate_metrics(metrics::Dict, targets::Dict)
    score = 0.0
    count = 0
    validated = Dict()

    for (metric, target_range) in targets
        if haskey(metrics, string(metric))
            value = metrics[string(metric)]
            in_range = target_range[1] <= value <= target_range[2]
            metric_score = in_range ? 100.0 : max(0.0, 100.0 - abs(value - mean(target_range)) / 10)
            score += metric_score
            count += 1
            validated[metric] = Dict(
                "value" => value,
                "target" => "$(target_range[1])-$(target_range[2])",
                "valid" => in_range,
                "score" => metric_score
            )
        end
    end

    return Dict(
        "overall_score" => count > 0 ? score / count : 0.0,
        "metrics" => validated
    )
end

function generate_recommendations(metrics::Dict, targets::Dict)
    recs = String[]

    if haskey(metrics, "porosity") && haskey(targets, "porosity")
        porosity = metrics["porosity"]
        target = targets["porosity"]
        if porosity < target[1]
            push!(recs, "Consider increasing porosity by $(round(target[1] - porosity, digits=1))% for optimal cell infiltration")
        elseif porosity > target[2]
            push!(recs, "Porosity may be too high, consider reducing for better mechanical strength")
        end
    end

    return recs
end

function chat_with_agent(agent_type::String, message::String, context::Dict)
    # This would call the actual Agent modules
    # Stub response
    return Dict(
        "text" => "Based on your scaffold design, I recommend optimizing the porosity to 85% for better cell infiltration. The current pore size is within the optimal range.",
        "suggestions" => ["Optimize scaffold", "Export STL", "Run validation"]
    )
end

function text_to_scaffold(prompt::String, constraints::Dict)
    # This would call the TextToScaffold module
    # Stub response
    volume = generate_tpms_scaffold(:gyroid, 0.85, 2.0, 64, 0.0)
    return Dict(
        "volume" => volume,
        "explanation" => "Generated a gyroid scaffold with 85% porosity optimized for bone tissue engineering."
    )
end

function generate_gcode(volume::Array{Bool,3}, output_path::String, params::Dict)
    # This would call the GCodeGenerator module
    # Stub response
    layer_count = size(volume, 3)
    estimated_time = layer_count * 0.5  # 30 seconds per layer

    # Write basic G-code header
    open(output_path, "w") do f
        println(f, "; G-code generated by Darwin Scaffold Studio")
        println(f, "; Layer height: $(params["layer_height"])")
        println(f, "G28 ; Home all axes")
        println(f, "M104 S$(params["print_temperature"]) ; Set hotend temp")
        println(f, "M140 S$(params["bed_temperature"]) ; Set bed temp")
    end

    return Dict(
        "layer_count" => layer_count,
        "estimated_time" => estimated_time
    )
end

function parse_gcode_layer(gcode_path::String, layer::Int)
    # Parse G-code file and return paths for specific layer
    # Stub response
    return [
        Dict("type" => "extrude", "points" => [[0, 0], [10, 0], [10, 10], [0, 10], [0, 0]])
    ]
end

# Start server
port = 8081
@info "Starting Darwin Scaffold Engine on port $port"
@info "API Documentation:"
@info "  POST /workspace/create - Create new workspace"
@info "  GET  /workspace/{id}/metrics - Get workspace metrics"
@info "  POST /tpms/generate - Generate TPMS scaffold"
@info "  POST /validation/check - Validate scaffold against literature"
@info "  POST /agents/chat - Chat with AI agent"
@info "  POST /export/stl - Export STL mesh"
@info "  POST /export/gcode - Generate G-code"
serve(port=port, middleware=[add_cors])
