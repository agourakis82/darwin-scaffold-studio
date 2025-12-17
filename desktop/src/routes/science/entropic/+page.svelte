<script lang="ts">
  import { onMount } from 'svelte';

  // Data from our analysis
  const polymerData = [
    { name: 'PLA', type: 'chain_end', cv: 6.2, omega: 50 },
    { name: 'PGA', type: 'chain_end', cv: 5.8, omega: 40 },
    { name: 'PCL', type: 'chain_end', cv: 7.1, omega: 80 },
    { name: 'PHBV', type: 'chain_end', cv: 6.8, omega: 60 },
    { name: 'PDO', type: 'chain_end', cv: 7.5, omega: 70 },
    { name: 'PLGA 50/50', type: 'random', cv: 15.2, omega: 200 },
    { name: 'PBAT', type: 'random', cv: 18.5, omega: 300 },
    { name: 'PBS', type: 'random', cv: 16.8, omega: 250 },
    { name: 'PU-ester', type: 'random', cv: 21.3, omega: 400 },
    { name: 'PBSA', type: 'random', cv: 19.7, omega: 350 },
  ];

  // Entropic causality parameters
  let alpha = 0.055;
  let omegaMax = 2.73;
  let lambda = Math.log(2) / 3;

  // Compute effective omega
  function omegaEffective(omegaRaw: number): number {
    let eff = alpha * omegaRaw;
    eff = Math.min(eff, omegaMax);
    eff = Math.max(eff, 2.0);
    return eff;
  }

  // Compute causality
  function causality(omega: number): number {
    return Math.pow(omega, -lambda);
  }

  // Predict CV from omega
  function predictCV(omegaRaw: number): number {
    const omegaEff = omegaEffective(omegaRaw);
    const C = causality(omegaEff);
    return 30 * (1 - C);
  }

  // Computed data
  $: computedData = polymerData.map(p => ({
    ...p,
    omegaEff: omegaEffective(p.omega),
    cvPredicted: predictCV(p.omega),
    error: Math.abs(predictCV(p.omega) - p.cv)
  }));

  // Statistics
  $: chainEndCV = polymerData.filter(p => p.type === 'chain_end').map(p => p.cv);
  $: randomCV = polymerData.filter(p => p.type === 'random').map(p => p.cv);
  $: meanChainEnd = chainEndCV.reduce((a, b) => a + b, 0) / chainEndCV.length;
  $: meanRandom = randomCV.reduce((a, b) => a + b, 0) / randomCV.length;
  $: meanError = computedData.reduce((a, b) => a + b.error, 0) / computedData.length;

  // Canvas refs
  let cvComparisonCanvas: HTMLCanvasElement;
  let scatterCanvas: HTMLCanvasElement;
  let curveCanvas: HTMLCanvasElement;

  onMount(() => {
    drawCVComparison();
    drawScatterPlot();
    drawCausalityCurve();
  });

  // Update plots when parameters change
  $: if (cvComparisonCanvas) drawCVComparison();
  $: if (scatterCanvas) drawScatterPlot();
  $: if (curveCanvas) drawCausalityCurve();

  function drawCVComparison() {
    if (!cvComparisonCanvas) return;
    const ctx = cvComparisonCanvas.getContext('2d');
    if (!ctx) return;

    const width = cvComparisonCanvas.width;
    const height = cvComparisonCanvas.height;
    const padding = 60;

    ctx.fillStyle = '#0d1117';
    ctx.fillRect(0, 0, width, height);

    // Draw axes
    ctx.strokeStyle = '#30363d';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(padding, padding);
    ctx.lineTo(padding, height - padding);
    ctx.lineTo(width - padding, height - padding);
    ctx.stroke();

    // Y-axis labels
    ctx.fillStyle = '#8b949e';
    ctx.font = '12px Inter, sans-serif';
    ctx.textAlign = 'right';
    for (let i = 0; i <= 30; i += 5) {
      const y = height - padding - (i / 30) * (height - 2 * padding);
      ctx.fillText(`${i}%`, padding - 10, y + 4);
      ctx.beginPath();
      ctx.moveTo(padding, y);
      ctx.lineTo(width - padding, y);
      ctx.strokeStyle = '#21262d';
      ctx.stroke();
    }

    // Box plot for chain-end
    const boxWidth = 60;
    const x1 = padding + 80;
    const minCE = Math.min(...chainEndCV);
    const maxCE = Math.max(...chainEndCV);
    const q1CE = meanChainEnd - 0.5;
    const q3CE = meanChainEnd + 0.5;

    const yScale = (v: number) => height - padding - (v / 30) * (height - 2 * padding);

    // Chain-end box
    ctx.fillStyle = '#238636';
    ctx.fillRect(x1 - boxWidth/2, yScale(q3CE), boxWidth, yScale(q1CE) - yScale(q3CE));
    ctx.strokeStyle = '#3fb950';
    ctx.lineWidth = 2;
    ctx.strokeRect(x1 - boxWidth/2, yScale(q3CE), boxWidth, yScale(q1CE) - yScale(q3CE));

    // Median line
    ctx.beginPath();
    ctx.moveTo(x1 - boxWidth/2, yScale(meanChainEnd));
    ctx.lineTo(x1 + boxWidth/2, yScale(meanChainEnd));
    ctx.stroke();

    // Whiskers
    ctx.beginPath();
    ctx.moveTo(x1, yScale(minCE));
    ctx.lineTo(x1, yScale(q1CE));
    ctx.moveTo(x1, yScale(maxCE));
    ctx.lineTo(x1, yScale(q3CE));
    ctx.moveTo(x1 - 20, yScale(minCE));
    ctx.lineTo(x1 + 20, yScale(minCE));
    ctx.moveTo(x1 - 20, yScale(maxCE));
    ctx.lineTo(x1 + 20, yScale(maxCE));
    ctx.stroke();

    // Random box
    const x2 = width - padding - 80;
    const minR = Math.min(...randomCV);
    const maxR = Math.max(...randomCV);
    const q1R = meanRandom - 2;
    const q3R = meanRandom + 2;

    ctx.fillStyle = '#8957e5';
    ctx.fillRect(x2 - boxWidth/2, yScale(q3R), boxWidth, yScale(q1R) - yScale(q3R));
    ctx.strokeStyle = '#a371f7';
    ctx.lineWidth = 2;
    ctx.strokeRect(x2 - boxWidth/2, yScale(q3R), boxWidth, yScale(q1R) - yScale(q3R));

    ctx.beginPath();
    ctx.moveTo(x2 - boxWidth/2, yScale(meanRandom));
    ctx.lineTo(x2 + boxWidth/2, yScale(meanRandom));
    ctx.stroke();

    ctx.beginPath();
    ctx.moveTo(x2, yScale(minR));
    ctx.lineTo(x2, yScale(q1R));
    ctx.moveTo(x2, yScale(maxR));
    ctx.lineTo(x2, yScale(q3R));
    ctx.moveTo(x2 - 20, yScale(minR));
    ctx.lineTo(x2 + 20, yScale(minR));
    ctx.moveTo(x2 - 20, yScale(maxR));
    ctx.lineTo(x2 + 20, yScale(maxR));
    ctx.stroke();

    // Labels
    ctx.fillStyle = '#c9d1d9';
    ctx.font = '14px Inter, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('Chain-End', x1, height - padding + 30);
    ctx.fillText('Random', x2, height - padding + 30);

    ctx.fillText(`${meanChainEnd.toFixed(1)}%`, x1, yScale(meanChainEnd) - 10);
    ctx.fillText(`${meanRandom.toFixed(1)}%`, x2, yScale(meanRandom) - 10);

    // Title
    ctx.font = 'bold 16px Inter, sans-serif';
    ctx.fillText('CV Comparison by Scission Type', width/2, 30);
  }

  function drawScatterPlot() {
    if (!scatterCanvas) return;
    const ctx = scatterCanvas.getContext('2d');
    if (!ctx) return;

    const width = scatterCanvas.width;
    const height = scatterCanvas.height;
    const padding = 60;

    ctx.fillStyle = '#0d1117';
    ctx.fillRect(0, 0, width, height);

    // Draw axes
    ctx.strokeStyle = '#30363d';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(padding, padding);
    ctx.lineTo(padding, height - padding);
    ctx.lineTo(width - padding, height - padding);
    ctx.stroke();

    // Scale functions
    const xScale = (v: number) => padding + (v / 30) * (width - 2 * padding);
    const yScale = (v: number) => height - padding - (v / 30) * (height - 2 * padding);

    // Grid and labels
    ctx.fillStyle = '#8b949e';
    ctx.font = '12px Inter, sans-serif';
    for (let i = 0; i <= 30; i += 5) {
      const x = xScale(i);
      const y = yScale(i);

      ctx.textAlign = 'center';
      ctx.fillText(`${i}`, x, height - padding + 20);
      ctx.textAlign = 'right';
      ctx.fillText(`${i}`, padding - 10, y + 4);

      ctx.beginPath();
      ctx.strokeStyle = '#21262d';
      ctx.moveTo(x, padding);
      ctx.lineTo(x, height - padding);
      ctx.moveTo(padding, y);
      ctx.lineTo(width - padding, y);
      ctx.stroke();
    }

    // Perfect prediction line
    ctx.strokeStyle = '#f0883e';
    ctx.lineWidth = 2;
    ctx.setLineDash([5, 5]);
    ctx.beginPath();
    ctx.moveTo(xScale(0), yScale(0));
    ctx.lineTo(xScale(30), yScale(30));
    ctx.stroke();
    ctx.setLineDash([]);

    // Plot points
    for (const p of computedData) {
      const x = xScale(p.cv);
      const y = yScale(p.cvPredicted);

      ctx.beginPath();
      ctx.arc(x, y, 8, 0, Math.PI * 2);
      ctx.fillStyle = p.type === 'chain_end' ? '#3fb950' : '#a371f7';
      ctx.fill();
      ctx.strokeStyle = p.type === 'chain_end' ? '#238636' : '#8957e5';
      ctx.lineWidth = 2;
      ctx.stroke();
    }

    // Axis labels
    ctx.fillStyle = '#c9d1d9';
    ctx.font = '14px Inter, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('Observed CV (%)', width/2, height - 10);

    ctx.save();
    ctx.translate(20, height/2);
    ctx.rotate(-Math.PI/2);
    ctx.fillText('Predicted CV (%)', 0, 0);
    ctx.restore();

    // Title
    ctx.font = 'bold 16px Inter, sans-serif';
    ctx.fillText('Predicted vs Observed CV', width/2, 30);

    // Legend
    ctx.font = '12px Inter, sans-serif';
    ctx.fillStyle = '#3fb950';
    ctx.beginPath();
    ctx.arc(width - 120, 50, 6, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = '#c9d1d9';
    ctx.textAlign = 'left';
    ctx.fillText('Chain-End', width - 105, 54);

    ctx.fillStyle = '#a371f7';
    ctx.beginPath();
    ctx.arc(width - 120, 70, 6, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = '#c9d1d9';
    ctx.fillText('Random', width - 105, 74);
  }

  function drawCausalityCurve() {
    if (!curveCanvas) return;
    const ctx = curveCanvas.getContext('2d');
    if (!ctx) return;

    const width = curveCanvas.width;
    const height = curveCanvas.height;
    const padding = 60;

    ctx.fillStyle = '#0d1117';
    ctx.fillRect(0, 0, width, height);

    // Draw axes
    ctx.strokeStyle = '#30363d';
    ctx.lineWidth = 1;
    ctx.beginPath();
    ctx.moveTo(padding, padding);
    ctx.lineTo(padding, height - padding);
    ctx.lineTo(width - padding, height - padding);
    ctx.stroke();

    // Scale functions (log scale for x)
    const minOmega = 1;
    const maxOmega = 1000;
    const xScale = (v: number) => padding + (Math.log10(v) / 3) * (width - 2 * padding);
    const yScale = (v: number) => height - padding - v * (height - 2 * padding);

    // Grid and labels
    ctx.fillStyle = '#8b949e';
    ctx.font = '12px Inter, sans-serif';
    ctx.textAlign = 'center';

    for (const omega of [1, 10, 100, 1000]) {
      const x = xScale(omega);
      ctx.fillText(`${omega}`, x, height - padding + 20);
      ctx.beginPath();
      ctx.strokeStyle = '#21262d';
      ctx.moveTo(x, padding);
      ctx.lineTo(x, height - padding);
      ctx.stroke();
    }

    ctx.textAlign = 'right';
    for (let c = 0; c <= 1; c += 0.2) {
      const y = yScale(c);
      ctx.fillText(c.toFixed(1), padding - 10, y + 4);
      ctx.beginPath();
      ctx.moveTo(padding, y);
      ctx.lineTo(width - padding, y);
      ctx.stroke();
    }

    // Draw causality curve
    ctx.strokeStyle = '#4a9eff';
    ctx.lineWidth = 3;
    ctx.beginPath();

    for (let omega = minOmega; omega <= maxOmega; omega *= 1.1) {
      const omegaEff = omegaEffective(omega);
      const C = causality(omegaEff);
      const x = xScale(omega);
      const y = yScale(C);

      if (omega === minOmega) {
        ctx.moveTo(x, y);
      } else {
        ctx.lineTo(x, y);
      }
    }
    ctx.stroke();

    // Polya reference point
    const polyaOmega = 106;
    const polyaC = 0.3405;
    ctx.fillStyle = '#f0883e';
    ctx.beginPath();
    ctx.arc(xScale(polyaOmega), yScale(polyaC), 8, 0, Math.PI * 2);
    ctx.fill();

    ctx.fillStyle = '#c9d1d9';
    ctx.font = '12px Inter, sans-serif';
    ctx.textAlign = 'left';
    ctx.fillText('Polya (0.3405)', xScale(polyaOmega) + 12, yScale(polyaC) + 4);

    // Axis labels
    ctx.font = '14px Inter, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText('Omega (log scale)', width/2, height - 10);

    ctx.save();
    ctx.translate(20, height/2);
    ctx.rotate(-Math.PI/2);
    ctx.fillText('Causality C', 0, 0);
    ctx.restore();

    // Title
    ctx.font = 'bold 16px Inter, sans-serif';
    ctx.fillText('Entropic Causality: C = Omega^(-ln(2)/3)', width/2, 30);
  }
</script>

<div class="entropic-dashboard">
  <header>
    <h1>Entropic Causality Explorer</h1>
    <p class="subtitle">C = Omega^(-ln(2)/d) - Interactive Analysis Dashboard</p>
  </header>

  <div class="controls">
    <div class="control-group">
      <label>Alpha (accessibility)</label>
      <input type="range" min="0.01" max="0.2" step="0.005" bind:value={alpha} />
      <span class="value">{alpha.toFixed(3)}</span>
    </div>
    <div class="control-group">
      <label>Omega Max (saturation)</label>
      <input type="range" min="2" max="10" step="0.1" bind:value={omegaMax} />
      <span class="value">{omegaMax.toFixed(2)}</span>
    </div>
    <div class="control-group">
      <label>Lambda (exponent)</label>
      <input type="range" min="0.1" max="0.5" step="0.01" bind:value={lambda} />
      <span class="value">{lambda.toFixed(3)} (theory: {(Math.log(2)/3).toFixed(3)})</span>
    </div>
  </div>

  <div class="stats-row">
    <div class="stat-card chain-end">
      <h3>Chain-End Scission</h3>
      <div class="stat-value">{meanChainEnd.toFixed(1)}%</div>
      <div class="stat-label">Mean CV</div>
    </div>
    <div class="stat-card random">
      <h3>Random Scission</h3>
      <div class="stat-value">{meanRandom.toFixed(1)}%</div>
      <div class="stat-label">Mean CV</div>
    </div>
    <div class="stat-card error">
      <h3>Model Error</h3>
      <div class="stat-value">{meanError.toFixed(1)}%</div>
      <div class="stat-label">Mean Absolute Error</div>
    </div>
    <div class="stat-card polya">
      <h3>Polya Coincidence</h3>
      <div class="stat-value">{(Math.pow(106, -lambda)).toFixed(3)}</div>
      <div class="stat-label">C at Omega=106 (Polya: 0.3405)</div>
    </div>
  </div>

  <div class="charts-grid">
    <div class="chart-container">
      <canvas bind:this={cvComparisonCanvas} width="400" height="350"></canvas>
    </div>
    <div class="chart-container">
      <canvas bind:this={scatterCanvas} width="400" height="350"></canvas>
    </div>
    <div class="chart-container full-width">
      <canvas bind:this={curveCanvas} width="850" height="350"></canvas>
    </div>
  </div>

  <div class="data-table">
    <h2>Polymer Dataset</h2>
    <table>
      <thead>
        <tr>
          <th>Polymer</th>
          <th>Mechanism</th>
          <th>Omega Raw</th>
          <th>Omega Eff</th>
          <th>CV Observed</th>
          <th>CV Predicted</th>
          <th>Error</th>
        </tr>
      </thead>
      <tbody>
        {#each computedData as row}
          <tr class={row.type}>
            <td>{row.name}</td>
            <td>{row.type}</td>
            <td>{row.omega}</td>
            <td>{row.omegaEff.toFixed(2)}</td>
            <td>{row.cv.toFixed(1)}%</td>
            <td>{row.cvPredicted.toFixed(1)}%</td>
            <td class:low-error={row.error < 3} class:high-error={row.error > 5}>
              {row.error.toFixed(1)}%
            </td>
          </tr>
        {/each}
      </tbody>
    </table>
  </div>

  <div class="formula-box">
    <h3>The Entropic Causality Law</h3>
    <div class="formula">C = Omega_eff^(-ln(2)/d)</div>
    <div class="explanation">
      <p><strong>Omega_eff</strong> = min(alpha * Omega_raw, Omega_max)</p>
      <p><strong>CV</strong> = baseline * (1 - C)</p>
      <p><strong>Physical meaning:</strong> More ways to degrade = less predictable outcome</p>
    </div>
  </div>
</div>

<style>
  .entropic-dashboard {
    padding: 2rem;
    max-width: 1200px;
    margin: 0 auto;
    color: var(--text-primary, #c9d1d9);
  }

  header {
    text-align: center;
    margin-bottom: 2rem;
  }

  h1 {
    font-size: 2rem;
    color: var(--primary, #4a9eff);
    margin-bottom: 0.5rem;
  }

  .subtitle {
    color: var(--text-secondary, #8b949e);
    font-family: 'JetBrains Mono', monospace;
  }

  .controls {
    display: flex;
    gap: 2rem;
    flex-wrap: wrap;
    margin-bottom: 2rem;
    padding: 1.5rem;
    background: var(--bg-secondary, #161b22);
    border-radius: 8px;
    border: 1px solid var(--border, #30363d);
  }

  .control-group {
    flex: 1;
    min-width: 200px;
  }

  .control-group label {
    display: block;
    margin-bottom: 0.5rem;
    font-weight: 500;
    color: var(--text-secondary, #8b949e);
  }

  .control-group input[type="range"] {
    width: 100%;
    accent-color: var(--primary, #4a9eff);
  }

  .control-group .value {
    display: block;
    margin-top: 0.25rem;
    font-family: 'JetBrains Mono', monospace;
    font-size: 0.875rem;
  }

  .stats-row {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 1rem;
    margin-bottom: 2rem;
  }

  .stat-card {
    background: var(--bg-secondary, #161b22);
    border-radius: 8px;
    padding: 1.5rem;
    text-align: center;
    border: 1px solid var(--border, #30363d);
  }

  .stat-card h3 {
    font-size: 0.875rem;
    color: var(--text-secondary, #8b949e);
    margin-bottom: 0.5rem;
  }

  .stat-card .stat-value {
    font-size: 2rem;
    font-weight: bold;
    font-family: 'JetBrains Mono', monospace;
  }

  .stat-card .stat-label {
    font-size: 0.75rem;
    color: var(--text-secondary, #8b949e);
  }

  .stat-card.chain-end .stat-value { color: #3fb950; }
  .stat-card.random .stat-value { color: #a371f7; }
  .stat-card.error .stat-value { color: #f0883e; }
  .stat-card.polya .stat-value { color: #4a9eff; }

  .charts-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 1rem;
    margin-bottom: 2rem;
  }

  .chart-container {
    background: var(--bg-secondary, #161b22);
    border-radius: 8px;
    padding: 1rem;
    border: 1px solid var(--border, #30363d);
  }

  .chart-container.full-width {
    grid-column: 1 / -1;
  }

  .chart-container canvas {
    width: 100%;
    height: auto;
  }

  .data-table {
    background: var(--bg-secondary, #161b22);
    border-radius: 8px;
    padding: 1.5rem;
    margin-bottom: 2rem;
    border: 1px solid var(--border, #30363d);
    overflow-x: auto;
  }

  .data-table h2 {
    margin-bottom: 1rem;
    font-size: 1.25rem;
  }

  table {
    width: 100%;
    border-collapse: collapse;
    font-family: 'JetBrains Mono', monospace;
    font-size: 0.875rem;
  }

  th, td {
    padding: 0.75rem;
    text-align: left;
    border-bottom: 1px solid var(--border, #30363d);
  }

  th {
    color: var(--text-secondary, #8b949e);
    font-weight: 500;
  }

  tr.chain_end td:first-child { border-left: 3px solid #3fb950; }
  tr.random td:first-child { border-left: 3px solid #a371f7; }

  .low-error { color: #3fb950; }
  .high-error { color: #f85149; }

  .formula-box {
    background: linear-gradient(135deg, #161b22 0%, #1c2128 100%);
    border-radius: 8px;
    padding: 2rem;
    text-align: center;
    border: 1px solid var(--primary, #4a9eff);
  }

  .formula-box h3 {
    margin-bottom: 1rem;
    color: var(--primary, #4a9eff);
  }

  .formula {
    font-size: 1.5rem;
    font-family: 'JetBrains Mono', monospace;
    color: #f0883e;
    margin-bottom: 1.5rem;
  }

  .explanation {
    text-align: left;
    max-width: 500px;
    margin: 0 auto;
  }

  .explanation p {
    margin: 0.5rem 0;
    color: var(--text-secondary, #8b949e);
  }

  .explanation strong {
    color: var(--text-primary, #c9d1d9);
  }

  @media (max-width: 768px) {
    .charts-grid {
      grid-template-columns: 1fr;
    }

    .controls {
      flex-direction: column;
    }
  }
</style>
