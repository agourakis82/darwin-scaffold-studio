<script lang="ts">
  import { juliaApi } from '$lib/services/julia-api';
  import { scaffold } from '$lib/stores/scaffold';
  import { metrics } from '$lib/stores/metrics';

  let prompt = '';
  let isGenerating = false;
  let generatedExplanation = '';
  let error = '';

  // Constraint toggles
  let useConstraints = false;
  let porosityMin = 60;
  let porosityMax = 90;

  // Example prompts
  const examplePrompts = [
    'Create a bone scaffold with 80% porosity and interconnected pores',
    'Design a gyroid structure optimized for cartilage regeneration',
    'Generate a scaffold with gradient porosity from 70% to 90%',
    'Make a diamond TPMS scaffold for osteochondral tissue',
  ];

  async function handleGenerate() {
    if (!prompt.trim()) return;

    isGenerating = true;
    error = '';
    generatedExplanation = '';

    try {
      const constraints = useConstraints
        ? {
            material: $scaffold.material,
            tissue: $scaffold.tissue,
            porosity_range: [porosityMin / 100, porosityMax / 100] as [number, number],
          }
        : {
            material: $scaffold.material,
            tissue: $scaffold.tissue,
          };

      const result = await juliaApi.textToScaffold(prompt, constraints);

      if (result.success && result.data) {
        // Update scaffold store with new workspace
        scaffold.update((s) => ({
          ...s,
          workspaceId: result.data!.workspace_id,
          meshUrl: result.data!.mesh_url,
        }));

        // Update metrics
        metrics.update((m) => ({
          ...m,
          current: result.data!.metrics,
        }));

        generatedExplanation = result.data.explanation;
      } else {
        error = result.error || 'Failed to generate scaffold';
      }
    } catch (e) {
      error = e instanceof Error ? e.message : 'Unknown error occurred';
    } finally {
      isGenerating = false;
    }
  }

  function setExample(example: string) {
    prompt = example;
  }
</script>

<div class="text-to-scaffold">
  <div class="header">
    <div class="icon">
      <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M12 3l-8 4.5v9l8 4.5 8-4.5v-9l-8-4.5z"></path>
        <path d="M12 12l8-4.5"></path>
        <path d="M12 12v9"></path>
        <path d="M12 12L4 7.5"></path>
      </svg>
    </div>
    <div class="title">
      <h4>Text to Scaffold</h4>
      <span>Describe your scaffold in natural language</span>
    </div>
  </div>

  <div class="prompt-area">
    <textarea
      bind:value={prompt}
      placeholder="Describe the scaffold you want to create..."
      rows="3"
      disabled={isGenerating}
    ></textarea>

    <div class="examples">
      <span class="examples-label">Try:</span>
      {#each examplePrompts as example}
        <button class="example-chip" on:click={() => setExample(example)} disabled={isGenerating}>
          {example.slice(0, 30)}...
        </button>
      {/each}
    </div>
  </div>

  <div class="constraints" class:expanded={useConstraints}>
    <button class="constraints-toggle" on:click={() => (useConstraints = !useConstraints)}>
      <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class:rotated={useConstraints}>
        <polyline points="9 18 15 12 9 6"></polyline>
      </svg>
      Constraints
    </button>

    {#if useConstraints}
      <div class="constraints-content">
        <div class="constraint-row">
          <label>Porosity Range</label>
          <div class="range-inputs">
            <input type="number" bind:value={porosityMin} min="0" max="100" disabled={isGenerating} />
            <span>to</span>
            <input type="number" bind:value={porosityMax} min="0" max="100" disabled={isGenerating} />
            <span>%</span>
          </div>
        </div>

        <div class="constraint-info">
          <span>Material:</span> {$scaffold.material || 'Not set'}
          <span>Tissue:</span> {$scaffold.tissue || 'Not set'}
        </div>
      </div>
    {/if}
  </div>

  <button class="generate-btn" on:click={handleGenerate} disabled={!prompt.trim() || isGenerating}>
    {#if isGenerating}
      <span class="spinner"></span>
      Generating...
    {:else}
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"></polygon>
      </svg>
      Generate Scaffold
    {/if}
  </button>

  {#if error}
    <div class="error-message">
      <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <circle cx="12" cy="12" r="10"></circle>
        <line x1="12" y1="8" x2="12" y2="12"></line>
        <line x1="12" y1="16" x2="12.01" y2="16"></line>
      </svg>
      {error}
    </div>
  {/if}

  {#if generatedExplanation}
    <div class="explanation">
      <h5>AI Explanation</h5>
      <p>{generatedExplanation}</p>
    </div>
  {/if}
</div>

<style>
  .text-to-scaffold {
    display: flex;
    flex-direction: column;
    gap: 16px;
    padding: 16px;
    background: var(--bg-secondary);
    border-radius: 12px;
    border: 1px solid var(--border-color);
  }

  .header {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .icon {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 40px;
    height: 40px;
    border-radius: 10px;
    background: linear-gradient(135deg, #8b5cf6, #6366f1);
    color: white;
  }

  .title h4 {
    font-size: 14px;
    font-weight: 600;
    margin: 0;
  }

  .title span {
    font-size: 11px;
    color: var(--text-muted);
  }

  .prompt-area textarea {
    width: 100%;
    padding: 12px;
    border: 1px solid var(--border-color);
    border-radius: 8px;
    background: var(--bg-primary);
    color: var(--text-primary);
    font-family: inherit;
    font-size: 13px;
    resize: none;
    outline: none;
    transition: border-color var(--transition-fast);
  }

  .prompt-area textarea:focus {
    border-color: var(--primary);
  }

  .prompt-area textarea:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .examples {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    margin-top: 8px;
    align-items: center;
  }

  .examples-label {
    font-size: 11px;
    color: var(--text-muted);
  }

  .example-chip {
    padding: 4px 8px;
    font-size: 10px;
    background: var(--bg-tertiary);
    border: 1px solid var(--border-color);
    border-radius: 12px;
    color: var(--text-secondary);
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .example-chip:hover:not(:disabled) {
    border-color: var(--primary);
    color: var(--primary);
  }

  .example-chip:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .constraints {
    border-top: 1px solid var(--border-color);
    padding-top: 12px;
  }

  .constraints-toggle {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 4px 0;
    background: none;
    border: none;
    color: var(--text-secondary);
    font-size: 12px;
    cursor: pointer;
    transition: color var(--transition-fast);
  }

  .constraints-toggle:hover {
    color: var(--text-primary);
  }

  .constraints-toggle svg {
    transition: transform var(--transition-fast);
  }

  .constraints-toggle svg.rotated {
    transform: rotate(90deg);
  }

  .constraints-content {
    margin-top: 12px;
    display: flex;
    flex-direction: column;
    gap: 12px;
  }

  .constraint-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
  }

  .constraint-row label {
    font-size: 12px;
    color: var(--text-secondary);
  }

  .range-inputs {
    display: flex;
    align-items: center;
    gap: 6px;
  }

  .range-inputs input {
    width: 50px;
    padding: 4px 8px;
    border: 1px solid var(--border-color);
    border-radius: 4px;
    background: var(--bg-primary);
    color: var(--text-primary);
    font-size: 12px;
    text-align: center;
  }

  .range-inputs span {
    font-size: 11px;
    color: var(--text-muted);
  }

  .constraint-info {
    font-size: 11px;
    color: var(--text-muted);
    display: flex;
    gap: 12px;
  }

  .constraint-info span {
    color: var(--text-secondary);
  }

  .generate-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    padding: 12px 16px;
    background: linear-gradient(135deg, #8b5cf6, #6366f1);
    border: none;
    border-radius: 8px;
    color: white;
    font-size: 13px;
    font-weight: 500;
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .generate-btn:hover:not(:disabled) {
    transform: translateY(-1px);
    box-shadow: 0 4px 12px rgba(139, 92, 246, 0.3);
  }

  .generate-btn:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .spinner {
    width: 14px;
    height: 14px;
    border: 2px solid rgba(255, 255, 255, 0.3);
    border-top-color: white;
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
  }

  @keyframes spin {
    to {
      transform: rotate(360deg);
    }
  }

  .error-message {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 10px 12px;
    background: rgba(239, 68, 68, 0.1);
    border: 1px solid rgba(239, 68, 68, 0.3);
    border-radius: 8px;
    color: #ef4444;
    font-size: 12px;
  }

  .explanation {
    padding: 12px;
    background: var(--bg-tertiary);
    border-radius: 8px;
  }

  .explanation h5 {
    font-size: 11px;
    font-weight: 600;
    color: var(--text-muted);
    text-transform: uppercase;
    letter-spacing: 0.05em;
    margin: 0 0 8px 0;
  }

  .explanation p {
    font-size: 13px;
    color: var(--text-secondary);
    line-height: 1.5;
    margin: 0;
  }
</style>
