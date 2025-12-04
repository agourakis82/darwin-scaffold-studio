// WebGPU 3D Viewer for Darwin Scaffold Studio
// Uses modern WebGPU API for real-time rendering

class WebGPUScaffoldViewer {
    constructor(canvas) {
        this.canvas = canvas;
        this.device = null;
        this.context = null;
        this.pipeline = null;
        this.initialized = false;
    }

    async init() {
        if (!navigator.gpu) {
            console.error('WebGPU not supported');
            this.canvas.getContext('2d').fillText('WebGPU not supported', 10, 50);
            return false;
        }

        // Get GPU adapter and device
        const adapter = await navigator.gpu.requestAdapter();
        this.device = await adapter.requestDevice();

        // Configure canvas context
        this.context = this.canvas.getContext('webgpu');
        const format = navigator.gpu.getPreferredCanvasFormat();
        this.context.configure({
            device: this.device,
            format: format,
            alphaMode: 'premultiplied',
        });

        // Create rendering pipeline
        await this.createPipeline(format);

        this.initialized = true;
        console.log('WebGPU Viewer initialized');
        return true;
    }

    async createPipeline(format) {
        // Vertex shader (WGSL)
        const vertexShader = `
            struct Uniforms {
                modelViewProjection: mat4x4<f32>,
            };
            @group(0) @binding(0) var<uniform> uniforms: Uniforms;
            
            struct VertexInput {
                @location(0) position: vec3<f32>,
                @location(1) normal: vec3<f32>,
                @location(2) color: vec3<f32>,
            };
            
            struct VertexOutput {
                @builtin(position) position: vec4<f32>,
                @location(0) normal: vec3<f32>,
                @location(1) color: vec3<f32>,
            };
            
            @vertex
            fn main(input: VertexInput) -> VertexOutput {
                var output: VertexOutput;
                output.position = uniforms.modelViewProjection * vec4<f32>(input.position, 1.0);
                output.normal = input.normal;
                output.color = input.color;
                return output;
            }
        `;

        // Fragment shader with Blinn-Phong shading
        const fragmentShader = `
            @fragment
            fn main(@location(0) normal: vec3<f32>,
                   @location(1) color: vec3<f32>) -> @location(0) vec4<f32> {
                let lightDir = normalize(vec3<f32>(1.0, 1.0, 1.0));
                let ambient = 0.3;
                let diffuse = max(dot(normalize(normal), lightDir), 0.0) * 0.7;
                let lighting = ambient + diffuse;
                
                return vec4<f32>(color * lighting, 1.0);
            }
        `;

        // Create shader modules
        const vertexModule = this.device.createShaderModule({
            code: vertexShader,
        });

        const fragmentModule = this.device.createShaderModule({
            code: fragmentShader,
        });

        // Create pipeline
        this.pipeline = this.device.createRenderPipeline({
            layout: 'auto',
            vertex: {
                module: vertexModule,
                entryPoint: 'main',
                buffers: [{
                    arrayStride: 36,  // 3*4 + 3*4 + 3*4 (pos + normal + color)
                    attributes: [
                        { shaderLocation: 0, offset: 0, format: 'float32x3' },   // position
                        { shaderLocation: 1, offset: 12, format: 'float32x3' },  // normal
                        { shaderLocation: 2, offset: 24, format: 'float32x3' },  // color
                    ],
                }],
            },
            fragment: {
                module: fragmentModule,
                entryPoint: 'main',
                targets: [{ format: format }],
            },
            primitive: {
                topology: 'triangle-list',
                cullMode: 'back',
            },
            depthStencil: {
                format: 'depth24plus',
                depthWriteEnabled: true,
                depthCompare: 'less',
            },
        });
    }

    loadScaffoldMesh(vertices, indices) {
        if (!this.initialized) {
            console.error('Viewer not initialized');
            return;
        }

        // Create vertex buffer
        const vertexBuffer = this.device.createBuffer({
            size: vertices.byteLength,
            usage: GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST,
        });
        this.device.queue.writeBuffer(vertexBuffer, 0, vertices);

        // Create index buffer
        const indexBuffer = this.device.createBuffer({
            size: indices.byteLength,
            usage: GPUBufferUsage.INDEX | GPUBufferUsage.COPY_DST,
        });
        this.device.queue.writeBuffer(indexBuffer, 0, indices);

        this.vertexBuffer = vertexBuffer;
        this.indexBuffer = indexBuffer;
        this.indexCount = indices.length;

        console.log(`Loaded mesh: ${vertices.length / 9} vertices, ${indices.length / 3} triangles`);
    }

    render(camera) {
        if (!this.initialized || !this.vertexBuffer) {
            return;
        }

        // Create command encoder
        const commandEncoder = this.device.createCommandEncoder();

        // Create render pass
        const textureView = this.context.getCurrentTexture().createView();

        const renderPass = commandEncoder.beginRenderPass({
            colorAttachments: [{
                view: textureView,
                clearValue: { r: 0.1, g: 0.1, b: 0.15, a: 1.0 },
                loadOp: 'clear',
                storeOp: 'store',
            }],
            depthStencilAttachment: {
                view: this.depthTexture.createView(),
                depthClearValue: 1.0,
                depthLoadOp: 'clear',
                depthStoreOp: 'store',
            },
        });

        renderPass.setPipeline(this.pipeline);
        renderPass.setVertexBuffer(0, this.vertexBuffer);
        renderPass.setIndexBuffer(this.indexBuffer, 'uint32');
        renderPass.draw(this.indexCount);
        renderPass.end();

        // Submit
        this.device.queue.submit([commandEncoder.finish()]);
    }
}

// Export for use in agents.html
window.WebGPUScaffoldViewer = WebGPUScaffoldViewer;
