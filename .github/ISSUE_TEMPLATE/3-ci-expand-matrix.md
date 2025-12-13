name: CI: expand matrix to reproduce failing wheels and collect logs
about: Add CI jobs to cover platform/arch combinations and upload build artifacts/logs for debugging
labels: ci,infra,test
assignees: ''

## Summary

Add a CI job that builds wheels across the combinations of Python versions and platform architectures that currently fail, and upload the full logs and wheel artifacts for inspection.

## Goals


## Tasks

1. Add a workflow/job in GitHub Actions with a matrix covering target Python versions and target platforms/arches.
2. Ensure `pip` build output is preserved (no truncation) and save build logs.
3. Upload built wheel files and logs as job artifacts.
4. Add a small smoke test step that installs the wheel and runs `python -c "import benpy; print(benpy.__version__)"`.

## Acceptance criteria


## Notes

Consider using `cibuildwheel` for multi-arch macOS builds and set `skip`/`only` as needed while debugging.
 Repository: `benpy` branch `development`
- CI runs reproduce the failure and artifacts are available for debugging.
