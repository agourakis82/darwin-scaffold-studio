# Run Tests

Run the Darwin Scaffold Studio test suite.

## Arguments
$ARGUMENTS can be:
- `minimal` - Quick structure validation (default)
- `core` - Test core modules only
- `full` - Complete test suite (slow, loads all deps)
- `module:Name` - Test specific module (e.g., `module:MicroCT`)

## Instructions

Based on the argument, run the appropriate test:

### minimal (default)
```bash
julia --project=. test_minimal.jl
```

### core
```bash
julia --project=. -e '
module TestCore
include("src/DarwinScaffoldStudio/Core/Config.jl")
include("src/DarwinScaffoldStudio/Core/Types.jl")
include("src/DarwinScaffoldStudio/Core/Utils.jl")
include("src/DarwinScaffoldStudio/MicroCT/ImageLoader.jl")
include("src/DarwinScaffoldStudio/MicroCT/Metrics.jl")
include("src/DarwinScaffoldStudio/Optimization/ScaffoldOptimizer.jl")
println("All core modules loaded successfully!")
end'
```

### full
```bash
julia --project=. test/runtests.jl
```

Report test results with pass/fail counts and any errors encountered.
