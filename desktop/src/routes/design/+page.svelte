<script lang="ts">
  import { scaffold } from '$lib/stores/scaffold';
  import ScaffoldViewer3D from '$lib/components/visualization/ScaffoldViewer3D.svelte';
  import TPMSGenerator from '$lib/components/editor/TPMSGenerator.svelte';
  import AgentChat from '$lib/components/ai/AgentChat.svelte';
  import type { TPMSParameters } from '$lib/types/scaffold';

  let activeTab: 'tpms' | 'editor' | 'ai' = 'tpms';

  function handleGenerate(event: CustomEvent<TPMSParameters>) {
    console.log('Generating scaffold with params:', event.detail);
  }

  function handlePreview(event: CustomEvent<TPMSParameters>) {
    console.log('Preview with params:', event.detail);
  }
</script>

<div class="design-page">
  <div class="main-panel">
    <ScaffoldViewer3D />
  </div>

  <div class="side-panel">
    <div class="panel-tabs">
      <button
        class="tab"
        class:active={activeTab === 'tpms'}
        on:click={() => (activeTab = 'tpms')}
      >
        TPMS
      </button>
      <button
        class="tab"
        class:active={activeTab === 'editor'}
        on:click={() => (activeTab = 'editor')}
      >
        Editor
      </button>
      <button
        class="tab"
        class:active={activeTab === 'ai'}
        on:click={() => (activeTab = 'ai')}
      >
        AI Assistant
      </button>
    </div>

    <div class="panel-content">
      {#if activeTab === 'tpms'}
        <TPMSGenerator on:generate={handleGenerate} on:preview={handlePreview} />
      {:else if activeTab === 'editor'}
        <div class="editor-panel">
          <div class="editor-section">
            <h3>Edit Tools</h3>
            <div class="tool-grid">
              <button class="tool-btn">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <circle cx="12" cy="12" r="10"></circle>
                  <line x1="12" y1="8" x2="12" y2="16"></line>
                  <line x1="8" y1="12" x2="16" y2="12"></line>
                </svg>
                <span>Add Material</span>
              </button>
              <button class="tool-btn">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <circle cx="12" cy="12" r="10"></circle>
                  <line x1="8" y1="12" x2="16" y2="12"></line>
                </svg>
                <span>Remove</span>
              </button>
              <button class="tool-btn">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z"></path>
                </svg>
                <span>Smooth</span>
              </button>
              <button class="tool-btn">
                <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
                  <line x1="9" y1="3" x2="9" y2="21"></line>
                  <line x1="15" y1="3" x2="15" y2="21"></line>
                  <line x1="3" y1="9" x2="21" y2="9"></line>
                  <line x1="3" y1="15" x2="21" y2="15"></line>
                </svg>
                <span>Grid Snap</span>
              </button>
            </div>
          </div>

          <div class="editor-section">
            <h3>Brush Settings</h3>
            <div class="brush-settings">
              <div class="setting-item">
                <label>Size</label>
                <input type="range" min="1" max="20" value="5" />
                <span class="setting-value">5</span>
              </div>
              <div class="setting-item">
                <label>Strength</label>
                <input type="range" min="0" max="100" value="100" />
                <span class="setting-value">100%</span>
              </div>
              <div class="setting-item">
                <label>Falloff</label>
                <select>
                  <option>Sharp</option>
                  <option selected>Linear</option>
                  <option>Smooth</option>
                </select>
              </div>
            </div>
          </div>

          <div class="editor-section">
            <h3>History</h3>
            <div class="history-controls">
              <button class="history-btn" disabled={!$scaffold.canUndo} on:click={() => scaffold.undo()}>
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M3 7v6h6"></path>
                  <path d="M21 17a9 9 0 0 0-9-9 9 9 0 0 0-6 2.3L3 13"></path>
                </svg>
                Undo
              </button>
              <button class="history-btn" disabled={!$scaffold.canRedo} on:click={() => scaffold.redo()}>
                <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                  <path d="M21 7v6h-6"></path>
                  <path d="M3 17a9 9 0 0 1 9-9 9 9 0 0 1 6 2.3l3 2.7"></path>
                </svg>
                Redo
              </button>
            </div>
          </div>
        </div>
      {:else if activeTab === 'ai'}
        <AgentChat />
      {/if}
    </div>
  </div>
</div>

<style>
  .design-page {
    display: flex;
    height: 100%;
    gap: 1px;
    background: var(--border-color);
  }

  .main-panel {
    flex: 1;
    background: var(--bg-primary);
  }

  .side-panel {
    width: 340px;
    background: var(--bg-secondary);
    display: flex;
    flex-direction: column;
  }

  .panel-tabs {
    display: flex;
    border-bottom: 1px solid var(--border-color);
  }

  .tab {
    flex: 1;
    padding: 12px;
    background: none;
    border: none;
    border-bottom: 2px solid transparent;
    color: var(--text-muted);
    font-size: 12px;
    font-weight: 500;
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .tab:hover {
    color: var(--text-secondary);
  }

  .tab.active {
    color: var(--primary);
    border-bottom-color: var(--primary);
  }

  .panel-content {
    flex: 1;
    overflow-y: auto;
  }

  .editor-panel {
    display: flex;
    flex-direction: column;
    gap: 20px;
    padding: 16px;
  }

  .editor-section {
    display: flex;
    flex-direction: column;
    gap: 10px;
  }

  .editor-section h3 {
    font-size: 11px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: var(--text-muted);
    margin: 0;
  }

  .tool-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 8px;
  }

  .tool-btn {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 6px;
    padding: 12px;
    background: var(--bg-tertiary);
    border: 1px solid transparent;
    border-radius: 8px;
    color: var(--text-secondary);
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .tool-btn:hover {
    border-color: var(--border-color);
    color: var(--text-primary);
  }

  .tool-btn span {
    font-size: 11px;
  }

  .brush-settings {
    display: flex;
    flex-direction: column;
    gap: 12px;
  }

  .setting-item {
    display: flex;
    align-items: center;
    gap: 10px;
  }

  .setting-item label {
    min-width: 60px;
    font-size: 12px;
    color: var(--text-secondary);
  }

  .setting-item input[type="range"] {
    flex: 1;
    height: 4px;
  }

  .setting-item select {
    flex: 1;
    padding: 6px 10px;
    background: var(--bg-tertiary);
    border: 1px solid var(--border-color);
    border-radius: 6px;
    color: var(--text-primary);
    font-size: 12px;
  }

  .setting-value {
    min-width: 40px;
    font-size: 11px;
    font-family: 'JetBrains Mono', monospace;
    color: var(--text-muted);
    text-align: right;
  }

  .history-controls {
    display: flex;
    gap: 8px;
  }

  .history-btn {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 6px;
    padding: 10px;
    background: var(--bg-tertiary);
    border: 1px solid var(--border-color);
    border-radius: 6px;
    color: var(--text-secondary);
    font-size: 12px;
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .history-btn:hover:not(:disabled) {
    border-color: var(--primary);
    color: var(--primary);
  }

  .history-btn:disabled {
    opacity: 0.4;
    cursor: not-allowed;
  }
</style>
