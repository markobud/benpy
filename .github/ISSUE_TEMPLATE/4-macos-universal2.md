---
name: macOS: support universal2 and Apple Silicon
about: Implement universal2 or per-arch macOS wheel builds and ensure GLPK availability
labels: platform/macos,packaging,enhancement
assignees: ''
---

## Summary

Decide on and implement the macOS distribution strategy: build universal2 wheels or separate arm64/x86_64 wheels. Ensure GLPK and other C dependencies are available for each arch.

Repository: `benpy` branch `development`

## Tasks

- Decide preferred distribution strategy (universal2 vs per-arch).
- Update build scripts (e.g., `cibuildwheel` config) with correct flags and `MACOSX_DEPLOYMENT_TARGET`.
- Ensure GLPK is installed/built for both archs (Homebrew or vendored build).
- Validate produced wheel tags comply with PEPs for wheel platform tags.

## Acceptance criteria

- Successful CI builds for chosen macOS wheel strategy and documented instructions for maintainers.
