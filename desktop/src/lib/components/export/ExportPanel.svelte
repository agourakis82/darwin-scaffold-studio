<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { scaffold } from '$lib/stores/scaffold';
  import { juliaApi } from '$lib/services/julia-api';
  import ProgressRing from '../shared/ProgressRing.svelte';

  const dispatch = createEventDispatcher<{
    exported: { format: string; path: string };
  }>();

  // Export format
  type ExportFormat = 'stl' | 'gcode' | 'obj' | 'ply';
  let selectedFormat: ExportFormat = 'stl';

  // STL Options
  let stlQuality: 'low' | 'medium' | 'high' = 'medium';
  let stlSmoothing = true;
  let stlBinary = true;

  function setExportFormat(format: string) {
    selectedFormat = format as ExportFormat;
  }

  function setStlQuality(quality: string) {
    stlQuality = quality as typeof stlQuality;
  }

  // G-code Options
  let printerProfile = 'generic';
  let layerHeight = 0.2;
  let infillPercent = 20;
  let nozzleDiameter = 0.4;
  let printTemp = 200;
  let bedTemp = 60;

  // State
  let isExporting = false;
  let exportProgress = 0;
  let exportResult: { path: string; size: number } | null = null;
  let error: string | null = null;

  // Printer profiles
  const printerProfiles = [
    { id: 'generic', name: 'Generic FDM', nozzle: 0.4, temp: 200, bed: 60 },
    { id: 'regenhu', name: 'RegenHU 3DDiscovery', nozzle: 0.3, temp: 37, bed: 37 },
    { id: 'cellink', name: 'CELLINK BIO X', nozzle: 0.41, temp: 25, bed: 37 },
    { id: 'envisiontec', name: 'EnvisionTEC Bioplotter', nozzle: 0.4, temp: 25, bed: 37 },
    { id: 'custom', name: 'Custom', nozzle: 0.4, temp: 200, bed: 60 },
  ];

  function applyProfile(profileId: string) {
    const profile = printerProfiles.find((p) => p.id === profileId);
    if (profile && profileId !== 'custom') {
      nozzleDiameter = profile.nozzle;
      printTemp = profile.temp;
      bedTemp = profile.bed;
    }
    printerProfile = profileId;
  }

  async function handleExport() {
    if (!$scaffold.workspaceId) {
      error = 'No scaffold loaded';
      return;
    }

    isExporting = true;
    exportProgress = 0;
    error = null;
    exportResult = null;

    try {
      if (selectedFormat === 'stl') {
        // Simulate progress
        const progressInterval = setInterval(() => {
          exportProgress = Math.min(exportProgress + 10, 90);
        }, 200);

        const result = await juliaApi.exportSTL($scaffold.workspaceId, {
          quality: stlQuality,
          smoothing: stlSmoothing,
          binary: stlBinary,
        });

        clearInterval(progressInterval);

        if (result.success && result.data) {
          exportProgress = 100;
          exportResult = {
            path: result.data.file_path,
            size: result.data.size_bytes,
          };
          dispatch('exported', { format: 'stl', path: result.data.file_path });
        } else {
          error = result.error || 'Export failed';
        }
      } else if (selectedFormat === 'gcode') {
        const progressInterval = setInterval(() => {
          exportProgress = Math.min(exportProgress + 5, 90);
        }, 300);

        const result = await juliaApi.generateGCode($scaffold.workspaceId, {
          printer: printerProfile,
          layer_height: layerHeight,
          infill_percent: infillPercent,
          nozzle_diameter: nozzleDiameter,
          temperature: printTemp,
          bed_temperature: bedTemp,
        });

        clearInterval(progressInterval);

        if (result.success && result.data) {
          exportProgress = 100;
          exportResult = {
            path: result.data.file_path,
            size: 0, // G-code result doesn't include size
          };
          dispatch('exported', { format: 'gcode', path: result.data.file_path });
        } else {
          error = result.error || 'G-code generation failed';
        }
      }
    } catch (e) {
      error = `Export error: ${e}`;
    }

    isExporting = false;
  }

  function formatFileSize(bytes: number): string {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  }

  function resetExport() {
    exportResult = null;
    exportProgress = 0;
    error = null;
  }
</script>

<div class="export-panel">
  <h2>Export Scaffold</h2>

  <!-- Format Selection -->
  <div class="section">
    <h3>Format</h3>
    <div class="format-grid">
      {#each [
        { id: 'stl', name: 'STL Mesh', desc: 'For 3D printing', icon: '🔺' },
        { id: 'gcode', name: 'G-Code', desc: 'Direct printing', icon: '📄' },
        { id: 'obj', name: 'OBJ', desc: 'With materials', icon: '🎨' },
        { id: 'ply', name: 'PLY', desc: 'Point cloud', icon: '☁️' },
      ] as format}
        <button
          class="format-btn"
          class:selected={selectedFormat === format.id}
          on:click={() => { setExportFormat(format.id); resetExport(); }}
        >
          <span class="format-icon">{format.icon}</span>
          <span class="format-name">{format.name}</span>
          <span class="format-desc">{format.desc}</span>
        </button>
      {/each}
    </div>
  </div>

  <!-- STL Options -->
  {#if selectedFormat === 'stl'}
    <div class="section">
      <h3>STL Options</h3>

      <div class="option-group">
        <label class="option-label">Quality</label>
        <div class="quality-buttons">
          {#each ['low', 'medium', 'high'] as q}
            <button
              class="quality-btn"
              class:selected={stlQuality === q}
              on:click={() => setStlQuality(q)}
            >
              {q.charAt(0).toUpperCase() + q.slice(1)}
            </button>
          {/each}
        </div>
        <span class="option-hint">
          {stlQuality === 'low' ? 'Fast, larger file' : stlQuality === 'high' ? 'Slow, smaller file' : 'Balanced'}
        </span>
      </div>

      <label class="checkbox-option">
        <input type="checkbox" bind:checked={stlSmoothing} />
        <span>Apply smoothing</span>
      </label>

      <label class="checkbox-option">
        <input type="checkbox" bind:checked={stlBinary} />
        <span>Binary format (smaller file)</span>
      </label>
    </div>
  {/if}

  <!-- G-code Options -->
  {#if selectedFormat === 'gcode'}
    <div class="section">
      <h3>Printer Profile</h3>
      <select bind:value={printerProfile} on:change={() => applyProfile(printerProfile)} class="profile-select">
        {#each printerProfiles as profile}
          <option value={profile.id}>{profile.name}</option>
        {/each}
      </select>
    </div>

    <div class="section">
      <h3>Print Settings</h3>

      <div class="param-grid">
        <div class="param-item">
          <label for="layer-height">Layer Height</label>
          <div class="param-input">
            <input
              type="number"
              id="layer-height"
              min="0.05"
              max="0.5"
              step="0.05"
              bind:value={layerHeight}
            />
            <span class="unit">mm</span>
          </div>
        </div>

        <div class="param-item">
          <label for="infill">Infill</label>
          <div class="param-input">
            <input
              type="number"
              id="infill"
              min="0"
              max="100"
              step="5"
              bind:value={infillPercent}
            />
            <span class="unit">%</span>
          </div>
        </div>

        <div class="param-item">
          <label for="nozzle">Nozzle</label>
          <div class="param-input">
            <input
              type="number"
              id="nozzle"
              min="0.1"
              max="1.0"
              step="0.1"
              bind:value={nozzleDiameter}
            />
            <span class="unit">mm</span>
          </div>
        </div>

        <div class="param-item">
          <label for="temp">Temperature</label>
          <div class="param-input">
            <input
              type="number"
              id="temp"
              min="20"
              max="300"
              step="5"
              bind:value={printTemp}
            />
            <span class="unit">C</span>
          </div>
        </div>

        <div class="param-item">
          <label for="bed-temp">Bed Temp</label>
          <div class="param-input">
            <input
              type="number"
              id="bed-temp"
              min="20"
              max="120"
              step="5"
              bind:value={bedTemp}
            />
            <span class="unit">C</span>
          </div>
        </div>
      </div>
    </div>
  {/if}

  <!-- Export Progress/Result -->
  {#if isExporting}
    <div class="export-progress">
      <ProgressRing value={exportProgress} max={100} size={80} />
      <span class="progress-text">Exporting... {exportProgress}%</span>
    </div>
  {:else if exportResult}
    <div class="export-result">
      <div class="result-icon">
        <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
          <polyline points="22 4 12 14.01 9 11.01"></polyline>
        </svg>
      </div>
      <div class="result-info">
        <span class="result-label">Export Complete</span>
        <span class="result-path">{exportResult.path.split('/').pop()}</span>
        {#if exportResult.size > 0}
          <span class="result-size">{formatFileSize(exportResult.size)}</span>
        {/if}
      </div>
      <button class="btn-secondary" on:click={resetExport}>Export Another</button>
    </div>
  {:else}
    <button
      class="export-btn"
      on:click={handleExport}
      disabled={!$scaffold.workspaceId}
    >
      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
        <polyline points="7 10 12 15 17 10"></polyline>
        <line x1="12" y1="15" x2="12" y2="3"></line>
      </svg>
      Export {selectedFormat.toUpperCase()}
    </button>
  {/if}

  {#if error}
    <div class="error-message">
      {error}
    </div>
  {/if}
</div>

<style>
  .export-panel {
    display: flex;
    flex-direction: column;
    gap: 20px;
    padding: 16px;
    height: 100%;
    overflow-y: auto;
  }

  h2 {
    font-size: 16px;
    font-weight: 600;
    color: var(--text-primary);
    margin: 0;
  }

  .section {
    display: flex;
    flex-direction: column;
    gap: 10px;
  }

  h3 {
    font-size: 11px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: var(--text-muted);
    margin: 0;
  }

  .format-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 8px;
  }

  .format-btn {
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 12px;
    background: var(--bg-tertiary);
    border: 2px solid transparent;
    border-radius: 10px;
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .format-btn:hover {
    border-color: var(--border-color);
  }

  .format-btn.selected {
    border-color: var(--primary);
    background: rgba(74, 158, 255, 0.1);
  }

  .format-icon {
    font-size: 20px;
    margin-bottom: 4px;
  }

  .format-name {
    font-size: 12px;
    font-weight: 600;
    color: var(--text-primary);
  }

  .format-desc {
    font-size: 10px;
    color: var(--text-muted);
  }

  .option-group {
    display: flex;
    flex-direction: column;
    gap: 6px;
  }

  .option-label {
    font-size: 12px;
    color: var(--text-secondary);
  }

  .quality-buttons {
    display: flex;
    gap: 6px;
  }

  .quality-btn {
    flex: 1;
    padding: 8px;
    font-size: 11px;
    background: var(--bg-tertiary);
    border: 1px solid transparent;
    border-radius: 6px;
    color: var(--text-secondary);
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .quality-btn:hover {
    border-color: var(--border-color);
  }

  .quality-btn.selected {
    border-color: var(--primary);
    background: rgba(74, 158, 255, 0.1);
    color: var(--primary);
  }

  .option-hint {
    font-size: 10px;
    color: var(--text-muted);
  }

  .checkbox-option {
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 12px;
    color: var(--text-secondary);
    cursor: pointer;
  }

  .checkbox-option input {
    width: 16px;
    height: 16px;
    accent-color: var(--primary);
  }

  .profile-select {
    padding: 10px;
    background: var(--bg-tertiary);
    border: 1px solid var(--border-color);
    border-radius: 8px;
    color: var(--text-primary);
    font-size: 13px;
  }

  .profile-select:focus {
    outline: none;
    border-color: var(--primary);
  }

  .param-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 12px;
  }

  .param-item {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  .param-item label {
    font-size: 11px;
    color: var(--text-muted);
  }

  .param-input {
    display: flex;
    align-items: center;
    background: var(--bg-tertiary);
    border: 1px solid var(--border-color);
    border-radius: 6px;
    overflow: hidden;
  }

  .param-input input {
    flex: 1;
    padding: 8px 10px;
    background: transparent;
    border: none;
    color: var(--text-primary);
    font-family: 'JetBrains Mono', monospace;
    font-size: 12px;
  }

  .param-input input:focus {
    outline: none;
  }

  .param-input .unit {
    padding: 0 10px;
    font-size: 11px;
    color: var(--text-muted);
    background: var(--bg-secondary);
  }

  .export-progress {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 12px;
    padding: 24px;
    background: var(--bg-tertiary);
    border-radius: 12px;
  }

  .progress-text {
    font-size: 13px;
    color: var(--text-secondary);
  }

  .export-result {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 12px;
    padding: 24px;
    background: var(--bg-tertiary);
    border-radius: 12px;
  }

  .result-icon {
    color: var(--success);
  }

  .result-info {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 4px;
  }

  .result-label {
    font-size: 14px;
    font-weight: 600;
    color: var(--text-primary);
  }

  .result-path {
    font-size: 12px;
    color: var(--text-secondary);
    font-family: 'JetBrains Mono', monospace;
  }

  .result-size {
    font-size: 11px;
    color: var(--text-muted);
  }

  .export-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    padding: 14px;
    background: var(--primary);
    border: none;
    border-radius: 8px;
    color: white;
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    transition: all var(--transition-fast);
    margin-top: auto;
  }

  .export-btn:hover:not(:disabled) {
    background: var(--primary-hover);
  }

  .export-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .btn-secondary {
    padding: 10px 16px;
    background: var(--bg-secondary);
    border: 1px solid var(--border-color);
    border-radius: 6px;
    color: var(--text-secondary);
    font-size: 12px;
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .btn-secondary:hover {
    border-color: var(--primary);
    color: var(--primary);
  }

  .error-message {
    padding: 12px;
    background: rgba(239, 68, 68, 0.1);
    border: 1px solid var(--error);
    border-radius: 8px;
    font-size: 12px;
    color: var(--error);
  }
</style>
