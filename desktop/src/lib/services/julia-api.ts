/**
 * Julia Backend API Client
 * Communicates with DarwinScaffoldStudio Oxygen.jl server
 */

import { juliaStatus } from '$lib/stores/julia';
import type { ScaffoldMetrics, TPMSParameters, HeatmapType } from '$lib/types/scaffold';

const API_BASE = 'http://localhost:8080';

interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: string;
}

interface WorkspaceInfo {
  id: string;
  created_at: string;
  material: string;
  tissue: string;
  has_volume: boolean;
}

interface ValidationResult {
  overall_score: number;
  metrics: Record<string, {
    value: number;
    target: string;
    valid: boolean;
    score: number;
    citation?: string;
  }>;
  recommendations: string[];
  citations: string[];
}

interface STLExportOptions {
  quality: 'low' | 'medium' | 'high';
  smoothing: boolean;
  binary: boolean;
}

interface GCodeOptions {
  printer: string;
  layer_height: number;
  infill_percent: number;
  nozzle_diameter: number;
  temperature: number;
  bed_temperature: number;
}

class JuliaApiClient {
  private baseUrl: string;
  private abortController: AbortController | null = null;

  constructor(baseUrl: string = API_BASE) {
    this.baseUrl = baseUrl;
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {}
  ): Promise<ApiResponse<T>> {
    try {
      const response = await fetch(`${this.baseUrl}${endpoint}`, {
        ...options,
        headers: {
          'Content-Type': 'application/json',
          ...options.headers,
        },
      });

      if (!response.ok) {
        const errorText = await response.text();
        return {
          success: false,
          error: `HTTP ${response.status}: ${errorText}`,
        };
      }

      const data = await response.json();
      return { success: true, data };
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      return { success: false, error: message };
    }
  }

  // Health check
  async healthCheck(): Promise<boolean> {
    const result = await this.request<{ status: string }>('/health');
    const connected = result.success && result.data?.status === 'ok';
    juliaStatus.set(connected ? 'connected' : 'disconnected');
    return connected;
  }

  // Workspace Management
  async createWorkspace(material: string, tissue: string): Promise<ApiResponse<WorkspaceInfo>> {
    return this.request<WorkspaceInfo>('/workspace/create', {
      method: 'POST',
      body: JSON.stringify({ material, tissue }),
    });
  }

  async getWorkspaceMetrics(workspaceId: string): Promise<ApiResponse<ScaffoldMetrics>> {
    return this.request<ScaffoldMetrics>(`/workspace/${workspaceId}/metrics`);
  }

  async editWorkspace(
    workspaceId: string,
    operation: 'add' | 'remove' | 'smooth',
    params: Record<string, unknown>
  ): Promise<ApiResponse<{ success: boolean }>> {
    return this.request(`/workspace/${workspaceId}/edit`, {
      method: 'POST',
      body: JSON.stringify({ operation, params }),
    });
  }

  async undoWorkspace(workspaceId: string): Promise<ApiResponse<{ success: boolean }>> {
    return this.request(`/workspace/${workspaceId}/undo`, { method: 'POST' });
  }

  async redoWorkspace(workspaceId: string): Promise<ApiResponse<{ success: boolean }>> {
    return this.request(`/workspace/${workspaceId}/redo`, { method: 'POST' });
  }

  // TPMS Generation
  async generateTPMS(params: TPMSParameters): Promise<ApiResponse<{
    mesh_url: string;
    metrics: ScaffoldMetrics;
  }>> {
    return this.request('/tpms/generate', {
      method: 'POST',
      body: JSON.stringify(params),
    });
  }

  async previewTPMS(params: TPMSParameters): Promise<ApiResponse<{
    preview_url: string;
    estimated_metrics: Partial<ScaffoldMetrics>;
  }>> {
    return this.request('/tpms/preview', {
      method: 'POST',
      body: JSON.stringify(params),
    });
  }

  // Heatmaps
  async getHeatmap(
    workspaceId: string,
    type: HeatmapType
  ): Promise<ApiResponse<{
    data: number[];
    min: number;
    max: number;
    colormap: string;
  }>> {
    return this.request(`/workspace/${workspaceId}/heatmap/${type}`);
  }

  // Image Import
  async importImage(filePath: string): Promise<ApiResponse<{
    preview_url: string;
    dimensions: [number, number, number];
    voxel_size: number;
  }>> {
    return this.request('/import/image', {
      method: 'POST',
      body: JSON.stringify({ file_path: filePath }),
    });
  }

  async preprocessImage(
    filePath: string,
    options: {
      denoise?: boolean;
      normalize?: boolean;
      crop?: [number, number, number, number, number, number];
    }
  ): Promise<ApiResponse<{ preview_url: string }>> {
    return this.request('/import/preprocess', {
      method: 'POST',
      body: JSON.stringify({ file_path: filePath, ...options }),
    });
  }

  async segmentImage(
    filePath: string,
    threshold: number,
    method: 'otsu' | 'adaptive' | 'manual'
  ): Promise<ApiResponse<{
    volume_id: string;
    metrics: ScaffoldMetrics;
  }>> {
    return this.request('/import/segment', {
      method: 'POST',
      body: JSON.stringify({ file_path: filePath, threshold, method }),
    });
  }

  // Validation
  async validateScaffold(
    workspaceId: string,
    tissue: string
  ): Promise<ApiResponse<ValidationResult>> {
    return this.request('/validation/check', {
      method: 'POST',
      body: JSON.stringify({ workspace_id: workspaceId, tissue }),
    });
  }

  async getLiterature(tissue: string): Promise<ApiResponse<{
    references: Array<{
      id: string;
      authors: string;
      year: number;
      title: string;
      journal: string;
      metrics: Record<string, { min: number; max: number }>;
    }>;
  }>> {
    return this.request(`/literature/${tissue}`);
  }

  // AI Agents
  async chatWithAgent(
    agentType: 'design' | 'analysis' | 'synthesis',
    message: string,
    context: {
      workspace_id?: string;
      material?: string;
      tissue?: string;
      metrics?: ScaffoldMetrics;
    }
  ): Promise<ApiResponse<{
    response: string;
    suggestions?: string[];
    actions?: Array<{ type: string; params: Record<string, unknown> }>;
  }>> {
    return this.request('/agents/chat', {
      method: 'POST',
      body: JSON.stringify({ agent: agentType, message, context }),
    });
  }

  async textToScaffold(
    prompt: string,
    constraints?: {
      material?: string;
      tissue?: string;
      porosity_range?: [number, number];
    }
  ): Promise<ApiResponse<{
    workspace_id: string;
    mesh_url: string;
    metrics: ScaffoldMetrics;
    explanation: string;
  }>> {
    return this.request('/agents/text-to-scaffold', {
      method: 'POST',
      body: JSON.stringify({ prompt, constraints }),
    });
  }

  // Export
  async exportSTL(
    workspaceId: string,
    options: STLExportOptions
  ): Promise<ApiResponse<{ file_path: string; size_bytes: number }>> {
    return this.request('/export/stl', {
      method: 'POST',
      body: JSON.stringify({ workspace_id: workspaceId, ...options }),
    });
  }

  async generateGCode(
    workspaceId: string,
    options: GCodeOptions
  ): Promise<ApiResponse<{
    gcode_id: string;
    file_path: string;
    layer_count: number;
    estimated_time_minutes: number;
  }>> {
    return this.request('/export/gcode', {
      method: 'POST',
      body: JSON.stringify({ workspace_id: workspaceId, ...options }),
    });
  }

  async getGCodePreview(gcodeId: string, layer: number): Promise<ApiResponse<{
    paths: Array<{ type: 'travel' | 'extrude'; points: [number, number][] }>;
    layer_height: number;
  }>> {
    return this.request(`/export/gcode/${gcodeId}/preview?layer=${layer}`);
  }

  // Cancel ongoing request
  cancel(): void {
    if (this.abortController) {
      this.abortController.abort();
      this.abortController = null;
    }
  }
}

// Singleton instance
export const juliaApi = new JuliaApiClient();

// Auto health check on import
if (typeof window !== 'undefined') {
  juliaApi.healthCheck();
  // Periodic health check every 30 seconds
  setInterval(() => juliaApi.healthCheck(), 30000);
}
