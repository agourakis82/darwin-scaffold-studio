<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { invoke } from '@tauri-apps/api/tauri';
  import { juliaApi } from '$lib/services/julia-api';
  import ProgressRing from '../shared/ProgressRing.svelte';

  const dispatch = createEventDispatcher<{
    complete: { volumeId: string };
    cancel: void;
  }>();

  // Wizard state
  type Step = 'select' | 'preview' | 'preprocess' | 'segment' | 'confirm';
  let currentStep: Step = 'select';

  // File state
  let selectedFile: string | null = null;
  let fileType: 'microct' | 'sem' | 'dicom' | 'tiff' = 'microct';

  function setFileType(type: string) {
    fileType = type as typeof fileType;
  }

  // Preview state
  let previewUrl: string | null = null;
  let dimensions: [number, number, number] = [0, 0, 0];
  let voxelSize = 0;
  let isLoading = false;

  // Preprocessing options
  let denoise = true;
  let normalize = true;
  let cropEnabled = false;
  let cropBox: [number, number, number, number, number, number] = [0, 0, 0, 0, 0, 0];

  // Segmentation
  let threshold = 128;
  let segmentMethod: 'otsu' | 'adaptive' | 'manual' = 'otsu';

  function setSegmentMethod(method: string) {
    segmentMethod = method as typeof segmentMethod;
  }
  let segmentPreviewUrl: string | null = null;

  // Result
  let volumeId: string | null = null;
  let resultMetrics: Record<string, number> | null = null;

  // Error handling
  let error: string | null = null;

  async function selectFile() {
    try {
      const selected = await invoke<string | null>('select_file', {
        filters: [
          { name: 'MicroCT/SEM', extensions: ['nii', 'nii.gz', 'dcm', 'tif', 'tiff', 'png'] },
          { name: 'All Files', extensions: ['*'] },
        ],
      });

      if (selected) {
        selectedFile = selected;
        await loadPreview();
      }
    } catch (e) {
      error = `Failed to select file: ${e}`;
    }
  }

  async function loadPreview() {
    if (!selectedFile) return;

    isLoading = true;
    error = null;

    const result = await juliaApi.importImage(selectedFile);

    if (result.success && result.data) {
      previewUrl = result.data.preview_url;
      dimensions = result.data.dimensions;
      voxelSize = result.data.voxel_size;
      currentStep = 'preview';
    } else {
      error = result.error || 'Failed to load preview';
    }

    isLoading = false;
  }

  async function applyPreprocessing() {
    if (!selectedFile) return;

    isLoading = true;
    error = null;

    const result = await juliaApi.preprocessImage(selectedFile, {
      denoise,
      normalize,
      crop: cropEnabled ? cropBox : undefined,
    });

    if (result.success && result.data) {
      previewUrl = result.data.preview_url;
      currentStep = 'segment';
    } else {
      error = result.error || 'Preprocessing failed';
    }

    isLoading = false;
  }

  async function applySegmentation() {
    if (!selectedFile) return;

    isLoading = true;
    error = null;

    const result = await juliaApi.segmentImage(selectedFile, threshold, segmentMethod);

    if (result.success && result.data) {
      volumeId = result.data.volume_id;
      resultMetrics = result.data.metrics as unknown as Record<string, number>;
      currentStep = 'confirm';
    } else {
      error = result.error || 'Segmentation failed';
    }

    isLoading = false;
  }

  function handleComplete() {
    if (volumeId) {
      dispatch('complete', { volumeId });
    }
  }

  function handleCancel() {
    dispatch('cancel');
  }

  function goBack() {
    const steps: Step[] = ['select', 'preview', 'preprocess', 'segment', 'confirm'];
    const currentIndex = steps.indexOf(currentStep);
    if (currentIndex > 0) {
      currentStep = steps[currentIndex - 1];
    }
  }
</script>

<div class="import-wizard">
  <!-- Progress indicator -->
  <div class="progress-steps">
    {#each ['Select', 'Preview', 'Process', 'Segment', 'Confirm'] as step, i}
      {@const stepId = ['select', 'preview', 'preprocess', 'segment', 'confirm'][i]}
      <div
        class="step"
        class:active={currentStep === stepId}
        class:completed={['select', 'preview', 'preprocess', 'segment', 'confirm'].indexOf(currentStep) > i}
      >
        <div class="step-number">{i + 1}</div>
        <span class="step-label">{step}</span>
      </div>
      {#if i < 4}
        <div class="step-connector"></div>
      {/if}
    {/each}
  </div>

  <div class="wizard-content">
    <!-- Step 1: File Selection -->
    {#if currentStep === 'select'}
      <div class="step-content">
        <h2>Import MicroCT/SEM Data</h2>
        <p class="step-description">
          Select a MicroCT, SEM, or medical imaging file to analyze.
        </p>

        <div class="file-types">
          {#each [
            { id: 'microct', label: 'MicroCT', icon: '🔬', desc: 'NIfTI, TIFF stacks' },
            { id: 'sem', label: 'SEM', icon: '🔍', desc: 'PNG, TIFF images' },
            { id: 'dicom', label: 'DICOM', icon: '🏥', desc: 'Medical imaging' },
          ] as type}
            <button
              class="file-type-btn"
              class:selected={fileType === type.id}
              on:click={() => setFileType(type.id)}
            >
              <span class="type-icon">{type.icon}</span>
              <span class="type-label">{type.label}</span>
              <span class="type-desc">{type.desc}</span>
            </button>
          {/each}
        </div>

        <button class="select-file-btn" on:click={selectFile}>
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
            <polyline points="17 8 12 3 7 8"></polyline>
            <line x1="12" y1="3" x2="12" y2="15"></line>
          </svg>
          Select File
        </button>

        {#if selectedFile}
          <div class="selected-file">
            <span class="file-icon">📄</span>
            <span class="file-name">{selectedFile.split('/').pop()}</span>
          </div>
        {/if}
      </div>
    {/if}

    <!-- Step 2: Preview -->
    {#if currentStep === 'preview'}
      <div class="step-content">
        <h2>Data Preview</h2>

        <div class="preview-container">
          {#if previewUrl}
            <img src={previewUrl} alt="Preview" class="preview-image" />
          {:else}
            <div class="preview-placeholder">Loading preview...</div>
          {/if}
        </div>

        <div class="data-info">
          <div class="info-item">
            <span class="info-label">Dimensions</span>
            <span class="info-value">{dimensions[0]} x {dimensions[1]} x {dimensions[2]}</span>
          </div>
          <div class="info-item">
            <span class="info-label">Voxel Size</span>
            <span class="info-value">{voxelSize.toFixed(3)} mm</span>
          </div>
          <div class="info-item">
            <span class="info-label">Volume</span>
            <span class="info-value">
              {((dimensions[0] * dimensions[1] * dimensions[2] * voxelSize ** 3) / 1000).toFixed(2)} cm3
            </span>
          </div>
        </div>

        <div class="step-actions">
          <button class="btn-secondary" on:click={goBack}>Back</button>
          <button class="btn-primary" on:click={() => (currentStep = 'preprocess')}>
            Continue to Preprocessing
          </button>
        </div>
      </div>
    {/if}

    <!-- Step 3: Preprocessing -->
    {#if currentStep === 'preprocess'}
      <div class="step-content">
        <h2>Preprocessing</h2>
        <p class="step-description">Apply filters to improve segmentation quality.</p>

        <div class="options-grid">
          <label class="option-item">
            <input type="checkbox" bind:checked={denoise} />
            <div class="option-content">
              <span class="option-label">Denoise</span>
              <span class="option-desc">Remove noise with median filter</span>
            </div>
          </label>

          <label class="option-item">
            <input type="checkbox" bind:checked={normalize} />
            <div class="option-content">
              <span class="option-label">Normalize</span>
              <span class="option-desc">Adjust contrast and brightness</span>
            </div>
          </label>

          <label class="option-item">
            <input type="checkbox" bind:checked={cropEnabled} />
            <div class="option-content">
              <span class="option-label">Crop Region</span>
              <span class="option-desc">Select region of interest</span>
            </div>
          </label>
        </div>

        <div class="step-actions">
          <button class="btn-secondary" on:click={goBack}>Back</button>
          <button class="btn-primary" on:click={applyPreprocessing} disabled={isLoading}>
            {isLoading ? 'Processing...' : 'Apply & Continue'}
          </button>
        </div>
      </div>
    {/if}

    <!-- Step 4: Segmentation -->
    {#if currentStep === 'segment'}
      <div class="step-content">
        <h2>Segmentation</h2>
        <p class="step-description">Separate scaffold material from background.</p>

        <div class="segment-methods">
          {#each [
            { id: 'otsu', label: 'Otsu (Auto)', desc: 'Automatic threshold detection' },
            { id: 'adaptive', label: 'Adaptive', desc: 'Local threshold adaptation' },
            { id: 'manual', label: 'Manual', desc: 'Set threshold manually' },
          ] as method}
            <button
              class="method-btn"
              class:selected={segmentMethod === method.id}
              on:click={() => setSegmentMethod(method.id)}
            >
              <span class="method-label">{method.label}</span>
              <span class="method-desc">{method.desc}</span>
            </button>
          {/each}
        </div>

        {#if segmentMethod === 'manual'}
          <div class="threshold-control">
            <label for="threshold">Threshold</label>
            <input
              type="range"
              id="threshold"
              min="0"
              max="255"
              bind:value={threshold}
            />
            <span class="threshold-value">{threshold}</span>
          </div>
        {/if}

        <div class="step-actions">
          <button class="btn-secondary" on:click={goBack}>Back</button>
          <button class="btn-primary" on:click={applySegmentation} disabled={isLoading}>
            {isLoading ? 'Segmenting...' : 'Segment & Analyze'}
          </button>
        </div>
      </div>
    {/if}

    <!-- Step 5: Confirmation -->
    {#if currentStep === 'confirm'}
      <div class="step-content">
        <h2>Import Complete</h2>

        <div class="success-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
            <polyline points="22 4 12 14.01 9 11.01"></polyline>
          </svg>
        </div>

        {#if resultMetrics}
          <div class="result-metrics">
            <h3>Initial Metrics</h3>
            <div class="metrics-grid">
              {#each Object.entries(resultMetrics) as [key, value]}
                <div class="metric-item">
                  <span class="metric-label">{key.replace(/_/g, ' ')}</span>
                  <span class="metric-value">{typeof value === 'number' ? value.toFixed(2) : value}</span>
                </div>
              {/each}
            </div>
          </div>
        {/if}

        <div class="step-actions">
          <button class="btn-secondary" on:click={handleCancel}>Import Another</button>
          <button class="btn-primary" on:click={handleComplete}>
            Open in Editor
          </button>
        </div>
      </div>
    {/if}

    {#if error}
      <div class="error-message">
        {error}
      </div>
    {/if}

    {#if isLoading}
      <div class="loading-overlay">
        <ProgressRing value={50} max={100} size={60} />
        <span>Processing...</span>
      </div>
    {/if}
  </div>
</div>

<style>
  .import-wizard {
    display: flex;
    flex-direction: column;
    height: 100%;
    background: var(--bg-secondary);
  }

  .progress-steps {
    display: flex;
    align-items: center;
    justify-content: center;
    padding: 20px;
    border-bottom: 1px solid var(--border-color);
  }

  .step {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 4px;
  }

  .step-number {
    width: 28px;
    height: 28px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
    background: var(--bg-tertiary);
    color: var(--text-muted);
    font-size: 12px;
    font-weight: 600;
    transition: all var(--transition-fast);
  }

  .step.active .step-number {
    background: var(--primary);
    color: white;
  }

  .step.completed .step-number {
    background: var(--success);
    color: white;
  }

  .step-label {
    font-size: 10px;
    color: var(--text-muted);
  }

  .step.active .step-label {
    color: var(--primary);
  }

  .step-connector {
    width: 40px;
    height: 2px;
    background: var(--bg-tertiary);
    margin: 0 8px;
  }

  .wizard-content {
    flex: 1;
    padding: 24px;
    overflow-y: auto;
    position: relative;
  }

  .step-content {
    max-width: 500px;
    margin: 0 auto;
  }

  h2 {
    font-size: 20px;
    font-weight: 600;
    margin: 0 0 8px 0;
    color: var(--text-primary);
  }

  .step-description {
    color: var(--text-secondary);
    font-size: 13px;
    margin-bottom: 24px;
  }

  .file-types {
    display: flex;
    gap: 12px;
    margin-bottom: 24px;
  }

  .file-type-btn {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 16px;
    background: var(--bg-tertiary);
    border: 2px solid transparent;
    border-radius: 12px;
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .file-type-btn:hover {
    border-color: var(--border-color);
  }

  .file-type-btn.selected {
    border-color: var(--primary);
    background: rgba(74, 158, 255, 0.1);
  }

  .type-icon {
    font-size: 24px;
    margin-bottom: 8px;
  }

  .type-label {
    font-size: 13px;
    font-weight: 600;
    color: var(--text-primary);
  }

  .type-desc {
    font-size: 10px;
    color: var(--text-muted);
  }

  .select-file-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    width: 100%;
    padding: 16px;
    background: var(--primary);
    border: none;
    border-radius: 8px;
    color: white;
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .select-file-btn:hover {
    background: var(--primary-hover);
  }

  .selected-file {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-top: 16px;
    padding: 12px;
    background: var(--bg-tertiary);
    border-radius: 8px;
  }

  .file-name {
    font-size: 12px;
    color: var(--text-secondary);
    word-break: break-all;
  }

  .preview-container {
    aspect-ratio: 1;
    background: var(--bg-tertiary);
    border-radius: 12px;
    overflow: hidden;
    margin-bottom: 16px;
  }

  .preview-image {
    width: 100%;
    height: 100%;
    object-fit: contain;
  }

  .preview-placeholder {
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--text-muted);
  }

  .data-info {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 12px;
    margin-bottom: 24px;
  }

  .info-item {
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
    font-size: 14px;
    font-weight: 600;
    font-family: 'JetBrains Mono', monospace;
    color: var(--text-primary);
  }

  .options-grid {
    display: flex;
    flex-direction: column;
    gap: 12px;
    margin-bottom: 24px;
  }

  .option-item {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 12px;
    background: var(--bg-tertiary);
    border-radius: 8px;
    cursor: pointer;
  }

  .option-item input {
    width: 18px;
    height: 18px;
    accent-color: var(--primary);
  }

  .option-content {
    display: flex;
    flex-direction: column;
  }

  .option-label {
    font-size: 13px;
    font-weight: 500;
    color: var(--text-primary);
  }

  .option-desc {
    font-size: 11px;
    color: var(--text-muted);
  }

  .segment-methods {
    display: flex;
    gap: 8px;
    margin-bottom: 16px;
  }

  .method-btn {
    flex: 1;
    display: flex;
    flex-direction: column;
    padding: 12px;
    background: var(--bg-tertiary);
    border: 2px solid transparent;
    border-radius: 8px;
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .method-btn:hover {
    border-color: var(--border-color);
  }

  .method-btn.selected {
    border-color: var(--primary);
  }

  .method-label {
    font-size: 12px;
    font-weight: 600;
    color: var(--text-primary);
  }

  .method-desc {
    font-size: 10px;
    color: var(--text-muted);
  }

  .threshold-control {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 12px;
    background: var(--bg-tertiary);
    border-radius: 8px;
    margin-bottom: 24px;
  }

  .threshold-control label {
    font-size: 12px;
    color: var(--text-secondary);
  }

  .threshold-control input[type="range"] {
    flex: 1;
  }

  .threshold-value {
    min-width: 30px;
    font-family: 'JetBrains Mono', monospace;
    font-size: 12px;
    color: var(--text-primary);
  }

  .success-icon {
    display: flex;
    justify-content: center;
    margin: 24px 0;
    color: var(--success);
  }

  .result-metrics {
    margin-bottom: 24px;
  }

  .result-metrics h3 {
    font-size: 12px;
    font-weight: 600;
    text-transform: uppercase;
    color: var(--text-muted);
    margin-bottom: 12px;
  }

  .metrics-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 8px;
  }

  .metric-item {
    display: flex;
    justify-content: space-between;
    padding: 8px 12px;
    background: var(--bg-tertiary);
    border-radius: 6px;
  }

  .metric-label {
    font-size: 11px;
    color: var(--text-secondary);
    text-transform: capitalize;
  }

  .metric-value {
    font-size: 12px;
    font-weight: 600;
    font-family: 'JetBrains Mono', monospace;
    color: var(--text-primary);
  }

  .step-actions {
    display: flex;
    gap: 12px;
    margin-top: 24px;
  }

  .btn-primary,
  .btn-secondary {
    flex: 1;
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

  .btn-secondary:hover {
    border-color: var(--primary);
    color: var(--primary);
  }

  .btn-primary:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .error-message {
    margin-top: 16px;
    padding: 12px;
    background: rgba(239, 68, 68, 0.1);
    border: 1px solid var(--error);
    border-radius: 8px;
    font-size: 12px;
    color: var(--error);
  }

  .loading-overlay {
    position: absolute;
    inset: 0;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 16px;
    background: rgba(13, 17, 23, 0.9);
    color: var(--text-secondary);
  }
</style>
