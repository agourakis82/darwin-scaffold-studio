# Development Helper

Quick development tasks for Darwin Scaffold Studio.

## Arguments
$ARGUMENTS - the dev task to run

## Available Tasks

### `new module:Name` - Create new Julia module
Create a new module with proper structure in the appropriate directory.

### `fix` - Auto-fix common issues
Scan for and fix common Julia issues (import paths, type annotations).

### `deps` - Check/update dependencies
Verify Project.toml deps are correct and suggest updates.

### `docs` - Generate documentation
Generate docstrings summary for all exported functions.

### `bench` - Run benchmarks
Run performance benchmarks on core functions.

### `profile` - Profile module loading
Show which modules take longest to load.

### `todo` - List TODOs in code
Find all TODO/FIXME/HACK comments in the codebase.

### `check` - Pre-commit checks
Run linting, type checks, and tests before committing.

## Instructions

Parse the task from $ARGUMENTS and execute the appropriate action.
Always show progress and results clearly.
