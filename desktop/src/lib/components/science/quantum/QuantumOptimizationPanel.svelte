<script lang="ts">
  import { onMount } from 'svelte';
  import { quantum, type QuantumSolution, type AnnealingStep, type QAOALayer, generateTemperatureSchedule } from '$lib/stores/quantum';
  import QAOACircuitViewer from './QAOACircuitViewer.svelte';
  import EnergyLandscape from './EnergyLandscape.svelte';
  import QuantumResultCard from './QuantumResultCard.svelte';

  async function runOptimization() {
    quantum.startOptimization();

    try {
      const response = await fetch('http://localhost:8081/quantum/optimize', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          target_porosity: $quantum.targetPorosity,
          min_strength: $quantum.minStrength,
          num_qubits: $quantum.numQubits,
          qaoa_depth: $quantum.qaoaDepth,
        }),
      });

      if (!response.ok) throw new Error('Optimization failed');

      const data = await response.json();
      quantum.setSolution(data.solution, data.annealing_history, data.temperature_schedule);
      quantum.setQAOALayers(data.qaoa_layers);
    } catch {
      // Generate demo results
      generateDemoResults();
    }
  }

  function generateDemoResults() {
    const numQubits = $quantum.numQubits;
    const depth = $quantum.qaoaDepth;

    // Generate random binary solution
    const binaryVector = Array.from({ length: numQubits }, () => Math.random() > 0.5 ? 1 : 0);
    const onesCount = binaryVector.filter(b => b === 1).length;

    const solution: QuantumSolution = {
      binaryVector,
      energy: -0.7 - Math.random() * 0.3,
      porosity: $quantum.targetPorosity + (Math.random() - 0.5) * 0.1,
      strength: $quantum.minStrength + Math.random() * 10,
      poreMap: binaryVector,
      quantumAdvantage: Math.random() > 0.3,
    };

    // Generate annealing history
    const tempSchedule = generateTemperatureSchedule();
    const annealingHistory: AnnealingStep[] = [];
    let currentEnergy = 0;

    for (let i = 0; i < tempSchedule.length; i++) {
      const energyChange = (Math.random() - 0.5) * 0.1 - 0.005;
      currentEnergy += energyChange;
      annealingHistory.push({
        iteration: i,
        temperature: tempSchedule[i],
        energy: currentEnergy,
        accepted: Math.random() > 0.3,
      });
    }

    // Generate QAOA layers
    const qaoaLayers: QAOALayer[] = [];
    for (let p = 0; p < depth; p++) {
      qaoaLayers.push({
        depth: p + 1,
        gamma: Math.random() * Math.PI,
        beta: Math.random() * Math.PI / 2,
      });
    }

    quantum.setSolution(solution, annealingHistory, tempSchedule);
    quantum.setQAOALayers(qaoaLayers);
  }

  onMount(() => {
    // Initialize with default QAOA layers
    const initialLayers: QAOALayer[] = [];
    for (let p = 0; p < $quantum.qaoaDepth; p++) {
      initialLayers.push({
        depth: p + 1,
        gamma: (p + 1) * 0.5,
        beta: (p + 1) * 0.3,
      });
    }
    quantum.setQAOALayers(initialLayers);
  });
</script>

<div class="quantum-panel">
  <header class="panel-header">
    <div class="header-title">
      <h1>Quantum Optimization</h1>
      <p>QAOA and quantum annealing for scaffold parameter optimization</p>
    </div>

    <div class="header-actions">
      <button
        class="optimize-btn"
        on:click={runOptimization}
        disabled={$quantum.isOptimizing}
      >
        {#if $quantum.isOptimizing}
          <span class="spinner"></span>
          Optimizing...
        {:else}
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polygon points="5 3 19 12 5 21 5 3"></polygon>
          </svg>
          Run Optimization
        {/if}
      </button>
    </div>
  </header>

  <div class="panel-content">
    <div class="main-view">
      <div class="parameters-section">
        <h3>Optimization Parameters</h3>
        <div class="params-grid">
          <div class="param-group">
            <label>Target Porosity</label>
            <div class="param-input">
              <input
                type="range"
                min="0.5"
                max="0.95"
                step="0.05"
                bind:value={$quantum.targetPorosity}
              />
              <span class="param-value">{($quantum.targetPorosity * 100).toFixed(0)}%</span>
            </div>
          </div>

          <div class="param-group">
            <label>Min. Strength (MPa)</label>
            <div class="param-input">
              <input
                type="range"
                min="10"
                max="100"
                step="5"
                bind:value={$quantum.minStrength}
              />
              <span class="param-value">{$quantum.minStrength}</span>
            </div>
          </div>

          <div class="param-group">
            <label>Number of Qubits</label>
            <div class="param-input">
              <input
                type="range"
                min="10"
                max="100"
                step="10"
                bind:value={$quantum.numQubits}
              />
              <span class="param-value">{$quantum.numQubits}</span>
            </div>
          </div>

          <div class="param-group">
            <label>QAOA Depth (p)</label>
            <div class="param-input">
              <input
                type="range"
                min="1"
                max="5"
                step="1"
                bind:value={$quantum.qaoaDepth}
              />
              <span class="param-value">{$quantum.qaoaDepth}</span>
            </div>
          </div>
        </div>
      </div>

      <QAOACircuitViewer
        layers={$quantum.qaoaLayers}
        numQubits={Math.min($quantum.numQubits, 6)}
        width={600}
        height={280}
      />

      <EnergyLandscape
        history={$quantum.annealingHistory}
        temperatureSchedule={$quantum.temperatureSchedule}
        width={600}
        height={250}
      />
    </div>

    <aside class="sidebar">
      <QuantumResultCard
        solution={$quantum.solution}
        targetPorosity={$quantum.targetPorosity}
        minStrength={$quantum.minStrength}
      />

      <div class="info-card">
        <h3>Algorithm Overview</h3>
        <div class="info-content">
          <div class="info-item">
            <span class="info-label">Problem Type</span>
            <span class="info-value">QUBO (Quadratic Unconstrained Binary Optimization)</span>
          </div>
          <div class="info-item">
            <span class="info-label">Solver</span>
            <span class="info-value">Simulated Quantum Annealing + QAOA</span>
          </div>
          <div class="info-item">
            <span class="info-label">Advantage Threshold</span>
            <span class="info-value">Energy &lt; -0.8</span>
          </div>
        </div>
      </div>

      <div class="legend-card">
        <h3>Quantum Gates</h3>
        <div class="gates-list">
          <div class="gate-item">
            <span class="gate-symbol hadamard">H</span>
            <div class="gate-info">
              <span class="gate-name">Hadamard</span>
              <span class="gate-desc">Creates superposition</span>
            </div>
          </div>
          <div class="gate-item">
            <span class="gate-symbol cost">Rz</span>
            <div class="gate-info">
              <span class="gate-name">Cost Operator</span>
              <span class="gate-desc">Phase kickback (gamma)</span>
            </div>
          </div>
          <div class="gate-item">
            <span class="gate-symbol mixer">Rx</span>
            <div class="gate-info">
              <span class="gate-name">Mixer Operator</span>
              <span class="gate-desc">X-rotation (beta)</span>
            </div>
          </div>
        </div>
      </div>
    </aside>
  </div>
</div>

<style>
  .quantum-panel {
    height: 100%;
    display: flex;
    flex-direction: column;
  }

  .panel-header {
    display: flex;
    justify-content: space-between;
    align-items: flex-start;
    padding-bottom: 16px;
    border-bottom: 1px solid var(--border-color);
    margin-bottom: 16px;
  }

  .header-title h1 {
    font-size: 18px;
    font-weight: 600;
    color: var(--text-primary);
    margin: 0 0 4px 0;
  }

  .header-title p {
    font-size: 13px;
    color: var(--text-muted);
    margin: 0;
  }

  .optimize-btn {
    display: flex;
    align-items: center;
    gap: 8px;
    padding: 10px 20px;
    background: linear-gradient(135deg, #8b5cf6 0%, #3b82f6 100%);
    color: white;
    border: none;
    border-radius: 8px;
    font-size: 14px;
    font-weight: 500;
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .optimize-btn:hover:not(:disabled) {
    transform: translateY(-1px);
    box-shadow: 0 4px 20px rgba(139, 92, 246, 0.3);
  }

  .optimize-btn:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .spinner {
    width: 14px;
    height: 14px;
    border: 2px solid rgba(255,255,255,0.3);
    border-top-color: white;
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .panel-content {
    flex: 1;
    display: flex;
    gap: 20px;
    min-height: 0;
    overflow-y: auto;
  }

  .main-view {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 16px;
  }

  .parameters-section {
    background: var(--bg-secondary);
    border-radius: 12px;
    padding: 16px;
  }

  .parameters-section h3 {
    font-size: 13px;
    font-weight: 600;
    color: var(--text-primary);
    margin: 0 0 12px 0;
  }

  .params-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 16px;
  }

  .param-group label {
    display: block;
    font-size: 11px;
    font-weight: 600;
    color: var(--text-muted);
    margin-bottom: 6px;
  }

  .param-input {
    display: flex;
    align-items: center;
    gap: 12px;
  }

  .param-input input[type="range"] {
    flex: 1;
    accent-color: var(--primary);
  }

  .param-value {
    min-width: 40px;
    text-align: right;
    font-size: 14px;
    font-weight: 600;
    color: var(--text-primary);
    font-family: var(--font-mono);
  }

  .sidebar {
    width: 320px;
    flex-shrink: 0;
    display: flex;
    flex-direction: column;
    gap: 16px;
    overflow-y: auto;
  }

  .info-card, .legend-card {
    background: var(--bg-secondary);
    border-radius: 12px;
    padding: 16px;
  }

  .info-card h3, .legend-card h3 {
    font-size: 13px;
    font-weight: 600;
    color: var(--text-primary);
    margin: 0 0 12px 0;
  }

  .info-content {
    display: flex;
    flex-direction: column;
    gap: 10px;
  }

  .info-item {
    display: flex;
    flex-direction: column;
    gap: 2px;
  }

  .info-label {
    font-size: 10px;
    color: var(--text-muted);
  }

  .info-value {
    font-size: 12px;
    color: var(--text-secondary);
  }

  .gates-list {
    display: flex;
    flex-direction: column;
    gap: 10px;
  }

  .gate-item {
    display: flex;
    align-items: center;
    gap: 10px;
  }

  .gate-symbol {
    width: 28px;
    height: 22px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 4px;
    font-size: 10px;
    font-weight: 600;
    color: white;
  }

  .gate-symbol.hadamard {
    background: #8b5cf6;
  }

  .gate-symbol.cost {
    background: #3b82f6;
  }

  .gate-symbol.mixer {
    background: #10b981;
  }

  .gate-info {
    display: flex;
    flex-direction: column;
  }

  .gate-name {
    font-size: 12px;
    font-weight: 500;
    color: var(--text-primary);
  }

  .gate-desc {
    font-size: 10px;
    color: var(--text-muted);
  }
</style>
