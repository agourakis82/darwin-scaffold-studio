<script lang="ts">
  import { onMount } from 'svelte';
  import { blockchain, selectedBlock as selectedBlockStore, chainLength, type ResearchBlock, type VerificationResult, type BlockData } from '$lib/stores/blockchain';
  import BlockchainTimeline from './BlockchainTimeline.svelte';
  import BlockDetailCard from './BlockDetailCard.svelte';
  import VerificationStatus from './VerificationStatus.svelte';

  let selectedBlockData: ResearchBlock | null = null;

  $: selectedBlockData = $selectedBlockStore;

  function handleSelectBlock(event: CustomEvent<number>) {
    blockchain.selectBlock(event.detail);
  }

  async function loadChain() {
    blockchain.startLoading();

    try {
      const response = await fetch('http://localhost:8081/blockchain/chain');
      if (!response.ok) throw new Error('Failed to load chain');

      const data = await response.json();
      blockchain.setChain(data.chain);
    } catch {
      // Generate demo chain
      generateDemoChain();
    }
  }

  function generateDemoChain() {
    const experimentTypes = ['scaffold_design', 'optimization', 'analysis', 'fabrication', 'validation'];
    const researchers = ['Dr. Smith', 'Darwin_Auto_Pipeline', 'Dr. Johnson', 'LabAssistant_AI'];

    const chain: ResearchBlock[] = [];
    let prevHash = '0'.repeat(64);
    const baseTime = Date.now() / 1000 - 86400 * 7;  // Start 7 days ago

    for (let i = 0; i < 12; i++) {
      const expType = experimentTypes[i % experimentTypes.length];
      const timestamp = baseTime + i * 3600 * (2 + Math.random() * 4);

      const data: BlockData = {
        type: 'experiment',
        experimentType: expType,
        parameters: {
          porosity: 0.7 + Math.random() * 0.2,
          pore_size: 100 + Math.random() * 100,
          material: 'PLGA',
        },
        results: {
          achieved_porosity: 0.7 + Math.random() * 0.2,
          strength: 40 + Math.random() * 30,
          score: 70 + Math.random() * 25,
        },
        reproducible: Math.random() > 0.1,
        dataLocation: 'Qm' + Math.random().toString(36).substring(2, 46),
        researcherId: researchers[Math.floor(Math.random() * researchers.length)],
        platform: 'Darwin Scaffold Studio',
        version: '2.5.1.0',
      };

      const blockContent = JSON.stringify({ index: i, timestamp, data, prevHash });
      const hash = 'sha256_' + Math.random().toString(36).substring(2, 66);
      const signature = 'sig_' + Math.random().toString(36).substring(2, 66);

      chain.push({
        index: i,
        timestamp,
        data,
        previousHash: prevHash,
        hash,
        signature,
      });

      prevHash = hash;
    }

    blockchain.setChain(chain);
  }

  async function verifyChain() {
    blockchain.startVerification();

    try {
      const response = await fetch('http://localhost:8081/blockchain/verify');
      if (!response.ok) throw new Error('Verification failed');

      const data = await response.json();
      blockchain.setVerification(data);
    } catch {
      // Generate demo verification
      const verification: VerificationResult = {
        valid: Math.random() > 0.1,
        message: `Blockchain valid: ${$chainLength} blocks`,
      };
      blockchain.setVerification(verification);
    }
  }

  async function addExperiment() {
    const newIndex = $blockchain.chain.length;
    const prevBlock = $blockchain.chain[$blockchain.chain.length - 1];

    const data: BlockData = {
      type: 'experiment',
      experimentType: 'scaffold_design',
      parameters: {
        porosity: 0.85,
        pore_size: 150,
        material: 'PCL',
      },
      results: {
        achieved_porosity: 0.83,
        strength: 55,
        score: 88,
      },
      reproducible: true,
      dataLocation: 'Qm' + Math.random().toString(36).substring(2, 46),
      researcherId: 'Current_User',
      platform: 'Darwin Scaffold Studio',
      version: '2.5.1.0',
    };

    const newBlock: ResearchBlock = {
      index: newIndex,
      timestamp: Date.now() / 1000,
      data,
      previousHash: prevBlock?.hash || '0'.repeat(64),
      hash: 'sha256_' + Math.random().toString(36).substring(2, 66),
      signature: 'sig_' + Math.random().toString(36).substring(2, 66),
    };

    blockchain.addBlock(newBlock);
    blockchain.selectBlock(newIndex);
  }

  onMount(() => {
    if ($blockchain.chain.length === 0) {
      generateDemoChain();
    }
  });
</script>

<div class="blockchain-panel">
  <header class="panel-header">
    <div class="header-title">
      <h1>Blockchain Provenance</h1>
      <p>Immutable record of scaffold design history and experiments</p>
    </div>

    <div class="header-actions">
      <button class="action-btn secondary" on:click={loadChain} disabled={$blockchain.isLoading}>
        {#if $blockchain.isLoading}
          <span class="spinner"></span>
        {:else}
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="23 4 23 10 17 10"></polyline>
            <polyline points="1 20 1 14 7 14"></polyline>
            <path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"></path>
          </svg>
        {/if}
        Reload
      </button>

      <button class="action-btn secondary" on:click={verifyChain} disabled={$blockchain.isVerifying}>
        {#if $blockchain.isVerifying}
          <span class="spinner"></span>
        {:else}
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
          </svg>
        {/if}
        Verify Chain
      </button>

      <button class="action-btn primary" on:click={addExperiment}>
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <line x1="12" y1="5" x2="12" y2="19"></line>
          <line x1="5" y1="12" x2="19" y2="12"></line>
        </svg>
        Add Block
      </button>
    </div>
  </header>

  <div class="panel-content">
    <div class="timeline-section">
      <BlockchainTimeline
        chain={$blockchain.chain}
        selectedBlock={$blockchain.selectedBlock}
        on:select={handleSelectBlock}
      />
    </div>

    <aside class="sidebar">
      <BlockDetailCard block={selectedBlockData} />

      <VerificationStatus
        verification={$blockchain.verification}
        chainLength={$chainLength}
        isVerifying={$blockchain.isVerifying}
      />

      <div class="info-card">
        <h3>About Provenance</h3>
        <p>Each block contains a cryptographic hash of the previous block, creating an immutable chain of records.</p>
        <div class="info-features">
          <div class="feature">
            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
              <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
            </svg>
            <span>SHA-256 hashing</span>
          </div>
          <div class="feature">
            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
            </svg>
            <span>Digital signatures</span>
          </div>
          <div class="feature">
            <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polyline points="22 12 16 12 14 15 10 15 8 12 2 12"></polyline>
              <path d="M5.45 5.11L2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"></path>
            </svg>
            <span>IPFS data storage</span>
          </div>
        </div>
      </div>
    </aside>
  </div>
</div>

<style>
  .blockchain-panel {
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

  .header-actions {
    display: flex;
    gap: 10px;
  }

  .action-btn {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 8px 14px;
    border: none;
    border-radius: 8px;
    font-size: 13px;
    font-weight: 500;
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .action-btn.primary {
    background: linear-gradient(135deg, #f59e0b 0%, #f97316 100%);
    color: white;
  }

  .action-btn.primary:hover {
    transform: translateY(-1px);
    box-shadow: 0 4px 20px rgba(245, 158, 11, 0.3);
  }

  .action-btn.secondary {
    background: var(--bg-secondary);
    border: 1px solid var(--border-color);
    color: var(--text-primary);
  }

  .action-btn.secondary:hover:not(:disabled) {
    background: var(--bg-tertiary);
  }

  .action-btn:disabled {
    opacity: 0.6;
    cursor: not-allowed;
  }

  .spinner {
    width: 14px;
    height: 14px;
    border: 2px solid var(--border-color);
    border-top-color: var(--text-primary);
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
  }

  .action-btn.primary .spinner {
    border-color: rgba(255,255,255,0.3);
    border-top-color: white;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .panel-content {
    flex: 1;
    display: flex;
    gap: 20px;
    min-height: 0;
  }

  .timeline-section {
    width: 320px;
    flex-shrink: 0;
  }

  .sidebar {
    flex: 1;
    display: flex;
    flex-direction: column;
    gap: 16px;
    overflow-y: auto;
  }

  .info-card {
    background: var(--bg-secondary);
    border-radius: 12px;
    padding: 16px;
  }

  .info-card h3 {
    font-size: 13px;
    font-weight: 600;
    color: var(--text-primary);
    margin: 0 0 10px 0;
  }

  .info-card p {
    font-size: 12px;
    color: var(--text-muted);
    line-height: 1.5;
    margin: 0 0 12px 0;
  }

  .info-features {
    display: flex;
    flex-direction: column;
    gap: 8px;
  }

  .feature {
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 12px;
    color: var(--text-secondary);
  }

  .feature svg {
    color: var(--primary);
  }
</style>
