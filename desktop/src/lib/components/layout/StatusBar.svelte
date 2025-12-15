<script lang="ts">
  import { scaffold, voxelSize } from '$lib/stores/scaffold';
  import { operationProgress } from '$lib/stores/julia';

  $: dimensions = $scaffold?.dimensions || [0, 0, 0];
  $: volumeMm = dimensions.map(d => (d * $voxelSize / 1000).toFixed(2));
</script>

<footer class="statusbar">
  <div class="status-left">
    {#if $operationProgress}
      <div class="progress-indicator">
        <div class="progress-bar">
          <div class="progress-fill" style="width: {$operationProgress.percent}%"></div>
        </div>
        <span class="progress-text">{$operationProgress.message}</span>
      </div>
    {:else}
      <span class="status-text">Ready</span>
    {/if}
  </div>

  <div class="status-center">
    {#if $scaffold}
      <span class="status-item">
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
        </svg>
        {dimensions[0]} x {dimensions[1]} x {dimensions[2]} voxels
      </span>
      <span class="status-divider">|</span>
      <span class="status-item">
        {volumeMm[0]} x {volumeMm[1]} x {volumeMm[2]} mm
      </span>
    {/if}
  </div>

  <div class="status-right">
    <span class="status-item">
      Voxel: {$voxelSize} um
    </span>
    <span class="status-divider">|</span>
    <span class="status-item version">
      v1.0.0
    </span>
  </div>
</footer>

<style>
  .statusbar {
    display: flex;
    align-items: center;
    justify-content: space-between;
    height: var(--statusbar-height);
    padding: 0 12px;
    background: var(--bg-tertiary);
    border-top: 1px solid var(--border-color);
    font-size: 11px;
    color: var(--text-muted);
  }

  .status-left,
  .status-center,
  .status-right {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .status-left {
    flex: 1;
  }

  .status-right {
    flex: 1;
    justify-content: flex-end;
  }

  .status-item {
    display: flex;
    align-items: center;
    gap: 4px;
  }

  .status-divider {
    color: var(--border-color);
  }

  .progress-indicator {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .progress-bar {
    width: 100px;
    height: 4px;
    background: var(--bg-primary);
    border-radius: 2px;
    overflow: hidden;
  }

  .progress-fill {
    height: 100%;
    background: var(--primary);
    border-radius: 2px;
    transition: width var(--transition-fast);
  }

  .progress-text {
    color: var(--text-secondary);
  }

  .version {
    font-family: var(--font-mono);
  }
</style>
