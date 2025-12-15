<script lang="ts">
  import { chatHistory, isTyping, addMessage, updateLastMessage, suggestionChips } from '$lib/stores/chat';
  import { scaffold } from '$lib/stores/scaffold';
  import { metrics } from '$lib/stores/metrics';
  import { juliaApi } from '$lib/services/julia-api';
  import { wsService } from '$lib/services/websocket';
  import ChatMessage from './ChatMessage.svelte';

  let inputMessage = '';
  let chatContainer: HTMLDivElement;
  let streamingContent = '';

  // Agent types
  type AgentType = 'design' | 'analysis' | 'synthesis';
  let selectedAgent: AgentType = 'design';

  const agentInfo: Record<AgentType, { name: string; description: string }> = {
    design: { name: 'Design Assistant', description: 'Scaffold design and optimization' },
    analysis: { name: 'Analysis Expert', description: 'Metrics and validation' },
    synthesis: { name: 'Synthesis Guide', description: 'Fabrication and materials' },
  };

  // Build context for the agent
  function buildContext() {
    return {
      workspace_id: $scaffold.workspaceId,
      material: $scaffold.material,
      tissue: $scaffold.tissue,
      metrics: $metrics.current,
    };
  }

  async function handleSend() {
    if (!inputMessage.trim()) return;

    const message = inputMessage;
    inputMessage = '';

    // Add user message
    addMessage({ role: 'user', content: message });

    isTyping.set(true);
    streamingContent = '';

    try {
      // Try streaming first via WebSocket
      const useStreaming = false; // Set to true when WebSocket is ready

      if (useStreaming) {
        // Add placeholder message for streaming
        const msgId = addMessage({ role: 'assistant', content: '' });

        await wsService.streamChat(
          selectedAgent,
          message,
          buildContext(),
          // On chunk
          (chunk: string) => {
            streamingContent += chunk;
            updateLastMessage(streamingContent);
            scrollToBottom();
          },
          // On complete
          (response: { suggestions?: string[] }) => {
            updateLastMessage(streamingContent, response.suggestions);
            isTyping.set(false);
            streamingContent = '';
            scrollToBottom();
          },
          // On error
          (error: string) => {
            addMessage({ role: 'error', content: `Error: ${error}` });
            isTyping.set(false);
            streamingContent = '';
          }
        );
      } else {
        // Fallback to regular HTTP API
        const result = await juliaApi.chatWithAgent(
          selectedAgent,
          message,
          buildContext()
        );

        if (result.success && result.data) {
          addMessage({
            role: 'assistant',
            content: result.data.response,
            suggestions: result.data.suggestions,
          });
        } else {
          addMessage({
            role: 'error',
            content: result.error || 'Failed to get response from agent',
          });
        }

        isTyping.set(false);
        scrollToBottom();
      }
    } catch (error) {
      addMessage({
        role: 'error',
        content: `Error: ${error instanceof Error ? error.message : 'Unknown error'}`,
      });
      isTyping.set(false);
    }
  }

  function scrollToBottom() {
    setTimeout(() => {
      chatContainer?.scrollTo({ top: chatContainer.scrollHeight, behavior: 'smooth' });
    }, 100);
  }

  function handleChipClick(chip: string) {
    inputMessage = chip;
    handleSend();
  }

  function handleSuggestionClick(suggestion: string) {
    inputMessage = suggestion;
    handleSend();
  }

  function handleKeydown(e: KeyboardEvent) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  }

  function setAgent(agent: AgentType) {
    selectedAgent = agent;
  }
</script>

<div class="agent-chat">
  <div class="chat-header">
    <div class="agent-avatar" class:design={selectedAgent === 'design'} class:analysis={selectedAgent === 'analysis'} class:synthesis={selectedAgent === 'synthesis'}>
      {#if selectedAgent === 'design'}
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M12 8V4H8"></path>
          <rect x="8" y="8" width="8" height="8" rx="1"></rect>
          <path d="M12 16v4h4"></path>
          <path d="M8 12H4"></path>
          <path d="M20 12h-4"></path>
        </svg>
      {:else if selectedAgent === 'analysis'}
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <line x1="18" y1="20" x2="18" y2="10"></line>
          <line x1="12" y1="20" x2="12" y2="4"></line>
          <line x1="6" y1="20" x2="6" y2="14"></line>
        </svg>
      {:else}
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"></path>
        </svg>
      {/if}
    </div>
    <div class="agent-info">
      <h4>{agentInfo[selectedAgent].name}</h4>
      <span class="status">{$isTyping ? 'Thinking...' : agentInfo[selectedAgent].description}</span>
    </div>
    <div class="agent-selector">
      <button
        class="agent-btn"
        class:active={selectedAgent === 'design'}
        on:click={() => setAgent('design')}
        title="Design Assistant"
      >
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="8" y="8" width="8" height="8" rx="1"/></svg>
      </button>
      <button
        class="agent-btn"
        class:active={selectedAgent === 'analysis'}
        on:click={() => setAgent('analysis')}
        title="Analysis Expert"
      >
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>
      </button>
      <button
        class="agent-btn"
        class:active={selectedAgent === 'synthesis'}
        on:click={() => setAgent('synthesis')}
        title="Synthesis Guide"
      >
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/></svg>
      </button>
    </div>
  </div>

  <div class="chat-messages" bind:this={chatContainer}>
    {#if $chatHistory.length === 0}
      <div class="empty-state">
        <p>Ask me anything about scaffold design!</p>
        <div class="suggestion-chips">
          {#each suggestionChips.slice(0, 4) as chip}
            <button class="chip" on:click={() => handleChipClick(chip)}>
              {chip}
            </button>
          {/each}
        </div>
      </div>
    {:else}
      {#each $chatHistory as message (message.id)}
        <ChatMessage {message} />
      {/each}

      {#if $isTyping}
        <div class="typing-indicator">
          <span></span>
          <span></span>
          <span></span>
        </div>
      {/if}
    {/if}
  </div>

  <div class="chat-input">
    <textarea
      bind:value={inputMessage}
      on:keydown={handleKeydown}
      placeholder="Ask about scaffold design..."
      rows="1"
    ></textarea>
    <button
      class="send-btn"
      on:click={handleSend}
      disabled={!inputMessage.trim() || $isTyping}
    >
      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <line x1="22" y1="2" x2="11" y2="13"></line>
        <polygon points="22 2 15 22 11 13 2 9 22 2"></polygon>
      </svg>
    </button>
  </div>
</div>

<style>
  .agent-chat {
    display: flex;
    flex-direction: column;
    height: 100%;
    background: var(--bg-secondary);
  }

  .chat-header {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 12px 16px;
    border-bottom: 1px solid var(--border-color);
  }

  .agent-avatar {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 40px;
    height: 40px;
    border-radius: 10px;
    background: linear-gradient(135deg, var(--primary), var(--secondary));
    color: white;
    transition: background var(--transition-fast);
  }

  .agent-avatar.design {
    background: linear-gradient(135deg, #4a9eff, #00d4aa);
  }

  .agent-avatar.analysis {
    background: linear-gradient(135deg, #f59e0b, #ef4444);
  }

  .agent-avatar.synthesis {
    background: linear-gradient(135deg, #10b981, #059669);
  }

  .agent-info {
    flex: 1;
  }

  .agent-info h4 {
    font-size: 14px;
    font-weight: 600;
    margin: 0;
  }

  .agent-selector {
    display: flex;
    gap: 4px;
    background: var(--bg-tertiary);
    padding: 4px;
    border-radius: 8px;
  }

  .agent-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 28px;
    height: 28px;
    border: none;
    border-radius: 6px;
    background: transparent;
    color: var(--text-muted);
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .agent-btn:hover {
    background: var(--bg-secondary);
    color: var(--text-primary);
  }

  .agent-btn.active {
    background: var(--primary);
    color: white;
  }

  .status {
    font-size: 11px;
    color: var(--text-muted);
  }

  .chat-messages {
    flex: 1;
    overflow-y: auto;
    padding: 16px;
  }

  .empty-state {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 100%;
    text-align: center;
  }

  .empty-state p {
    color: var(--text-secondary);
    margin-bottom: 16px;
  }

  .suggestion-chips {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    justify-content: center;
  }

  .chip {
    padding: 8px 12px;
    font-size: 12px;
    background: var(--bg-tertiary);
    border: 1px solid var(--border-color);
    border-radius: 16px;
    color: var(--text-secondary);
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .chip:hover {
    background: var(--primary);
    border-color: var(--primary);
    color: white;
  }

  .typing-indicator {
    display: flex;
    gap: 4px;
    padding: 12px;
  }

  .typing-indicator span {
    width: 8px;
    height: 8px;
    background: var(--text-muted);
    border-radius: 50%;
    animation: bounce 1.4s infinite ease-in-out;
  }

  .typing-indicator span:nth-child(2) {
    animation-delay: 0.2s;
  }

  .typing-indicator span:nth-child(3) {
    animation-delay: 0.4s;
  }

  @keyframes bounce {
    0%, 80%, 100% { transform: scale(0.6); opacity: 0.5; }
    40% { transform: scale(1); opacity: 1; }
  }

  .chat-input {
    display: flex;
    gap: 8px;
    padding: 12px 16px;
    border-top: 1px solid var(--border-color);
  }

  .chat-input textarea {
    flex: 1;
    padding: 10px 14px;
    border: 1px solid var(--border-color);
    border-radius: 20px;
    background: var(--bg-primary);
    color: var(--text-primary);
    font-family: inherit;
    font-size: 13px;
    resize: none;
    outline: none;
    transition: border-color var(--transition-fast);
  }

  .chat-input textarea:focus {
    border-color: var(--primary);
  }

  .send-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background: var(--primary);
    border: none;
    color: white;
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .send-btn:hover:not(:disabled) {
    background: var(--primary-hover);
    transform: scale(1.05);
  }

  .send-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
</style>
