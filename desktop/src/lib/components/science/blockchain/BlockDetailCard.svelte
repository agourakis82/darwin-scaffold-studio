<script lang="ts">
  import type { ResearchBlock } from '$lib/stores/blockchain';
  import { formatTimestamp, truncateHash, getBlockColor } from '$lib/stores/blockchain';

  export let block: ResearchBlock | null = null;

  function copyToClipboard(text: string) {
    navigator.clipboard.writeText(text);
  }
</script>

<div class="detail-card">
  <h3 class="title">Block Details</h3>

  {#if block}
    {@const blockType = block.data.type || 'unknown'}
    <div class="block-info">
      <div class="info-header">
        <span class="block-number">Block #{block.index}</span>
        <span class="block-badge" style="background: {getBlockColor(blockType)}">
          {blockType}
        </span>
      </div>

      <div class="info-section">
        <h4>Hashes</h4>
        <div class="hash-row">
          <span class="hash-label">Current</span>
          <div class="hash-value">
            <code>{truncateHash(block.hash, 12)}</code>
            <button class="copy-btn" on:click={() => copyToClipboard(block.hash)} title="Copy full hash">
              <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                <rect x="9" y="9" width="13" height="13" rx="2" ry="2"></rect>
                <path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"></path>
              </svg>
            </button>
          </div>
        </div>
        <div class="hash-row">
          <span class="hash-label">Previous</span>
          <div class="hash-value">
            <code>{block.index === 0 ? 'Genesis (none)' : truncateHash(block.previousHash, 12)}</code>
          </div>
        </div>
      </div>

      <div class="info-section">
        <h4>Metadata</h4>
        <div class="meta-grid">
          <div class="meta-item">
            <span class="meta-label">Timestamp</span>
            <span class="meta-value">{formatTimestamp(block.timestamp)}</span>
          </div>
          {#if block.data.researcherId}
            <div class="meta-item">
              <span class="meta-label">Researcher</span>
              <span class="meta-value">{block.data.researcherId}</span>
            </div>
          {/if}
          {#if block.data.platform}
            <div class="meta-item">
              <span class="meta-label">Platform</span>
              <span class="meta-value">{block.data.platform}</span>
            </div>
          {/if}
          {#if block.data.version}
            <div class="meta-item">
              <span class="meta-label">Version</span>
              <span class="meta-value">{block.data.version}</span>
            </div>
          {/if}
        </div>
      </div>

      {#if block.data.parameters}
        <div class="info-section">
          <h4>Parameters</h4>
          <div class="params-list">
            {#each Object.entries(block.data.parameters) as [key, value]}
              <div class="param-row">
                <span class="param-key">{key}</span>
                <span class="param-value">{typeof value === 'number' ? value.toFixed(3) : value}</span>
              </div>
            {/each}
          </div>
        </div>
      {/if}

      {#if block.data.results}
        <div class="info-section">
          <h4>Results</h4>
          <div class="params-list">
            {#each Object.entries(block.data.results) as [key, value]}
              <div class="param-row">
                <span class="param-key">{key}</span>
                <span class="param-value">{typeof value === 'number' ? value.toFixed(3) : value}</span>
              </div>
            {/each}
          </div>
        </div>
      {/if}

      {#if block.data.dataLocation}
        <div class="info-section">
          <h4>Data Storage</h4>
          <div class="storage-info">
            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polyline points="22 12 16 12 14 15 10 15 8 12 2 12"></polyline>
              <path d="M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"></path>
            </svg>
            <code class="ipfs-cid">{block.data.dataLocation}</code>
          </div>
        </div>
      {/if}

      <div class="info-section">
        <h4>Signature</h4>
        <div class="signature-display">
          <code>{truncateHash(block.signature, 16)}</code>
          <span class="verified-badge">
            <svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
              <polyline points="22 4 12 14.01 9 11.01"></polyline>
            </svg>
            Verified
          </span>
        </div>
      </div>
    </div>
  {:else}
    <div class="no-selection">
      <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
        <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
        <circle cx="8.5" cy="8.5" r="1.5"></circle>
        <polyline points="21 15 16 10 5 21"></polyline>
      </svg>
      <p>No block selected</p>
      <p class="hint">Click on a block in the timeline to view details</p>
    </div>
  {/if}
</div>

<style>
  .detail-card {
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

  .block-info {
    display: flex;
    flex-direction: column;
    gap: 16px;
  }

  .info-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .block-number {
    font-size: 18px;
    font-weight: 700;
    color: var(--text-primary);
  }

  .block-badge {
    padding: 4px 10px;
    border-radius: 12px;
    font-size: 11px;
    font-weight: 600;
    color: white;
    text-transform: uppercase;
  }

  .info-section {
    padding: 12px;
    background: var(--bg-tertiary);
    border-radius: 8px;
  }

  .info-section h4 {
    font-size: 11px;
    font-weight: 600;
    color: var(--text-muted);
    margin: 0 0 10px 0;
    text-transform: uppercase;
  }

  .hash-row {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 8px;
  }

  .hash-row:last-child {
    margin-bottom: 0;
  }

  .hash-label {
    font-size: 11px;
    color: var(--text-muted);
  }

  .hash-value {
    display: flex;
    align-items: center;
    gap: 6px;
  }

  .hash-value code {
    font-size: 11px;
    font-family: var(--font-mono);
    color: var(--text-secondary);
    background: var(--bg-primary);
    padding: 2px 6px;
    border-radius: 4px;
  }

  .copy-btn {
    background: none;
    border: none;
    padding: 4px;
    cursor: pointer;
    color: var(--text-muted);
    border-radius: 4px;
    transition: all var(--transition-fast);
  }

  .copy-btn:hover {
    background: var(--bg-primary);
    color: var(--text-primary);
  }

  .meta-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 10px;
  }

  .meta-item {
    display: flex;
    flex-direction: column;
    gap: 2px;
  }

  .meta-label {
    font-size: 10px;
    color: var(--text-muted);
  }

  .meta-value {
    font-size: 12px;
    color: var(--text-primary);
  }

  .params-list {
    display: flex;
    flex-direction: column;
    gap: 6px;
  }

  .param-row {
    display: flex;
    justify-content: space-between;
    font-size: 12px;
  }

  .param-key {
    color: var(--text-muted);
  }

  .param-value {
    color: var(--text-primary);
    font-family: var(--font-mono);
  }

  .storage-info {
    display: flex;
    align-items: center;
    gap: 8px;
    color: var(--text-muted);
  }

  .ipfs-cid {
    font-size: 11px;
    font-family: var(--font-mono);
    color: var(--text-secondary);
  }

  .signature-display {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .signature-display code {
    font-size: 11px;
    font-family: var(--font-mono);
    color: var(--text-secondary);
  }

  .verified-badge {
    display: flex;
    align-items: center;
    gap: 4px;
    font-size: 11px;
    color: var(--success);
  }

  .no-selection {
    padding: 32px;
    text-align: center;
    color: var(--text-muted);
  }

  .no-selection svg {
    opacity: 0.5;
    margin-bottom: 12px;
  }

  .no-selection p {
    margin: 0;
    font-size: 13px;
  }

  .no-selection .hint {
    font-size: 12px;
    margin-top: 4px;
  }
</style>
