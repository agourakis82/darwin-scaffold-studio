# Start Darwin Server

Start the Darwin Scaffold Studio HTTP server.

## Arguments
$ARGUMENTS can be:
- `julia` - Start Julia/Oxygen.jl server (port 8080)
- `rust` - Start Rust/Axum server (port 3000)
- `both` - Start both servers
- `stop` - Stop all servers

## Instructions

### Julia Server (Oxygen.jl)
```bash
cd /home/agourakis82/workspace/darwin-scaffold-studio
julia --project=. src/server.jl &
```
Endpoints: http://localhost:8080

### Rust Server (WebGPU/WebXR)
```bash
cd /home/agourakis82/workspace/darwin-scaffold-studio/darwin-server
cargo run &
```
Endpoints: http://localhost:3000

### Stop Servers
```bash
pkill -f "julia.*server.jl"
pkill -f "darwin-server"
```

After starting, verify the server is running and report available endpoints.
