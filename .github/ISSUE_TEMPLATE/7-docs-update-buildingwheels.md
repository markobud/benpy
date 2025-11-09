---
name: Docs: update BuildingWheels.md with platform-specific prerequisites
about: Document system prerequisites, devcontainer hints, and troubleshooting for wheel building
labels: docs,help-wanted
assignees: ''
---

Repository: `benpy` branch `development`

## Summary

Update `doc/BuildingWheels.md` (and/or add `RELEASE.md`) with clear, platform-specific instructions and troubleshooting for building wheels locally and on CI.

## Content to add

- Exact system packages for Linux (manylinux), macOS (Homebrew packages), and Windows (MSVC, GLPK installer/build steps).
- Recommended Python versions and compiler/toolchain versions.
- How to use the devcontainer included in the repo for reproducible builds.
- Example `cibuildwheel` and GitHub Actions snippets.
- Common errors and quick fixes (linker errors, missing headers, wheel tag problems).

## Acceptance criteria

- `doc/BuildingWheels.md` updated to allow a new developer to reproduce wheel builds locally and on CI.
