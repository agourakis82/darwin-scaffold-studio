// WebXR Immersive Visualization for Darwin Scaffold Studio
// Enables VR/AR exploration of 3D scaffolds

class DarwinWebXR {
    constructor() {
        this.xrSession = null;
        this.gl = null;
        this.xrRefSpace = null;
        this.scaffoldMesh = null;
    }

    async initialize() {
        // Check WebXR support
        if (!navigator.xr) {
            console.error('WebXR not supported');
            return false;
        }

        // Check VR support
        const vrSupported = await navigator.xr.isSessionSupported('immersive-vr');
        const arSupported = await navigator.xr.isSessionSupported('immersive-ar');

        console.log(`VR supported: ${vrSupported}, AR supported: ${arSupported}`);

        return vrSupported || arSupported;
    }

    async startVRSession(canvas) {
        try {
            // Request VR session
            this.xrSession = await navigator.xr.requestSession('immersive-vr', {
                requiredFeatures: ['local-floor'],
                optionalFeatures: ['hand-tracking', 'bounded-floor']
            });

            // Setup WebGL context for XR
            this.gl = canvas.getContext('webgl', { xrCompatible: true });
            await this.gl.makeXRCompatible();

            // Set up XR layer
            const xrLayer = new XRWebGLLayer(this.xrSession, this.gl);
            this.xrSession.updateRenderState({ baseLayer: xrLayer });

            // Get reference space
            this.xrRefSpace = await this.xrSession.requestReferenceSpace('local-floor');

            // Start render loop
            this.xrSession.requestAnimationFrame(this.onXRFrame.bind(this));

            console.log('VR session started');
            return true;

        } catch (error) {
            console.error('Failed to start VR session:', error);
            return false;
        }
    }

    async startARSession(canvas) {
        try {
            // Request AR session
            this.xrSession = await navigator.xr.requestSession('immersive-ar', {
                requiredFeatures: ['hit-test'],
                optionalFeatures: ['dom-overlay'],
                domOverlay: { root: document.body }
            });

            // Same WebGL setup as VR
            this.gl = canvas.getContext('webgl', { xrCompatible: true });
            await this.gl.makeXRCompatible();

            const xrLayer = new XRWebGLLayer(this.xrSession, this.gl);
            this.xrSession.updateRenderState({ baseLayer: xrLayer });

            this.xrRefSpace = await this.xrSession.requestReferenceSpace('local');

            this.xrSession.requestAnimationFrame(this.onXRFrame.bind(this));

            console.log('AR session started');
            return true;

        } catch (error) {
            console.error('Failed to start AR session:', error);
            return false;
        }
    }

    onXRFrame(time, frame) {
        const session = frame.session;
        session.requestAnimationFrame(this.onXRFrame.bind(this));

        // Get viewer pose
        const pose = frame.getViewerPose(this.xrRefSpace);
        if (!pose) return;

        // Get WebGL layer
        const layer = session.renderState.baseLayer;
        this.gl.bindFramebuffer(this.gl.FRAMEBUFFER, layer.framebuffer);

        // Clear
        this.gl.clearColor(0.1, 0.1, 0.15, 1.0);
        this.gl.clear(this.gl.COLOR_BUFFER_BIT | this.gl.DEPTH_BUFFER_BIT);

        // Render for each view (eye)
        for (const view of pose.views) {
            const viewport = layer.getViewport(view);
            this.gl.viewport(viewport.x, viewport.y, viewport.width, viewport.height);

            // Render scaffold mesh
            this.renderScaffold(view);
        }
    }

    renderScaffold(view) {
        if (!this.scaffoldMesh) return;

        // Get view matrix
        const viewMatrix = view.transform.inverse.matrix;
        const projectionMatrix = view.projectionMatrix;

        // Combine matrices
        const mvpMatrix = this.multiplyMatrices(projectionMatrix, viewMatrix);

        // Draw scaffold (simplified - real uses shaders)
        // In production: use same rendering pipeline as WebGPU viewer

        // Enable depth test
        this.gl.enable(this.gl.DEPTH_TEST);

        // ... actual rendering code would go here ...
    }

    loadScaffoldMesh(vertices, indices) {
        // Create WebGL buffers for scaffold
        this.scaffoldMesh = {
            vertices: this.createBuffer(vertices),
            indices: this.createBuffer(indices),
            indexCount: indices.length
        };

        console.log('Scaffold mesh loaded for XR');
    }

    createBuffer(data) {
        const buffer = this.gl.createBuffer();
        this.gl.bindBuffer(this.gl.ARRAY_BUFFER, buffer);
        this.gl.bufferData(this.gl.ARRAY_BUFFER, new Float32Array(data), this.gl.STATIC_DRAW);
        return buffer;
    }

    multiplyMatrices(a, b) {
        // 4x4 matrix multiplication
        const result = new Float32Array(16);
        for (let i = 0; i < 4; i++) {
            for (let j = 0; j < 4; j++) {
                result[i * 4 + j] =
                    a[i * 4 + 0] * b[0 * 4 + j] +
                    a[i * 4 + 1] * b[1 * 4 + j] +
                    a[i * 4 + 2] * b[2 * 4 + j] +
                    a[i * 4 + 3] * b[3 * 4 + j];
            }
        }
        return result;
    }

    // Hand tracking for gesture controls
    enableHandTracking() {
        if (!this.xrSession || !this.xrSession.inputSources) return;

        for (const inputSource of this.xrSession.inputSources) {
            if (inputSource.hand) {
                console.log('Hand tracking enabled');
                // Track hand joints for pinch gestures, etc.
            }
        }
    }

    // Haptic feedback
    triggerHaptic(intensity = 1.0, duration = 100) {
        if (!this.xrSession) return;

        for (const inputSource of this.xrSession.inputSources) {
            if (inputSource.gamepad && inputSource.gamepad.hapticActuators) {
                inputSource.gamepad.hapticActuators[0].pulse(intensity, duration);
            }
        }
    }

    endSession() {
        if (this.xrSession) {
            this.xrSession.end();
            this.xrSession = null;
            console.log('XR session ended');
        }
    }
}

// Export for use
window.DarwinWebXR = DarwinWebXR;

// UI Controls
function setupXRButtons() {
    const vrButton = document.getElementById('enter-vr');
    const arButton = document.getElementById('enter-ar');

    const xr = new DarwinWebXR();

    xr.initialize().then(supported => {
        if (supported) {
            vrButton.onclick = () => {
                const canvas = document.createElement('canvas');
                document.body.appendChild(canvas);
                xr.startVRSession(canvas);
            };

            arButton.onclick = () => {
                const canvas = document.createElement('canvas');
                document.body.appendChild(canvas);
                xr.startARSession(canvas);
            };
        } else {
            vrButton.disabled = true;
            arButton.disabled = true;
            vrButton.textContent = 'XR Not Supported';
        }
    });
}

// Initialize when ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', setupXRButtons);
} else {
    setupXRButtons();
}
