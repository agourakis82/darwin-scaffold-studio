# Debug Issue

Debug a problem in Darwin Scaffold Studio.

## Arguments
$ARGUMENTS - Description of the issue or error message

## Instructions

1. **Reproduce the issue**
   - Run the failing code
   - Capture full error message and stack trace

2. **Analyze the error**
   - Identify error type (LoadError, MethodError, TypeError, etc.)
   - Find the source file and line number
   - Understand what the code is trying to do

3. **Common Darwin issues**

   ### LoadError / UndefVarError
   - Check import paths (`..` vs `...`)
   - Verify module is included before use
   - Check circular dependencies

   ### MethodError
   - Check function signatures
   - Verify type annotations match
   - Check if method is exported

   ### TypeError
   - Check type definitions in Types.jl
   - Verify struct field types
   - Check constructor arguments

4. **Fix and verify**
   - Make minimal fix
   - Test module loads
   - Run related tests
   - Check for side effects

5. **Document the fix**
   - Explain what caused the issue
   - Note if similar issues might exist elsewhere
