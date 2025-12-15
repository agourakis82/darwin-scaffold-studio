// Application state management

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppSettings {
    pub theme: String,
    pub julia_server_url: String,
    pub auto_start_julia: bool,
    pub default_material: String,
    pub default_tissue: String,
    pub default_voxel_size: f64,
}

impl Default for AppSettings {
    fn default() -> Self {
        Self {
            theme: "dark".to_string(),
            julia_server_url: "http://localhost:8081".to_string(),
            auto_start_julia: true,
            default_material: "PCL".to_string(),
            default_tissue: "bone".to_string(),
            default_voxel_size: 10.0,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkspaceState {
    pub id: String,
    pub name: String,
    pub file_path: Option<String>,
    pub modified: bool,
}

#[derive(Debug, Default)]
pub struct AppState {
    pub julia_running: bool,
    pub julia_pid: Option<u32>,
    pub settings: AppSettings,
    pub workspaces: HashMap<String, WorkspaceState>,
    pub current_workspace: Option<String>,
}
