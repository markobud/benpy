---
name: CI: add smoke test for built wheels
about: Validate built wheels by installing them and running a minimal import/example
labels: ci,test,packaging
assignees: ''
---

Repository: `benpy` branch `development`

## Summary

After building wheels in CI, validate them by installing and running a minimal example to catch runtime import/link-time failures early.

## Tasks

1. After wheel build step, create a clean virtualenv.
2. `pip install` the produced wheel(s).
3. Run a smoke command, e.g. `python -c "import benpy; print(benpy.__version__)"` or run `src/examples/TestVLP.py` minimal flow.
4. Fail the job and upload logs/artifacts if the smoke test fails.

## Acceptance criteria

- CI fails when installed wheel does not import or run the smoke test.
