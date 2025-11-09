---
name: macOS wheel build failures (triage)
about: Investigate and fix macOS wheel build failures (universal2 / arm64 / x86_64)
labels: platform/macos,build,ci,priority/high
assignees: ''
---

## Summary

Wheel builds for macOS are failing for one or more Python versions/architectures (universal2, arm64 and/or x86_64). This issue is for triage and root-cause identification.

## Environment

- Repository: `benpy` branch `development`
- Relevant files: `pyproject.toml`, `setup.py`, `src/benpy.pyx`, `doc/BuildingWheels.md`
- CI: GitHub Actions macOS runners (macos-latest / macos-11 / macos-12)
- System dependency: GLPK (installed via Homebrew or built from source)

## Steps to reproduce

1. On a macOS runner (GitHub Actions) or local macOS machine:
   - Checkout `v210-upgrade`.
   - Run: `pip wheel . -w dist_wheels` or `python -m build`.
2. Observe the failing step (compilation, linking, wheel tag creation).
3. Attach the full build log and the output of `python -V` and `uname -a`.

## Expected behavior

At least one macOS wheel (universal2 or per-arch) builds successfully with correct wheel tags and links to required libraries.

## Actual behavior

Attach representative CI logs or local build logs showing the failure (link errors, missing headers, or wheel tag mismatch).

## Logs / artifacts to attach

- Full CI job log
- `pip`/`python -m build` output
- `setup.py` verbose build output (if available)

## Acceptance criteria

- Successful build of a macOS wheel on CI for a target Python version/arch.
- Root cause documented and a proposed fix described in this issue.
- A plan for building remaining macOS targets (universal2/arm64/x86_64) is recorded.

## Suggested next steps / debugging hints

- Verify how GLPK is provided on macOS CI (brew vs vendored).
- Check `MACOSX_DEPLOYMENT_TARGET`, `CFLAGS`, and `LDFLAGS` in build environment.
- Consider using `cibuildwheel` for macOS universal2/arm64 handling.
