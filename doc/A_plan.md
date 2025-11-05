# Plan A — Upgrade benpy to bensolve 2.1.0 (Cython wrapper)

## Overview
This document describes Plan A: the preferred, incremental path to upgrade benpy to use bensolve 2.1.0 while keeping a Cython-based wrapper. The plan focuses on safety, reproducibility, tests, and CI automation. All work will be done on the v210-upgrade branch.

## Goals
- Build benpy against bensolve 2.1.0 (vendored in src/bensolve-mod).
- Keep the wrapper maintainable by centralizing C declarations into .pxd files.
- Add tests and CI to validate builds across platforms and produce wheels.
- Preserve backward compatibility when possible and document breaking changes.

## High-level Phases
Phase 0 — Discovery (1 day)
- Run automated header diffs between current vendored bensolve-mod and official 2.1.0 headers.
- Generate a short report of changed enums, function signatures, typedefs, and structs.
- Run an initial Cython build to collect compile-time errors.

Phase 1 — Cython refactor & extern updates (1–3 days)
- Centralize C declarations into .pxd files (one per logical header: bslv_main, bslv_lp, bslv_vlp, bslv_algs, bslv_lists, bslv_poly).
- Replace monolithic extern blocks in src/benpy.pyx with cimports from the .pxd files.
- Update Cython types, enums, and function prototypes so they exactly match 2.1.0 headers.
- Update THISVERSION in wrapper to "2.1.0".

Phase 2 — Memory ownership & threading (0.5–1 day)
- Audit functions that allocate memory; ensure the wrapper frees or takes ownership as required.
- Add helper free functions or small C shims if upstream changed ownership semantics.
- Optionally release the GIL around long-running solve calls if bensolve internals are thread-safe.

Phase 3 — Tests and CI (2–4 days)
- Add pytest-based unit tests using small example problems (from src/bensolve-mod/ex).
- Add GitHub Actions workflow that performs:
  - Build & test on Linux, macOS, Windows (matrix of Python versions).
  - Build wheels using cibuildwheel and upload artifacts for verification.

Phase 4 — Release and follow-up (0.5–1 day)
- Update README and CHANGELOG to document bensolve 2.1.0 integration and any API changes.
- Tag a release on the v210-upgrade branch and publish wheels to PyPI / releases.
- Monitor issues and patch any regressions.

## Concrete Tasks (commit-sized)
1. Add tools/diff_headers.sh and run it; commit the report (HeaderDiffReport.txt).
2. Add src/pxd files mapping bensolve headers (one file per header).
3. Refactor src/benpy.pyx to cimport the new .pxd files.
4. Fix Cython compile errors (update types, enums, function signatures).
5. Add basic tests under tests/ (test_import.py, test_examples.py).
6. Add CI workflow under .github/workflows/ci.yml that runs tests and builds wheels.
7. Update docs/README.md and THISVERSION string.
8. Tag and release.

## Estimated Timeline
- Discovery & first compile: 1 day
- Cython refactor & extern updates: 1–3 days
- Memory & ownership adjustments: 0.5–1 day
- Tests & CI setup: 2–4 days
- Release & follow-up: 0.5–1 day
Total: 5–10 working days depending on API differences and CI/wheel troubleshooting.

## Risks and Mitigations
- ABI-breaking struct/typedef changes: Mitigation — update Cython declarations and add tests; consider small C compatibility shims.
- Memory ownership changes causing leaks/double-free: Mitigation — audit allocation functions and add explicit frees (or wrapper-managed buffers).
- Build failures on different platforms: Mitigation — use CI matrix and cibuildwheel early; fix platform-specific build flags.
- Vendored divergences vs upstream: keep patches minimal and documented, consider contributing fixes upstream.

## Rollback Plan
- Keep the v210-upgrade branch isolated. If regressions occur, revert specific commits on that branch and continue iterative fixes. The main branch remains unchanged until release.

## Next Action (immediate)
I will add this file into the repository under the v210-upgrade branch as doc/A_plan.md with the commit message 'docs: add A plan for v2.1.0 upgrade'.