# Create Release

Create a new version release for Darwin Scaffold Studio.

## Arguments
$ARGUMENTS should be the version type: `patch`, `minor`, or `major`

Example: `/release patch` bumps 2.0.1 -> 2.0.2

## Instructions

1. Get current version from Project.toml
2. Calculate new version based on argument
3. Update files:
   - Project.toml (version field)
   - CHANGELOG.md (add new section)
   - CITATION.cff (if exists)
4. Run minimal tests to verify
5. Commit with message: "chore: Bump version to vX.Y.Z"
6. Create git tag: vX.Y.Z
7. Push to origin with tags
8. Create GitHub release with auto-generated notes

### Version Rules
- patch: Bug fixes, no new features (X.Y.Z -> X.Y.Z+1)
- minor: New features, backward compatible (X.Y.Z -> X.Y+1.0)
- major: Breaking changes (X.Y.Z -> X+1.0.0)

Ask for confirmation before pushing/releasing.
