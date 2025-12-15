<script lang="ts">
  import type { QAOALayer } from '$lib/stores/quantum';

  export let layers: QAOALayer[] = [];
  export let numQubits: number = 5;
  export let width: number = 600;
  export let height: number = 300;

  const qubitSpacing = 40;
  const layerWidth = 80;
  const gateWidth = 30;
  const gateHeight = 24;
  const startX = 60;
  const startY = 40;

  $: displayQubits = Math.min(numQubits, 6);  // Show max 6 qubits
  $: svgHeight = startY + displayQubits * qubitSpacing + 40;
</script>

<div class="circuit-viewer">
  <h4 class="title">QAOA Circuit (p = {layers.length})</h4>

  <svg {width} height={svgHeight} class="circuit-svg">
    <!-- Qubit labels -->
    {#each Array(displayQubits) as _, i}
      <text x="20" y={startY + i * qubitSpacing + 5} class="qubit-label">
        |q{i}⟩
      </text>
    {/each}

    <!-- Qubit lines -->
    {#each Array(displayQubits) as _, i}
      <line
        x1={startX}
        y1={startY + i * qubitSpacing}
        x2={startX + (layers.length * 2 + 1) * layerWidth}
        y2={startY + i * qubitSpacing}
        class="qubit-line"
      />
    {/each}

    <!-- Initial Hadamard gates (superposition) -->
    {#each Array(displayQubits) as _, i}
      <g transform="translate({startX + 20}, {startY + i * qubitSpacing - gateHeight/2})">
        <rect
          width={gateWidth}
          height={gateHeight}
          rx="4"
          class="gate hadamard"
        />
        <text x={gateWidth/2} y={gateHeight/2 + 4} class="gate-label">H</text>
      </g>
    {/each}

    <!-- QAOA layers -->
    {#each layers as layer, p}
      <!-- Cost operator (gamma) -->
      <g transform="translate({startX + 60 + p * layerWidth * 2}, 0)">
        <!-- Vertical connections for entanglement -->
        {#each Array(displayQubits - 1) as _, i}
          <line
            x1={gateWidth/2}
            y1={startY + i * qubitSpacing}
            x2={gateWidth/2}
            y2={startY + (i + 1) * qubitSpacing}
            class="entangle-line"
          />
        {/each}

        <!-- Cost gates -->
        {#each Array(displayQubits) as _, i}
          <g transform="translate(0, {startY + i * qubitSpacing - gateHeight/2})">
            <rect
              width={gateWidth}
              height={gateHeight}
              rx="4"
              class="gate cost"
            />
            <text x={gateWidth/2} y={gateHeight/2 + 4} class="gate-label">Rz</text>
          </g>
        {/each}

        <!-- Gamma angle label -->
        <text x={gateWidth/2} y={startY + displayQubits * qubitSpacing + 20} class="angle-label">
          γ{p+1}={layer.gamma.toFixed(2)}
        </text>
      </g>

      <!-- Mixer operator (beta) -->
      <g transform="translate({startX + 60 + p * layerWidth * 2 + layerWidth}, 0)">
        {#each Array(displayQubits) as _, i}
          <g transform="translate(0, {startY + i * qubitSpacing - gateHeight/2})">
            <rect
              width={gateWidth}
              height={gateHeight}
              rx="4"
              class="gate mixer"
            />
            <text x={gateWidth/2} y={gateHeight/2 + 4} class="gate-label">Rx</text>
          </g>
        {/each}

        <!-- Beta angle label -->
        <text x={gateWidth/2} y={startY + displayQubits * qubitSpacing + 20} class="angle-label">
          β{p+1}={layer.beta.toFixed(2)}
        </text>
      </g>
    {/each}

    <!-- Measurement symbols -->
    {#each Array(displayQubits) as _, i}
      <g transform="translate({startX + 60 + layers.length * layerWidth * 2 + 20}, {startY + i * qubitSpacing - 12})">
        <rect width="24" height="24" rx="2" class="measurement" />
        <path d="M4,18 Q12,6 20,18" stroke="currentColor" stroke-width="1.5" fill="none" class="meter-arc" />
        <line x1="12" y1="18" x2="18" y2="8" class="meter-needle" />
      </g>
    {/each}

    <!-- More qubits indicator -->
    {#if numQubits > displayQubits}
      <text x="20" y={startY + displayQubits * qubitSpacing + 5} class="more-label">
        ... +{numQubits - displayQubits} more
      </text>
    {/if}
  </svg>

  <div class="legend">
    <div class="legend-item">
      <span class="legend-box hadamard"></span>
      <span>Hadamard (H)</span>
    </div>
    <div class="legend-item">
      <span class="legend-box cost"></span>
      <span>Cost Rz(γ)</span>
    </div>
    <div class="legend-item">
      <span class="legend-box mixer"></span>
      <span>Mixer Rx(β)</span>
    </div>
  </div>
</div>

<style>
  .circuit-viewer {
    background: var(--bg-secondary);
    border-radius: 12px;
    padding: 16px;
  }

  .title {
    font-size: 13px;
    font-weight: 600;
    color: var(--text-primary);
    margin: 0 0 12px 0;
  }

  .circuit-svg {
    display: block;
    margin: 0 auto;
  }

  .qubit-label {
    font-size: 12px;
    font-family: var(--font-mono);
    fill: var(--text-secondary);
  }

  .qubit-line {
    stroke: var(--text-muted);
    stroke-width: 1;
  }

  .gate {
    stroke-width: 1.5;
  }

  .gate.hadamard {
    fill: rgba(139, 92, 246, 0.2);
    stroke: #8b5cf6;
  }

  .gate.cost {
    fill: rgba(59, 130, 246, 0.2);
    stroke: #3b82f6;
  }

  .gate.mixer {
    fill: rgba(16, 185, 129, 0.2);
    stroke: #10b981;
  }

  .gate-label {
    font-size: 10px;
    font-weight: 600;
    fill: var(--text-primary);
    text-anchor: middle;
    dominant-baseline: middle;
  }

  .angle-label {
    font-size: 9px;
    font-family: var(--font-mono);
    fill: var(--text-muted);
    text-anchor: middle;
  }

  .entangle-line {
    stroke: #3b82f6;
    stroke-width: 1;
    stroke-dasharray: 3,2;
  }

  .measurement {
    fill: rgba(107, 114, 128, 0.2);
    stroke: var(--text-muted);
    stroke-width: 1;
  }

  .meter-arc {
    stroke: var(--text-muted);
  }

  .meter-needle {
    stroke: var(--text-primary);
    stroke-width: 1.5;
  }

  .more-label {
    font-size: 11px;
    fill: var(--text-muted);
    font-style: italic;
  }

  .legend {
    display: flex;
    justify-content: center;
    gap: 20px;
    margin-top: 12px;
    padding-top: 12px;
    border-top: 1px solid var(--border-color);
  }

  .legend-item {
    display: flex;
    align-items: center;
    gap: 6px;
    font-size: 11px;
    color: var(--text-secondary);
  }

  .legend-box {
    width: 16px;
    height: 12px;
    border-radius: 2px;
  }

  .legend-box.hadamard {
    background: rgba(139, 92, 246, 0.3);
    border: 1px solid #8b5cf6;
  }

  .legend-box.cost {
    background: rgba(59, 130, 246, 0.3);
    border: 1px solid #3b82f6;
  }

  .legend-box.mixer {
    background: rgba(16, 185, 129, 0.3);
    border: 1px solid #10b981;
  }
</style>
