<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import * as d3 from 'd3';
  import type { AnnealingStep } from '$lib/stores/quantum';

  export let history: AnnealingStep[] = [];
  export let temperatureSchedule: number[] = [];
  export let width: number = 500;
  export let height: number = 250;

  let container: HTMLDivElement;
  let svg: d3.Selection<SVGSVGElement, unknown, null, undefined>;

  const margin = { top: 20, right: 60, bottom: 40, left: 60 };
  const innerWidth = width - margin.left - margin.right;
  const innerHeight = height - margin.top - margin.bottom;

  $: if (svg && history.length > 0) {
    updateChart();
  }

  onMount(() => {
    createChart();
  });

  function createChart() {
    svg = d3.select(container)
      .append('svg')
      .attr('width', width)
      .attr('height', height);

    // Main group
    const g = svg.append('g')
      .attr('transform', `translate(${margin.left},${margin.top})`);

    // Axes groups
    g.append('g').attr('class', 'x-axis').attr('transform', `translate(0,${innerHeight})`);
    g.append('g').attr('class', 'y-axis-energy');
    g.append('g').attr('class', 'y-axis-temp').attr('transform', `translate(${innerWidth},0)`);

    // Line paths
    g.append('path').attr('class', 'energy-line');
    g.append('path').attr('class', 'temp-line');

    // Labels
    svg.append('text')
      .attr('class', 'axis-label')
      .attr('x', margin.left + innerWidth / 2)
      .attr('y', height - 5)
      .attr('text-anchor', 'middle')
      .text('Iteration');

    svg.append('text')
      .attr('class', 'axis-label energy-label')
      .attr('transform', `rotate(-90)`)
      .attr('x', -(margin.top + innerHeight / 2))
      .attr('y', 15)
      .attr('text-anchor', 'middle')
      .text('Energy');

    svg.append('text')
      .attr('class', 'axis-label temp-label')
      .attr('transform', `rotate(90)`)
      .attr('x', margin.top + innerHeight / 2)
      .attr('y', -width + 15)
      .attr('text-anchor', 'middle')
      .text('Temperature');

    if (history.length > 0) updateChart();
  }

  function updateChart() {
    if (!svg || history.length === 0) return;

    const g = svg.select('g');

    // Scales
    const xScale = d3.scaleLinear()
      .domain([0, history.length - 1])
      .range([0, innerWidth]);

    const energyExtent = d3.extent(history, d => d.energy) as [number, number];
    const yEnergyScale = d3.scaleLinear()
      .domain([energyExtent[0] * 1.1, energyExtent[1] * 0.9])
      .range([innerHeight, 0]);

    const tempExtent = d3.extent(history, d => d.temperature) as [number, number];
    const yTempScale = d3.scaleLog()
      .domain([Math.max(0.0001, tempExtent[0]), tempExtent[1]])
      .range([innerHeight, 0]);

    // Axes
    g.select('.x-axis')
      .call(d3.axisBottom(xScale).ticks(5) as any);

    g.select('.y-axis-energy')
      .call(d3.axisLeft(yEnergyScale).ticks(5) as any);

    g.select('.y-axis-temp')
      .call(d3.axisRight(yTempScale).ticks(5, '.0e') as any);

    // Energy line
    const energyLine = d3.line<AnnealingStep>()
      .x((_, i) => xScale(i))
      .y(d => yEnergyScale(d.energy))
      .curve(d3.curveMonotoneX);

    g.select('.energy-line')
      .datum(history)
      .attr('d', energyLine)
      .attr('fill', 'none')
      .attr('stroke', '#3b82f6')
      .attr('stroke-width', 2);

    // Temperature line
    const tempLine = d3.line<AnnealingStep>()
      .x((_, i) => xScale(i))
      .y(d => yTempScale(Math.max(0.0001, d.temperature)))
      .curve(d3.curveMonotoneX);

    g.select('.temp-line')
      .datum(history)
      .attr('d', tempLine)
      .attr('fill', 'none')
      .attr('stroke', '#f59e0b')
      .attr('stroke-width', 2)
      .attr('stroke-dasharray', '4,2');

    // Accepted points
    const acceptedData = history.filter(d => d.accepted);

    const points = g.selectAll('.accepted-point')
      .data(acceptedData, (d: any) => d.iteration);

    points.exit().remove();

    points.enter()
      .append('circle')
      .attr('class', 'accepted-point')
      .attr('r', 3)
      .attr('fill', '#10b981')
      .merge(points as any)
      .attr('cx', d => xScale(d.iteration))
      .attr('cy', d => yEnergyScale(d.energy));
  }
</script>

<div class="energy-chart" bind:this={container}>
  {#if history.length === 0}
    <div class="no-data">
      <p>No annealing data</p>
      <p class="hint">Run optimization to see energy landscape</p>
    </div>
  {/if}
</div>

<div class="chart-legend">
  <div class="legend-item">
    <span class="legend-line energy"></span>
    <span>Energy</span>
  </div>
  <div class="legend-item">
    <span class="legend-line temp"></span>
    <span>Temperature</span>
  </div>
  <div class="legend-item">
    <span class="legend-dot"></span>
    <span>Accepted</span>
  </div>
</div>

<style>
  .energy-chart {
    background: var(--bg-secondary);
    border-radius: 12px;
    padding: 16px;
    position: relative;
  }

  .no-data {
    position: absolute;
    inset: 0;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    color: var(--text-muted);
  }

  .no-data p {
    margin: 0;
    font-size: 13px;
  }

  .no-data .hint {
    font-size: 12px;
    margin-top: 4px;
  }

  :global(.energy-chart .x-axis),
  :global(.energy-chart .y-axis-energy),
  :global(.energy-chart .y-axis-temp) {
    font-size: 10px;
    color: var(--text-muted);
  }

  :global(.energy-chart .x-axis line),
  :global(.energy-chart .x-axis path),
  :global(.energy-chart .y-axis-energy line),
  :global(.energy-chart .y-axis-energy path),
  :global(.energy-chart .y-axis-temp line),
  :global(.energy-chart .y-axis-temp path) {
    stroke: var(--border-color);
  }

  :global(.energy-chart .axis-label) {
    font-size: 11px;
    fill: var(--text-secondary);
  }

  :global(.energy-chart .energy-label) {
    fill: #3b82f6;
  }

  :global(.energy-chart .temp-label) {
    fill: #f59e0b;
  }

  .chart-legend {
    display: flex;
    justify-content: center;
    gap: 20px;
    margin-top: 12px;
  }

  .legend-item {
    display: flex;
    align-items: center;
    gap: 6px;
    font-size: 11px;
    color: var(--text-secondary);
  }

  .legend-line {
    width: 20px;
    height: 2px;
  }

  .legend-line.energy {
    background: #3b82f6;
  }

  .legend-line.temp {
    background: #f59e0b;
    background: repeating-linear-gradient(
      90deg,
      #f59e0b 0px,
      #f59e0b 4px,
      transparent 4px,
      transparent 6px
    );
  }

  .legend-dot {
    width: 8px;
    height: 8px;
    border-radius: 50%;
    background: #10b981;
  }
</style>
