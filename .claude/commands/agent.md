# Run Darwin Agent

Execute an AI agent for scaffold design, analysis, or literature synthesis.

## Arguments
$ARGUMENTS should specify the agent and task: `agent_type "task description"`

Example: `design "Create a bone scaffold with 80% porosity for load-bearing applications"`

## Available Agents

### Design Agent (design)
- Generate 3D scaffold designs
- Optimize parameters for specific applications
- Export to STL for 3D printing
- Uses code-capable LLM (qwen2.5-coder:7b)

### Analysis Agent (analysis)
- Compute advanced metrics (KEC, percolation)
- Predict cell viability using ML
- Compare against literature benchmarks
- Statistical analysis

### Synthesis Agent (synthesis)
- Search scientific literature
- Extract experimental methods
- Propose new experiments
- Generate citations

## Instructions

1. Parse the agent type and task from arguments
2. Check if Ollama is running (`curl http://localhost:11434/api/tags`)
3. Initialize the appropriate agent
4. Run the agent reasoning loop
5. Present results with tool usage log

If Ollama is not running, suggest: `ollama serve` and model download.
