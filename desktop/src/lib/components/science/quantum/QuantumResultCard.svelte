<script lang="ts">
  import type { QuantumSolution } from '$lib/stores/quantum';
  import { formatEnergy, getAdvantageColor } from '$lib/stores/quantum';

  export let solution: QuantumSolution | null = null;
  export let targetPorosity: number = 0.7;
  export let minStrength: number = 50.0;

  $: porosityError = solution ? ((solution.porosity - targetPorosity) / targetPorosity * 100) : 0;
  $: strengthMargin = solution ? (solution.strength - minStrength) : 0;
</script>

<div class="result-card">
  <h3 class="title">Optimization Result</h3>

  {#if solution}
    <div class="result-content">
      <div class="energy-section">
        <div class="energy-display" class:advantage={solution.quantumAdvantage}>
          <span class="energy-value">{formatEnergy(solution.energy)}</span>
          <span class="energy-label">QUBO Energy</span>
        </div>
        <div class="advantage-badge" class:active={solution.quantumAdvantage}>
          {#if solution.quantumAdvantage}
            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
              <polyline points="22 4 12 14.01 9 11.01"></polyline>
            </svg>
            Quantum Advantage
          {:else}
            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="10"></circle>
              <line x1="12" y1="8" x2="12" y2="12"></line>
              <line x1="12" y1="16" x2="12.01" y2="16"></line>
            </svg>
            Classical Regime
          {/if}
        </div>
      </div>

      <div class="metrics-grid">
        <div class="metric-card">
          <div class="metric-header">
            <span class="metric-name">Porosity</span>
            <span class="metric-badge" class:success={Math.abs(porosityError) < 5} class:warning={Math.abs(porosityError) >= 5}>
              {porosityError >= 0 ? '+' : ''}{porosityError.toFixed(1)}%
            </span>
          </div>
          <div class="metric-values">
            <div class="metric-item">
              <span class="label">Target</span>
              <span class="value">{(targetPorosity * 100).toFixed(0)}%</span>
            </div>
            <div class="metric-item">
              <span class="label">Achieved</span>
              <span class="value highlight">{(solution.porosity * 100).toFixed(1)}%</span>
            </div>
          </div>
        </div>

        <div class="metric-card">
          <div class="metric-header">
            <span class="metric-name">Strength</span>
            <span class="metric-badge" class:success={strengthMargin >= 0} class:error={strengthMargin < 0}>
              {strengthMargin >= 0 ? '+' : ''}{strengthMargin.toFixed(1)} MPa
            </span>
          </div>
          <div class="metric-values">
            <div class="metric-item">
              <span class="label">Minimum</span>
              <span class="value">{minStrength.toFixed(0)} MPa</span>
            </div>
            <div class="metric-item">
              <span class="label">Predicted</span>
              <span class="value highlight">{solution.strength.toFixed(1)} MPa</span>
            </div>
          </div>
        </div>
      </div>

      <div class="solution-preview">
        <span class="preview-label">Solution Vector ({solution.binaryVector.length} qubits)</span>
        <div class="binary-display">
          {#each solution.binaryVector.slice(0, 32) as bit, i}
            <span class="bit" class:one={bit === 1}>{bit}</span>
          {/each}
          {#if solution.binaryVector.length > 32}
            <span class="more">...</span>
          {/if}
        </div>
      </div>
    </div>
  {:else}
    <div class="no-result">
      <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
        <circle cx="12" cy="12" r="10"></circle>
        <path d="M12 6v6l4 2"></path>
      </svg>
      <p>No optimization result</p>
      <p class="hint">Configure parameters and click "Run Optimization"</p>
    </div>
  {/if}
</div>

<style>
  .result-card {
    background: var(--bg-secondary);
    border-radius: 12px;
    padding: 20px;
  }

  .title {
    font-size: 14px;
    font-weight: 600;
    color: var(--text-primary);
    margin: 0 0 16px 0;
  }

  .result-content {
    display: flex;
    flex-direction: column;
    gap: 16px;
  }

  .energy-section {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 16px;
    background: var(--bg-tertiary);
    border-radius: 10px;
  }

  .energy-display {
    text-align: center;
  }

  .energy-value {
    display: block;
    font-size: 28px;
    font-weight: 700;
    font-family: var(--font-mono);
    color: var(--text-primary);
  }

  .energy-display.advantage .energy-value {
    color: var(--success);
  }

  .energy-label {
    display: block;
    font-size: 11px;
    color: var(--text-muted);
    margin-top: 4px;
  }

  .advantage-badge {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 8px 12px;
    background: var(--bg-secondary);
    border-radius: 20px;
    font-size: 12px;
    font-weight: 500;
    color: var(--text-muted);
  }

  .advantage-badge.active {
    background: rgba(16, 185, 129, 0.15);
    color: var(--success);
  }

  .metrics-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 12px;
  }

  .metric-card {
    padding: 14px;
    background: var(--bg-tertiary);
    border-radius: 8px;
  }

  .metric-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 10px;
  }

  .metric-name {
    font-size: 12px;
    font-weight: 600;
    color: var(--text-secondary);
  }

  .metric-badge {
    font-size: 10px;
    font-weight: 600;
    padding: 2px 6px;
    border-radius: 4px;
  }

  .metric-badge.success {
    background: rgba(16, 185, 129, 0.15);
    color: var(--success);
  }

  .metric-badge.warning {
    background: rgba(245, 158, 11, 0.15);
    color: var(--warning);
  }

  .metric-badge.error {
    background: rgba(239, 68, 68, 0.15);
    color: var(--error);
  }

  .metric-values {
    display: flex;
    justify-content: space-between;
  }

  .metric-item {
    display: flex;
    flex-direction: column;
    gap: 2px;
  }

  .metric-item .label {
    font-size: 10px;
    color: var(--text-muted);
  }

  .metric-item .value {
    font-size: 14px;
    font-weight: 600;
    color: var(--text-secondary);
  }

  .metric-item .value.highlight {
    color: var(--text-primary);
  }

  .solution-preview {
    padding: 12px;
    background: var(--bg-tertiary);
    border-radius: 8px;
  }

  .preview-label {
    display: block;
    font-size: 11px;
    color: var(--text-muted);
    margin-bottom: 8px;
  }

  .binary-display {
    display: flex;
    flex-wrap: wrap;
    gap: 2px;
    font-family: var(--font-mono);
    font-size: 10px;
  }

  .bit {
    width: 14px;
    height: 14px;
    display: flex;
    align-items: center;
    justify-content: center;
    background: var(--bg-primary);
    border-radius: 2px;
    color: var(--text-muted);
  }

  .bit.one {
    background: var(--primary);
    color: white;
  }

  .more {
    color: var(--text-muted);
    padding: 0 4px;
  }

  .no-result {
    padding: 32px;
    text-align: center;
    color: var(--text-muted);
  }

  .no-result svg {
    margin-bottom: 12px;
    opacity: 0.5;
  }

  .no-result p {
    margin: 0;
    font-size: 13px;
  }

  .no-result .hint {
    font-size: 12px;
    margin-top: 4px;
  }
</style>
