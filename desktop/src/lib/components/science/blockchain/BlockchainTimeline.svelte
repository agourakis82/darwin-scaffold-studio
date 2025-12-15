<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import type { ResearchBlock } from '$lib/stores/blockchain';
  import { formatTimestamp, truncateHash, getBlockColor } from '$lib/stores/blockchain';

  export let chain: ResearchBlock[] = [];
  export let selectedBlock: number | null = null;

  const dispatch = createEventDispatcher<{ select: number }>();

  function handleBlockClick(index: number) {
    dispatch('select', index);
  }

  function getTimeDiff(current: ResearchBlock, previous: ResearchBlock | null): string {
    if (!previous) return 'Genesis';
    const diff = current.timestamp - previous.timestamp;
    if (diff < 60) return `${Math.round(diff)}s ago`;
    if (diff < 3600) return `${Math.round(diff / 60)}m ago`;
    if (diff < 86400) return `${Math.round(diff / 3600)}h ago`;
    return `${Math.round(diff / 86400)}d ago`;
  }
</script>

<div class="timeline">
  <div class="timeline-header">
    <h3>Provenance Chain</h3>
    <span class="block-count">{chain.length} blocks</span>
  </div>

  {#if chain.length > 0}
    <div class="timeline-scroll">
      {#each chain as block, i}
        {@const prevBlock = i > 0 ? chain[i - 1] : null}
        {@const blockType = block.data.type || 'unknown'}
        <button
          class="timeline-block"
          class:selected={selectedBlock === block.index}
          class:genesis={i === 0}
          on:click={() => handleBlockClick(block.index)}
        >
          <div class="block-connector">
            {#if i > 0}
              <div class="connector-line"></div>
            {/if}
            <div class="connector-dot" style="background: {getBlockColor(blockType)}"></div>
          </div>

          <div class="block-content">
            <div class="block-header">
              <span class="block-index">#{block.index}</span>
              <span class="block-type" style="background: {getBlockColor(blockType)}20; color: {getBlockColor(blockType)}">
                {blockType}
              </span>
            </div>

            <div class="block-hash">
              <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
                <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
              </svg>
              <span>{truncateHash(block.hash, 6)}</span>
            </div>

            <div class="block-meta">
              <span class="timestamp">{formatTimestamp(block.timestamp)}</span>
              <span class="time-diff">{getTimeDiff(block, prevBlock)}</span>
            </div>

            {#if block.data.experimentType}
              <div class="experiment-type">
                {block.data.experimentType}
              </div>
            {/if}
          </div>
        </button>
      {/each}
    </div>
  {:else}
    <div class="no-blocks">
      <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
        <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
        <line x1="3" y1="9" x2="21" y2="9"></line>
        <line x1="9" y1="21" x2="9" y2="9"></line>
      </svg>
      <p>No blocks in chain</p>
      <p class="hint">Create experiments to build provenance history</p>
    </div>
  {/if}
</div>

<style>
  .timeline {
    background: var(--bg-secondary);
    border-radius: 12px;
    padding: 16px;
    height: 100%;
    display: flex;
    flex-direction: column;
  }

  .timeline-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16px;
  }

  .timeline-header h3 {
    font-size: 14px;
    font-weight: 600;
    color: var(--text-primary);
    margin: 0;
  }

  .block-count {
    font-size: 12px;
    color: var(--text-muted);
    padding: 4px 8px;
    background: var(--bg-tertiary);
    border-radius: 12px;
  }

  .timeline-scroll {
    flex: 1;
    overflow-y: auto;
    display: flex;
    flex-direction: column;
    gap: 0;
  }

  .timeline-block {
    display: flex;
    gap: 12px;
    padding: 12px;
    background: transparent;
    border: none;
    text-align: left;
    cursor: pointer;
    border-radius: 8px;
    transition: all var(--transition-fast);
  }

  .timeline-block:hover {
    background: var(--bg-tertiary);
  }

  .timeline-block.selected {
    background: rgba(74, 158, 255, 0.1);
    border: 1px solid var(--primary);
  }

  .block-connector {
    display: flex;
    flex-direction: column;
    align-items: center;
    width: 20px;
    flex-shrink: 0;
  }

  .connector-line {
    width: 2px;
    height: 20px;
    background: var(--border-color);
    margin-bottom: -4px;
  }

  .connector-dot {
    width: 12px;
    height: 12px;
    border-radius: 50%;
    border: 2px solid var(--bg-secondary);
    box-shadow: 0 0 0 2px var(--border-color);
  }

  .timeline-block.genesis .connector-dot {
    width: 16px;
    height: 16px;
  }

  .block-content {
    flex: 1;
    min-width: 0;
  }

  .block-header {
    display: flex;
    align-items: center;
    gap: 8px;
    margin-bottom: 6px;
  }

  .block-index {
    font-size: 14px;
    font-weight: 600;
    color: var(--text-primary);
  }

  .block-type {
    font-size: 10px;
    font-weight: 600;
    padding: 2px 6px;
    border-radius: 4px;
    text-transform: uppercase;
  }

  .block-hash {
    display: flex;
    align-items: center;
    gap: 4px;
    font-size: 11px;
    font-family: var(--font-mono);
    color: var(--text-muted);
    margin-bottom: 6px;
  }

  .block-meta {
    display: flex;
    justify-content: space-between;
    font-size: 10px;
    color: var(--text-muted);
  }

  .time-diff {
    color: var(--text-secondary);
  }

  .experiment-type {
    margin-top: 6px;
    font-size: 11px;
    color: var(--text-secondary);
    padding: 4px 8px;
    background: var(--bg-primary);
    border-radius: 4px;
    display: inline-block;
  }

  .no-blocks {
    flex: 1;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    color: var(--text-muted);
    text-align: center;
  }

  .no-blocks svg {
    opacity: 0.5;
    margin-bottom: 12px;
  }

  .no-blocks p {
    margin: 0;
    font-size: 13px;
  }

  .no-blocks .hint {
    font-size: 12px;
    margin-top: 4px;
  }
</style>
