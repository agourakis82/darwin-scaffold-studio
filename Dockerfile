# Darwin Scaffold Studio - Reproducible Environment
# Multi-stage build for smaller image

# ============================================================================
# Stage 1: Builder - Install dependencies
# ============================================================================
FROM julia:1.10-bullseye AS builder

WORKDIR /app

# Copy project files first (for caching)
COPY Project.toml Manifest.toml ./

# Install dependencies
RUN julia --project=. -e '\
    using Pkg; \
    Pkg.instantiate(); \
    Pkg.precompile()'

# ============================================================================
# Stage 2: Runtime
# ============================================================================
FROM julia:1.10-bullseye

LABEL maintainer="Darwin Scaffold Studio"
LABEL description="Tissue Engineering Scaffold Analysis Platform"
LABEL version="0.2.0"

# Install system dependencies for visualization and image processing
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1-mesa-glx \
    libxrender1 \
    libxext6 \
    libsm6 \
    libjpeg62-turbo \
    libpng16-16 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy precompiled packages from builder
COPY --from=builder /root/.julia /root/.julia

# Copy project files
COPY Project.toml Manifest.toml ./
COPY src/ ./src/
COPY test/ ./test/
COPY scripts/ ./scripts/
COPY data/ ./data/

# Verify installation
RUN julia --project=. -e '\
    using Pkg; \
    Pkg.instantiate(); \
    include("src/DarwinScaffoldStudio.jl"); \
    using .DarwinScaffoldStudio; \
    println("✅ DarwinScaffoldStudio loaded successfully")'

# Default command: start Julia REPL with project
CMD ["julia", "--project=.", "-e", "include(\"src/DarwinScaffoldStudio.jl\"); using .DarwinScaffoldStudio; println(\"Darwin Scaffold Studio v0.2.0 ready\"); include(\"scripts/interactive_shell.jl\")"]

# ============================================================================
# Usage Examples
# ============================================================================
#
# Build:
#   docker build -t darwin-scaffold-studio .
#
# Run interactive:
#   docker run -it darwin-scaffold-studio
#
# Run with volume mount (for your data):
#   docker run -it -v /path/to/your/data:/app/user_data darwin-scaffold-studio
#
# Run tests:
#   docker run darwin-scaffold-studio julia --project=. test/runtests.jl
#
# Run validation benchmark:
#   docker run darwin-scaffold-studio julia --project=. scripts/run_validation_benchmark.jl
#
# ============================================================================
