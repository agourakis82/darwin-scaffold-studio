// Julia server bridge - manages Julia process lifecycle

use std::process::{Child, Command, Stdio};
use std::sync::Mutex;
use tauri::{AppHandle, Manager};
use thiserror::Error;

#[derive(Error, Debug)]
pub enum JuliaError {
    #[error("Failed to start Julia server: {0}")]
    StartError(String),
    #[error("Julia server not running")]
    NotRunning,
    #[error("Failed to connect to Julia server: {0}")]
    ConnectionError(String),
}

static JULIA_PROCESS: Mutex<Option<Child>> = Mutex::new(None);

pub async fn start_julia_server(app: &AppHandle) -> Result<(), JuliaError> {
    let mut process_guard = JULIA_PROCESS.lock().unwrap();

    if process_guard.is_some() {
        return Ok(()); // Already running
    }

    // Get the project root (parent of desktop/)
    let project_root = std::env::current_dir()
        .map_err(|e| JuliaError::StartError(e.to_string()))?
        .parent()
        .map(|p| p.to_path_buf())
        .unwrap_or_else(|| std::env::current_dir().unwrap());

    println!("Starting Julia server from: {:?}", project_root);

    // Start Julia server
    let child = Command::new("julia")
        .args([
            "--project=.",
            "-e",
            r#"
            include("src/server.jl")
            println("Julia server started on port 8081")
            # Keep the process alive
            while true
                sleep(1)
            end
            "#,
        ])
        .current_dir(&project_root)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| JuliaError::StartError(e.to_string()))?;

    let pid = child.id();
    *process_guard = Some(child);

    // Update app state
    if let Some(state) = app.try_state::<Mutex<crate::state::AppState>>() {
        let mut state = state.lock().unwrap();
        state.julia_running = true;
        state.julia_pid = Some(pid);
    }

    // Wait for server to be ready
    tokio::time::sleep(tokio::time::Duration::from_secs(5)).await;

    // Check if server is responding
    let client = reqwest::Client::new();
    for _ in 0..30 {
        match client.get("http://localhost:8081/health").send().await {
            Ok(response) if response.status().is_success() => {
                println!("Julia server is ready");
                return Ok(());
            }
            _ => {
                tokio::time::sleep(tokio::time::Duration::from_secs(1)).await;
            }
        }
    }

    Err(JuliaError::ConnectionError("Server did not respond within timeout".to_string()))
}

pub async fn stop_julia_server(app: &AppHandle) -> Result<(), JuliaError> {
    let mut process_guard = JULIA_PROCESS.lock().unwrap();

    if let Some(mut child) = process_guard.take() {
        child.kill().map_err(|e| JuliaError::StartError(e.to_string()))?;
    }

    // Update app state
    if let Some(state) = app.try_state::<Mutex<crate::state::AppState>>() {
        let mut state = state.lock().unwrap();
        state.julia_running = false;
        state.julia_pid = None;
    }

    Ok(())
}

pub fn is_julia_running() -> bool {
    let process_guard = JULIA_PROCESS.lock().unwrap();
    process_guard.is_some()
}
