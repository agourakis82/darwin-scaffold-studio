<script lang="ts">
  import ScaffoldViewer3D from '$lib/components/visualization/ScaffoldViewer3D.svelte';
  import MetricsDashboard from '$lib/components/metrics/MetricsDashboard.svelte';
  import AgentChat from '$lib/components/ai/AgentChat.svelte';
  import { scaffold, workspaceId } from '$lib/stores/scaffold';
  import { metrics } from '$lib/stores/metrics';

  let showChat = false;
  let rightPanelWidth = 320;
</script>

<svelte:head>
  <title>Darwin Scaffold Studio</title>
</svelte:head>

<div class="home-layout">
  <!-- Main 3D Viewer -->
  <div class="viewer-container">
    {#if $workspaceId}
      <ScaffoldViewer3D workspaceId={$workspaceId} />
    {:else}
      <div class="empty-state">
        <div class="empty-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
            <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"></path>
            <polyline points="3.27 6.96 12 12.01 20.73 6.96"></polyline>
            <line x1="12" y1="22.08" x2="12" y2="12"></line>
          </svg>
        </div>
        <h2>Welcome to Darwin Scaffold Studio</h2>
        <p>Start by importing a MicroCT/SEM image or generating a TPMS scaffold</p>
        <div class="quick-actions">
          <a href="/analyze" class="btn btn-primary">
            Import Image
          </a>
          <a href="/design" class="btn btn-secondary">
            Generate TPMS
          </a>
        </div>
      </div>
    {/if}
  </div>

  <!-- Right Panel -->
  <div class="right-panel" style="width: {rightPanelWidth}px">
    <div class="panel-tabs">
      <button
        class="tab"
        class:active={!showChat}
        on:click={() => showChat = false}
      >
        Metrics
      </button>
      <button
        class="tab"
        class:active={showChat}
        on:click={() => showChat = true}
      >
        AI Assistant
      </button>
    </div>

    <div class="panel-content">
      {#if showChat}
        <AgentChat />
      {:else}
        <MetricsDashboard />
      {/if}
    </div>
  </div>
</div>

<style>
  .home-layout {
    display: flex;
    height: 100%;
    gap: 16px;
  }

  .viewer-container {
    flex: 1;
    background: var(--bg-secondary);
    border-radius: 12px;
    overflow: hidden;
    position: relative;
  }

  .empty-state {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    height: 100%;
    text-align: center;
    padding: 40px;
  }

  .empty-icon {
    color: var(--text-muted);
    margin-bottom: 24px;
    opacity: 0.5;
  }

  .empty-state h2 {
    font-size: 24px;
    font-weight: 600;
    margin-bottom: 8px;
    background: linear-gradient(135deg, var(--primary), var(--secondary));
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
  }

  .empty-state p {
    color: var(--text-secondary);
    margin-bottom: 24px;
  }

  .quick-actions {
    display: flex;
    gap: 12px;
  }

  .right-panel {
    display: flex;
    flex-direction: column;
    background: var(--bg-secondary);
    border-radius: 12px;
    overflow: hidden;
    min-width: 280px;
    max-width: 400px;
  }

  .panel-tabs {
    display: flex;
    border-bottom: 1px solid var(--border-color);
  }

  .tab {
    flex: 1;
    padding: 12px 16px;
    font-size: 14px;
    font-weight: 500;
    color: var(--text-secondary);
    background: transparent;
    border: none;
    cursor: pointer;
    transition: all var(--transition-fast);
    position: relative;
  }

  .tab:hover {
    color: var(--text-primary);
    background: var(--bg-tertiary);
  }

  .tab.active {
    color: var(--primary);
  }

  .tab.active::after {
    content: '';
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    height: 2px;
    background: var(--primary);
  }

  .panel-content {
    flex: 1;
    overflow: auto;
  }
</style>
