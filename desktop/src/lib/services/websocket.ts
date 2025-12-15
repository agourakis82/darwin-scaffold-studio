/**
 * WebSocket Service for Real-time Communication
 * Handles streaming AI responses and live metrics updates
 */

import { writable, type Writable } from 'svelte/store';
import { juliaStatus } from '$lib/stores/julia';

const WS_BASE = 'ws://localhost:8080';

type MessageHandler = (data: unknown) => void;

interface StreamingMessage {
  type: 'chunk' | 'complete' | 'error';
  content?: string;
  data?: unknown;
  error?: string;
}

interface MetricsUpdate {
  workspace_id: string;
  metrics: Record<string, number>;
  timestamp: number;
}

class WebSocketService {
  private ws: WebSocket | null = null;
  private reconnectAttempts = 0;
  private maxReconnectAttempts = 5;
  private reconnectDelay = 1000;
  private messageHandlers: Map<string, Set<MessageHandler>> = new Map();
  private pendingMessages: string[] = [];

  public connectionState: Writable<'connecting' | 'connected' | 'disconnected' | 'error'> =
    writable('disconnected');

  connect(): void {
    if (this.ws?.readyState === WebSocket.OPEN) {
      return;
    }

    this.connectionState.set('connecting');

    try {
      this.ws = new WebSocket(`${WS_BASE}/ws`);

      this.ws.onopen = () => {
        console.log('WebSocket connected');
        this.connectionState.set('connected');
        this.reconnectAttempts = 0;

        // Send any pending messages
        while (this.pendingMessages.length > 0) {
          const msg = this.pendingMessages.shift();
          if (msg) this.ws?.send(msg);
        }
      };

      this.ws.onclose = () => {
        console.log('WebSocket disconnected');
        this.connectionState.set('disconnected');
        this.scheduleReconnect();
      };

      this.ws.onerror = (error) => {
        console.error('WebSocket error:', error);
        this.connectionState.set('error');
      };

      this.ws.onmessage = (event) => {
        try {
          const message = JSON.parse(event.data);
          this.handleMessage(message);
        } catch (e) {
          console.error('Failed to parse WebSocket message:', e);
        }
      };
    } catch (error) {
      console.error('Failed to create WebSocket:', error);
      this.connectionState.set('error');
      this.scheduleReconnect();
    }
  }

  private scheduleReconnect(): void {
    if (this.reconnectAttempts >= this.maxReconnectAttempts) {
      console.log('Max reconnect attempts reached');
      juliaStatus.set('disconnected');
      return;
    }

    this.reconnectAttempts++;
    const delay = this.reconnectDelay * Math.pow(2, this.reconnectAttempts - 1);

    console.log(`Reconnecting in ${delay}ms (attempt ${this.reconnectAttempts})`);

    setTimeout(() => {
      this.connect();
    }, delay);
  }

  private handleMessage(message: { type: string; channel?: string; data?: unknown }): void {
    const channel = message.channel || message.type;
    const handlers = this.messageHandlers.get(channel);

    if (handlers) {
      handlers.forEach((handler) => handler(message.data ?? message));
    }

    // Handle global message types
    if (message.type === 'ping') {
      this.send({ type: 'pong' });
    }
  }

  subscribe(channel: string, handler: MessageHandler): () => void {
    if (!this.messageHandlers.has(channel)) {
      this.messageHandlers.set(channel, new Set());
    }

    this.messageHandlers.get(channel)!.add(handler);

    // Return unsubscribe function
    return () => {
      this.messageHandlers.get(channel)?.delete(handler);
    };
  }

  send(data: unknown): void {
    const message = JSON.stringify(data);

    if (this.ws?.readyState === WebSocket.OPEN) {
      this.ws.send(message);
    } else {
      // Queue message for when connection is restored
      this.pendingMessages.push(message);
      this.connect();
    }
  }

  disconnect(): void {
    this.reconnectAttempts = this.maxReconnectAttempts; // Prevent reconnect
    this.ws?.close();
    this.ws = null;
    this.connectionState.set('disconnected');
  }

  // Streaming AI Chat
  async streamChat(
    agentType: 'design' | 'analysis' | 'synthesis',
    message: string,
    context: Record<string, unknown>,
    onChunk: (chunk: string) => void,
    onComplete: (response: { suggestions?: string[] }) => void,
    onError: (error: string) => void
  ): Promise<void> {
    const requestId = crypto.randomUUID();

    const unsubscribe = this.subscribe(`chat:${requestId}`, (data) => {
      const msg = data as StreamingMessage;

      switch (msg.type) {
        case 'chunk':
          if (msg.content) onChunk(msg.content);
          break;
        case 'complete':
          onComplete(msg.data as { suggestions?: string[] });
          unsubscribe();
          break;
        case 'error':
          onError(msg.error || 'Unknown error');
          unsubscribe();
          break;
      }
    });

    this.send({
      type: 'chat_stream',
      request_id: requestId,
      agent: agentType,
      message,
      context,
    });
  }

  // Subscribe to real-time metrics updates
  subscribeToMetrics(
    workspaceId: string,
    handler: (metrics: Record<string, number>) => void
  ): () => void {
    // Request metrics subscription
    this.send({
      type: 'subscribe_metrics',
      workspace_id: workspaceId,
    });

    const unsubscribe = this.subscribe(`metrics:${workspaceId}`, (data) => {
      const update = data as MetricsUpdate;
      handler(update.metrics);
    });

    // Return cleanup function that also unsubscribes from server
    return () => {
      unsubscribe();
      this.send({
        type: 'unsubscribe_metrics',
        workspace_id: workspaceId,
      });
    };
  }

  // Subscribe to progress updates (for long-running operations)
  subscribeToProgress(
    operationId: string,
    onProgress: (progress: number, message: string) => void,
    onComplete: () => void
  ): () => void {
    return this.subscribe(`progress:${operationId}`, (data) => {
      const update = data as { progress: number; message: string; complete?: boolean };

      if (update.complete) {
        onComplete();
      } else {
        onProgress(update.progress, update.message);
      }
    });
  }
}

// Singleton instance
export const wsService = new WebSocketService();

// Auto-connect when in browser
if (typeof window !== 'undefined') {
  wsService.connect();
}
