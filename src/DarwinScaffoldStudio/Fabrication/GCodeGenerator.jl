"""
G-Code Generator for Bioprinting

Generate G-code for bioprinters from optimized scaffold geometry.
Supports 3DBS, EnvisionTEC, Cellink, and generic RepRap-style printers.

References:
- ISO 6983 (G-code standard)
- 3DBS printer documentation
- Bioprinting best practices (Murphy & Atala 2014)
"""

module GCodeGenerator

using LinearAlgebra
using Statistics
using Printf

export generate_gcode, GCodeConfig, GCodeResult
export generate_infill_pattern, calculate_print_time
export PRINTER_3DBS, PRINTER_CELLINK, PRINTER_GENERIC

# ============================================================================
# PRINTER CONFIGURATIONS
# ============================================================================

"""
    GCodeConfig

Configuration for G-code generation.

# Fields
- `printer_type::String`: Printer model ("3DBS", "Cellink", "Generic")
- `nozzle_diameter_um::Float64`: Nozzle diameter in micrometers
- `layer_height_um::Float64`: Layer height in micrometers
- `print_speed_mm_s::Float64`: Print speed in mm/s
- `travel_speed_mm_s::Float64`: Travel speed in mm/s
- `extrusion_multiplier::Float64`: Flow rate multiplier
- `temperature_c::Float64`: Nozzle temperature (if applicable)
- `bed_temperature_c::Float64`: Bed temperature
- `pressure_kpa::Float64`: Extrusion pressure for pneumatic
- `retraction_mm::Float64`: Retraction distance
- `z_hop_mm::Float64`: Z-lift during travel
- `material::String`: Material being printed
- `infill_density::Float64`: Infill density (0-1)
- `infill_pattern::String`: Pattern ("rectilinear", "gyroid", "honeycomb")
- `perimeters::Int`: Number of perimeter walls
- `start_gcode::String`: Custom start G-code
- `end_gcode::String`: Custom end G-code
"""
struct GCodeConfig
    printer_type::String
    nozzle_diameter_um::Float64
    layer_height_um::Float64
    print_speed_mm_s::Float64
    travel_speed_mm_s::Float64
    extrusion_multiplier::Float64
    temperature_c::Float64
    bed_temperature_c::Float64
    pressure_kpa::Float64
    retraction_mm::Float64
    z_hop_mm::Float64
    material::String
    infill_density::Float64
    infill_pattern::String
    perimeters::Int
    start_gcode::String
    end_gcode::String
end

# Preset configurations
const PRINTER_3DBS = GCodeConfig(
    "3DBS",
    250.0,      # 250μm nozzle (typical for 3DBS)
    200.0,      # 200μm layer height
    5.0,        # 5 mm/s (slow for bioprinting)
    50.0,       # 50 mm/s travel
    1.0,        # extrusion multiplier
    37.0,       # 37°C (body temperature for cell-laden)
    37.0,       # bed temperature
    50.0,       # 50 kPa pressure
    0.0,        # no retraction (pneumatic)
    0.5,        # 0.5mm z-hop
    "PCL",      # default material
    0.5,        # 50% infill
    "rectilinear",
    2,          # 2 perimeters
    """
; 3DBS Bioprinter Start Code
G28 ; Home all axes
G90 ; Absolute positioning
M82 ; Absolute extrusion
G92 E0 ; Reset extruder
M104 S{temp} ; Set temperature
M109 S{temp} ; Wait for temperature
G1 Z5 F1000 ; Lift nozzle
""",
    """
; 3DBS Bioprinter End Code
M104 S0 ; Turn off heater
G91 ; Relative positioning
G1 Z10 F1000 ; Lift nozzle
G90 ; Absolute positioning
G28 X Y ; Home X and Y
M84 ; Disable motors
"""
)

const PRINTER_CELLINK = GCodeConfig(
    "Cellink",
    410.0,      # 410μm (22G needle)
    300.0,      # 300μm layer
    3.0,        # 3 mm/s
    30.0,       # 30 mm/s travel
    1.0,
    25.0,       # Room temperature for hydrogels
    25.0,
    30.0,       # 30 kPa
    0.0,
    0.3,
    "GelMA",
    0.4,
    "rectilinear",
    2,
    "; Cellink BIO X Start\nG28\nG90\n",
    "; Cellink BIO X End\nG28 X Y\n"
)

const PRINTER_GENERIC = GCodeConfig(
    "Generic",
    400.0,
    200.0,
    10.0,
    60.0,
    1.0,
    200.0,      # For thermoplastics
    60.0,
    0.0,        # No pneumatic
    1.0,        # Standard retraction
    0.4,
    "PLA",
    0.2,
    "rectilinear",
    3,
    "G28\nG90\nM82\n",
    "M104 S0\nG28 X Y\nM84\n"
)

"""
    GCodeResult

Result of G-code generation.

# Fields
- `gcode::String`: Complete G-code string
- `n_layers::Int`: Number of layers
- `total_length_mm::Float64`: Total extrusion path length
- `print_time_min::Float64`: Estimated print time
- `material_volume_mm3::Float64`: Material volume used
- `bbox::Tuple`: Bounding box (x_min, x_max, y_min, y_max, z_min, z_max)
"""
struct GCodeResult
    gcode::String
    n_layers::Int
    total_length_mm::Float64
    print_time_min::Float64
    material_volume_mm3::Float64
    bbox::NTuple{6,Float64}
end

# ============================================================================
# MAIN G-CODE GENERATION
# ============================================================================

"""
    generate_gcode(binary_volume::AbstractArray{Bool,3},
                   voxel_size_um::Float64,
                   config::GCodeConfig=PRINTER_3DBS) -> GCodeResult

Generate G-code from binary scaffold volume.

# Arguments
- `binary_volume`: 3D binary array (true = solid)
- `voxel_size_um`: Voxel size in micrometers
- `config`: Printer configuration

# Returns
- `GCodeResult` with complete G-code and statistics
"""
function generate_gcode(
    binary_volume::AbstractArray{Bool,3},
    voxel_size_um::Float64,
    config::GCodeConfig=PRINTER_3DBS
)::GCodeResult
    dims = size(binary_volume)

    # Convert voxel size to mm
    voxel_mm = voxel_size_um / 1000.0
    layer_height_mm = config.layer_height_um / 1000.0
    nozzle_mm = config.nozzle_diameter_um / 1000.0

    # Calculate layer indices
    z_step_voxels = max(1, round(Int, config.layer_height_um / voxel_size_um))
    layer_indices = 1:z_step_voxels:dims[3]
    n_layers = length(layer_indices)

    # Start building G-code
    gcode = IOBuffer()

    # Header
    println(gcode, "; Generated by DarwinScaffoldStudio")
    println(gcode, "; Printer: $(config.printer_type)")
    println(gcode, "; Material: $(config.material)")
    println(gcode, "; Layer height: $(layer_height_mm) mm")
    println(gcode, "; Nozzle: $(nozzle_mm) mm")
    println(gcode, "; Layers: $n_layers")
    println(gcode, "")

    # Start code (with temperature substitution)
    start_code = replace(config.start_gcode, "{temp}" => string(config.temperature_c))
    println(gcode, start_code)
    println(gcode, "")

    # Track statistics
    total_length = 0.0
    total_extrusion = 0.0
    current_e = 0.0

    # Bounding box
    x_min, x_max = Inf, -Inf
    y_min, y_max = Inf, -Inf
    z_min, z_max = 0.0, 0.0

    # Process each layer
    for (layer_num, z_idx) in enumerate(layer_indices)
        z_mm = (z_idx - 1) * voxel_mm
        z_max = z_mm
        if layer_num == 1
            z_min = z_mm
        end

        println(gcode, "; Layer $layer_num / $n_layers")
        println(gcode, "G1 Z$(@sprintf("%.3f", z_mm)) F$(config.travel_speed_mm_s * 60)")

        # Get slice at this Z
        slice = binary_volume[:, :, z_idx]

        # Generate toolpath for this layer
        paths, path_length = generate_layer_toolpath(
            slice, voxel_mm, nozzle_mm,
            config.infill_density, config.infill_pattern,
            config.perimeters, layer_num
        )

        total_length += path_length

        # Convert paths to G-code
        for path in paths
            if isempty(path)
                continue
            end

            # Move to start (travel)
            x_start, y_start = path[1]
            x_min = min(x_min, x_start)
            x_max = max(x_max, x_start)
            y_min = min(y_min, y_start)
            y_max = max(y_max, y_start)

            # Z-hop if configured
            if config.z_hop_mm > 0
                println(gcode, "G1 Z$(@sprintf("%.3f", z_mm + config.z_hop_mm)) F$(config.travel_speed_mm_s * 60)")
            end

            # Retract if configured
            if config.retraction_mm > 0
                current_e -= config.retraction_mm
                println(gcode, "G1 E$(@sprintf("%.4f", current_e)) F1800")
            end

            # Travel move
            println(gcode, "G0 X$(@sprintf("%.3f", x_start)) Y$(@sprintf("%.3f", y_start)) F$(config.travel_speed_mm_s * 60)")

            # Lower Z
            if config.z_hop_mm > 0
                println(gcode, "G1 Z$(@sprintf("%.3f", z_mm)) F$(config.travel_speed_mm_s * 60)")
            end

            # Un-retract
            if config.retraction_mm > 0
                current_e += config.retraction_mm
                println(gcode, "G1 E$(@sprintf("%.4f", current_e)) F1800")
            end

            # Print moves
            for i in 2:length(path)
                x, y = path[i]
                x_min = min(x_min, x)
                x_max = max(x_max, x)
                y_min = min(y_min, y)
                y_max = max(y_max, y)

                # Calculate extrusion
                x_prev, y_prev = path[i-1]
                segment_length = sqrt((x - x_prev)^2 + (y - y_prev)^2)

                # Extrusion volume = cross-section * length
                # For bioprinting, approximate as rectangular: width * height * length
                extrusion_volume = nozzle_mm * layer_height_mm * segment_length

                # Convert to linear E (assuming filament diameter = nozzle for bioink)
                filament_area = π * (nozzle_mm / 2)^2
                e_increment = extrusion_volume / filament_area * config.extrusion_multiplier

                current_e += e_increment
                total_extrusion += e_increment

                # Print command
                println(gcode, "G1 X$(@sprintf("%.3f", x)) Y$(@sprintf("%.3f", y)) E$(@sprintf("%.4f", current_e)) F$(config.print_speed_mm_s * 60)")
            end
        end

        println(gcode, "")
    end

    # End code
    println(gcode, config.end_gcode)

    # Calculate print time
    print_time_min = calculate_print_time(
        total_length,
        config.print_speed_mm_s,
        config.travel_speed_mm_s,
        n_layers
    )

    # Material volume
    material_volume_mm3 = total_extrusion * π * (nozzle_mm / 2)^2

    # Handle edge case for bounding box
    if isinf(x_min)
        x_min, x_max = 0.0, dims[1] * voxel_mm
        y_min, y_max = 0.0, dims[2] * voxel_mm
    end

    return GCodeResult(
        String(take!(gcode)),
        n_layers,
        total_length,
        print_time_min,
        material_volume_mm3,
        (x_min, x_max, y_min, y_max, z_min, z_max)
    )
end

# ============================================================================
# TOOLPATH GENERATION
# ============================================================================

"""
Generate toolpath for a single layer.
Returns vector of paths and total path length.
"""
function generate_layer_toolpath(
    slice::AbstractMatrix{Bool},
    voxel_mm::Float64,
    nozzle_mm::Float64,
    infill_density::Float64,
    infill_pattern::String,
    n_perimeters::Int,
    layer_num::Int
)::Tuple{Vector{Vector{Tuple{Float64,Float64}}}, Float64}
    paths = Vector{Vector{Tuple{Float64,Float64}}}()
    total_length = 0.0

    h, w = size(slice)

    # Find contours (perimeters)
    contours = find_contours(slice, voxel_mm)

    # Generate perimeters (offset inward)
    for p in 1:n_perimeters
        offset = (p - 0.5) * nozzle_mm
        for contour in contours
            offset_contour = offset_path(contour, offset)
            if !isempty(offset_contour)
                push!(paths, offset_contour)
                total_length += path_length(offset_contour)
            end
        end
    end

    # Generate infill inside perimeters
    if infill_density > 0
        inner_offset = n_perimeters * nozzle_mm
        infill_paths = generate_infill(
            slice, voxel_mm, nozzle_mm,
            infill_density, infill_pattern,
            inner_offset, layer_num
        )

        for path in infill_paths
            push!(paths, path)
            total_length += path_length(path)
        end
    end

    return (paths, total_length)
end

"""
Find contours in binary slice using marching squares.
"""
function find_contours(
    slice::AbstractMatrix{Bool},
    voxel_mm::Float64
)::Vector{Vector{Tuple{Float64,Float64}}}
    h, w = size(slice)
    contours = Vector{Vector{Tuple{Float64,Float64}}}()

    # Simple edge detection
    visited = falses(h, w)

    for i in 1:h-1
        for j in 1:w-1
            if slice[i,j] && !visited[i,j]
                # Check if boundary
                is_boundary = false
                for (di, dj) in [(-1,0), (1,0), (0,-1), (0,1)]
                    ni, nj = i + di, j + dj
                    if ni < 1 || ni > h || nj < 1 || nj > w || !slice[ni, nj]
                        is_boundary = true
                        break
                    end
                end

                if is_boundary
                    contour = trace_contour(slice, i, j, visited, voxel_mm)
                    if length(contour) > 3
                        push!(contours, contour)
                    end
                end
            end
        end
    end

    return contours
end

"""
Trace a contour from starting point.
"""
function trace_contour(
    slice::AbstractMatrix{Bool},
    start_i::Int,
    start_j::Int,
    visited::AbstractMatrix{Bool},
    voxel_mm::Float64
)::Vector{Tuple{Float64,Float64}}
    h, w = size(slice)
    contour = Vector{Tuple{Float64,Float64}}()

    # 8-connectivity directions (clockwise)
    dirs = [(0,1), (1,1), (1,0), (1,-1), (0,-1), (-1,-1), (-1,0), (-1,1)]

    i, j = start_i, start_j
    dir_idx = 1

    for _ in 1:min(h * w, 10000)  # Limit iterations
        visited[i, j] = true
        push!(contour, ((j - 0.5) * voxel_mm, (i - 0.5) * voxel_mm))

        # Find next boundary pixel
        found = false
        for k in 1:8
            check_idx = mod1(dir_idx + k - 1, 8)
            di, dj = dirs[check_idx]
            ni, nj = i + di, j + dj

            if 1 <= ni <= h && 1 <= nj <= w && slice[ni, nj]
                # Check if still boundary
                is_boundary = false
                for (bi, bj) in dirs
                    bi2, bj2 = ni + bi, nj + bj
                    if bi2 < 1 || bi2 > h || bj2 < 1 || bj2 > w || !slice[bi2, bj2]
                        is_boundary = true
                        break
                    end
                end

                if is_boundary
                    i, j = ni, nj
                    dir_idx = mod1(check_idx + 5, 8)  # Turn around
                    found = true
                    break
                end
            end
        end

        if !found || (i == start_i && j == start_j && length(contour) > 1)
            break
        end
    end

    # Close contour
    if length(contour) > 2
        push!(contour, contour[1])
    end

    return contour
end

"""
Offset path inward by given distance.
"""
function offset_path(
    path::Vector{Tuple{Float64,Float64}},
    offset::Float64
)::Vector{Tuple{Float64,Float64}}
    if length(path) < 3
        return Tuple{Float64,Float64}[]
    end

    result = Vector{Tuple{Float64,Float64}}()
    n = length(path) - 1  # Exclude closing point

    for i in 1:n
        prev_idx = mod1(i - 1, n)
        next_idx = mod1(i + 1, n)

        x, y = path[i]
        x_prev, y_prev = path[prev_idx]
        x_next, y_next = path[next_idx]

        # Edge vectors
        e1 = (x - x_prev, y - y_prev)
        e2 = (x_next - x, y_next - y)

        # Normals (pointing inward - assuming clockwise contour)
        n1 = normalize_vec((e1[2], -e1[1]))
        n2 = normalize_vec((e2[2], -e2[1]))

        # Average normal
        avg_n = normalize_vec((n1[1] + n2[1], n1[2] + n2[2]))

        # Offset point
        new_x = x + avg_n[1] * offset
        new_y = y + avg_n[2] * offset

        push!(result, (new_x, new_y))
    end

    # Close path
    if !isempty(result)
        push!(result, result[1])
    end

    return result
end

"""
Normalize 2D vector.
"""
function normalize_vec(v::Tuple{Float64,Float64})::Tuple{Float64,Float64}
    len = sqrt(v[1]^2 + v[2]^2)
    if len < 1e-10
        return (0.0, 0.0)
    end
    return (v[1] / len, v[2] / len)
end

# ============================================================================
# INFILL PATTERNS
# ============================================================================

"""
    generate_infill_pattern(bounds::NTuple{4,Float64},
                           density::Float64,
                           pattern::String,
                           line_width::Float64,
                           angle::Float64) -> Vector{Vector{Tuple{Float64,Float64}}}

Generate infill pattern within bounds.

# Arguments
- `bounds`: (x_min, x_max, y_min, y_max)
- `density`: Infill density (0-1)
- `pattern`: "rectilinear", "gyroid", "honeycomb", "concentric"
- `line_width`: Line spacing base
- `angle`: Pattern rotation angle (degrees)
"""
function generate_infill_pattern(
    bounds::NTuple{4,Float64},
    density::Float64,
    pattern::String,
    line_width::Float64,
    angle::Float64
)::Vector{Vector{Tuple{Float64,Float64}}}
    if pattern == "rectilinear"
        return generate_rectilinear_infill(bounds, density, line_width, angle)
    elseif pattern == "honeycomb"
        return generate_honeycomb_infill(bounds, density, line_width)
    elseif pattern == "gyroid"
        return generate_gyroid_infill(bounds, density, line_width)
    elseif pattern == "concentric"
        return generate_concentric_infill(bounds, density, line_width)
    else
        return generate_rectilinear_infill(bounds, density, line_width, angle)
    end
end

"""
Generate infill for slice (with boundary checking).
"""
function generate_infill(
    slice::AbstractMatrix{Bool},
    voxel_mm::Float64,
    nozzle_mm::Float64,
    density::Float64,
    pattern::String,
    inner_offset::Float64,
    layer_num::Int
)::Vector{Vector{Tuple{Float64,Float64}}}
    h, w = size(slice)

    # Bounds
    x_max = w * voxel_mm
    y_max = h * voxel_mm

    # Alternating angle for rectilinear
    angle = (layer_num % 2 == 0) ? 0.0 : 90.0

    # Generate base pattern
    base_paths = generate_infill_pattern(
        (inner_offset, x_max - inner_offset, inner_offset, y_max - inner_offset),
        density,
        pattern,
        nozzle_mm,
        angle
    )

    # Clip paths to solid regions
    clipped_paths = Vector{Vector{Tuple{Float64,Float64}}}()

    for path in base_paths
        clipped = clip_path_to_slice(path, slice, voxel_mm)
        append!(clipped_paths, clipped)
    end

    return clipped_paths
end

"""
Rectilinear infill pattern.
"""
function generate_rectilinear_infill(
    bounds::NTuple{4,Float64},
    density::Float64,
    line_width::Float64,
    angle::Float64
)::Vector{Vector{Tuple{Float64,Float64}}}
    x_min, x_max, y_min, y_max = bounds

    # Line spacing based on density
    spacing = line_width / max(density, 0.01)

    paths = Vector{Vector{Tuple{Float64,Float64}}}()

    # Rotation
    θ = deg2rad(angle)
    cos_θ, sin_θ = cos(θ), sin(θ)

    # Center of bounds
    cx = (x_min + x_max) / 2
    cy = (y_min + y_max) / 2

    # Generate lines in rotated space
    diagonal = sqrt((x_max - x_min)^2 + (y_max - y_min)^2)

    y_line = -diagonal / 2
    direction = 1  # Alternating direction

    while y_line < diagonal / 2
        # Line in rotated space: y = y_line
        x1, y1 = -diagonal / 2, y_line
        x2, y2 = diagonal / 2, y_line

        # Rotate back
        x1_r = x1 * cos_θ - y1 * sin_θ + cx
        y1_r = x1 * sin_θ + y1 * cos_θ + cy
        x2_r = x2 * cos_θ - y2 * sin_θ + cx
        y2_r = x2 * sin_θ + y2 * cos_θ + cy

        # Clip to bounds
        clipped = clip_line_to_bounds((x1_r, y1_r, x2_r, y2_r), bounds)

        if !isnothing(clipped)
            if direction > 0
                push!(paths, [(clipped[1], clipped[2]), (clipped[3], clipped[4])])
            else
                push!(paths, [(clipped[3], clipped[4]), (clipped[1], clipped[2])])
            end
        end

        y_line += spacing
        direction *= -1
    end

    return paths
end

"""
Honeycomb infill pattern.
"""
function generate_honeycomb_infill(
    bounds::NTuple{4,Float64},
    density::Float64,
    line_width::Float64
)::Vector{Vector{Tuple{Float64,Float64}}}
    x_min, x_max, y_min, y_max = bounds

    # Hexagon size based on density
    hex_size = line_width / max(density, 0.01) * 2
    hex_height = hex_size * sqrt(3)

    paths = Vector{Vector{Tuple{Float64,Float64}}}()

    row = 0
    y = y_min
    while y < y_max
        x_offset = (row % 2) * hex_size * 1.5
        x = x_min + x_offset

        path = Vector{Tuple{Float64,Float64}}()

        while x < x_max
            # Hexagon vertices
            for i in 0:5
                angle = π / 3 * i + π / 6
                hx = x + hex_size * cos(angle)
                hy = y + hex_size * sin(angle)

                if x_min <= hx <= x_max && y_min <= hy <= y_max
                    push!(path, (hx, hy))
                end
            end

            x += hex_size * 3
        end

        if length(path) > 1
            push!(paths, path)
        end

        y += hex_height / 2
        row += 1
    end

    return paths
end

"""
Gyroid infill (approximation using sinusoids).
"""
function generate_gyroid_infill(
    bounds::NTuple{4,Float64},
    density::Float64,
    line_width::Float64
)::Vector{Vector{Tuple{Float64,Float64}}}
    x_min, x_max, y_min, y_max = bounds

    # Period based on density
    period = line_width / max(density, 0.01) * 4

    paths = Vector{Vector{Tuple{Float64,Float64}}}()

    # Generate multiple sinusoid lines
    n_lines = ceil(Int, (y_max - y_min) / (period / 4))

    for i in 0:n_lines
        y_base = y_min + i * period / 4
        path = Vector{Tuple{Float64,Float64}}()

        x = x_min
        step = period / 20

        while x < x_max
            y = y_base + (period / 4) * sin(2π * x / period)

            if y_min <= y <= y_max
                push!(path, (x, y))
            end

            x += step
        end

        if length(path) > 1
            push!(paths, path)
        end
    end

    return paths
end

"""
Concentric infill pattern.
"""
function generate_concentric_infill(
    bounds::NTuple{4,Float64},
    density::Float64,
    line_width::Float64
)::Vector{Vector{Tuple{Float64,Float64}}}
    x_min, x_max, y_min, y_max = bounds

    cx = (x_min + x_max) / 2
    cy = (y_min + y_max) / 2

    spacing = line_width / max(density, 0.01)
    max_radius = min(x_max - cx, y_max - cy, cx - x_min, cy - y_min)

    paths = Vector{Vector{Tuple{Float64,Float64}}}()

    r = spacing
    while r < max_radius
        path = Vector{Tuple{Float64,Float64}}()

        for θ in 0:0.1:(2π + 0.1)
            x = cx + r * cos(θ)
            y = cy + r * sin(θ)
            push!(path, (x, y))
        end

        push!(paths, path)
        r += spacing
    end

    return paths
end

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

"""
Clip line to bounds.
"""
function clip_line_to_bounds(
    line::NTuple{4,Float64},
    bounds::NTuple{4,Float64}
)::Union{Nothing, NTuple{4,Float64}}
    x1, y1, x2, y2 = line
    x_min, x_max, y_min, y_max = bounds

    # Cohen-Sutherland algorithm (simplified)
    # Just check if line intersects bounds

    # Clamp endpoints
    x1_c = clamp(x1, x_min, x_max)
    y1_c = clamp(y1, y_min, y_max)
    x2_c = clamp(x2, x_min, x_max)
    y2_c = clamp(y2, y_min, y_max)

    # Check if line is valid
    if x1_c == x2_c && y1_c == y2_c
        return nothing
    end

    return (x1_c, y1_c, x2_c, y2_c)
end

"""
Clip path to solid regions of slice.
"""
function clip_path_to_slice(
    path::Vector{Tuple{Float64,Float64}},
    slice::AbstractMatrix{Bool},
    voxel_mm::Float64
)::Vector{Vector{Tuple{Float64,Float64}}}
    h, w = size(slice)
    clipped = Vector{Vector{Tuple{Float64,Float64}}}()
    current_segment = Vector{Tuple{Float64,Float64}}()

    for (x, y) in path
        # Convert to pixel coordinates
        i = clamp(round(Int, y / voxel_mm + 0.5), 1, h)
        j = clamp(round(Int, x / voxel_mm + 0.5), 1, w)

        if slice[i, j]
            push!(current_segment, (x, y))
        else
            if length(current_segment) > 1
                push!(clipped, copy(current_segment))
            end
            empty!(current_segment)
        end
    end

    if length(current_segment) > 1
        push!(clipped, current_segment)
    end

    return clipped
end

"""
Calculate path length.
"""
function path_length(path::Vector{Tuple{Float64,Float64}})::Float64
    if length(path) < 2
        return 0.0
    end

    total = 0.0
    for i in 2:length(path)
        x1, y1 = path[i-1]
        x2, y2 = path[i]
        total += sqrt((x2 - x1)^2 + (y2 - y1)^2)
    end

    return total
end

"""
    calculate_print_time(total_length_mm::Float64,
                         print_speed::Float64,
                         travel_speed::Float64,
                         n_layers::Int) -> Float64

Estimate print time in minutes.
"""
function calculate_print_time(
    total_length_mm::Float64,
    print_speed::Float64,
    travel_speed::Float64,
    n_layers::Int
)::Float64
    # Print time
    print_time = total_length_mm / print_speed / 60  # minutes

    # Estimate travel time (roughly 20% of print moves)
    travel_time = total_length_mm * 0.2 / travel_speed / 60

    # Layer change time (estimate 2 seconds per layer)
    layer_time = n_layers * 2 / 60

    return print_time + travel_time + layer_time
end

"""
    save_gcode(result::GCodeResult, filepath::String)

Save G-code to file.
"""
function save_gcode(result::GCodeResult, filepath::String)
    open(filepath, "w") do io
        write(io, result.gcode)
    end
    @info "G-code saved to $filepath"
    @info "  Layers: $(result.n_layers)"
    @info "  Print time: $(@sprintf("%.1f", result.print_time_min)) min"
    @info "  Material: $(@sprintf("%.2f", result.material_volume_mm3)) mm³"
end

end # module GCodeGenerator
