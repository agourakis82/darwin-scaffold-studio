<script lang="ts">
  import { metrics, validation, metricsLoading } from '$lib/stores/metrics';
  import MetricCard from './MetricCard.svelte';
  import ProgressRing from '../shared/ProgressRing.svelte';

  $: overallScore = $validation?.overall_score ?? 0;
  $: scoreColor = overallScore >= 80 ? '#10b981' : overallScore >= 60 ? '#f59e0b' : '#ef4444';

  // Demo metrics for UI preview
  const demoMetrics = {
    porosity: { value: 82.5, target: '70-95%', valid: true, score: 85 },
    pore_size: { value: 215, target: '100-500 um', valid: true, score: 78 },
    interconnectivity: { value: 91.2, target: '>= 90%', valid: true, score: 92 },
    elastic_modulus: { value: 45.3, target: 'Tissue-specific', valid: true, score: 70 },
    tortuosity: { value: 1.18, target: '1.0-1.5', valid: true, score: 88 },
    permeability: { value: 2.4e-10, target: '>1e-11 m^2', valid: true, score: 75 },
  };

  const recommendations = [
    'Consider increasing porosity by 5-10% for improved cell infiltration',
    'Pore size distribution is optimal for osteoblast attachment',
  ];

  const citations = [
    'Murphy et al. 2010 - Biomaterials',
    'Karageorgiou & Kaplan 2005',
  ];
</script>

<div class="metrics-dashboard">
  <!-- Overall Score -->
  <div class="overall-score">
    <ProgressRing
      value={78}
      max={100}
      size={100}
      strokeWidth={8}
      color={scoreColor}
    />
    <div class="score-info">
      <span class="score-value">78</span>
      <span class="score-label">Q1 Score</span>
    </div>
  </div>

  <!-- Metric Cards -->
  <div class="metric-grid">
    <MetricCard
      label="Porosity"
      value={demoMetrics.porosity.value}
      unit="%"
      target={demoMetrics.porosity.target}
      valid={demoMetrics.porosity.valid}
      score={demoMetrics.porosity.score}
    />

    <MetricCard
      label="Pore Size"
      value={demoMetrics.pore_size.value}
      unit="um"
      target={demoMetrics.pore_size.target}
      valid={demoMetrics.pore_size.valid}
      score={demoMetrics.pore_size.score}
    />

    <MetricCard
      label="Interconnectivity"
      value={demoMetrics.interconnectivity.value}
      unit="%"
      target={demoMetrics.interconnectivity.target}
      valid={demoMetrics.interconnectivity.valid}
      score={demoMetrics.interconnectivity.score}
    />

    <MetricCard
      label="Elastic Modulus"
      value={demoMetrics.elastic_modulus.value}
      unit="MPa"
      target={demoMetrics.elastic_modulus.target}
      valid={demoMetrics.elastic_modulus.valid}
      score={demoMetrics.elastic_modulus.score}
    />

    <MetricCard
      label="Tortuosity"
      value={demoMetrics.tortuosity.value}
      unit=""
      target={demoMetrics.tortuosity.target}
      valid={demoMetrics.tortuosity.valid}
      score={demoMetrics.tortuosity.score}
    />

    <MetricCard
      label="Permeability"
      value={demoMetrics.permeability.value}
      unit="m^2"
      target={demoMetrics.permeability.target}
      valid={demoMetrics.permeability.valid}
      score={demoMetrics.permeability.score}
      scientific={true}
    />
  </div>

  <!-- Recommendations -->
  <div class="recommendations">
    <h4>Recommendations</h4>
    <ul>
      {#each recommendations as rec}
        <li>{rec}</li>
      {/each}
    </ul>
  </div>

  <!-- Citations -->
  <div class="citations">
    <h4>Literature References</h4>
    <ul>
      {#each citations as cite}
        <li>{cite}</li>
      {/each}
    </ul>
  </div>
</div>

<style>
  .metrics-dashboard {
    display: flex;
    flex-direction: column;
    gap: 16px;
    padding: 16px;
    height: 100%;
    overflow-y: auto;
  }

  .overall-score {
    display: flex;
    align-items: center;
    gap: 16px;
    padding: 16px;
    background: var(--bg-tertiary);
    border-radius: 12px;
  }

  .score-info {
    display: flex;
    flex-direction: column;
  }

  .score-value {
    font-size: 32px;
    font-weight: 700;
    background: linear-gradient(135deg, var(--primary), var(--secondary));
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
  }

  .score-label {
    font-size: 12px;
    color: var(--text-muted);
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }

  .metric-grid {
    display: grid;
    grid-template-columns: repeat(2, 1fr);
    gap: 8px;
  }

  .recommendations,
  .citations {
    padding: 12px;
    background: var(--bg-tertiary);
    border-radius: 8px;
  }

  .recommendations {
    border-left: 3px solid var(--warning);
  }

  .citations {
    border-left: 3px solid var(--info);
  }

  h4 {
    font-size: 11px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: var(--text-muted);
    margin-bottom: 8px;
  }

  ul {
    margin: 0;
    padding-left: 16px;
  }

  li {
    font-size: 12px;
    color: var(--text-secondary);
    margin-bottom: 4px;
  }
</style>
