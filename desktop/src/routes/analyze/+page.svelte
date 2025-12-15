<script lang="ts">
  import { scaffold } from '$lib/stores/scaffold';
  import ScaffoldViewer3D from '$lib/components/visualization/ScaffoldViewer3D.svelte';
  import MetricsDashboard from '$lib/components/metrics/MetricsDashboard.svelte';
  import ImportWizard from '$lib/components/wizard/ImportWizard.svelte';

  let showImportWizard = false;
  let activeTab: 'metrics' | 'validation' | 'literature' = 'metrics';

  function handleImportComplete(event: CustomEvent<{ volumeId: string }>) {
    scaffold.setWorkspace(event.detail.volumeId);
    showImportWizard = false;
  }
</script>

<div class="analyze-page">
  <div class="main-panel">
    {#if showImportWizard}
      <ImportWizard
        on:complete={handleImportComplete}
        on:cancel={() => (showImportWizard = false)}
      />
    {:else if $scaffold.workspaceId}
      <ScaffoldViewer3D />
    {:else}
      <div class="empty-state">
        <div class="empty-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
            <path d="M14.5 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V7.5L14.5 2z"></path>
            <polyline points="14 2 14 8 20 8"></polyline>
            <line x1="12" y1="18" x2="12" y2="12"></line>
            <line x1="9" y1="15" x2="15" y2="15"></line>
          </svg>
        </div>
        <h2>No Scaffold Loaded</h2>
        <p>Import a MicroCT or SEM image to analyze scaffold structure.</p>
        <button class="import-btn" on:click={() => (showImportWizard = true)}>
          Import Data
        </button>
      </div>
    {/if}
  </div>

  <div class="side-panel">
    <div class="panel-tabs">
      <button
        class="tab"
        class:active={activeTab === 'metrics'}
        on:click={() => (activeTab = 'metrics')}
      >
        Metrics
      </button>
      <button
        class="tab"
        class:active={activeTab === 'validation'}
        on:click={() => (activeTab = 'validation')}
      >
        Validation
      </button>
      <button
        class="tab"
        class:active={activeTab === 'literature'}
        on:click={() => (activeTab = 'literature')}
      >
        Literature
      </button>
    </div>

    <div class="panel-content">
      {#if activeTab === 'metrics'}
        <MetricsDashboard />
      {:else if activeTab === 'validation'}
        <div class="validation-panel">
          <div class="validation-header">
            <h3>Q1 Literature Validation</h3>
            <p>Compare scaffold metrics against published research.</p>
          </div>

          <div class="validation-status">
            <div class="status-item passed">
              <span class="status-icon">&#10003;</span>
              <span class="status-label">Porosity</span>
              <span class="status-value">82.5% (70-95%)</span>
            </div>
            <div class="status-item passed">
              <span class="status-icon">&#10003;</span>
              <span class="status-label">Pore Size</span>
              <span class="status-value">215 um (100-500)</span>
            </div>
            <div class="status-item passed">
              <span class="status-icon">&#10003;</span>
              <span class="status-label">Interconnectivity</span>
              <span class="status-value">91.2% (>90%)</span>
            </div>
            <div class="status-item warning">
              <span class="status-icon">!</span>
              <span class="status-label">Elastic Modulus</span>
              <span class="status-value">45.3 MPa (tissue-specific)</span>
            </div>
          </div>

          <div class="tissue-select">
            <label for="tissue">Target Tissue</label>
            <select id="tissue" bind:value={$scaffold.tissue}>
              <option value="bone">Bone</option>
              <option value="cartilage">Cartilage</option>
              <option value="skin">Skin</option>
              <option value="muscle">Muscle</option>
              <option value="neural">Neural</option>
              <option value="vascular">Vascular</option>
            </select>
          </div>
        </div>
      {:else if activeTab === 'literature'}
        <div class="literature-panel">
          <h3>Reference Database</h3>

          <div class="reference-list">
            <div class="reference-item">
              <span class="ref-citation">Murphy et al. 2010</span>
              <span class="ref-journal">Biomaterials</span>
              <p class="ref-summary">
                Porosity 100-200um optimal for bone regeneration. Higher porosity improves cell infiltration.
              </p>
            </div>

            <div class="reference-item">
              <span class="ref-citation">Karageorgiou & Kaplan 2005</span>
              <span class="ref-journal">Biomaterials</span>
              <p class="ref-summary">
                Porosity 90-95%, interconnectivity >= 90% required for osteogenesis.
              </p>
            </div>

            <div class="reference-item">
              <span class="ref-citation">Gibson & Ashby 1997</span>
              <span class="ref-journal">Cellular Solids</span>
              <p class="ref-summary">
                E_scaffold = (1-porosity)^2 * E_solid. Mechanical property prediction model.
              </p>
            </div>

            <div class="reference-item">
              <span class="ref-citation">Hollister 2005</span>
              <span class="ref-journal">Nature Materials</span>
              <p class="ref-summary">
                Designed scaffolds for bone regeneration. Pore architecture critical for tissue integration.
              </p>
            </div>
          </div>
        </div>
      {/if}
    </div>
  </div>
</div>

<style>
  .analyze-page {
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

  .empty-state {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 16px;
    padding: 32px;
    text-align: center;
  }

  .empty-icon {
    color: var(--text-muted);
    opacity: 0.5;
  }

  .empty-state h2 {
    font-size: 18px;
    font-weight: 600;
    color: var(--text-primary);
    margin: 0;
  }

  .empty-state p {
    font-size: 13px;
    color: var(--text-secondary);
    margin: 0;
    max-width: 300px;
  }

  .import-btn {
    padding: 12px 24px;
    background: var(--primary);
    border: none;
    border-radius: 8px;
    color: white;
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .import-btn:hover {
    background: var(--primary-hover);
  }

  .validation-panel,
  .literature-panel {
    padding: 16px;
  }

  .validation-header {
    margin-bottom: 16px;
  }

  .validation-header h3 {
    font-size: 14px;
    font-weight: 600;
    color: var(--text-primary);
    margin: 0 0 4px 0;
  }

  .validation-header p {
    font-size: 12px;
    color: var(--text-muted);
    margin: 0;
  }

  .validation-status {
    display: flex;
    flex-direction: column;
    gap: 8px;
    margin-bottom: 20px;
  }

  .status-item {
    display: flex;
    align-items: center;
    gap: 10px;
    padding: 10px 12px;
    background: var(--bg-tertiary);
    border-radius: 8px;
    border-left: 3px solid;
  }

  .status-item.passed {
    border-left-color: var(--success);
  }

  .status-item.warning {
    border-left-color: var(--warning);
  }

  .status-item.failed {
    border-left-color: var(--error);
  }

  .status-icon {
    font-size: 12px;
    font-weight: bold;
  }

  .status-item.passed .status-icon {
    color: var(--success);
  }

  .status-item.warning .status-icon {
    color: var(--warning);
  }

  .status-label {
    flex: 1;
    font-size: 12px;
    color: var(--text-primary);
  }

  .status-value {
    font-size: 11px;
    font-family: 'JetBrains Mono', monospace;
    color: var(--text-muted);
  }

  .tissue-select {
    display: flex;
    flex-direction: column;
    gap: 6px;
  }

  .tissue-select label {
    font-size: 11px;
    font-weight: 500;
    text-transform: uppercase;
    color: var(--text-muted);
  }

  .tissue-select select {
    padding: 10px;
    background: var(--bg-tertiary);
    border: 1px solid var(--border-color);
    border-radius: 8px;
    color: var(--text-primary);
    font-size: 13px;
  }

  .literature-panel h3 {
    font-size: 14px;
    font-weight: 600;
    color: var(--text-primary);
    margin: 0 0 16px 0;
  }

  .reference-list {
    display: flex;
    flex-direction: column;
    gap: 12px;
  }

  .reference-item {
    padding: 12px;
    background: var(--bg-tertiary);
    border-radius: 8px;
    border-left: 3px solid var(--info);
  }

  .ref-citation {
    font-size: 12px;
    font-weight: 600;
    color: var(--text-primary);
  }

  .ref-journal {
    font-size: 10px;
    color: var(--text-muted);
    margin-left: 8px;
  }

  .ref-summary {
    font-size: 11px;
    color: var(--text-secondary);
    margin: 8px 0 0 0;
    line-height: 1.5;
  }
</style>
