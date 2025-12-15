<script lang="ts">
  export let value: number = 0;
  export let max: number = 100;
  export let size: number = 100;
  export let strokeWidth: number = 8;
  export let color: string = 'var(--primary)';

  $: percentage = Math.min(100, Math.max(0, (value / max) * 100));
  $: radius = (size - strokeWidth) / 2;
  $: circumference = 2 * Math.PI * radius;
  $: offset = circumference - (percentage / 100) * circumference;
</script>

<svg
  class="progress-ring"
  width={size}
  height={size}
  viewBox="0 0 {size} {size}"
>
  <!-- Background circle -->
  <circle
    class="progress-ring-bg"
    cx={size / 2}
    cy={size / 2}
    r={radius}
    stroke-width={strokeWidth}
  />

  <!-- Progress circle -->
  <circle
    class="progress-ring-progress"
    cx={size / 2}
    cy={size / 2}
    r={radius}
    stroke-width={strokeWidth}
    stroke={color}
    stroke-dasharray={circumference}
    stroke-dashoffset={offset}
    stroke-linecap="round"
  />
</svg>

<style>
  .progress-ring {
    transform: rotate(-90deg);
  }

  .progress-ring-bg {
    fill: none;
    stroke: var(--bg-tertiary);
  }

  .progress-ring-progress {
    fill: none;
    transition: stroke-dashoffset 0.5s ease;
  }
</style>
