---
name: Tests: add integration tests that validate wheel-installed package behavior
about: Add small, fast integration tests that run after wheel build to verify import and basic functionality
labels: test,ci
assignees: ''
---

Repository: `benpy` branch `development`

## Summary

Add small integration tests that are executed after a wheel is built and installed in CI. These tests should be fast and detect import/runtime issues.

## Suggested tests

- `import benpy` and confirm `benpy.__version__` returns expected version.
- Run a minimal example from `src/examples/TestVLP.py` or a small script that constructs a trivial VLP and calls the solver to ensure C-extension entrypoints work.

## Tasks

1. Add test files under `tests/` (or a separate smoke-tests directory) that run when a built wheel is installed.
2. Wire the tests into the CI job that runs after wheel creation.

## Acceptance criteria

- Smoke tests run in CI after wheel creation and fail the job with useful logs on errors.
