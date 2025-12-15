<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { scaffold } from '$lib/stores/scaffold';
  import { juliaApi } from '$lib/services/julia-api';
  import type { TPMSType, TPMSParameters } from '$lib/types/scaffold';

  const dispatch = createEventDispatcher<{
    generate: TPMSParameters;
    preview: TPMSParameters;
  }>();

  // TPMS Parameters
  let surfaceType: TPMSType = 'gyroid';
  let porosity = 75;
  let unitCellSize = 2.0;
  let gridResolution = 64;
  let isoValue = 0.0;

  function setSurfaceType(type: string) {
    surfaceType = type as TPMSType;
  }

  // UI State
  let isGenerating = false;
  let isPreviewLoading = false;
  let error: string | null = null;

  // TPMS Surface descriptions
  const surfaceInfo: Record<TPMSType, { name: string; description: string; optimal: string }> = {
    gyroid: {
      name: 'Gyroid',
      description: 'Excellent for bone tissue. Self-supporting, no overhangs.',
      optimal: 'Bone, cartilage',
    },
    diamond: {
      name: 'Diamond',
      description: 'High stiffness, low porosity achievable.',
      optimal: 'Load-bearing applications',
    },
    schwarz_p: {
      name: 'Schwarz P',
      description: 'Simple primitive surface. Good for high porosity.',
      optimal: 'Soft tissue, skin',
    },
    schwarz_d: {
      name: 'Schwarz D',
      description: 'Double diamond variant. Complex internal structure.',
      optimal: 'Neural tissue',
    },
    neovius: {
      name: 'Neovius',
      description: 'High surface area. Complex pore network.',
      optimal: 'Drug delivery, filters',
    },
    lidinoid: {
      name: 'Lidinoid',
      description: 'Asymmetric channels. Directional properties.',
      optimal: 'Vascular scaffolds',
    },
    iwp: {
      name: 'I-WP',
      description: 'Intermediate between Gyroid and Diamond.',
      optimal: 'General purpose',
    },
    frd: {
      name: 'F-RD',
      description: 'Face-centered rhombic dodecahedra.',
      optimal: 'Mechanical strength',
    },
  };

  // Tissue-specific porosity hints
  $: porosityHint = getPorosityHint($scaffold.tissue);

  function getPorosityHint(tissue: string): { min: number; max: number; optimal: number } {
    const hints: Record<string, { min: number; max: number; optimal: number }> = {
      bone: { min: 70, max: 95, optimal: 85 },
      cartilage: { min: 80, max: 95, optimal: 90 },
      skin: { min: 85, max: 98, optimal: 92 },
      muscle: { min: 75, max: 90, optimal: 82 },
      neural: { min: 85, max: 95, optimal: 90 },
      vascular: { min: 80, max: 95, optimal: 88 },
    };
    return hints[tissue] || { min: 70, max: 95, optimal: 80 };
  }

  // Debounced preview
  let previewTimeout: ReturnType<typeof setTimeout>;

  function schedulePreview() {
    clearTimeout(previewTimeout);
    previewTimeout = setTimeout(() => {
      requestPreview();
    }, 500);
  }

  async function requestPreview() {
    if (isPreviewLoading) return;

    isPreviewLoading = true;
    error = null;

    const params: TPMSParameters = {
      surface_type: surfaceType,
      porosity: porosity / 100,
      unit_cell_size: unitCellSize,
      grid_resolution: Math.floor(gridResolution / 4), // Lower res for preview
      iso_value: isoValue,
    };

    dispatch('preview', params);

    const result = await juliaApi.previewTPMS(params);

    if (!result.success) {
      error = result.error || 'Preview failed';
    }

    isPreviewLoading = false;
  }

  async function handleGenerate() {
    if (isGenerating) return;

    isGenerating = true;
    error = null;

    const params: TPMSParameters = {
      surface_type: surfaceType,
      porosity: porosity / 100,
      unit_cell_size: unitCellSize,
      grid_resolution: gridResolution,
      iso_value: isoValue,
    };

    dispatch('generate', params);

    const result = await juliaApi.generateTPMS(params);

    if (!result.success) {
      error = result.error || 'Generation failed';
    }

    isGenerating = false;
  }

  // Watch for parameter changes
  $: surfaceType, porosity, unitCellSize, schedulePreview();
</script>

<div class="tpms-generator">
  <div class="section">
    <h3>Surface Type</h3>
    <div class="surface-grid">
      {#each Object.entries(surfaceInfo) as [type, info]}
        <button
          class="surface-card"
          class:selected={surfaceType === type}
          on:click={() => setSurfaceType(type)}
        >
          <span class="surface-name">{info.name}</span>
          <span class="surface-optimal">{info.optimal}</span>
        </button>
      {/each}
    </div>

    {#if surfaceInfo[surfaceType]}
      <p class="surface-description">
        {surfaceInfo[surfaceType].description}
      </p>
    {/if}
  </div>

  <div class="section">
    <h3>Porosity</h3>
    <div class="slider-container">
      <input
        type="range"
        min="20"
        max="98"
        bind:value={porosity}
        class="slider"
      />
      <div class="slider-value">{porosity}%</div>
    </div>

    <div class="porosity-hints">
      <div class="hint-bar">
        <div
          class="optimal-zone"
          style="left: {porosityHint.min - 20}%; width: {porosityHint.max - porosityHint.min}%"
        ></div>
        <div
          class="optimal-marker"
          style="left: {porosityHint.optimal - 20}%"
        ></div>
      </div>
      <span class="hint-label">
        Optimal for {$scaffold.tissue || 'bone'}: {porosityHint.optimal}%
      </span>
    </div>
  </div>

  <div class="section">
    <h3>Unit Cell Size</h3>
    <div class="slider-container">
      <input
        type="range"
        min="0.5"
        max="5.0"
        step="0.1"
        bind:value={unitCellSize}
        class="slider"
      />
      <div class="slider-value">{unitCellSize.toFixed(1)} mm</div>
    </div>
    <p class="param-hint">
      Controls pore size. Smaller values = smaller pores.
    </p>
  </div>

  <div class="section">
    <h3>Resolution</h3>
    <div class="resolution-buttons">
      {#each [32, 64, 128, 256] as res}
        <button
          class="res-btn"
          class:selected={gridResolution === res}
          on:click={() => (gridResolution = res)}
        >
          {res}
        </button>
      {/each}
    </div>
    <p class="param-hint">
      Higher resolution = more detail, longer generation time.
    </p>
  </div>

  <div class="section">
    <h3>Advanced</h3>
    <div class="advanced-param">
      <label for="iso-value">Iso-value</label>
      <input
        type="number"
        id="iso-value"
        min="-1"
        max="1"
        step="0.1"
        bind:value={isoValue}
      />
    </div>
    <p class="param-hint">
      Shifts the surface. 0 = standard, positive = thicker walls.
    </p>
  </div>

  {#if error}
    <div class="error-message">
      {error}
    </div>
  {/if}

  <div class="actions">
    <button
      class="btn-secondary"
      on:click={requestPreview}
      disabled={isPreviewLoading}
    >
      {#if isPreviewLoading}
        <span class="spinner"></span>
        Previewing...
      {:else}
        Preview
      {/if}
    </button>

    <button
      class="btn-primary"
      on:click={handleGenerate}
      disabled={isGenerating}
    >
      {#if isGenerating}
        <span class="spinner"></span>
        Generating...
      {:else}
        Generate Scaffold
      {/if}
    </button>
  </div>
</div>

<style>
  .tpms-generator {
    display: flex;
    flex-direction: column;
    gap: 20px;
    padding: 16px;
    height: 100%;
    overflow-y: auto;
  }

  .section {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  h3 {
    font-size: 11px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: var(--text-muted);
    margin: 0;
  }

  .surface-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 6px;
  }

  .surface-card {
    display: flex;
    flex-direction: column;
    padding: 10px;
    background: var(--bg-tertiary);
    border: 1px solid transparent;
    border-radius: 8px;
    cursor: pointer;
    transition: all var(--transition-fast);
    text-align: left;
  }

  .surface-card:hover {
    border-color: var(--border-color);
  }

  .surface-card.selected {
    border-color: var(--primary);
    background: rgba(74, 158, 255, 0.1);
  }

  .surface-name {
    font-size: 12px;
    font-weight: 600;
    color: var(--text-primary);
  }

  .surface-optimal {
    font-size: 10px;
    color: var(--text-muted);
  }

  .surface-description {
    font-size: 11px;
    color: var(--text-secondary);
    background: var(--bg-tertiary);
    padding: 8px;
    border-radius: 6px;
    margin: 0;
  }

  .slider-container {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .slider {
    flex: 1;
    height: 6px;
    background: var(--bg-tertiary);
    border-radius: 3px;
    -webkit-appearance: none;
    appearance: none;
  }

  .slider::-webkit-slider-thumb {
    -webkit-appearance: none;
    width: 16px;
    height: 16px;
    background: var(--primary);
    border-radius: 50%;
    cursor: pointer;
    transition: transform var(--transition-fast);
  }

  .slider::-webkit-slider-thumb:hover {
    transform: scale(1.2);
  }

  .slider-value {
    min-width: 60px;
    font-size: 13px;
    font-weight: 600;
    font-family: 'JetBrains Mono', monospace;
    color: var(--text-primary);
    text-align: right;
  }

  .porosity-hints {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  .hint-bar {
    position: relative;
    height: 4px;
    background: var(--bg-tertiary);
    border-radius: 2px;
  }

  .optimal-zone {
    position: absolute;
    height: 100%;
    background: rgba(16, 185, 129, 0.3);
    border-radius: 2px;
  }

  .optimal-marker {
    position: absolute;
    top: -2px;
    width: 8px;
    height: 8px;
    background: var(--success);
    border-radius: 50%;
    transform: translateX(-50%);
  }

  .hint-label {
    font-size: 10px;
    color: var(--text-muted);
  }

  .param-hint {
    font-size: 10px;
    color: var(--text-muted);
    margin: 0;
  }

  .resolution-buttons {
    display: flex;
    gap: 6px;
  }

  .res-btn {
    flex: 1;
    padding: 8px;
    font-size: 12px;
    font-family: 'JetBrains Mono', monospace;
    background: var(--bg-tertiary);
    border: 1px solid transparent;
    border-radius: 6px;
    color: var(--text-secondary);
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .res-btn:hover {
    border-color: var(--border-color);
  }

  .res-btn.selected {
    border-color: var(--primary);
    background: rgba(74, 158, 255, 0.1);
    color: var(--primary);
  }

  .advanced-param {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .advanced-param label {
    font-size: 12px;
    color: var(--text-secondary);
  }

  .advanced-param input {
    width: 80px;
    padding: 6px 10px;
    font-size: 12px;
    font-family: 'JetBrains Mono', monospace;
    background: var(--bg-tertiary);
    border: 1px solid var(--border-color);
    border-radius: 6px;
    color: var(--text-primary);
  }

  .advanced-param input:focus {
    outline: none;
    border-color: var(--primary);
  }

  .error-message {
    padding: 10px;
    background: rgba(239, 68, 68, 0.1);
    border: 1px solid var(--error);
    border-radius: 6px;
    font-size: 12px;
    color: var(--error);
  }

  .actions {
    display: flex;
    gap: 8px;
    margin-top: auto;
    padding-top: 16px;
    border-top: 1px solid var(--border-color);
  }

  .btn-primary,
  .btn-secondary {
    flex: 1;
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    padding: 12px;
    font-size: 13px;
    font-weight: 500;
    border-radius: 8px;
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .btn-primary {
    background: var(--primary);
    border: none;
    color: white;
  }

  .btn-primary:hover:not(:disabled) {
    background: var(--primary-hover);
  }

  .btn-secondary {
    background: var(--bg-tertiary);
    border: 1px solid var(--border-color);
    color: var(--text-secondary);
  }

  .btn-secondary:hover:not(:disabled) {
    border-color: var(--primary);
    color: var(--primary);
  }

  .btn-primary:disabled,
  .btn-secondary:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .spinner {
    width: 14px;
    height: 14px;
    border: 2px solid transparent;
    border-top-color: currentColor;
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
  }

  @keyframes spin {
    to {
      transform: rotate(360deg);
    }
  }
</style>
