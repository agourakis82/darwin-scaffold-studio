// Darwin Scaffold Studio - Tauri Desktop Application
// Premium GUI for tissue engineering scaffold analysis

#![cfg_attr(
    all(not(debug_assertions), target_os = "windows"),
    windows_subsystem = "windows"
)]

mod commands;
mod julia_bridge;
mod state;

use state::AppState;
use std::sync::Mutex;
use tauri::Manager;

fn main() {
    tauri::Builder::default()
        .manage(Mutex::new(AppState::default()))
        .setup(|app| {
            let window = app.get_window("main").unwrap();

            // Set window title with version
            window.set_title("Darwin Scaffold Studio v1.0.0").unwrap();

            // Start Julia server in background
            let app_handle = app.handle();
            tauri::async_runtime::spawn(async move {
                if let Err(e) = julia_bridge::start_julia_server(&app_handle).await {
                    eprintln!("Failed to start Julia server: {}", e);
                }
            });

            Ok(())
        })
        .invoke_handler(tauri::generate_handler![
            commands::get_julia_status,
            commands::start_julia_server,
            commands::stop_julia_server,
            commands::open_file_dialog,
            commands::save_file_dialog,
            commands::analyze_scaffold,
            commands::generate_tpms,
            commands::get_metrics,
            commands::export_stl,
            commands::chat_with_agent,
            commands::get_app_settings,
            commands::set_app_settings,
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
