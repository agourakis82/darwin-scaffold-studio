<script lang="ts">
  import type { ChatMessage } from '$lib/stores/chat';

  export let message: ChatMessage;

  function formatTime(date: Date): string {
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  }
</script>

<div class="message" class:user={message.role === 'user'} class:error={message.role === 'error'}>
  {#if message.role === 'assistant'}
    <div class="avatar assistant">
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M12 8V4H8"></path>
        <rect x="8" y="8" width="8" height="8" rx="1"></rect>
        <path d="M12 16v4h4"></path>
      </svg>
    </div>
  {/if}

  <div class="message-content">
    <div class="bubble">
      {message.content}
    </div>

    {#if message.suggestions && message.suggestions.length > 0}
      <div class="suggestions">
        {#each message.suggestions as suggestion}
          <button class="suggestion-btn">{suggestion}</button>
        {/each}
      </div>
    {/if}

    <span class="timestamp">{formatTime(message.timestamp)}</span>
  </div>

  {#if message.role === 'user'}
    <div class="avatar user">
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2"></path>
        <circle cx="12" cy="7" r="4"></circle>
      </svg>
    </div>
  {/if}
</div>

<style>
  .message {
    display: flex;
    gap: 10px;
    margin-bottom: 16px;
    animation: slideUp 0.3s ease;
  }

  @keyframes slideUp {
    from {
      opacity: 0;
      transform: translateY(10px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }

  .message.user {
    flex-direction: row-reverse;
  }

  .avatar {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 32px;
    height: 32px;
    border-radius: 8px;
    flex-shrink: 0;
  }

  .avatar.assistant {
    background: linear-gradient(135deg, var(--primary), var(--secondary));
    color: white;
  }

  .avatar.user {
    background: var(--bg-tertiary);
    color: var(--text-secondary);
  }

  .message-content {
    max-width: 80%;
  }

  .bubble {
    padding: 10px 14px;
    border-radius: 16px;
    font-size: 13px;
    line-height: 1.5;
  }

  .message:not(.user) .bubble {
    background: var(--bg-tertiary);
    color: var(--text-primary);
    border-bottom-left-radius: 4px;
  }

  .message.user .bubble {
    background: var(--primary);
    color: white;
    border-bottom-right-radius: 4px;
  }

  .message.error .bubble {
    background: rgba(239, 68, 68, 0.1);
    color: var(--error);
    border: 1px solid var(--error);
  }

  .suggestions {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    margin-top: 8px;
  }

  .suggestion-btn {
    padding: 6px 10px;
    font-size: 11px;
    background: var(--bg-secondary);
    border: 1px solid var(--border-color);
    border-radius: 12px;
    color: var(--text-secondary);
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .suggestion-btn:hover {
    border-color: var(--primary);
    color: var(--primary);
  }

  .timestamp {
    display: block;
    font-size: 10px;
    color: var(--text-muted);
    margin-top: 4px;
  }

  .message.user .timestamp {
    text-align: right;
  }
</style>
