// TypeScript types for scaffold data structures

export interface ScaffoldState {
  dimensions: [number, number, number];
  voxelSize: number;
  material: string;
  tissue: string;
  modified: boolean;
}

export interface ScaffoldMetrics {
  porosity: number;
  mean_pore_size_um: number;
  interconnectivity: number;
  tortuosity: number;
  specific_surface_area: number;
  elastic_modulus: number;
  yield_strength: number;
  permeability: number;
}

export interface ScaffoldParameters {
  porosity_target: number;
  pore_size_target_um: number;
  interconnectivity_target: number;
  tortuosity_target: number;
  volume_mm3: [number, number, number];
  resolution_um: number;
}

export interface OptimizationResults {
  optimized_metrics: ScaffoldMetrics;
  original_metrics: ScaffoldMetrics;
  improvement_percent: Record<string, number>;
  fabrication_method: string;
  fabrication_parameters: Record<string, any>;
}

export interface TPMSParameters {
  surface_type: 'gyroid' | 'diamond' | 'schwarz_p' | 'neovius' | 'iwp';
  porosity: number;
  unit_cell_size: number;
  n_cells: [number, number, number];
}

export interface HeatmapType {
  id: string;
  name: string;
  unit: string;
  colormap: string;
}

export const HEATMAP_TYPES: HeatmapType[] = [
  { id: 'POROSITY_LOCAL', name: 'Local Porosity', unit: '%', colormap: 'viridis' },
  { id: 'STRESS_VONMISES', name: 'Stress (Von Mises)', unit: 'MPa', colormap: 'plasma' },
  { id: 'PERMEABILITY', name: 'Permeability', unit: 'm^2', colormap: 'inferno' },
  { id: 'PORE_SIZE', name: 'Pore Size', unit: 'um', colormap: 'viridis' },
  { id: 'WALL_THICKNESS', name: 'Wall Thickness', unit: 'um', colormap: 'cividis' },
  { id: 'INTERCONNECTIVITY', name: 'Interconnectivity', unit: '%', colormap: 'viridis' },
  { id: 'TORTUOSITY', name: 'Tortuosity', unit: '', colormap: 'magma' },
  { id: 'NUTRIENT_DIFFUSION', name: 'Nutrient Diffusion', unit: 'mol/m^3', colormap: 'plasma' },
  { id: 'CELL_MIGRATION', name: 'Cell Migration', unit: '', colormap: 'viridis' },
  { id: 'CURVATURE_MEAN', name: 'Mean Curvature', unit: '1/mm', colormap: 'coolwarm' },
  { id: 'CURVATURE_GAUSSIAN', name: 'Gaussian Curvature', unit: '1/mm^2', colormap: 'coolwarm' },
];

export interface Material {
  id: string;
  name: string;
  description: string;
  elastic_modulus: number;
  yield_strength: number;
  density: number;
  degradation_time: string;
  biocompatible: boolean;
  fda_approved: boolean;
}

export const MATERIALS: Material[] = [
  { id: 'PCL', name: 'PCL', description: 'Poly-e-caprolactone', elastic_modulus: 400, yield_strength: 16, density: 1145, degradation_time: '6-24 months', biocompatible: true, fda_approved: true },
  { id: 'PLA', name: 'PLA', description: 'Poly(lactic acid)', elastic_modulus: 3500, yield_strength: 70, density: 1250, degradation_time: '12-18 months', biocompatible: true, fda_approved: true },
  { id: 'PLGA', name: 'PLGA', description: 'Copolymer', elastic_modulus: 2000, yield_strength: 45, density: 1300, degradation_time: '2-6 months', biocompatible: true, fda_approved: true },
  { id: 'Collagen', name: 'Collagen', description: 'Natural ECM protein', elastic_modulus: 100, yield_strength: 5, density: 1100, degradation_time: '1-4 weeks', biocompatible: true, fda_approved: true },
  { id: 'Chitosan', name: 'Chitosan', description: 'Biopolymer', elastic_modulus: 200, yield_strength: 8, density: 1100, degradation_time: '2-6 months', biocompatible: true, fda_approved: true },
  { id: 'Hydroxyapatite', name: 'HA/TCP', description: 'Ceramic', elastic_modulus: 80000, yield_strength: 100, density: 3160, degradation_time: '12-36 months', biocompatible: true, fda_approved: true },
  { id: 'Ti6Al4V', name: 'Ti6Al4V', description: 'Titanium alloy', elastic_modulus: 110000, yield_strength: 900, density: 4430, degradation_time: 'Non-degradable', biocompatible: true, fda_approved: true },
];

export interface TissueTarget {
  id: string;
  name: string;
  color: string;
  optimal_porosity: [number, number];
  optimal_pore_size: [number, number];
  min_interconnectivity: number;
}

export const TISSUE_TARGETS: TissueTarget[] = [
  { id: 'bone', name: 'Bone', color: '#f59e0b', optimal_porosity: [0.85, 0.95], optimal_pore_size: [100, 500], min_interconnectivity: 0.9 },
  { id: 'cartilage', name: 'Cartilage', color: '#3b82f6', optimal_porosity: [0.80, 0.90], optimal_pore_size: [50, 300], min_interconnectivity: 0.85 },
  { id: 'skin', name: 'Skin', color: '#ec4899', optimal_porosity: [0.70, 0.85], optimal_pore_size: [50, 200], min_interconnectivity: 0.80 },
  { id: 'vascular', name: 'Vascular', color: '#ef4444', optimal_porosity: [0.75, 0.90], optimal_pore_size: [100, 400], min_interconnectivity: 0.95 },
  { id: 'neural', name: 'Neural', color: '#a855f7', optimal_porosity: [0.80, 0.90], optimal_pore_size: [10, 100], min_interconnectivity: 0.90 },
];
