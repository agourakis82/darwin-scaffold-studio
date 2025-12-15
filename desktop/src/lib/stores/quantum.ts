import { writable, derived } from 'svelte/store';

export interface QAOALayer {
  depth: number;
  gamma: number;  // Cost operator angle
  beta: number;   // Mixer operator angle
}

export interface QuantumSolution {
  binaryVector: number[];  // 0s and 1s
  energy: number;
  porosity: number;
  strength: number;
  poreMap: number[];
  quantumAdvantage: boolean;
}

export interface AnnealingStep {
  iteration: number;
  temperature: number;
  energy: number;
  accepted: boolean;
}

export interface QuantumState {
  targetPorosity: number;
  minStrength: number;
  numQubits: number;
  qaoaDepth: number;
  solution: QuantumSolution | null;
  annealingHistory: AnnealingStep[];
  temperatureSchedule: number[];
  qaoaLayers: QAOALayer[];
  isOptimizing: boolean;
  error: string | null;
}

const initialState: QuantumState = {
  targetPorosity: 0.7,
  minStrength: 50.0,
  numQubits: 50,
  qaoaDepth: 3,
  solution: null,
  annealingHistory: [],
  temperatureSchedule: [],
  qaoaLayers: [],
  isOptimizing: false,
  error: null,
};

function createQuantumStore() {
  const { subscribe, set, update } = writable<QuantumState>(initialState);

  return {
    subscribe,
    reset: () => set(initialState),

    setParameters: (params: Partial<Pick<QuantumState, 'targetPorosity' | 'minStrength' | 'numQubits' | 'qaoaDepth'>>) =>
      update(state => ({ ...state, ...params })),

    startOptimization: () => update(state => ({
      ...state,
      isOptimizing: true,
      error: null,
      solution: null,
      annealingHistory: [],
    })),

    setSolution: (solution: QuantumSolution, annealingHistory: AnnealingStep[], temperatureSchedule: number[]) =>
      update(state => ({
        ...state,
        solution,
        annealingHistory,
        temperatureSchedule,
        isOptimizing: false,
      })),

    setQAOALayers: (layers: QAOALayer[]) => update(state => ({
      ...state,
      qaoaLayers: layers,
    })),

    setError: (error: string) => update(state => ({
      ...state,
      isOptimizing: false,
      error,
    })),
  };
}

export const quantum = createQuantumStore();

// Derived stores
export const solution = derived(quantum, $q => $q.solution);
export const isOptimizing = derived(quantum, $q => $q.isOptimizing);

// Helper to format energy
export function formatEnergy(energy: number): string {
  return energy.toFixed(4);
}

// Helper to get advantage color
export function getAdvantageColor(hasAdvantage: boolean): string {
  return hasAdvantage ? '#10b981' : '#6b7280';
}

// Generate temperature schedule (exponential cooling)
export function generateTemperatureSchedule(numSteps: number = 100): number[] {
  const tInitial = 10.0;
  const tFinal = 0.001;
  const schedule: number[] = [];

  for (let i = 0; i <= numSteps; i++) {
    const t = tInitial * Math.pow(tFinal / tInitial, i / numSteps);
    schedule.push(t);
  }

  return schedule;
}
