// Julia server connection state
import { writable, derived } from 'svelte/store';

// Connection status
export const juliaConnected = writable<boolean>(false);
export const juliaStatus = writable<'connected' | 'disconnected' | 'connecting'>('disconnected');

// Server URL
export const juliaServerUrl = writable<string>('http://localhost:8081');

// Operation progress
export interface OperationProgress {
  id: string;
  message: string;
  percent: number;
  status: 'running' | 'completed' | 'error';
}

export const operationProgress = writable<OperationProgress | null>(null);

// Pending operations queue
export const pendingOperations = writable<string[]>([]);

// Derived: Is busy
export const isBusy = derived(
  [operationProgress, pendingOperations],
  ([$progress, $pending]) => {
    return $progress !== null || $pending.length > 0;
  }
);

// Actions
export function setConnected(connected: boolean) {
  juliaConnected.set(connected);
}

export function setProgress(progress: OperationProgress | null) {
  operationProgress.set(progress);
}

export function addPendingOperation(id: string) {
  pendingOperations.update((ops) => [...ops, id]);
}

export function removePendingOperation(id: string) {
  pendingOperations.update((ops) => ops.filter((op) => op !== id));
}

// Check server health
export async function checkConnection(): Promise<boolean> {
  try {
    const response = await fetch('http://localhost:8081/health');
    const connected = response.ok;
    juliaConnected.set(connected);
    return connected;
  } catch {
    juliaConnected.set(false);
    return false;
  }
}
