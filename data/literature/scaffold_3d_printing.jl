# ============================================================================
# SCAFFOLD 3D PRINTING - Extrusion & Bioprinting
# ============================================================================
# Converts scaffold designs to printable parameters and G-code
# Supports: FDM (thermoplastics), Bioprinting (hydrogels)
# ============================================================================

using Printf

# ============================================================================
# PRINTER DEFINITIONS
# ============================================================================

"""
3D Printer specification for scaffold fabrication.
"""
struct PrinterSpec
    name::String
    type::Symbol                    # :fdm, :bioprint, :sla, :sls
    nozzle_diameters_mm::Vector{Float64}  # Available nozzles
    min_layer_height_mm::Float64
    max_layer_height_mm::Float64
    build_volume_mm::Tuple{Float64, Float64, Float64}  # X, Y, Z
    temp_range_c::Tuple{Float64, Float64}  # Min-max temperature
    pressure_range_kpa::Tuple{Float64, Float64}  # For bioprinters
    speed_range_mm_s::Tuple{Float64, Float64}
    compatible_materials::Vector{String}  # Polymer abbreviations
end

const PRINTER_DATABASE = Dict(
    # FDM Printers for thermoplastics
    :fdm_standard => PrinterSpec(
        "Standard FDM (Prusa/Ender style)",
        :fdm,
        [0.2, 0.3, 0.4, 0.6, 0.8],  # Nozzle sizes
        0.05,                        # Min layer
        0.35,                        # Max layer
        (250.0, 210.0, 210.0),      # Build volume
        (180.0, 260.0),             # Temp range
        (0.0, 0.0),                 # No pressure (filament)
        (10.0, 150.0),              # Speed range
        ["PCL", "PLA", "PLGA85", "PLGA50", "PGA", "PHB", "PPF", "PLDLA"]
    ),

    :fdm_high_temp => PrinterSpec(
        "High-Temp FDM (PEEK capable)",
        :fdm,
        [0.25, 0.4, 0.6],
        0.05,
        0.30,
        (200.0, 200.0, 200.0),
        (250.0, 420.0),
        (0.0, 0.0),
        (5.0, 80.0),
        ["PCL", "PLA", "PLGA85", "PLGA50", "PGA", "PHB", "PPF", "PU", "PLDLA"]
    ),

    # Bioprinters for hydrogels
    :bioprint_pneumatic => PrinterSpec(
        "Pneumatic Bioprinter (CELLINK/Allevi style)",
        :bioprint,
        [0.15, 0.20, 0.25, 0.33, 0.41, 0.60],  # Needle gauges as mm
        0.1,
        0.5,
        (130.0, 90.0, 90.0),
        (4.0, 65.0),                # Cooling to heating
        (5.0, 300.0),               # Pressure kPa
        (1.0, 30.0),                # Slow for bioinks
        ["ALG", "COL1", "GelMA", "HA", "FIB", "CHI", "PEGDA", "SILK", "MAT"]
    ),

    :bioprint_screw => PrinterSpec(
        "Screw-Driven Bioprinter (precise extrusion)",
        :bioprint,
        [0.20, 0.25, 0.41, 0.60, 0.84],
        0.1,
        0.6,
        (150.0, 150.0, 100.0),
        (4.0, 45.0),
        (0.0, 0.0),                 # Screw-driven, not pressure
        (0.5, 20.0),
        ["ALG", "COL1", "GelMA", "HA", "FIB", "CHI", "PEGDA", "SILK"]
    ),

    :bioprint_dual => PrinterSpec(
        "Dual-Head Bioprinter (hydrogel + support)",
        :bioprint,
        [0.20, 0.25, 0.33, 0.41],
        0.1,
        0.4,
        (100.0, 100.0, 80.0),
        (4.0, 60.0),
        (10.0, 400.0),
        (1.0, 25.0),
        ["ALG", "COL1", "GelMA", "HA", "FIB", "CHI", "PEGDA"]
    ),
)

# ============================================================================
# MATERIAL PRINT PARAMETERS
# ============================================================================

"""
Optimal print parameters for a material.
"""
struct MaterialPrintParams
    polymer_abbrev::String
    print_type::Symbol              # :fdm or :bioprint
    optimal_temp_c::Float64         # Nozzle/bed temp
    bed_temp_c::Float64             # Bed temperature
    optimal_speed_mm_s::Float64
    optimal_pressure_kpa::Float64   # For bioprinting
    layer_height_factor::Float64    # Multiplier of nozzle diameter
    cooling_required::Bool
    crosslink_during_print::Bool    # UV/ionic during print
    crosslink_method::String        # Post-print crosslinking
    min_wall_thickness_mm::Float64  # Minimum printable wall
    notes::String
end

const MATERIAL_PRINT_PARAMS = Dict(
    # FDM Thermoplastics
    "PCL" => MaterialPrintParams(
        "PCL", :fdm,
        80.0, 30.0,         # Low temp polymer
        25.0, 0.0,
        0.5,                # 50% of nozzle
        true,               # Needs cooling
        false, "None",
        0.3,
        "Low melting point, easy to print, slow crystallization"
    ),
    "PLA" => MaterialPrintParams(
        "PLA", :fdm,
        210.0, 60.0,
        40.0, 0.0,
        0.5,
        true,
        false, "None",
        0.3,
        "Standard FDM material, good detail"
    ),
    "PLGA85" => MaterialPrintParams(
        "PLGA85", :fdm,
        190.0, 50.0,
        30.0, 0.0,
        0.5,
        true,
        false, "None",
        0.35,
        "Medical grade, requires dry filament"
    ),
    "PLGA50" => MaterialPrintParams(
        "PLGA50", :fdm,
        180.0, 45.0,
        25.0, 0.0,
        0.5,
        true,
        false, "None",
        0.35,
        "Faster degradation than 85:15"
    ),
    "PGA" => MaterialPrintParams(
        "PGA", :fdm,
        230.0, 70.0,
        20.0, 0.0,
        0.6,
        false,
        false, "None",
        0.4,
        "High temp, moisture sensitive"
    ),
    "PLDLA" => MaterialPrintParams(
        "PLDLA", :fdm,
        185.0, 55.0,        # Similar to PLA but slightly lower
        35.0, 0.0,
        0.5,
        true,               # Cooling helps
        false, "None",
        0.25,               # Good detail possible
        "Medical grade 70:30 L:DL ratio, good for bone, 24-52 wk degradation"
    ),

    # Bioprinting Hydrogels
    "ALG" => MaterialPrintParams(
        "ALG", :bioprint,
        25.0, 25.0,
        8.0, 40.0,
        0.8,                # Thicker layers for hydrogels
        false,
        true, "CaCl2",      # Ionic crosslink during/after
        0.20,               # Can print ~200 μm walls with fine nozzle
        "Print into CaCl2 bath or spray crosslink"
    ),
    "COL1" => MaterialPrintParams(
        "COL1", :bioprint,
        8.0, 37.0,          # Cold nozzle, warm bed for gelation
        5.0, 25.0,
        0.7,
        false,
        false, "GEN",       # Post-print genipin crosslink
        0.25,               # Can print ~250 μm walls
        "Keep cold (4-8C), gels at 37C"
    ),
    "GelMA" => MaterialPrintParams(
        "GelMA", :bioprint,
        25.0, 15.0,         # Room temp nozzle, cool bed
        6.0, 35.0,
        0.7,
        true,               # Cool to prevent premature gelation
        true, "UV-LAP",     # UV crosslink during/after
        0.15,               # Fine features possible with UV cure
        "UV crosslink 365nm, 10-30s per layer"
    ),
    "PEGDA" => MaterialPrintParams(
        "PEGDA", :bioprint,
        25.0, 25.0,
        10.0, 30.0,
        0.6,
        false,
        true, "UV-IRG",     # UV crosslink
        0.15,               # Fine features with photocuring
        "Photo-crosslink with Irgacure 2959"
    ),
    "HA" => MaterialPrintParams(
        "HA", :bioprint,
        25.0, 25.0,
        4.0, 50.0,          # Higher pressure, viscous
        0.8,
        false,
        true, "UV-LAP",
        0.20,               # 200 μm walls achievable
        "Thiol-ene click chemistry or UV crosslink"
    ),
    "FIB" => MaterialPrintParams(
        "FIB", :bioprint,
        25.0, 37.0,
        3.0, 15.0,          # Very soft, low pressure
        0.9,
        false,
        true, "THR",        # Thrombin crosslink
        0.25,               # Soft material, ~250 μm
        "Print fibrinogen, spray thrombin to crosslink"
    ),
    "CHI" => MaterialPrintParams(
        "CHI", :bioprint,
        25.0, 25.0,
        6.0, 45.0,
        0.7,
        false,
        false, "GEN",       # Genipin post-crosslink
        0.20,               # 200 μm walls
        "pH-sensitive gelation, genipin crosslink"
    ),
    "SILK" => MaterialPrintParams(
        "SILK", :bioprint,
        25.0, 25.0,
        5.0, 35.0,
        0.7,
        false,
        false, "MeOH",      # Methanol induces beta-sheet
        0.20,               # Good printability
        "Methanol vapor treatment for crystallization"
    ),

    # Ceramic paste extrusion (robocasting)
    "TCP" => MaterialPrintParams(
        "TCP", :fdm,        # Ceramic paste extrusion
        25.0, 25.0,         # Room temp extrusion
        5.0, 80.0,          # High pressure paste
        0.6,
        false,
        false, "Sinter",    # Post-print sintering at 1100°C
        0.30,               # ~300 μm minimum
        "Ceramic paste extrusion, requires sintering 1100-1200°C"
    ),
    "BG45S5" => MaterialPrintParams(
        "BG45S5", :fdm,     # Ceramic paste extrusion
        25.0, 25.0,
        4.0, 100.0,
        0.6,
        false,
        false, "Sinter",    # Post-print sintering
        0.35,               # ~350 μm minimum
        "Bioglass paste extrusion, sinter at 1000°C"
    ),
    "HAp" => MaterialPrintParams(
        "HAp", :fdm,        # Ceramic paste extrusion
        25.0, 25.0,
        3.0, 120.0,
        0.5,
        false,
        false, "Sinter",    # Post-print sintering at 1200°C
        0.35,               # ~350 μm minimum
        "Hydroxyapatite paste, sinter at 1200°C"
    ),
)

# ============================================================================
# PRINTABILITY ANALYSIS
# ============================================================================

"""
Check if a scaffold design is printable with given printer.
Returns detailed printability report.
"""
function check_printability(scaffold_geometry::NamedTuple,
                            polymer_abbrev::String,
                            printer::PrinterSpec)
    issues = String[]
    warnings = String[]
    params = Dict{String, Any}()

    # Get material print params
    if !haskey(MATERIAL_PRINT_PARAMS, polymer_abbrev)
        push!(issues, "No print parameters for material: $polymer_abbrev")
        return (printable=false, issues=issues, warnings=warnings, params=params)
    end

    mat_params = MATERIAL_PRINT_PARAMS[polymer_abbrev]

    # Check material compatibility
    if !(polymer_abbrev in printer.compatible_materials)
        push!(issues, "Material $polymer_abbrev not compatible with $(printer.name)")
    end

    # Check print type match
    if mat_params.print_type != printer.type
        push!(issues, "Material requires $(mat_params.print_type), printer is $(printer.type)")
    end

    # Convert scaffold geometry to mm
    pore_size_mm = scaffold_geometry.pore_size_um / 1000.0
    wall_thickness_mm = scaffold_geometry.wall_thickness_um / 1000.0
    window_size_mm = scaffold_geometry.window_size_um / 1000.0

    # Find suitable nozzle
    suitable_nozzles = filter(n -> n <= wall_thickness_mm * 1.5 && n >= wall_thickness_mm * 0.3,
                              printer.nozzle_diameters_mm)

    if isempty(suitable_nozzles)
        # Try to find closest nozzle
        min_nozzle = minimum(printer.nozzle_diameters_mm)
        if wall_thickness_mm < min_nozzle * 0.5
            push!(issues, @sprintf("Wall thickness %.0f μm too thin for smallest nozzle %.0f μm",
                wall_thickness_mm * 1000, min_nozzle * 1000))
        else
            push!(warnings, @sprintf("Wall thickness %.0f μm may require multiple passes",
                wall_thickness_mm * 1000))
            suitable_nozzles = [min_nozzle]
        end
    end

    if !isempty(suitable_nozzles)
        selected_nozzle = suitable_nozzles[1]  # Smallest suitable
        params["nozzle_mm"] = selected_nozzle
        params["layer_height_mm"] = selected_nozzle * mat_params.layer_height_factor
    end

    # Check pore size vs nozzle
    if !isempty(suitable_nozzles)
        if pore_size_mm < suitable_nozzles[1] * 1.5
            push!(warnings, @sprintf("Pore size %.0f μm close to nozzle diameter - may have bridging issues",
                pore_size_mm * 1000))
        end
    end

    # Check minimum feature size
    if wall_thickness_mm < mat_params.min_wall_thickness_mm
        push!(issues, @sprintf("Wall %.0f μm below material minimum %.0f μm",
            wall_thickness_mm * 1000, mat_params.min_wall_thickness_mm * 1000))
    end

    # Check temperature
    if mat_params.optimal_temp_c < printer.temp_range_c[1] ||
       mat_params.optimal_temp_c > printer.temp_range_c[2]
        push!(issues, @sprintf("Material temp %.0f°C outside printer range %.0f-%.0f°C",
            mat_params.optimal_temp_c, printer.temp_range_c...))
    end

    # Set print parameters
    params["nozzle_temp_c"] = mat_params.optimal_temp_c
    params["bed_temp_c"] = mat_params.bed_temp_c
    params["print_speed_mm_s"] = mat_params.optimal_speed_mm_s
    params["pressure_kpa"] = mat_params.optimal_pressure_kpa
    params["crosslink_method"] = mat_params.crosslink_method
    params["crosslink_during"] = mat_params.crosslink_during_print

    printable = isempty(issues)

    return (
        printable = printable,
        issues = issues,
        warnings = warnings,
        params = params,
        material_params = mat_params,
        selected_nozzle_mm = get(params, "nozzle_mm", 0.0)
    )
end

# ============================================================================
# SCAFFOLD GEOMETRY GENERATION
# ============================================================================

"""
Scaffold architecture types for 3D printing.
"""
@enum ScaffoldArchitecture begin
    GRID_WOODPILE       # 0/90 alternating layers
    GRID_OFFSET         # Offset grid pattern
    HONEYCOMB           # Hexagonal pattern
    GYROID              # TPMS gyroid
    DIAMOND             # TPMS diamond
    SCHWARZ_P           # TPMS Schwarz P
end

"""
Generate layer pattern for scaffold printing.
Returns path coordinates for one layer.
"""
function generate_layer_pattern(;
    architecture::ScaffoldArchitecture = GRID_WOODPILE,
    layer_num::Int = 0,
    build_size_mm::Tuple{Float64, Float64} = (10.0, 10.0),
    pore_size_mm::Float64 = 0.3,
    strut_width_mm::Float64 = 0.3,
    nozzle_mm::Float64 = 0.4
)
    paths = Vector{Tuple{Float64, Float64}}[]

    # Spacing between struts (center to center)
    spacing = pore_size_mm + strut_width_mm

    if architecture == GRID_WOODPILE
        # Alternating 0/90 degree layers
        if layer_num % 2 == 0
            # X-direction struts
            y = strut_width_mm / 2
            while y < build_size_mm[2]
                push!(paths, [(0.0, y), (build_size_mm[1], y)])
                y += spacing
            end
        else
            # Y-direction struts
            x = strut_width_mm / 2
            while x < build_size_mm[1]
                push!(paths, [(x, 0.0), (x, build_size_mm[2])])
                x += spacing
            end
        end

    elseif architecture == GRID_OFFSET
        # Offset grid - shifted every other layer
        offset = (layer_num % 2) * spacing / 2

        if (layer_num ÷ 2) % 2 == 0
            # X-direction
            y = strut_width_mm / 2 + offset
            while y < build_size_mm[2]
                push!(paths, [(0.0, y), (build_size_mm[1], y)])
                y += spacing
            end
        else
            # Y-direction
            x = strut_width_mm / 2 + offset
            while x < build_size_mm[1]
                push!(paths, [(x, 0.0), (x, build_size_mm[2])])
                x += spacing
            end
        end

    elseif architecture == HONEYCOMB
        # Simplified honeycomb - zigzag pattern
        # Full implementation would need proper hex geometry
        y = strut_width_mm / 2
        row = 0
        while y < build_size_mm[2]
            path = Tuple{Float64, Float64}[]
            x = (row % 2) * spacing / 2
            going_up = true
            while x < build_size_mm[1]
                push!(path, (x, y))
                if going_up
                    push!(path, (x + spacing/2, y + spacing/2))
                else
                    push!(path, (x + spacing/2, y - spacing/2))
                end
                going_up = !going_up
                x += spacing
            end
            push!(paths, path)
            y += spacing
            row += 1
        end
    end

    return paths
end

# ============================================================================
# G-CODE GENERATION
# ============================================================================

"""
Generate G-code for scaffold printing.
"""
function generate_gcode(;
    scaffold_geometry::NamedTuple,
    polymer_abbrev::String,
    printer::PrinterSpec,
    build_size_mm::Tuple{Float64, Float64, Float64} = (10.0, 10.0, 5.0),
    architecture::ScaffoldArchitecture = GRID_WOODPILE,
    infill_density::Float64 = 1.0  # 1.0 = full scaffold structure
)
    # Check printability first
    printability = check_printability(scaffold_geometry, polymer_abbrev, printer)

    if !printability.printable
        error("Scaffold not printable: $(join(printability.issues, "; "))")
    end

    # Get parameters
    nozzle = printability.selected_nozzle_mm
    layer_height = printability.params["layer_height_mm"]
    print_speed = printability.params["print_speed_mm_s"]
    nozzle_temp = printability.params["nozzle_temp_c"]
    bed_temp = printability.params["bed_temp_c"]

    pore_mm = scaffold_geometry.pore_size_um / 1000.0
    wall_mm = scaffold_geometry.wall_thickness_um / 1000.0

    # Calculate number of layers
    num_layers = ceil(Int, build_size_mm[3] / layer_height)

    # Start G-code
    gcode = String[]

    # Header
    push!(gcode, "; Scaffold G-code generated by DarwinScaffoldStudio")
    push!(gcode, "; Material: $polymer_abbrev")
    push!(gcode, "; Printer: $(printer.name)")
    push!(gcode, @sprintf("; Build size: %.1f x %.1f x %.1f mm", build_size_mm...))
    push!(gcode, @sprintf("; Pore size: %.0f um, Wall: %.0f um", pore_mm*1000, wall_mm*1000))
    push!(gcode, @sprintf("; Layers: %d, Layer height: %.2f mm", num_layers, layer_height))
    push!(gcode, "")

    # Startup sequence
    push!(gcode, "; === STARTUP ===")
    push!(gcode, "G28 ; Home all axes")
    push!(gcode, "G90 ; Absolute positioning")
    push!(gcode, "M82 ; Extruder absolute mode")

    if printer.type == :fdm
        push!(gcode, @sprintf("M104 S%.0f ; Set nozzle temp", nozzle_temp))
        push!(gcode, @sprintf("M140 S%.0f ; Set bed temp", bed_temp))
        push!(gcode, @sprintf("M109 S%.0f ; Wait for nozzle temp", nozzle_temp))
        push!(gcode, @sprintf("M190 S%.0f ; Wait for bed temp", bed_temp))
    elseif printer.type == :bioprint
        push!(gcode, @sprintf("; Set nozzle temp: %.0f C", nozzle_temp))
        push!(gcode, @sprintf("; Set bed temp: %.0f C", bed_temp))
        push!(gcode, @sprintf("; Set pressure: %.0f kPa", printability.params["pressure_kpa"]))
    end

    push!(gcode, "G1 Z5 F300 ; Lift nozzle")
    push!(gcode, "")

    # Calculate extrusion
    filament_diameter = 1.75  # mm for FDM
    nozzle_area = pi * (nozzle/2)^2
    filament_area = pi * (filament_diameter/2)^2
    extrusion_multiplier = nozzle_area * layer_height / filament_area

    total_e = 0.0

    # Print layers
    push!(gcode, "; === PRINTING ===")

    for layer in 0:(num_layers-1)
        z = (layer + 1) * layer_height
        push!(gcode, "")
        push!(gcode, @sprintf("; Layer %d, Z=%.2f", layer, z))
        push!(gcode, @sprintf("G1 Z%.3f F300", z))

        # Generate layer pattern
        paths = generate_layer_pattern(
            architecture = architecture,
            layer_num = layer,
            build_size_mm = (build_size_mm[1], build_size_mm[2]),
            pore_size_mm = pore_mm,
            strut_width_mm = wall_mm,
            nozzle_mm = nozzle
        )

        for path in paths
            if length(path) < 2
                continue
            end

            # Move to start (no extrusion)
            start = path[1]
            push!(gcode, @sprintf("G0 X%.3f Y%.3f F%.0f", start[1], start[2], print_speed * 60 * 2))

            # Print path
            for i in 2:length(path)
                pt = path[i]
                prev = path[i-1]
                dist = sqrt((pt[1]-prev[1])^2 + (pt[2]-prev[2])^2)
                total_e += dist * extrusion_multiplier

                if printer.type == :fdm
                    push!(gcode, @sprintf("G1 X%.3f Y%.3f E%.4f F%.0f",
                        pt[1], pt[2], total_e, print_speed * 60))
                else
                    # Bioprinter - no E value, pressure-driven
                    push!(gcode, @sprintf("G1 X%.3f Y%.3f F%.0f",
                        pt[1], pt[2], print_speed * 60))
                end
            end
        end

        # Crosslinking pause for photocurable materials
        if printability.params["crosslink_during"] && layer % 5 == 4
            push!(gcode, "; UV crosslink pause")
            push!(gcode, "G4 P5000 ; Dwell 5 seconds for UV")
        end
    end

    # End sequence
    push!(gcode, "")
    push!(gcode, "; === FINISH ===")
    push!(gcode, "G1 Z$(build_size_mm[3] + 10) F300 ; Lift nozzle")
    push!(gcode, "G28 X Y ; Home X Y")

    if printer.type == :fdm
        push!(gcode, "M104 S0 ; Nozzle heater off")
        push!(gcode, "M140 S0 ; Bed heater off")
    end

    push!(gcode, "M84 ; Disable motors")

    # Post-processing notes
    if printability.params["crosslink_method"] != "None"
        push!(gcode, "")
        push!(gcode, "; === POST-PROCESSING ===")
        push!(gcode, "; Crosslink with: $(printability.params["crosslink_method"])")
    end

    # Statistics
    print_time_min = (total_e / extrusion_multiplier) / print_speed / 60
    material_volume_mm3 = total_e * filament_area

    return (
        gcode = join(gcode, "\n"),
        num_layers = num_layers,
        print_time_min = print_time_min,
        material_volume_mm3 = material_volume_mm3,
        printability = printability
    )
end

# ============================================================================
# PRINT-OPTIMIZED SCAFFOLD ADAPTATION
# ============================================================================

"""
Adapt scaffold geometry for printability.
Scales features up to meet minimum printer requirements while maintaining porosity.
"""
function adapt_for_printing(scaffold_geometry::NamedTuple,
                            polymer_abbrev::String,
                            printer::PrinterSpec;
                            target_porosity::Union{Nothing, Float64} = nothing)

    if !haskey(MATERIAL_PRINT_PARAMS, polymer_abbrev)
        error("No print parameters for material: $polymer_abbrev")
    end

    mat_params = MATERIAL_PRINT_PARAMS[polymer_abbrev]

    # Get minimum feature sizes
    min_nozzle = minimum(printer.nozzle_diameters_mm)
    min_wall = max(mat_params.min_wall_thickness_mm, min_nozzle * 0.8)
    min_pore = min_nozzle * 1.5  # Need clearance for nozzle

    # Current geometry in mm
    current_wall = scaffold_geometry.wall_thickness_um / 1000.0
    current_pore = scaffold_geometry.pore_size_um / 1000.0
    current_porosity = scaffold_geometry.porosity

    # Calculate scale factor needed
    wall_scale = current_wall < min_wall ? min_wall / current_wall : 1.0
    pore_scale = current_pore < min_pore ? min_pore / current_pore : 1.0
    scale_factor = max(wall_scale, pore_scale)

    # Apply scaling
    new_wall_mm = current_wall * scale_factor
    new_pore_mm = current_pore * scale_factor
    new_window_mm = scaffold_geometry.window_size_um / 1000.0 * scale_factor

    # Recalculate porosity (for cubic unit cell)
    # Porosity ≈ pore³ / (pore + wall)³
    unit_cell = new_pore_mm + new_wall_mm
    new_porosity = (new_pore_mm / unit_cell)^3

    # If target porosity specified, try to maintain it by adjusting pore/wall ratio
    if target_porosity !== nothing && new_porosity < target_porosity * 0.9
        # Increase pore size to maintain porosity
        target_pore_ratio = target_porosity^(1/3)
        new_pore_mm = min_wall * target_pore_ratio / (1 - target_pore_ratio)
        new_pore_mm = max(new_pore_mm, min_pore)
        unit_cell = new_pore_mm + new_wall_mm
        new_porosity = (new_pore_mm / unit_cell)^3
    end

    # Select appropriate nozzle
    suitable_nozzles = filter(n -> n <= new_wall_mm * 1.2 && n >= new_wall_mm * 0.5,
                              printer.nozzle_diameters_mm)
    if isempty(suitable_nozzles)
        selected_nozzle = minimum(filter(n -> n <= new_wall_mm * 1.5, printer.nozzle_diameters_mm))
        if selected_nozzle === nothing
            selected_nozzle = minimum(printer.nozzle_diameters_mm)
        end
    else
        selected_nozzle = suitable_nozzles[1]
    end

    # Create adapted geometry
    adapted = (
        porosity = new_porosity,
        pore_size_um = new_pore_mm * 1000,
        window_size_um = new_window_mm * 1000,
        wall_thickness_um = new_wall_mm * 1000,
        E_scaffold_mpa = scaffold_geometry.E_scaffold_mpa,  # Keep original
        sigma_scaffold_mpa = scaffold_geometry.sigma_scaffold_mpa,
        crosslinking = scaffold_geometry.crosslinking,
        # Print-specific additions
        print_adapted = true,
        scale_factor = scale_factor,
        selected_nozzle_mm = selected_nozzle,
        layer_height_mm = selected_nozzle * mat_params.layer_height_factor,
    )

    return adapted
end

"""
Check if a material is FDM-printable (thermoplastic) or needs bioprinting.
"""
function get_print_method(polymer_abbrev::String)
    if haskey(MATERIAL_PRINT_PARAMS, polymer_abbrev)
        return MATERIAL_PRINT_PARAMS[polymer_abbrev].print_type
    end

    # Infer from material properties
    fdm_materials = ["PCL", "PLA", "PGA", "PLGA50", "PLGA85", "PHB", "PPF", "PU", "PLDLA"]
    bioprint_materials = ["ALG", "COL1", "GelMA", "PEGDA", "HA", "FIB", "CHI", "SILK", "MAT"]
    ceramic_materials = ["HAp", "TCP", "BG45S5", "HAp-PCL", "HAp-PLGA", "TCP-COL"]

    if polymer_abbrev in fdm_materials
        return :fdm
    elseif polymer_abbrev in bioprint_materials
        return :bioprint
    elseif polymer_abbrev in ceramic_materials
        return :ceramic  # Needs SLS or special processing
    else
        return :unknown
    end
end

"""
Select best printer for a material.
"""
function select_printer(polymer_abbrev::String)
    method = get_print_method(polymer_abbrev)

    if method == :fdm
        return PRINTER_DATABASE[:fdm_standard]
    elseif method == :bioprint
        return PRINTER_DATABASE[:bioprint_pneumatic]
    elseif method == :ceramic
        # Ceramics need special handling - suggest composite approach
        return nothing
    else
        return nothing
    end
end

# ============================================================================
# SCAFFOLD-TO-PRINT WORKFLOW
# ============================================================================

"""
Complete workflow: scaffold design → print parameters → G-code
Set adapt_for_print=true to automatically scale geometry for printability.
"""
function scaffold_to_print(tissue_type::Symbol;
    printer_type::Union{Symbol, Nothing} = nothing,  # Auto-select if nothing
    build_size_mm::Tuple{Float64, Float64, Float64} = (10.0, 10.0, 5.0),
    architecture::ScaffoldArchitecture = GRID_WOODPILE,
    adapt_for_print::Bool = true,  # Scale geometry for printability
    verbose::Bool = true
)
    # Load scaffold design module
    if !@isdefined(design_scaffold)
        include("scaffold_design_optimization.jl")
    end

    # Get optimal scaffold design
    design = design_scaffold(tissue_type, verbose=false)

    if !design.validation.all_pass
        @warn "Scaffold design has validation issues"
    end

    polymer = design.polymer.abbrev

    # Auto-select printer based on material
    if printer_type === nothing
        printer = select_printer(polymer)
        if printer === nothing
            error("No suitable printer found for material: $polymer (try ceramic processing)")
        end
    else
        printer = PRINTER_DATABASE[printer_type]
    end

    # Working geometry (may be adapted)
    geometry = design.geometry
    adapted_geometry = nothing

    if verbose
        println("=" ^ 70)
        println("SCAFFOLD TO 3D PRINT: $(design.tissue.name)")
        println("=" ^ 70)
        println()
        println("ORIGINAL SCAFFOLD DESIGN")
        println("-" ^ 70)
        println(@sprintf("  Polymer: %s", design.polymer.name))
        println(@sprintf("  Porosity: %.0f%%", design.geometry.porosity * 100))
        println(@sprintf("  Pore size: %.0f μm", design.geometry.pore_size_um))
        println(@sprintf("  Wall thickness: %.0f μm", design.geometry.wall_thickness_um))
        if design.crosslinking !== nothing
            println(@sprintf("  Crosslinking: %s", design.crosslinking.name))
        end
        println()
    end

    # Check if adaptation needed
    initial_check = check_printability(geometry, polymer, printer)

    if !initial_check.printable && adapt_for_print && haskey(MATERIAL_PRINT_PARAMS, polymer)
        # Adapt geometry for printability
        adapted_geometry = adapt_for_printing(geometry, polymer, printer;
            target_porosity = design.geometry.porosity)
        geometry = adapted_geometry

        if verbose
            println("PRINT-ADAPTED GEOMETRY")
            println("-" ^ 70)
            println(@sprintf("  Scale factor: %.1fx", adapted_geometry.scale_factor))
            println(@sprintf("  New porosity: %.0f%% (was %.0f%%)",
                adapted_geometry.porosity * 100, design.geometry.porosity * 100))
            println(@sprintf("  New pore size: %.0f μm (was %.0f μm)",
                adapted_geometry.pore_size_um, design.geometry.pore_size_um))
            println(@sprintf("  New wall thickness: %.0f μm (was %.0f μm)",
                adapted_geometry.wall_thickness_um, design.geometry.wall_thickness_um))
            println(@sprintf("  Selected nozzle: %.2f mm", adapted_geometry.selected_nozzle_mm))
            println()
        end
    end

    # Check printability (with adapted geometry if applicable)
    printability = check_printability(geometry, polymer, printer)

    if verbose
        println("PRINTABILITY CHECK")
        println("-" ^ 70)
        println(@sprintf("  Printer: %s (%s)", printer.name, printer.type))
        println(@sprintf("  Printable: %s", printability.printable ? "✓ YES" : "✗ NO"))

        if !isempty(printability.issues)
            println("  Issues:")
            for issue in printability.issues
                println("    ✗ $issue")
            end
        end

        if !isempty(printability.warnings)
            println("  Warnings:")
            for warning in printability.warnings
                println("    ⚠ $warning")
            end
        end

        if printability.printable
            println("  Print Parameters:")
            println(@sprintf("    Nozzle: %.2f mm", printability.selected_nozzle_mm))
            println(@sprintf("    Layer height: %.2f mm", printability.params["layer_height_mm"]))
            println(@sprintf("    Nozzle temp: %.0f°C", printability.params["nozzle_temp_c"]))
            println(@sprintf("    Print speed: %.0f mm/s", printability.params["print_speed_mm_s"]))
            if printer.type == :bioprint
                println(@sprintf("    Pressure: %.0f kPa", printability.params["pressure_kpa"]))
            end
            println(@sprintf("    Crosslink: %s", printability.params["crosslink_method"]))
        end
        println()
    end

    # Generate G-code if printable
    gcode_result = nothing
    if printability.printable
        gcode_result = generate_gcode(
            scaffold_geometry = geometry,
            polymer_abbrev = polymer,
            printer = printer,
            build_size_mm = build_size_mm,
            architecture = architecture
        )

        if verbose
            println("G-CODE GENERATED")
            println("-" ^ 70)
            println(@sprintf("  Build size: %.0f × %.0f × %.0f mm", build_size_mm...))
            println(@sprintf("  Layers: %d", gcode_result.num_layers))
            println(@sprintf("  Est. print time: %.0f min", gcode_result.print_time_min))
            println(@sprintf("  Material volume: %.1f mm³", gcode_result.material_volume_mm3))
            println()
        end
    end

    return (
        design = design,
        printer = printer,
        original_geometry = design.geometry,
        print_geometry = geometry,
        adapted = adapted_geometry !== nothing,
        printability = printability,
        gcode = gcode_result,
        build_size_mm = build_size_mm
    )
end

# ============================================================================
# QUICK TEST
# ============================================================================

if abspath(PROGRAM_FILE) == @__FILE__
    println("Testing scaffold 3D printing module...")

    # Include design module
    include("scaffold_design_optimization.jl")

    # Test with skin (bioprint) and bone (FDM)
    println("\n" * "=" ^ 70)
    result_skin = scaffold_to_print(:skin, printer_type=:bioprint_pneumatic, verbose=true)

    println("\n" * "=" ^ 70)
    result_bone = scaffold_to_print(:trabecular_bone, printer_type=:fdm_standard, verbose=true)
end
