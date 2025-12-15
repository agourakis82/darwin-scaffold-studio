<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import * as THREE from 'three';
  import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
  import { heatmapType } from '$lib/stores/scaffold';
  import { HEATMAP_TYPES } from '$lib/types/scaffold';

  export let workspaceId: string;
  export let showHeatmap = false;
  export let wireframe = false;

  let container: HTMLDivElement;
  let scene: THREE.Scene;
  let camera: THREE.PerspectiveCamera;
  let renderer: THREE.WebGLRenderer;
  let controls: OrbitControls;
  let scaffoldMesh: THREE.Mesh | null = null;
  let animationId: number;
  let gridHelper: THREE.GridHelper;
  let axesHelper: THREE.AxesHelper;

  // View controls
  let isLoading = true;
  let errorMessage = '';

  onMount(async () => {
    initScene();
    await loadScaffoldMesh();
    animate();
    window.addEventListener('resize', onResize);
  });

  onDestroy(() => {
    window.removeEventListener('resize', onResize);
    if (animationId) cancelAnimationFrame(animationId);

    // Dispose scaffold mesh
    if (scaffoldMesh) {
      scaffoldMesh.geometry.dispose();
      (scaffoldMesh.material as THREE.Material).dispose();
    }

    // Dispose helpers
    if (gridHelper) gridHelper.dispose();
    if (axesHelper) axesHelper.dispose();

    if (controls) controls.dispose();
    if (renderer) renderer.dispose();
  });

  function initScene() {
    // Scene
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x0d1117);

    // Camera
    camera = new THREE.PerspectiveCamera(
      45,
      container.clientWidth / container.clientHeight,
      0.1,
      1000
    );
    camera.position.set(80, 80, 80);

    // Renderer
    renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setSize(container.clientWidth, container.clientHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    container.appendChild(renderer.domElement);

    // Controls
    controls = new OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.05;
    controls.minDistance = 10;
    controls.maxDistance = 500;

    // Lighting
    const ambientLight = new THREE.AmbientLight(0xffffff, 0.4);
    scene.add(ambientLight);

    const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
    directionalLight.position.set(50, 100, 50);
    directionalLight.castShadow = true;
    scene.add(directionalLight);

    const fillLight = new THREE.DirectionalLight(0x4a9eff, 0.3);
    fillLight.position.set(-50, 50, -50);
    scene.add(fillLight);

    // Grid helper
    gridHelper = new THREE.GridHelper(100, 20, 0x30363d, 0x21262d);
    scene.add(gridHelper);

    // Axes helper
    axesHelper = new THREE.AxesHelper(30);
    scene.add(axesHelper);
  }

  async function loadScaffoldMesh() {
    isLoading = true;
    errorMessage = '';

    try {
      // For demo, create a sample scaffold mesh
      const geometry = createSampleScaffoldGeometry();

      const material = new THREE.MeshPhongMaterial({
        color: 0x4a9eff,
        specular: 0x222222,
        shininess: 30,
        wireframe: wireframe,
        transparent: true,
        opacity: 0.9,
      });

      scaffoldMesh = new THREE.Mesh(geometry, material);
      scaffoldMesh.castShadow = true;
      scaffoldMesh.receiveShadow = true;
      scene.add(scaffoldMesh);

      // Fit camera to mesh
      fitCameraToMesh();
      isLoading = false;
    } catch (error) {
      errorMessage = 'Failed to load scaffold mesh';
      isLoading = false;
      console.error(error);
    }
  }

  function createSampleScaffoldGeometry(): THREE.BufferGeometry {
    // Create a sample gyroid-like structure using parametric equations
    const geometry = new THREE.BoxGeometry(40, 40, 40, 20, 20, 20);

    // Apply gyroid deformation to vertices
    const positions = geometry.attributes.position;
    const vertex = new THREE.Vector3();

    for (let i = 0; i < positions.count; i++) {
      vertex.fromBufferAttribute(positions, i);

      // Gyroid equation: sin(x)cos(y) + sin(y)cos(z) + sin(z)cos(x) = 0
      const scale = 0.15;
      const x = vertex.x * scale;
      const y = vertex.y * scale;
      const z = vertex.z * scale;

      const gyroid = Math.sin(x) * Math.cos(y) + Math.sin(y) * Math.cos(z) + Math.sin(z) * Math.cos(x);

      // Displace vertices based on gyroid value
      const displacement = Math.abs(gyroid) * 3;
      vertex.normalize().multiplyScalar(20 + displacement);

      positions.setXYZ(i, vertex.x, vertex.y, vertex.z);
    }

    geometry.computeVertexNormals();
    return geometry;
  }

  function fitCameraToMesh() {
    if (!scaffoldMesh) return;

    const box = new THREE.Box3().setFromObject(scaffoldMesh);
    const center = box.getCenter(new THREE.Vector3());
    const size = box.getSize(new THREE.Vector3());

    const maxDim = Math.max(size.x, size.y, size.z);
    const fov = camera.fov * (Math.PI / 180);
    const cameraZ = Math.abs(maxDim / Math.sin(fov / 2)) * 1.5;

    camera.position.set(center.x + cameraZ * 0.5, center.y + cameraZ * 0.5, center.z + cameraZ);
    controls.target.copy(center);
    controls.update();
  }

  function resetCamera() {
    camera.position.set(80, 80, 80);
    controls.target.set(0, 0, 0);
    controls.update();
  }

  function onResize() {
    if (!container) return;
    camera.aspect = container.clientWidth / container.clientHeight;
    camera.updateProjectionMatrix();
    renderer.setSize(container.clientWidth, container.clientHeight);
  }

  function animate() {
    animationId = requestAnimationFrame(animate);
    controls.update();
    renderer.render(scene, camera);
  }

  function toggleWireframe() {
    wireframe = !wireframe;
    if (scaffoldMesh) {
      (scaffoldMesh.material as THREE.MeshPhongMaterial).wireframe = wireframe;
    }
  }

  // Reactive updates
  $: if (scaffoldMesh && wireframe !== undefined) {
    (scaffoldMesh.material as THREE.MeshPhongMaterial).wireframe = wireframe;
  }
</script>

<div class="viewer-wrapper" bind:this={container}>
  {#if isLoading}
    <div class="loading-overlay">
      <div class="spinner"></div>
      <span>Loading scaffold...</span>
    </div>
  {/if}

  {#if errorMessage}
    <div class="error-overlay">
      <span>{errorMessage}</span>
    </div>
  {/if}

  <div class="viewer-controls">
    <button class="control-btn" on:click={resetCamera} title="Reset View">
      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"></path>
        <path d="M3 3v5h5"></path>
      </svg>
    </button>

    <button
      class="control-btn"
      class:active={wireframe}
      on:click={toggleWireframe}
      title={wireframe ? 'Solid' : 'Wireframe'}
    >
      <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect>
        <line x1="3" y1="9" x2="21" y2="9"></line>
        <line x1="3" y1="15" x2="21" y2="15"></line>
        <line x1="9" y1="3" x2="9" y2="21"></line>
        <line x1="15" y1="3" x2="15" y2="21"></line>
      </svg>
    </button>

    <select
      class="heatmap-select"
      bind:value={$heatmapType}
      on:change={() => showHeatmap = !!$heatmapType}
    >
      <option value="">No Heatmap</option>
      {#each HEATMAP_TYPES as type}
        <option value={type.id}>{type.name}</option>
      {/each}
    </select>
  </div>
</div>

<style>
  .viewer-wrapper {
    position: relative;
    width: 100%;
    height: 100%;
    min-height: 400px;
    border-radius: 8px;
    overflow: hidden;
  }

  .viewer-controls {
    position: absolute;
    top: 12px;
    right: 12px;
    display: flex;
    gap: 8px;
    z-index: 10;
  }

  .control-btn {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 36px;
    height: 36px;
    border-radius: 8px;
    background: rgba(22, 27, 34, 0.9);
    backdrop-filter: blur(8px);
    border: 1px solid var(--border-color);
    color: var(--text-secondary);
    cursor: pointer;
    transition: all var(--transition-fast);
  }

  .control-btn:hover {
    background: var(--bg-tertiary);
    color: var(--text-primary);
  }

  .control-btn.active {
    background: var(--primary);
    color: white;
    border-color: var(--primary);
  }

  .heatmap-select {
    padding: 8px 12px;
    border-radius: 8px;
    background: rgba(22, 27, 34, 0.9);
    backdrop-filter: blur(8px);
    border: 1px solid var(--border-color);
    color: var(--text-primary);
    font-size: 13px;
    cursor: pointer;
  }

  .loading-overlay,
  .error-overlay {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 12px;
    background: rgba(13, 17, 23, 0.9);
    z-index: 20;
  }

  .spinner {
    width: 40px;
    height: 40px;
    border: 3px solid var(--border-color);
    border-top-color: var(--primary);
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }

  .error-overlay {
    color: var(--error);
  }
</style>
