// Darwin Research Hub - Agent WebSocket Client

class DarwinAgentClient {
    constructor() {
        this.ws = null;
        this.reconnectAttempts = 0;
        this.maxReconnectAttempts = 5;
        this.chatMessages = document.getElementById('chat-messages');
        this.chatInput = document.getElementById('chat-input');
        this.sendBtn = document.getElementById('send-btn');
        this.agentSelect = document.getElementById('agent-select');
        this.statusIndicator = document.getElementById('ws-status');
        this.statusText = document.getElementById('status-text');

        this.connect();
        this.setupEventListeners();
    }

    connect() {
        const wsUrl = `ws://${window.location.host}/ws/agent-chat`;
        console.log('Connecting to:', wsUrl);

        try {
            this.ws = new WebSocket(wsUrl);

            this.ws.onopen = () => {
                console.log('WebSocket connected');
                this.updateStatus(true);
                this.reconnectAttempts = 0;
                this.addSystemMessage('Connected to Darwin agents ✓');
            };

            this.ws.onmessage = (event) => {
                const message = JSON.parse(event.data);
                this.handleMessage(message);
            };

            this.ws.onerror = (error) => {
                console.error('WebSocket error:', error);
                this.addSystemMessage('Connection error. Retrying...');
            };

            this.ws.onclose = () => {
                console.log('WebSocket closed');
                this.updateStatus(false);
                this.attemptReconnect();
            };

        } catch (error) {
            console.error('Failed to create WebSocket:', error);
            this.updateStatus(false);
        }
    }

    attemptReconnect() {
        if (this.reconnectAttempts < this.maxReconnectAttempts) {
            this.reconnectAttempts++;
            this.addSystemMessage(`Reconnecting... (${this.reconnectAttempts}/${this.maxReconnectAttempts})`);
            setTimeout(() => this.connect(), 2000 * this.reconnectAttempts);
        } else {
            this.addSystemMessage('Failed to connect. Please refresh the page.');
        }
    }

    updateStatus(connected) {
        if (connected) {
            this.statusIndicator.className = 'status-indicator connected';
            this.statusText.textContent = 'Connected';
        } else {
            this.statusIndicator.className = 'status-indicator disconnected';
            this.statusText.textContent = 'Disconnected';
        }
    }

    setupEventListeners() {
        this.sendBtn.addEventListener('click', () => this.sendMessage());
        this.chatInput.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') this.sendMessage();
        });
    }

    sendMessage() {
        const text = this.chatInput.value.trim();
        if (!text || !this.ws || this.ws.readyState !== WebSocket.OPEN) {
            return;
        }

        const agentType = this.agentSelect.value;
        const message = {
            agent_type: agentType,
            content: text,
            timestamp: Date.now()
        };

        // Display user message
        this.addUserMessage(text);

        // Send to server
        this.ws.send(JSON.stringify(message));

        // Clear input
        this.chatInput.value = '';
    }

    handleMessage(message) {
        console.log('Received:', message);

        if (message.type === 'system') {
            this.addSystemMessage(message.content);
        } else if (message.agent_name) {
            // Agent response
            this.addAgentMessage(message.agent_name, message.response);

            // Handle tool calls if any
            if (message.tool_calls && message.tool_calls.length > 0) {
                message.tool_calls.forEach(tool => {
                    this.addSystemMessage(`🔧 Used tool: ${tool.tool_name}`);
                });
            }

            // Update metrics if available
            if (message.metrics) {
                this.updateMetrics(message.metrics);
            }
        }
    }

    addUserMessage(text) {
        const msgDiv = document.createElement('div');
        msgDiv.className = 'message user';
        msgDiv.innerHTML = `
            <div class="message-header">You</div>
            <p>${this.escapeHtml(text)}</p>
        `;
        this.chatMessages.appendChild(msgDiv);
        this.scrollToBottom();
    }

    addAgentMessage(agentName, text) {
        const msgDiv = document.createElement('div');
        msgDiv.className = 'message agent';
        msgDiv.innerHTML = `
            <div class="message-header">${agentName}</div>
            <p>${this.escapeHtml(text)}</p>
        `;
        this.chatMessages.appendChild(msgDiv);
        this.scrollToBottom();
    }

    addSystemMessage(text) {
        const msgDiv = document.createElement('div');
        msgDiv.className = 'message system';
        msgDiv.innerHTML = `<p>${this.escapeHtml(text)}</p>`;
        this.chatMessages.appendChild(msgDiv);
        this.scrollToBottom();
    }

    updateMetrics(metrics) {
        const metricsDisplay = document.getElementById('metrics-display');
        metricsDisplay.innerHTML = '<h3>Latest Analysis</h3>';

        for (const [key, value] of Object.entries(metrics)) {
            const metricDiv = document.createElement('div');
            metricDiv.style.marginBottom = '0.5rem';
            metricDiv.innerHTML = `
                <strong>${key.replace(/_/g, ' ').toUpperCase()}:</strong>
                <span style="color: #10b981;">${typeof value === 'number' ? value.toFixed(3) : value}</span>
            `;
            metricsDisplay.appendChild(metricDiv);
        }
    }

    scrollToBottom() {
        this.chatMessages.scrollTop = this.chatMessages.scrollHeight;
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }
}

// Initialize when page loads
document.addEventListener('DOMContentLoaded', () => {
    window.darwinClient = new DarwinAgentClient();
    console.log('Darwin Agent Client initialized');
});
