---
name: Windows: decide and implement GLPK dependency strategy
about: Choose whether to vendor GLPK, link statically, or require system install and update build accordingly
labels: platform/windows,dependency,packaging
assignees: ''
---

Repository: `benpy` branch `development`

## Summary

For Windows we must choose how to provide GLPK for build and runtime. Current failures indicate missing or mismatched GLPK at link/load time.

## Options to evaluate

1. Vendor/build GLPK during wheel build and bundle the DLL into the wheel (preferred for end-user convenience).
2. Require GLPK to be preinstalled on the system (documented in docs) — easier for builds but worse UX.
3. Use a conda/externally-managed dependency (not ideal for PyPI wheels).

## Tasks

- Evaluate licensing compatibility for bundling GLPK.
- Prototype a CI step that builds and bundles GLPK for Windows.
- Update `setup.py`/build logic and CI scripts accordingly.

## Acceptance criteria

- A Windows wheel builds on CI and either contains a usable GLPK DLL or documents a reproducible install step for runtime.
