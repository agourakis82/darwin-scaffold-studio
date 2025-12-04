# Refactor Code

Refactor Darwin Scaffold Studio code for better quality.

## Arguments
$ARGUMENTS - What to refactor (file path, module name, or "all" for suggestions)

## Refactoring Types

### `simplify` - Reduce complexity
- Extract repeated code into functions
- Simplify nested conditionals
- Remove dead code

### `types` - Improve type safety
- Add type annotations
- Create custom types for clarity
- Use parametric types where appropriate

### `performance` - Optimize speed
- Avoid type instability
- Use in-place operations
- Pre-allocate arrays
- Avoid global variables

### `structure` - Improve organization
- Split large modules
- Group related functions
- Improve file organization

### `api` - Clean public interface
- Consistent naming
- Clear function signatures
- Good documentation

## Instructions

1. Analyze the target code
2. Identify improvement opportunities
3. Propose changes with rationale
4. Implement changes incrementally
5. Verify tests still pass
6. Show before/after comparison

## Julia Best Practices
- Avoid abstract containers (use `Vector{Float64}` not `Vector{Any}`)
- Use `@views` for array slices
- Prefer `eachindex` over `1:length`
- Use `const` for global constants
- Avoid string interpolation in hot paths
