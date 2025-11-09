---
name: Windows wheel build failures (triage)
about: Diagnose Windows wheel build and linking failures (MSVC, GLPK, runtime DLLs)
labels: platform/windows,build,ci,priority/high
assignees: ''
---

## Summary

Windows wheel builds are failing during compilation or linking. This issue is for triage to identify MSVC mismatches, missing GLPK libraries, or incorrect linker flags.

## Environment

- Repository: `benpy` branch `development`
- Relevant files: `setup.py`, `pyproject.toml`, `src/benpy.pyx`, `doc/BuildingWheels.md`
- CI: GitHub Actions windows-latest runner or similar
- Dependency: GLPK (not typically preinstalled on Windows)

## Steps to reproduce

1. On a Windows CI runner or local dev machine with MSVC:
   - Checkout `v210-upgrade`.
   - Run: `pip wheel . -w dist_wheels`.
2. Capture the compiler/linker output and attach logs.

## Expected behavior

Wheels build and link correctly; required runtime DLLs are either bundled or documented.

## Actual behavior

Attach representative logs showing unresolved symbols, missing `.lib` or DLL load errors.

## Logs / artifacts to attach

- Full CI job log
- `cl`/MSVC version info (`cl /Bv`) and `python -V`
- Linker error snippets

## Acceptance criteria

- A Windows wheel builds successfully on CI and passes a smoke test (import on a clean runner).
- Resolution documented: vendor vs dynamic GLPK strategy decided and implemented.

## Suggested next steps

- Determine if GLPK will be bundled or installed as part of CI before build.
- Check MSVC toolset version used by the runner and ensure ABI compatibility with target Python builds.
