const state = {
    filePath: null,
    voxelSize: 10.391,
    metrics: null
};

// DOM Elements
const dropZone = document.getElementById('drop-zone');
const fileInput = document.getElementById('file-input');

// Event Listeners
dropZone.addEventListener('click', () => fileInput.click());
fileInput.addEventListener('change', handleUpload);
dropZone.addEventListener('dragover', (e) => {
    e.preventDefault();
    dropZone.style.borderColor = '#667eea';
});
dropZone.addEventListener('dragleave', () => {
    dropZone.style.borderColor = 'rgba(255,255,255,0.3)';
});
dropZone.addEventListener('drop', (e) => {
    e.preventDefault();
    const files = e.dataTransfer.files;
    if (files.length) handleFile(files[0]);
});

// Input sync
document.getElementById('opt-porosity').addEventListener('input', (e) => {
    document.getElementById('val-porosity').textContent = Math.round(e.target.value * 100) + '%';
});
document.getElementById('opt-pore-size').addEventListener('input', (e) => {
    document.getElementById('val-pore-size').textContent = e.target.value + ' μm';
});

async function handleUpload(e) {
    const file = e.target.files[0];
    if (file) handleFile(file);
}

async function handleFile(file) {
    const formData = new FormData();
    formData.append('file', file);

    try {
        dropZone.innerHTML = '<div class="icon">⏳</div><h3>Uploading...</h3>';

        const res = await fetch('/api/upload', {
            method: 'POST',
            body: formData
        });

        const data = await res.json();
        state.filePath = data.file_path;

        // Auto-start analysis
        runAnalysis();

    } catch (err) {
        console.error(err);
        alert('Upload failed');
        dropZone.innerHTML = '<div class="icon">❌</div><h3>Error</h3>';
    }
}

async function runAnalysis() {
    state.voxelSize = parseFloat(document.getElementById('voxel-size').value);

    try {
        const res = await fetch('/api/analyze', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                file_path: state.filePath,
                voxel_size: state.voxelSize
            })
        });

        const data = await res.json();
        state.metrics = data.metrics;

        displayMetrics(data.metrics);
        if (data.problems && Object.keys(data.problems).length > 0) {
            displayProblems(data.problems);
        }

        showStage('stage-analyze');

    } catch (err) {
        console.error(err);
        alert('Analysis failed');
    }
}

function displayResults(data) {
    const m = data.metrics;
    document.getElementById('res-porosity').innerText = (m.porosity * 100).toFixed(1) + '%';
    document.getElementById('res-pore-size').innerText = m.mean_pore_size_um.toFixed(1) + ' µm';

    // Thesis Metrics
    document.getElementById('res-curvature').innerText = m.curvature_mean ? m.curvature_mean.toFixed(4) : "N/A";
    document.getElementById('res-entropy').innerText = m.entropy_shannon ? m.entropy_shannon.toFixed(3) : "N/A";
    document.getElementById('res-percolation').innerText = m.percolation_diameter_um ? m.percolation_diameter_um.toFixed(1) + ' µm' : "0 µm";

    // AI Score
    const aiScore = m.ai_viability_score || 0;
    const aiElem = document.getElementById('res-viability');
    aiElem.innerText = (aiScore * 100).toFixed(1) + '%';

    // Color code AI score
    if (aiScore > 0.8) aiElem.style.color = "#00ff88";
    else if (aiScore < 0.5) aiElem.style.color = "#ff4444";

    // Problems
    const pList = document.getElementById('problems-list');
    pList.innerHTML = '';
    if (data.problems) {
        for (const [key, val] of Object.entries(data.problems)) {
            pList.innerHTML += `<div class="problem-item">⚠️ ${val}</div>`;
        }
    }
}

function displayMetrics(metrics) {
    const container = document.getElementById('metrics-container');
    container.innerHTML = `
        <div class="metric-card ${metrics.porosity >= 0.9 ? 'pass' : 'fail'}">
            <h4>Porosity</h4>
            <div class="value">${(metrics.porosity * 100).toFixed(1)}%</div>
        </div>
        <div class="metric-card ${metrics.mean_pore_size_um >= 100 && metrics.mean_pore_size_um <= 200 ? 'pass' : 'fail'}">
            <h4>Pore Size</h4>
            <div class="value">${metrics.mean_pore_size_um.toFixed(1)} μm</div>
        </div>
        <div class="metric-card ${metrics.interconnectivity >= 0.9 ? 'pass' : 'fail'}">
            <h4>Interconnectivity</h4>
            <div class="value">${(metrics.interconnectivity * 100).toFixed(1)}%</div>
        </div>
        <div class="metric-card ${metrics.tortuosity < 1.2 ? 'pass' : 'fail'}">
            <h4>Tortuosity</h4>
            <div class="value">${metrics.tortuosity.toFixed(3)}</div>
        </div>
    `;
}

function displayProblems(problems) {
    const box = document.getElementById('problems-box');
    const list = document.getElementById('problems-list');
    box.classList.remove('hidden');
    list.innerHTML = Object.values(problems).map(p => `<li>${p}</li>`).join('');
}

function goToOptimize() {
    showStage('stage-optimize');
}

async function runOptimization() {
    const params = {
        porosity: parseFloat(document.getElementById('opt-porosity').value),
        pore_size: parseFloat(document.getElementById('opt-pore-size').value),
        method: document.getElementById('opt-method').value,
        resolution: state.voxelSize
    };

    try {
        const btn = document.querySelector('#stage-optimize button');
        btn.textContent = '⏳ Optimizing...';
        btn.disabled = true;

        const res = await fetch('/api/optimize', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(params)
        });

        const data = await res.json();

        // Show results
        document.getElementById('res-orig-porosity').textContent = (state.metrics.porosity * 100).toFixed(1) + '%';
        document.getElementById('res-opt-porosity').textContent = (data.optimized_metrics.porosity * 100).toFixed(1) + '%';

        // Setup download
        // Note: In a real app, we'd serve the file from the backend
        // Here we assume the backend returns a path we can't directly access from browser
        // So we'd need a download endpoint. For now, just a placeholder.
        document.getElementById('download-link').href = '#';
        document.getElementById('download-link').onclick = () => alert('Download simulated: ' + data.stl_path);

        showStage('stage-results');

        // Render 3D (Placeholder)
        render3DPlaceholder();

    } catch (err) {
        console.error(err);
        alert('Optimization failed');
    } finally {
        const btn = document.querySelector('#stage-optimize button');
        btn.textContent = '🚀 Generate Optimized Scaffold';
        btn.disabled = false;
    }
}

function render3DPlaceholder() {
    // Simple Plotly placeholder
    const data = [{
        type: 'scatter3d',
        mode: 'markers',
        x: [0, 1, 0, 1],
        y: [0, 0, 1, 1],
        z: [0, 1, 1, 0],
        marker: {
            size: 12,
            color: '#667eea',
            opacity: 0.8
        }
    }];

    const layout = {
        margin: { l: 0, r: 0, b: 0, t: 0 },
        paper_bgcolor: 'rgba(0,0,0,0)',
        plot_bgcolor: 'rgba(0,0,0,0)',
        scene: {
            xaxis: { visible: false },
            yaxis: { visible: false },
            zaxis: { visible: false }
        }
    };

    Plotly.newPlot('3d-viewer', data, layout);
}

function showStage(id) {
    document.querySelectorAll('.stage').forEach(el => el.classList.add('hidden'));
    document.getElementById(id).classList.remove('hidden');
    document.getElementById(id).classList.add('active');
}
