// Tauri command handlers - bridge between frontend and backend

use crate::julia_bridge;
use crate::state::{AppSettings, AppState};
use serde::{Deserialize, Serialize};
use std::sync::Mutex;
use tauri::{AppHandle, State};

#[derive(Debug, Serialize)]
pub struct JuliaStatus {
    pub running: bool,
    pub pid: Option<u32>,
    pub url: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ScaffoldMetrics {
    pub porosity: f64,
    pub mean_pore_size_um: f64,
    pub interconnectivity: f64,
    pub tortuosity: f64,
    pub specific_surface_area: f64,
    pub elastic_modulus: f64,
    pub yield_strength: f64,
    pub permeability: f64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TPMSParams {
    pub surface_type: String,
    pub porosity: f64,
    pub unit_cell_size: f64,
    pub n_cells: [u32; 3],
}

#[derive(Debug, Serialize, Deserialize)]
pub struct ChatMessage {
    pub message: String,
    pub agent: String,
    pub context: Option<serde_json::Value>,
}

// Julia server status
#[tauri::command]
pub fn get_julia_status(state: State<'_, Mutex<AppState>>) -> JuliaStatus {
    let state = state.lock().unwrap();
    JuliaStatus {
        running: state.julia_running,
        pid: state.julia_pid,
        url: state.settings.julia_server_url.clone(),
    }
}

// Start Julia server
#[tauri::command]
pub async fn start_julia_server(app: AppHandle) -> Result<(), String> {
    julia_bridge::start_julia_server(&app)
        .await
        .map_err(|e| e.to_string())
}

// Stop Julia server
#[tauri::command]
pub async fn stop_julia_server(app: AppHandle) -> Result<(), String> {
    julia_bridge::stop_julia_server(&app)
        .await
        .map_err(|e| e.to_string())
}

// Open file dialog
#[tauri::command]
pub async fn open_file_dialog(
    title: String,
    filters: Vec<(String, Vec<String>)>,
) -> Result<Option<String>, String> {
    use tauri::api::dialog::FileDialogBuilder;

    let (tx, rx) = std::sync::mpsc::channel();

    let mut builder = FileDialogBuilder::new().set_title(&title);

    for (name, extensions) in filters {
        let exts: Vec<&str> = extensions.iter().map(|s| s.as_str()).collect();
        builder = builder.add_filter(&name, &exts);
    }

    builder.pick_file(move |path| {
        let _ = tx.send(path.map(|p| p.to_string_lossy().to_string()));
    });

    rx.recv().map_err(|e| e.to_string())
}

// Save file dialog
#[tauri::command]
pub async fn save_file_dialog(
    title: String,
    default_name: String,
    filters: Vec<(String, Vec<String>)>,
) -> Result<Option<String>, String> {
    use tauri::api::dialog::FileDialogBuilder;

    let (tx, rx) = std::sync::mpsc::channel();

    let mut builder = FileDialogBuilder::new()
        .set_title(&title)
        .set_file_name(&default_name);

    for (name, extensions) in filters {
        let exts: Vec<&str> = extensions.iter().map(|s| s.as_str()).collect();
        builder = builder.add_filter(&name, &exts);
    }

    builder.save_file(move |path| {
        let _ = tx.send(path.map(|p| p.to_string_lossy().to_string()));
    });

    rx.recv().map_err(|e| e.to_string())
}

// Analyze scaffold via Julia API
#[tauri::command]
pub async fn analyze_scaffold(
    file_path: String,
    voxel_size: f64,
    state: State<'_, Mutex<AppState>>,
) -> Result<serde_json::Value, String> {
    let url = {
        let state = state.lock().unwrap();
        format!("{}/analyze", state.settings.julia_server_url)
    };

    let client = reqwest::Client::new();
    let response = client
        .post(&url)
        .json(&serde_json::json!({
            "file_path": file_path,
            "voxel_size": voxel_size
        }))
        .send()
        .await
        .map_err(|e| e.to_string())?;

    response.json().await.map_err(|e| e.to_string())
}

// Generate TPMS scaffold via Julia API
#[tauri::command]
pub async fn generate_tpms(
    params: TPMSParams,
    state: State<'_, Mutex<AppState>>,
) -> Result<serde_json::Value, String> {
    let url = {
        let state = state.lock().unwrap();
        format!("{}/tpms/generate", state.settings.julia_server_url)
    };

    let client = reqwest::Client::new();
    let response = client
        .post(&url)
        .json(&params)
        .send()
        .await
        .map_err(|e| e.to_string())?;

    response.json().await.map_err(|e| e.to_string())
}

// Get metrics for workspace
#[tauri::command]
pub async fn get_metrics(
    workspace_id: String,
    state: State<'_, Mutex<AppState>>,
) -> Result<ScaffoldMetrics, String> {
    let url = {
        let state = state.lock().unwrap();
        format!("{}/workspace/{}/metrics", state.settings.julia_server_url, workspace_id)
    };

    let client = reqwest::Client::new();
    let response = client
        .get(&url)
        .send()
        .await
        .map_err(|e| e.to_string())?;

    response.json().await.map_err(|e| e.to_string())
}

// Export to STL
#[tauri::command]
pub async fn export_stl(
    workspace_id: String,
    output_path: String,
    quality: String,
    state: State<'_, Mutex<AppState>>,
) -> Result<serde_json::Value, String> {
    let url = {
        let state = state.lock().unwrap();
        format!("{}/export/stl", state.settings.julia_server_url)
    };

    let client = reqwest::Client::new();
    let response = client
        .post(&url)
        .json(&serde_json::json!({
            "workspace_id": workspace_id,
            "output_path": output_path,
            "quality": quality
        }))
        .send()
        .await
        .map_err(|e| e.to_string())?;

    response.json().await.map_err(|e| e.to_string())
}

// Chat with AI agent
#[tauri::command]
pub async fn chat_with_agent(
    message: ChatMessage,
    state: State<'_, Mutex<AppState>>,
) -> Result<serde_json::Value, String> {
    let url = {
        let state = state.lock().unwrap();
        format!("{}/agents/chat", state.settings.julia_server_url)
    };

    let client = reqwest::Client::new();
    let response = client
        .post(&url)
        .json(&message)
        .send()
        .await
        .map_err(|e| e.to_string())?;

    response.json().await.map_err(|e| e.to_string())
}

// Get application settings
#[tauri::command]
pub fn get_app_settings(state: State<'_, Mutex<AppState>>) -> AppSettings {
    let state = state.lock().unwrap();
    state.settings.clone()
}

// Set application settings
#[tauri::command]
pub fn set_app_settings(
    settings: AppSettings,
    state: State<'_, Mutex<AppState>>,
) -> Result<(), String> {
    let mut state = state.lock().unwrap();
    state.settings = settings;
    Ok(())
}
