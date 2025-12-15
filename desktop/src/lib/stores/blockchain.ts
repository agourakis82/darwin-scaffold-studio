import { writable, derived } from 'svelte/store';

export interface BlockData {
  type: string;
  experimentType?: string;
  parameters?: Record<string, number | string>;
  results?: Record<string, number | string>;
  reproducible?: boolean;
  dataLocation?: string;  // IPFS CID
  researcherId?: string;
  platform?: string;
  version?: string;
}

export interface ResearchBlock {
  index: number;
  timestamp: number;  // Unix timestamp
  data: BlockData;
  previousHash: string;
  hash: string;
  signature: string;
}

export interface VerificationResult {
  valid: boolean;
  message: string;
  invalidBlockIndex?: number;
}

export interface BlockchainState {
  chain: ResearchBlock[];
  selectedBlock: number | null;
  verification: VerificationResult | null;
  isLoading: boolean;
  isVerifying: boolean;
  error: string | null;
}

const initialState: BlockchainState = {
  chain: [],
  selectedBlock: null,
  verification: null,
  isLoading: false,
  isVerifying: false,
  error: null,
};

function createBlockchainStore() {
  const { subscribe, set, update } = writable<BlockchainState>(initialState);

  return {
    subscribe,
    reset: () => set(initialState),

    startLoading: () => update(state => ({
      ...state,
      isLoading: true,
      error: null,
    })),

    setChain: (chain: ResearchBlock[]) => update(state => ({
      ...state,
      chain,
      isLoading: false,
    })),

    addBlock: (block: ResearchBlock) => update(state => ({
      ...state,
      chain: [...state.chain, block],
    })),

    selectBlock: (index: number | null) => update(state => ({
      ...state,
      selectedBlock: index,
    })),

    startVerification: () => update(state => ({
      ...state,
      isVerifying: true,
    })),

    setVerification: (verification: VerificationResult) => update(state => ({
      ...state,
      verification,
      isVerifying: false,
    })),

    setError: (error: string) => update(state => ({
      ...state,
      isLoading: false,
      isVerifying: false,
      error,
    })),
  };
}

export const blockchain = createBlockchainStore();

// Derived stores
export const chain = derived(blockchain, $b => $b.chain);
export const selectedBlock = derived(blockchain, $b =>
  $b.selectedBlock !== null ? $b.chain.find(b => b.index === $b.selectedBlock) : null
);
export const chainLength = derived(blockchain, $b => $b.chain.length);

// Helper to format timestamp
export function formatTimestamp(timestamp: number): string {
  return new Date(timestamp * 1000).toLocaleString();
}

// Helper to truncate hash
export function truncateHash(hash: string, length: number = 8): string {
  if (hash.length <= length * 2) return hash;
  return `${hash.slice(0, length)}...${hash.slice(-length)}`;
}

// Helper to get block type icon
export function getBlockTypeIcon(type: string): string {
  switch (type) {
    case 'experiment': return 'flask';
    case 'design': return 'grid';
    case 'analysis': return 'bar-chart';
    case 'fabrication': return 'printer';
    default: return 'box';
  }
}

// Helper to get block color by type
export function getBlockColor(type: string): string {
  switch (type) {
    case 'experiment': return '#8b5cf6';
    case 'design': return '#3b82f6';
    case 'analysis': return '#10b981';
    case 'fabrication': return '#f59e0b';
    default: return '#6b7280';
  }
}
