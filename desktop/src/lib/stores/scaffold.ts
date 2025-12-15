// Scaffold state management
import { writable, derived } from 'svelte/store';
import type { ScaffoldState, ScaffoldMetrics } from '$types/scaffold';

// Current scaffold data
export const scaffold = writable<ScaffoldState | null>(null);

// Workspace ID (from Julia backend)
export const workspaceId = writable<string | null>(null);

// Material selection
export const material = writable<string>('PCL');

// Target tissue type
export const tissue = writable<string>('bone');

// Voxel size in micrometers
export const voxelSize = writable<number>(10.0);

// Heatmap type for visualization
export const heatmapType = writable<string | null>(null);

// Editor state
export const editorTool = writable<string>('select');
export const brushSize = writable<number>(5);

// Undo/Redo stacks
export const undoStack = writable<any[]>([]);
export const redoStack = writable<any[]>([]);

// Derived: Can undo/redo
export const canUndo = derived(undoStack, ($stack) => $stack.length > 0);
export const canRedo = derived(redoStack, ($stack) => $stack.length > 0);

// Derived: Scaffold dimensions in mm
export const scaffoldDimensionsMm = derived(
  [scaffold, voxelSize],
  ([$scaffold, $voxelSize]) => {
    if (!$scaffold) return null;
    return {
      x: ($scaffold.dimensions[0] * $voxelSize) / 1000,
      y: ($scaffold.dimensions[1] * $voxelSize) / 1000,
      z: ($scaffold.dimensions[2] * $voxelSize) / 1000,
    };
  }
);

// Actions
export function resetScaffold() {
  scaffold.set(null);
  workspaceId.set(null);
  undoStack.set([]);
  redoStack.set([]);
}

export function setScaffold(data: ScaffoldState, id: string) {
  scaffold.set(data);
  workspaceId.set(id);
  undoStack.set([]);
  redoStack.set([]);
}
