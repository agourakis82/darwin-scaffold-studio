/**
 * Editor Store
 * Manages edit tool state and operations
 */

import { writable, derived } from 'svelte/store';

export type EditTool = 'select' | 'add' | 'remove' | 'smooth' | 'measure' | 'slice';
export type BrushFalloff = 'sharp' | 'linear' | 'smooth';

interface BrushSettings {
  size: number;
  strength: number;
  falloff: BrushFalloff;
}

interface SlicePlane {
  axis: 'x' | 'y' | 'z';
  position: number;
  visible: boolean;
}

interface MeasurementPoint {
  id: string;
  position: [number, number, number];
  label?: string;
}

interface EditorState {
  activeTool: EditTool;
  brush: BrushSettings;
  slicePlane: SlicePlane;
  measurementPoints: MeasurementPoint[];
  gridSnap: boolean;
  gridSize: number;
  showWireframe: boolean;
  showBoundingBox: boolean;
  symmetryMode: 'none' | 'x' | 'y' | 'z' | 'xyz';
}

const defaultState: EditorState = {
  activeTool: 'select',
  brush: {
    size: 5,
    strength: 100,
    falloff: 'linear',
  },
  slicePlane: {
    axis: 'z',
    position: 0.5,
    visible: false,
  },
  measurementPoints: [],
  gridSnap: false,
  gridSize: 1.0,
  showWireframe: false,
  showBoundingBox: false,
  symmetryMode: 'none',
};

function createEditorStore() {
  const { subscribe, set, update } = writable<EditorState>(defaultState);

  return {
    subscribe,

    setTool(tool: EditTool) {
      update((state) => ({ ...state, activeTool: tool }));
    },

    setBrushSize(size: number) {
      update((state) => ({
        ...state,
        brush: { ...state.brush, size: Math.max(1, Math.min(20, size)) },
      }));
    },

    setBrushStrength(strength: number) {
      update((state) => ({
        ...state,
        brush: { ...state.brush, strength: Math.max(0, Math.min(100, strength)) },
      }));
    },

    setBrushFalloff(falloff: BrushFalloff) {
      update((state) => ({
        ...state,
        brush: { ...state.brush, falloff },
      }));
    },

    setSlicePlane(axis: 'x' | 'y' | 'z', position: number) {
      update((state) => ({
        ...state,
        slicePlane: { ...state.slicePlane, axis, position },
      }));
    },

    toggleSlicePlane() {
      update((state) => ({
        ...state,
        slicePlane: { ...state.slicePlane, visible: !state.slicePlane.visible },
      }));
    },

    addMeasurementPoint(position: [number, number, number], label?: string) {
      const id = crypto.randomUUID();
      update((state) => ({
        ...state,
        measurementPoints: [...state.measurementPoints, { id, position, label }],
      }));
      return id;
    },

    removeMeasurementPoint(id: string) {
      update((state) => ({
        ...state,
        measurementPoints: state.measurementPoints.filter((p) => p.id !== id),
      }));
    },

    clearMeasurements() {
      update((state) => ({
        ...state,
        measurementPoints: [],
      }));
    },

    toggleGridSnap() {
      update((state) => ({ ...state, gridSnap: !state.gridSnap }));
    },

    setGridSize(size: number) {
      update((state) => ({ ...state, gridSize: Math.max(0.1, size) }));
    },

    toggleWireframe() {
      update((state) => ({ ...state, showWireframe: !state.showWireframe }));
    },

    toggleBoundingBox() {
      update((state) => ({ ...state, showBoundingBox: !state.showBoundingBox }));
    },

    setSymmetryMode(mode: EditorState['symmetryMode']) {
      update((state) => ({ ...state, symmetryMode: mode }));
    },

    reset() {
      set(defaultState);
    },
  };
}

export const editor = createEditorStore();

// Derived stores for convenience
export const activeTool = derived(editor, ($editor) => $editor.activeTool);
export const brushSettings = derived(editor, ($editor) => $editor.brush);
export const slicePlane = derived(editor, ($editor) => $editor.slicePlane);

// Measurement distance calculator
export const measurementDistance = derived(editor, ($editor) => {
  const points = $editor.measurementPoints;
  if (points.length < 2) return null;

  const [p1, p2] = points.slice(-2);
  const dx = p2.position[0] - p1.position[0];
  const dy = p2.position[1] - p1.position[1];
  const dz = p2.position[2] - p1.position[2];

  return Math.sqrt(dx * dx + dy * dy + dz * dz);
});
