<script lang="ts">
  import type { VerificationResult } from '$lib/stores/blockchain';

  export let verification: VerificationResult | null = null;
  export let chainLength: number = 0;
  export let isVerifying: boolean = false;
</script>

<div class="verification-card">
  <h3 class="title">Chain Verification</h3>

  {#if isVerifying}
    <div class="verifying">
      <div class="spinner"></div>
      <span>Verifying blockchain integrity...</span>
    </div>
  {:else if verification}
    <div class="verification-result" class:valid={verification.valid} class:invalid={!verification.valid}>
      <div class="status-icon">
        {#if verification.valid}
          <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
            <polyline points="22 4 12 14.01 9 11.01"></polyline>
          </svg>
        {:else}
          <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="12" cy="12" r="10"></circle>
            <line x1="15" y1="9" x2="9" y2="15"></line>
            <line x1="9" y1="9" x2="15" y2="15"></line>
          </svg>
        {/if}
      </div>

      <div class="status-text">
        <span class="status-label">{verification.valid ? 'Chain Valid' : 'Chain Compromised'}</span>
        <span class="status-message">{verification.message}</span>
      </div>
    </div>

    {#if verification.valid}
      <div class="verification-details">
        <div class="detail-item">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <rect x="3" y="11" width="18" height="11" rx="2" ry="2"></rect>
            <path d="M7 11V7a5 5 0 0 1 10 0v4"></path>
          </svg>
          <span>All hashes verified</span>
        </div>
        <div class="detail-item">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"></path>
          </svg>
          <span>All signatures valid</span>
        </div>
        <div class="detail-item">
          <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="22 7 13.5 15.5 8.5 10.5 2 17"></polyline>
            <polyline points="16 7 22 7 22 13"></polyline>
          </svg>
          <span>{chainLength} blocks in chain</span>
        </div>
      </div>
    {:else}
      <div class="error-details">
        <span class="error-label">Issue detected:</span>
        {#if verification.invalidBlockIndex !== undefined}
          <span class="error-info">Block #{verification.invalidBlockIndex} has been tampered with</span>
        {:else}
          <span class="error-info">{verification.message}</span>
        {/if}
      </div>
    {/if}
  {:else}
    <div class="no-verification">
      <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
        <circle cx="12" cy="12" r="10"></circle>
        <line x1="12" y1="8" x2="12" y2="12"></line>
        <line x1="12" y1="16" x2="12.01" y2="16"></line>
      </svg>
      <p>Chain not verified</p>
      <p class="hint">Click "Verify Chain" to check integrity</p>
    </div>
  {/if}
</div>

<style>
  .verification-card {
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

  .verifying {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 20px;
    color: var(--text-muted);
    font-size: 13px;
  }

  .spinner {
    width: 20px;
    height: 20px;
    border: 2px solid var(--border-color);
    border-top-color: var(--primary);
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .verification-result {
    display: flex;
    align-items: center;
    gap: 16px;
    padding: 16px;
    border-radius: 10px;
    margin-bottom: 16px;
  }

  .verification-result.valid {
    background: rgba(16, 185, 129, 0.1);
  }

  .verification-result.invalid {
    background: rgba(239, 68, 68, 0.1);
  }

  .status-icon {
    flex-shrink: 0;
  }

  .verification-result.valid .status-icon {
    color: var(--success);
  }

  .verification-result.invalid .status-icon {
    color: var(--error);
  }

  .status-text {
    display: flex;
    flex-direction: column;
    gap: 4px;
  }

  .status-label {
    font-size: 16px;
    font-weight: 600;
  }

  .verification-result.valid .status-label {
    color: var(--success);
  }

  .verification-result.invalid .status-label {
    color: var(--error);
  }

  .status-message {
    font-size: 12px;
    color: var(--text-secondary);
  }

  .verification-details {
    display: flex;
    flex-direction: column;
    gap: 10px;
    padding: 12px;
    background: var(--bg-tertiary);
    border-radius: 8px;
  }

  .detail-item {
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 12px;
    color: var(--text-secondary);
  }

  .detail-item svg {
    color: var(--success);
  }

  .error-details {
    padding: 12px;
    background: rgba(239, 68, 68, 0.1);
    border-radius: 8px;
    border: 1px solid rgba(239, 68, 68, 0.2);
  }

  .error-label {
    display: block;
    font-size: 11px;
    font-weight: 600;
    color: var(--error);
    margin-bottom: 4px;
  }

  .error-info {
    font-size: 12px;
    color: var(--text-secondary);
  }

  .no-verification {
    padding: 24px;
    text-align: center;
    color: var(--text-muted);
  }

  .no-verification svg {
    opacity: 0.5;
    margin-bottom: 12px;
  }

  .no-verification p {
    margin: 0;
    font-size: 13px;
  }

  .no-verification .hint {
    font-size: 12px;
    margin-top: 4px;
  }
</style>
