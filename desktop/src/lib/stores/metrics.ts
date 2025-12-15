// Metrics and validation state
import { writable, derived } from 'svelte/store';

export interface MetricValue {
  value: number;
  unit: string;
  min?: number;
  max?: number;
}

export interface ValidationResult {
  is_valid: boolean;
  overall_score: number;
  porosity: { valid: boolean; score: number; citations: string[] };
  pore_size: { valid: boolean; score: number; citations: string[] };
  interconnectivity: { valid: boolean; score: number; citations: string[] };
  mechanical: { valid: boolean; score: number };
  recommendations: string[];
}

export interface ScaffoldMetrics {
  porosity: MetricValue;
  pore_size: MetricValue;
  interconnectivity: MetricValue;
  tortuosity: MetricValue;
  specific_surface_area: MetricValue;
  elastic_modulus: MetricValue;
  yield_strength: MetricValue;
  permeability: MetricValue;
}

// Current metrics
export const metrics = writable<ScaffoldMetrics | null>(null);

// Validation results
export const validation = writable<ValidationResult | null>(null);

// Heatmap data
export const heatmapData = writable<{
  type: string;
  data: Float32Array;
  min: number;
  max: number;
  colormap: string;
} | null>(null);

// Is metrics loading
export const metricsLoading = writable<boolean>(false);

// Derived: Overall health status
export const healthStatus = derived(validation, ($validation) => {
  if (!$validation) return 'unknown';
  if ($validation.overall_score >= 80) return 'excellent';
  if ($validation.overall_score >= 60) return 'good';
  if ($validation.overall_score >= 40) return 'fair';
  return 'poor';
});

// Derived: Has critical issues
export const hasCriticalIssues = derived(validation, ($validation) => {
  if (!$validation) return false;
  return !$validation.porosity.valid ||
         !$validation.pore_size.valid ||
         !$validation.interconnectivity.valid;
});

// Actions
export function resetMetrics() {
  metrics.set(null);
  validation.set(null);
  heatmapData.set(null);
}

export function updateMetrics(newMetrics: ScaffoldMetrics) {
  metrics.set(newMetrics);
}

export function updateValidation(newValidation: ValidationResult) {
  validation.set(newValidation);
}
