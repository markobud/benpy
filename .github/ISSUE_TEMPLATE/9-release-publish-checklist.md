---
name: Release: publishing checklist for wheels
about: Checklist and verification steps to publish new platform wheels to PyPI
labels: release,docs
assignees: ''
---

Repository: `benpy` branch `development`

## Summary

After wheel builds and smoke tests pass, follow a repeatable checklist to publish wheels to PyPI and validate them on target platforms.

## Checklist

1. Build wheels for all target platforms and Python versions.
2. Run smoke tests (import + minimal example) for each wheel.
3. Optionally sign wheels or add metadata (if desired).
4. Tag the release in Git and create a changelog entry.
5. Upload wheels to PyPI (use `twine upload dist/*`).
6. Verify on a clean environment (pip install from PyPI) on each platform.
7. Monitor issue tracker and collect user reports for regressions.

## Acceptance criteria

- Published wheels are installable on their target platforms and pass smoke tests.
