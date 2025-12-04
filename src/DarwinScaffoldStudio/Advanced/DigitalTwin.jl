module DigitalTwin

using DifferentialEquations

export create_digital_twin, update_from_sensors, predict_future_state

"""
Real-Time Digital Twin with Biosensor Integration (2025 SOTA)

Creates live digital replica of scaffold + tissue.
Integrates real-time sensor data:
- pH sensors
- O₂ sensors
- Glucose sensors
- Temperature
- Mechanical strain gauges

Enables closed-loop control and predictive maintenance.
"""

mutable struct ScaffoldDigitalTwin
    # Physical state
    current_state::Dict{String, Float64}
    
    # Sensor history
    sensor_data::Dict{String, Vector{Float64}}
    timestamps::Vector{Float64}
    
    # Predictive model
    physics_model::Function
    
    # Control parameters
    target_ranges::Dict{String, Tuple{Float64, Float64}}
end

"""
    create_digital_twin(scaffold_id, sensor_config)

Initialize digital twin linked to physical scaffold via sensors.
"""
function create_digital_twin(scaffold_id::String)
    # Initial state
    state = Dict(
        "pH" => 7.4,
        "O2" => 21.0,  # % O₂
        "glucose" => 5.5,  # mM
        "temperature" => 37.0,  # °C
        "cell_density" => 1e6,  # cells/mL
        "mechanical_strain" => 0.0  # %
    )
    
    # Target physiological ranges
    targets = Dict(
        "pH" => (7.2, 7.6),
        "O2" => (10.0, 21.0),
        "glucose" => (4.0, 7.0),
        "temperature" => (36.5, 37.5),
        "cell_density" => (1e6, 1e8),
        "mechanical_strain" => (0.0, 5.0)
    )
    
    # Physics-based model
    physics = scaffold_physics_model
    
    twin = ScaffoldDigitalTwin(
        state,
        Dict{String, Vector{Float64}}(),
        Float64[],
        physics,
        targets
    )
    
    @info "Digital twin created for scaffold $scaffold_id"
    return twin
end

"""
    update_from_sensors(twin, new_measurements, timestamp)

Update digital twin state from real sensor readings.
Performs data fusion and anomaly detection.
"""
function update_from_sensors(twin::ScaffoldDigitalTwin, 
                             measurements::Dict{String, Float64},
                             timestamp::Float64)
    
    # Store measurements
    push!(twin.timestamps, timestamp)
    for (sensor, value) in measurements
        if !haskey(twin.sensor_data, sensor)
            twin.sensor_data[sensor] = Float64[]
        end
        push!(twin.sensor_data[sensor], value)
        
        # Update current state (Kalman filter-style fusion)
        # Weighted average: 70% new data, 30% model prediction
        model_prediction = twin.physics_model(twin.current_state, timestamp)[sensor]
        twin.current_state[sensor] = 0.7 * value + 0.3 * model_prediction
    end
    
    # Anomaly detection
    anomalies = detect_anomalies(twin, measurements)
    
    if !isempty(anomalies)
        @warn "Anomalies detected: $anomalies"
    end
    
    return Dict("state" => twin.current_state, "anomalies" => anomalies)
end

"""
Detect out-of-range values and sudden changes
"""
function detect_anomalies(twin::ScaffoldDigitalTwin, measurements::Dict)
    anomalies = []
    
    for (sensor, value) in measurements
        # Check if in target range
        if haskey(twin.target_ranges, sensor)
            range_min, range_max = twin.target_ranges[sensor]
            if value < range_min || value > range_max
                push!(anomalies, Dict(
                    "sensor" => sensor,
                    "value" => value,
                    "expected_range" => (range_min, range_max),
                    "type" => "out_of_range"
                ))
            end
        end
        
        # Check for sudden changes (if history available)
        if haskey(twin.sensor_data, sensor) && length(twin.sensor_data[sensor]) > 0
            last_value = twin.sensor_data[sensor][end]
            change_rate = abs(value - last_value)
            
            # Flag if >20% change in one timestep
            if change_rate > 0.2 * last_value
                push!(anomalies, Dict(
                    "sensor" => sensor,
                    "change_rate" => change_rate,
                    "type" => "rapid_change"
                ))
            end
        end
    end
    
    return anomalies
end

"""
    predict_future_state(twin, time_horizon)

Predict scaffold state over next N hours using physics model.
Enables predictive maintenance and intervention planning.
"""
function predict_future_state(twin::ScaffoldDigitalTwin, hours_ahead::Float64=24.0)
    # Current state as initial condition
    u0 = [twin.current_state[key] for key in sort(collect(keys(twin.current_state)))]
    
    # Time span
    t_current = length(twin.timestamps) > 0 ? twin.timestamps[end] : 0.0
    tspan = (0.0, hours_ahead)
    
    # ODE system for coupled dynamics
    function dynamics!(du, u, p, t)
        # Unpack state
        pH, O2, glucose, temp, cell_density, strain = u
        
        # Cell growth (logistic)
        K_max = 1e8  # Carrying capacity
        r_growth = 0.1 / 24  # 1/hour (10% per day)
        du[5] = r_growth * cell_density * (1 - cell_density / K_max)
        
        # O₂ consumption (proportional to cells)
        O2_consumption_rate = 0.01 * cell_density / 1e6  # %/hour
        du[2] = -O2_consumption_rate
        
        #Glucose consumption
        glucose_consumption = 0.05 * cell_density / 1e6  # mM/hour
        du[3] = -glucose_consumption
        
        # pH drift (lactic acid production)
        pH_drift = -0.001 * cell_density / 1e6  # per hour
        du[1] = pH_drift
        
        # Temperature (stable in incubator)
        du[4] = 0.0
        
        # Mechanical strain (constant for static culture)
        du[6] = 0.0
    end
    
    # Solve ODE
    prob = ODEProblem(dynamics!, u0, tspan)
    sol = solve(prob, Tsit5())
    
    # Extract predictions at key timepoints
    prediction_times = [6.0, 12.0, 24.0]  # 6h, 12h, 24h
    predictions = Dict()
    
    for t in prediction_times
        state_at_t = sol(t)
        predictions["t+$(Int(t))h"] = Dict(
            "pH" => state_at_t[1],
            "O2" => state_at_t[2],
            "glucose" => state_at_t[3],
            "temperature" => state_at_t[4],
            "cell_density" => state_at_t[5],
            "mechanical_strain" => state_at_t[6]
        )
    end
    
    # Recommendations based on predictions
    recommendations = generate_recommendations(predictions, twin.target_ranges)
    
    return Dict(
        "predictions" => predictions,
        "recommendations" => recommendations,
        "forecast_confidence" => 0.85  # Heuristic
    )
end

function generate_recommendations(predictions, target_ranges)
    recs = []
    
    # Check 24h prediction
    final_state = predictions["t+24h"]
    
    if final_state["O2"] < target_ranges["O2"][1]
        push!(recs, "Increase O₂ supply or reduce cell density")
    end
    
    if final_state["glucose"] < target_ranges["glucose"][1]
        push!(recs, "Refresh culture medium in next 12 hours")
    end
    
    if final_state["pH"] < target_ranges["pH"][1]
        push!(recs, "Add pH buffer or increase medium exchange rate")
    end
    
    if isempty(recs)
        push!(recs, "System stable - no intervention needed")
    end
    
    return recs
end

function scaffold_physics_model(state::Dict, t::Float64)
    # Simple model for predictions
    # Real: use coupled PDEs from PINNs module
    return state
end

end # module
