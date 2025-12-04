use axum::{
    extract::{
        ws::{Message, WebSocket, WebSocketUpgrade},
        State,
    },
    response::IntoResponse,
    routing::get,
};
use futures::{sink::SinkExt, stream::StreamExt};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tokio::sync::Mutex;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentMessage {
    pub agent_type: String,  // "design", "analysis", "synthesis"
    pub content: String,
    pub timestamp: u64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentResponse {
    pub agent_name: String,
    pub response: String,
    pub tool_calls: Vec<ToolCall>,
    pub status: String,  // "thinking", "using_tool", "complete"
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolCall {
    pub tool_name: String,
    pub args: serde_json::Value,
    pub result: Option<serde_json::Value>,
}

pub struct AgentWorkspaceState {
    pub scaffolds: Vec<String>,  // Paths to scaffold files
    pub metrics: serde_json::Value,
    pub chat_history: Vec<(String, String)>,  // (role, content)
}

impl AgentWorkspaceState {
    pub fn new() -> Self {
        Self {
            scaffolds: Vec::new(),
            metrics: serde_json::json!({}),
            chat_history: Vec::new(),
        }
    }
}

/// WebSocket handler for agent chat
pub async fn agent_chat_handler(
    ws: WebSocketUpgrade,
    State(workspace): State<Arc<Mutex<AgentWorkspaceState>>>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_agent_socket(socket, workspace))
}

async fn handle_agent_socket(
    socket: WebSocket,
    workspace: Arc<Mutex<AgentWorkspaceState>>,
) {
    let (mut sender, mut receiver) = socket.split();

    // Send welcome message
    let welcome = serde_json::json!({
        "type": "system",
        "content": "Darwin Research Hub initialized. Agents ready.",
    });
    
    if sender.send(Message::Text(welcome.to_string())).await.is_err() {
        return;
    }

    while let Some(Ok(msg)) = receiver.next().await {
        if let Message::Text(text) = msg {
            // Parse user message
            let user_msg: Result<AgentMessage, _> = serde_json::from_str(&text);
            
            match user_msg {
                Ok(agent_msg) => {
                    // Add to chat history
                    {
                        let mut ws = workspace.lock().await;
                        ws.chat_history.push(("user".to_string(), agent_msg.content.clone()));
                    }
                    
                    // Route to appropriate agent (Julia backend)
                    let response = route_to_agent(agent_msg, &workspace).await;
                    
                    // Send response back
                    if let Ok(resp_json) = serde_json::to_string(&response) {
                        if sender.send(Message::Text(resp_json)).await.is_err() {
                            break;
                        }
                    }
                }
                Err(e) => {
                    eprintln!("Failed to parse agent message: {}", e);
                }
            }
        }
    }
}

async fn route_to_agent(
    msg: AgentMessage,
    workspace: &Arc<Mutex<AgentWorkspaceState>>,
) -> AgentResponse {
    // In real implementation, this would call the Julia backend
    // For now, return a mock response
    
    let agent_name = match msg.agent_type.as_str() {
        "design" => "Design Agent",
        "analysis" => "Analysis Agent",
        "synthesis" => "Synthesis Agent",
        _ => "Unknown Agent",
    };
    
    // Simulate processing
    tokio::time::sleep(tokio::time::Duration::from_millis(500)).await;
    
    AgentResponse {
        agent_name: agent_name.to_string(),
        response: format!("Processing your request: {}", msg.content),
        tool_calls: vec![],
        status: "complete".to_string(),
    }
}

async fn agent_chat_handler_wrapper<S>(
    ws: WebSocketUpgrade,
    State(states): State<(Arc<S>, Arc<Mutex<AgentWorkspaceState>>)>,
) -> impl IntoResponse 
where
    S: Clone + Send + Sync + 'static,
{
    let workspace = states.1.clone();
    ws.on_upgrade(move |socket| handle_agent_socket(socket, workspace))
}

pub fn agent_routes<S>() -> axum::Router<(Arc<S>, Arc<Mutex<AgentWorkspaceState>>)> 
where
    S: Clone + Send + Sync + 'static,
{
    axum::Router::new()
        .route("/ws/agent-chat", get(agent_chat_handler_wrapper::<S>))
}
