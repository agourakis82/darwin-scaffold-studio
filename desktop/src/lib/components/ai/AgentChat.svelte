<script lang="ts">
  import { chatHistory, isTyping, addMessage, suggestionChips } from '$lib/stores/chat';
  import { scaffold } from '$lib/stores/scaffold';
  import ChatMessage from './ChatMessage.svelte';

  let inputMessage = '';
  let chatContainer: HTMLDivElement;

  async function handleSend() {
    if (!inputMessage.trim()) return;

    const message = inputMessage;
    inputMessage = '';

    // Add user message
    addMessage({ role: 'user', content: message });

    // Simulate AI response (in production, this would call Julia backend)
    isTyping.set(true);

    setTimeout(() => {
      // Demo response
      const responses = [
        "Based on your current scaffold design, I recommend increasing the porosity to 85% for optimal bone regeneration. The Murphy et al. 2010 study showed that porosity in the 85-95% range provides the best cell infiltration.",
        "I've analyzed your scaffold. The current pore size of 215 um is well within the optimal range for osteoblast attachment. Consider the gyroid TPMS structure for improved mechanical properties.",
        "Your interconnectivity of 91.2% exceeds the minimum threshold of 90% recommended by Karageorgiou & Kaplan (2005). This should support good nutrient transport.",
      ];

      addMessage({
        role: 'assistant',
        content: responses[Math.floor(Math.random() * responses.length)],
        suggestions: ['Optimize scaffold', 'Export STL', 'Run validation'],
      });

      isTyping.set(false);

      // Scroll to bottom
      setTimeout(() => {
        chatContainer?.scrollTo({ top: chatContainer.scrollHeight, behavior: 'smooth' });
      }, 100);
    }, 1500);
  }

  function handleChipClick(chip: string) {
    inputMessage = chip;
    handleSend();
  }

  function handleKeydown(e: KeyboardEvent) {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  }
</script>

<div class="agent-chat">
  <div class="chat-header">
    <div class="agent-avatar">
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M12 8V4H8"></path>
        <rect x="8" y="8" width="8" height="8" rx="1"></rect>
        <path d="M12 16v4h4"></path>
        <path d="M8 12H4"></path>
        <path d="M20 12h-4"></path>
      </svg>
    </div>
    <div class="agent-info">
      <h4>Design Assistant</h4>
      <span class="status">{$isTyping ? 'Thinking...' : 'Online'}</span>
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
  }

  .agent-info h4 {
    font-size: 14px;
    font-weight: 600;
    margin: 0;
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
