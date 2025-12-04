use axum::{
    extract::{Multipart, State},
    http::StatusCode,
    response::{Html, IntoResponse, Json},
    routing::{get, post},
    Router,
};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::{net::SocketAddr, path::PathBuf, sync::Arc};
use tower_http::{cors::CorsLayer, services::ServeDir};
use uuid::Uuid;
use tokio::sync::Mutex;

mod agents;
use agents::{AgentWorkspaceState, agent_routes};

#[derive(Deserialize, Serialize, Debug)]
struct OptimizationRequest {
    porosity: f64,
    pore_size: f64,
    method: String,
    resolution: f64,
    material: Option<String>,
    use_case: Option<String>,
}

#[derive(Clone)]
struct AppState {
    julia_url: String,
    upload_dir: PathBuf,
}

#[tokio::main]
async fn main() {
    // Initialize tracing
    tracing_subscriber::fmt::init();

    let upload_dir = PathBuf::from("/tmp/darwin_uploads");
    tokio::fs::create_dir_all(&upload_dir).await.unwrap();

    let state = Arc::new(AppState {
        julia_url: "http://127.0.0.1:8081".to_string(),
        upload_dir,
    });

    // Agent workspace (shared across WebSocket connections)
    let agent_workspace = Arc::new(Mutex::new(AgentWorkspaceState::new()));

    // Create combined state
    let combined_state = (state.clone(), agent_workspace);

    let app = Router::new()
        .route("/api/upload", post(upload_handler))
        .route("/api/analyze", post(analyze_handler))
        .route("/api/optimize", post(optimize_handler))
        .route("/api/mesh", post(mesh_handler))
        .with_state(state)
        .merge(agent_routes().with_state(combined_state))  // Agent routes with combined state
        .nest_service("/", ServeDir::new("public"))
        .layer(CorsLayer::permissive());

    let addr = SocketAddr::from(([0, 0, 0, 0], 3000));
    println!("🚀 Darwin Server listening on {}", addr);
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

async fn upload_handler(
    State(state): State<Arc<AppState>>,
    mut multipart: Multipart,
) -> Result<Json<Value>, (StatusCode, String)> {
    while let Some(field) = multipart.next_field().await.map_err(|e| (StatusCode::BAD_REQUEST, e.to_string()))? {
        let name = field.name().unwrap().to_string();
        
        if name == "file" {
            let file_name = field.file_name().unwrap_or("upload.dat").to_string();
            let data = field.bytes().await.map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
            
            let file_id = Uuid::new_v4();
            let file_path = state.upload_dir.join(format!("{}_{}", file_id, file_name));
            
            tokio::fs::write(&file_path, data).await.map_err(|e| (StatusCode::INTERNAL_SERVER_ERROR, e.to_string()))?;
            
            return Ok(Json(serde_json::json!({
                "file_path": file_path.to_string_lossy(),
                "file_id": file_id.to_string(),
                "original_name": file_name
            })));
        }
    }
    
    Err((StatusCode::BAD_REQUEST, "No file found".to_string()))
}

async fn analyze_handler(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<Value>,
) -> impl IntoResponse {
    proxy_to_julia(&state.julia_url, "analyze", payload).await
}

async fn optimize_handler(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<Value>,
) -> impl IntoResponse {
    proxy_to_julia(&state.julia_url, "optimize", payload).await
}

async fn mesh_handler(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<Value>,
) -> impl IntoResponse {
    proxy_to_julia(&state.julia_url, "mesh", payload).await
}

async fn proxy_to_julia(base_url: &str, endpoint: &str, payload: Value) -> impl IntoResponse {
    let client = reqwest::Client::new();
    let url = format!("{}/{}", base_url, endpoint);
    
    match client.post(&url).json(&payload).send().await {
        Ok(res) => {
            let status = res.status();
            match res.json::<Value>().await {
                Ok(body) => (StatusCode::from_u16(status.as_u16()).unwrap(), Json(body)).into_response(),
                Err(e) => (StatusCode::INTERNAL_SERVER_ERROR, Json(serde_json::json!({"error": e.to_string()}))).into_response(),
            }
        },
        Err(e) => (StatusCode::BAD_GATEWAY, Json(serde_json::json!({"error": e.to_string()}))).into_response(),
    }
}
