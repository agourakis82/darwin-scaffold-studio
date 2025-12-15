<script lang="ts">
  import { scaffold } from '$lib/stores/scaffold';
  import ScaffoldViewer3D from '$lib/components/visualization/ScaffoldViewer3D.svelte';
  import ExportPanel from '$lib/components/export/ExportPanel.svelte';

  let activeTab: 'export' | 'gcode-preview' | 'print-queue' = 'export';
  let gcodeLayer = 1;
  let totalLayers = 100;

  function handleExported(event: CustomEvent<{ format: string; path: string }>) {
    console.log('Exported:', event.detail);
  }
</script>

<div class="fabricate-page">
  <div class="main-panel">
    {#if activeTab === 'gcode-preview'}
      <div class="gcode-viewer">
        <div class="gcode-canvas">
          <canvas id="gcode-canvas"></canvas>
        </div>
        <div class="layer-controls">
          <button
            class="layer-btn"
            disabled={gcodeLayer <= 1}
            on:click={() => (gcodeLayer = Math.max(1, gcodeLayer - 1))}
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polyline points="15 18 9 12 15 6"></polyline>
            </svg>
          </button>
          <div class="layer-slider">
            <input
              type="range"
              min="1"
              max={totalLayers}
              bind:value={gcodeLayer}
            />
            <span class="layer-label">Layer {gcodeLayer} / {totalLayers}</span>
          </div>
          <button
            class="layer-btn"
            disabled={gcodeLayer >= totalLayers}
            on:click={() => (gcodeLayer = Math.min(totalLayers, gcodeLayer + 1))}
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polyline points="9 18 15 12 9 6"></polyline>
            </svg>
          </button>
        </div>
      </div>
    {:else}
      <ScaffoldViewer3D />
    {/if}
  </div>

  <div class="side-panel">
    <div class="panel-tabs">
      <button
        class="tab"
        class:active={activeTab === 'export'}
        on:click={() => (activeTab = 'export')}
      >
        Export
      </button>
      <button
        class="tab"
        class:active={activeTab === 'gcode-preview'}
        on:click={() => (activeTab = 'gcode-preview')}
      >
        G-Code
      </button>
      <button
        class="tab"
        class:active={activeTab === 'print-queue'}
        on:click={() => (activeTab = 'print-queue')}
      >
        Print Queue
      </button>
    </div>

    <div class="panel-content">
      {#if activeTab === 'export'}
        <ExportPanel on:exported={handleExported} />
      {:else if activeTab === 'gcode-preview'}
        <div class="gcode-info">
          <h3>G-Code Analysis</h3>

          <div class="info-grid">
            <div class="info-card">
              <span class="info-label">Total Layers</span>
              <span class="info-value">{totalLayers}</span>
            </div>
            <div class="info-card">
              <span class="info-label">Est. Time</span>
              <span class="info-value">2h 15m</span>
            </div>
            <div class="info-card">
              <span class="info-label">Material</span>
              <span class="info-value">12.4 g</span>
            </div>
            <div class="info-card">
              <span class="info-label">Travel</span>
              <span class="info-value">4.2 m</span>
            </div>
          </div>

          <div class="legend">
            <h4>Path Types</h4>
            <div class="legend-items">
              <div class="legend-item">
                <span class="legend-color" style="background: #4a9eff;"></span>
                <span>Perimeter</span>
              </div>
              <div class="legend-item">
                <span class="legend-color" style="background: #00d4aa;"></span>
                <span>Infill</span>
              </div>
              <div class="legend-item">
                <span class="legend-color" style="background: #f59e0b;"></span>
                <span>Support</span>
              </div>
              <div class="legend-item">
                <span class="legend-color" style="background: rgba(255,255,255,0.2);"></span>
                <span>Travel</span>
              </div>
            </div>
          </div>

          <div class="layer-details">
            <h4>Layer {gcodeLayer} Details</h4>
            <div class="detail-row">
              <span>Height</span>
              <span>{(gcodeLayer * 0.2).toFixed(2)} mm</span>
            </div>
            <div class="detail-row">
              <span>Extrusion</span>
              <span>0.124 g</span>
            </div>
            <div class="detail-row">
              <span>Time</span>
              <span>48 sec</span>
            </div>
          </div>
        </div>
      {:else if activeTab === 'print-queue'}
        <div class="print-queue">
          <h3>Print Queue</h3>

          <div class="queue-empty">
            <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
              <path d="M6 9V2h12v7"></path>
              <path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"></path>
              <path d="M6 14h12v8H6z"></path>
            </svg>
            <p>No prints queued</p>
            <span class="hint">Export G-code to add to print queue</span>
          </div>

          <div class="printer-status">
            <h4>Printer Status</h4>
            <div class="status-indicator disconnected">
              <span class="status-dot"></span>
              <span>No printer connected</span>
            </div>
            <button class="connect-btn">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71"></path>
                <path d="M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71"></path>
              </svg>
              Connect Printer
            </button>
          </div>
        </div>
      {/if}
    </div>
  </div>
</div>

<style>
  .fabricate-page {
    display: flex;
    height: 100%;
    gap: 1px;
    background: var(--border-color);
  }

  .main-panel {
    flex: 1;
    background: var(--bg-primary);
    display: flex;
    flex-direction: column;
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

  .gcode-viewer {
    flex: 1;
    display: flex;
    flex-direction: column;
  }

  .gcode-canvas {
    flex: 1;
    background: var(--bg-secondary);
  }

  .gcode-canvas canvas {
    width: 100%;
    height: 100%;
  }

  .layer-controls {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 12px 16px;
    background: var(--bg-tertiary);
    border-top: 1px solid var(--border-color);
  }

  .layer-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 32px;
    height: 32px;
    background: var(--bg-secondary);
    border: 1px solid var(--border-color);
    border-radius: 6px;
    color: var(--text-secondary);
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .layer-btn:hover:not(:disabled) {
    border-color: var(--primary);
    color: var(--primary);
  }

  .layer-btn:disabled {
    opacity: 0.3;
    cursor: not-allowed;
  }

  .layer-slider {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  .layer-slider input {
    width: 100%;
  }

  .layer-label {
    font-size: 11px;
    color: var(--text-muted);
    text-align: center;
  }

  .gcode-info,
  .print-queue {
    padding: 16px;
  }

  .gcode-info h3,
  .print-queue h3 {
    font-size: 14px;
    font-weight: 600;
    color: var(--text-primary);
    margin: 0 0 16px 0;
  }

  .info-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 8px;
    margin-bottom: 20px;
  }

  .info-card {
    display: flex;
    flex-direction: column;
    padding: 12px;
    background: var(--bg-tertiary);
    border-radius: 8px;
  }

  .info-label {
    font-size: 10px;
    color: var(--text-muted);
    text-transform: uppercase;
  }

  .info-value {
    font-size: 16px;
    font-weight: 600;
    font-family: 'JetBrains Mono', monospace;
    color: var(--text-primary);
  }

  .legend {
    margin-bottom: 20px;
  }

  .legend h4,
  .layer-details h4,
  .printer-status h4 {
    font-size: 11px;
    font-weight: 600;
    text-transform: uppercase;
    color: var(--text-muted);
    margin: 0 0 10px 0;
  }

  .legend-items {
    display: flex;
    flex-wrap: wrap;
    gap: 12px;
  }

  .legend-item {
    display: flex;
    align-items: center;
    gap: 6px;
    font-size: 11px;
    color: var(--text-secondary);
  }

  .legend-color {
    width: 12px;
    height: 12px;
    border-radius: 2px;
  }

  .layer-details {
    padding: 12px;
    background: var(--bg-tertiary);
    border-radius: 8px;
  }

  .detail-row {
    display: flex;
    justify-content: space-between;
    padding: 6px 0;
    font-size: 12px;
    border-bottom: 1px solid var(--border-color);
  }

  .detail-row:last-child {
    border-bottom: none;
  }

  .detail-row span:first-child {
    color: var(--text-secondary);
  }

  .detail-row span:last-child {
    font-family: 'JetBrains Mono', monospace;
    color: var(--text-primary);
  }

  .queue-empty {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    padding: 40px 20px;
    text-align: center;
    color: var(--text-muted);
  }

  .queue-empty svg {
    margin-bottom: 16px;
    opacity: 0.5;
  }

  .queue-empty p {
    font-size: 14px;
    color: var(--text-secondary);
    margin: 0 0 4px 0;
  }

  .queue-empty .hint {
    font-size: 12px;
  }

  .printer-status {
    margin-top: 24px;
    padding-top: 20px;
    border-top: 1px solid var(--border-color);
  }

  .status-indicator {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 12px;
    background: var(--bg-tertiary);
    border-radius: 8px;
    font-size: 12px;
    color: var(--text-secondary);
    margin-bottom: 12px;
  }

  .status-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
  }

  .status-indicator.disconnected .status-dot {
    background: var(--text-muted);
  }

  .status-indicator.connected .status-dot {
    background: var(--success);
  }

  .connect-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    width: 100%;
    padding: 10px;
    background: var(--bg-tertiary);
    border: 1px solid var(--border-color);
    border-radius: 8px;
    color: var(--text-secondary);
    font-size: 13px;
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .connect-btn:hover {
    border-color: var(--primary);
    color: var(--primary);
  }
</style>
