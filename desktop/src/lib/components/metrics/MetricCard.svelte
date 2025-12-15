<script lang="ts">
  export let label: string;
  export let value: number;
  export let unit: string;
  export let target: string = '';
  export let valid: boolean = true;
  export let score: number = 0;
  export let scientific: boolean = false;

  function formatValue(val: number, sci: boolean): string {
    if (sci) {
      return val.toExponential(1);
    }
    if (val >= 1000) {
      return val.toFixed(0);
    }
    if (val >= 100) {
      return val.toFixed(1);
    }
    return val.toFixed(2);
  }

  $: displayValue = formatValue(value, scientific);
  $: statusColor = valid ? (score >= 80 ? 'var(--success)' : 'var(--warning)') : 'var(--error)';
</script>

<div class="metric-card" class:invalid={!valid}>
  <div class="metric-header">
    <span class="metric-label">{label}</span>
    <span class="metric-status" style="background: {statusColor}"></span>
  </div>

  <div class="metric-value">
    <span class="value">{displayValue}</span>
    {#if unit}
      <span class="unit">{unit}</span>
    {/if}
  </div>

  {#if target}
    <div class="metric-target">
      Target: {target}
    </div>
  {/if}

  {#if score > 0}
    <div class="metric-score">
      <div class="score-bar">
        <div class="score-fill" style="width: {score}%; background: {statusColor}"></div>
      </div>
      <span class="score-text">{score}%</span>
    </div>
  {/if}
</div>

<style>
  .metric-card {
    padding: 12px;
    background: var(--bg-tertiary);
    border-radius: 8px;
    border: 1px solid transparent;
    transition: all var(--transition-fast);
  }

  .metric-card:hover {
    border-color: var(--border-color);
  }

  .metric-card.invalid {
    border-color: var(--error);
    background: rgba(239, 68, 68, 0.1);
  }

  .metric-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 8px;
  }

  .metric-label {
    font-size: 11px;
    font-weight: 500;
    color: var(--text-muted);
    text-transform: uppercase;
    letter-spacing: 0.03em;
  }

  .metric-status {
    width: 8px;
    height: 8px;
    border-radius: 50%;
  }

  .metric-value {
    display: flex;
    align-items: baseline;
    gap: 4px;
    margin-bottom: 4px;
  }

  .value {
    font-size: 20px;
    font-weight: 600;
    font-family: 'JetBrains Mono', monospace;
    color: var(--text-primary);
  }

  .unit {
    font-size: 11px;
    color: var(--text-muted);
  }

  .metric-target {
    font-size: 10px;
    color: var(--text-muted);
    margin-bottom: 8px;
  }

  .metric-score {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .score-bar {
    flex: 1;
    height: 4px;
    background: var(--bg-primary);
    border-radius: 2px;
    overflow: hidden;
  }

  .score-fill {
    height: 100%;
    border-radius: 2px;
    transition: width var(--transition-base);
  }

  .score-text {
    font-size: 10px;
    font-weight: 500;
    color: var(--text-secondary);
    min-width: 28px;
    text-align: right;
  }
</style>
