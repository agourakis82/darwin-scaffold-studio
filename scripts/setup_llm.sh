#!/bin/bash
# Darwin Scaffold Studio - SOTA 2025 Setup Script
# Installs and configures Ollama with recommended models for tissue engineering research

set -e

echo "🧬 Darwin Scaffold Studio - Installing AI Stack"
echo "=============================================="

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "📦 Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "✅ Ollama already installed"
fi

# Start Ollama service
echo "🚀 Starting Ollama service..."
ollama serve &
OLLAMA_PID=$!
sleep 3

# Check if service is running
if ! curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "❌ Failed to start Ollama service"
    exit 1
fi

echo "✅ Ollama service running (PID: $OLLAMA_PID)"

# Pull recommended models for Darwin
echo ""
echo "📥 Pulling AI models (this may take 10-30 minutes)..."
echo ""

# 1. Vision-Language Model (for SEM/MicroCT analysis)
echo "1/4: Vision Model (LLaVA 7B) - Analyze scaffold images..."
ollama pull llava:7b

# 2. Code Generation Model (for Julia code synthesis)
echo "2/4: Code Model (Qwen2.5-Coder 7B) - Generate optimization code..."
ollama pull qwen2.5-coder:7b

# 3. Fast Reasoning Model (for interactive analysis)
echo "3/4: Reasoning Model (Llama 3.2 3B) - Fast scaffold analysis..."
ollama pull llama3.2:3b

# 4. (Optional) Larger model for complex tasks
echo "4/4: Advanced Model (Qwen2.5-Coder 32B) - Optional, for best results..."
read -p "Pull 32B model? (Requires ~20GB disk) [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    ollama pull qwen2.5-coder:32b
else
    echo "⏭️  Skipped 32B model"
fi

# Verify models
echo ""
echo "📋 Installed Models:"
ollama list

# Test inference
echo ""
echo "🧪 Testing inference..."
TEST_RESPONSE=$(ollama run llama3.2:3b "What is tissue engineering?" --verbose=false 2>&1 | head -n 3)
echo "Test response: $TEST_RESPONSE"

echo ""
echo "✅ Darwin AI Stack Setup Complete!"
echo ""
echo "🎯 Next Steps:"
echo "   1. Start Julia server: julia --project=. src/server.jl"
echo "   2. Start Darwin server: cd darwin-server && cargo run"
echo "   3. Open browser: http://localhost:3000"
echo ""
echo "💡 Tip: Ollama is running in background (PID: $OLLAMA_PID)"
echo "   Stop with: kill $OLLAMA_PID"
echo "   Or run 'ollama serve' in a separate terminal for persistence"
