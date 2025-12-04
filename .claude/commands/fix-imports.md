# Fix Import Issues

Automatically detect and fix Julia module import issues.

## Common Issues to Fix

1. **Wrong relative import depth**
   - `...Module` when should be `..Module`
   - Missing dots for parent module access

2. **Module vs Type confusion**
   - Using module name as type annotation
   - Example: `optimizer::ScaffoldOptimizer` should be `optimizer::Optimizer`

3. **Missing exports**
   - Functions used but not exported
   - Types referenced but not exported

4. **Circular dependencies**
   - Module A imports B, B imports A

## Instructions

1. Scan all .jl files in src/DarwinScaffoldStudio/
2. Parse each module's `using` and `import` statements
3. Check for common patterns that cause LoadError
4. Fix issues automatically or report what needs manual fix
5. Test that modules load after fixes

## Scan Pattern
```bash
grep -r "using \.\." src/DarwinScaffoldStudio/
grep -r "::.*Module" src/DarwinScaffoldStudio/
```

Report findings in a table with file, line, issue, and fix.
