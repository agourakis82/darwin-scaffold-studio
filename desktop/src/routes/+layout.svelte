<script lang="ts">
  import '../app.css';
  import Sidebar from '$lib/components/layout/Sidebar.svelte';
  import TopBar from '$lib/components/layout/TopBar.svelte';
  import StatusBar from '$lib/components/layout/StatusBar.svelte';
  import { juliaConnected } from '$lib/stores/julia';
  import { onMount } from 'svelte';

  let sidebarCollapsed = false;

  onMount(() => {
    // Check Julia server connection on mount
    checkJuliaConnection();
  });

  async function checkJuliaConnection() {
    try {
      const response = await fetch('http://localhost:8081/health');
      if (response.ok) {
        juliaConnected.set(true);
      }
    } catch {
      juliaConnected.set(false);
    }
  }
</script>

<div class="app-container">
  <TopBar />

  <div class="main-content">
    <Sidebar bind:collapsed={sidebarCollapsed} />

    <main class="workspace" class:sidebar-collapsed={sidebarCollapsed}>
      <slot />
    </main>
  </div>

  <StatusBar />
</div>

<style>
  .app-container {
    display: flex;
    flex-direction: column;
    height: 100vh;
    overflow: hidden;
  }

  .main-content {
    display: flex;
    flex: 1;
    overflow: hidden;
  }

  .workspace {
    flex: 1;
    overflow: auto;
    padding: 16px;
    margin-left: var(--sidebar-width);
    transition: margin-left var(--transition-base);
  }

  .workspace.sidebar-collapsed {
    margin-left: 64px;
  }
</style>
