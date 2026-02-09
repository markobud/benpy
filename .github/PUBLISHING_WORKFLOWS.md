# GitHub Actions Publishing Workflows - Documentation

## Overview

This document describes the publishing workflows for the benpy package to PyPI and TestPyPI.

## Workflows

### 1. test_publish.yml - TestPyPI Publishing

**Purpose**: Test the publication process using TestPyPI before publishing to production PyPI.

**Trigger**: Manual workflow dispatch with confirmation input

**Usage**:
1. Go to Actions tab in GitHub
2. Select "Publish to TestPyPI" workflow
3. Click "Run workflow"
4. Type `test-publish` in the confirmation field
5. Click "Run workflow"

**What it does**:
- Builds the source distribution (sdist)
- Publishes to TestPyPI
- Attempts to verify installation from TestPyPI

**Requirements**:
- Configure TestPyPI trusted publishing OR set `TESTPYPI_API_TOKEN` secret
- Create `testpypi` environment in repository settings

### 2. publish_pypi.yml - Production PyPI Publishing

**Purpose**: Publish the package to production PyPI.

**Triggers**:
- Automatically when a GitHub release is published
- Manual workflow dispatch with confirmation input

**Usage (Manual)**:
1. Go to Actions tab in GitHub
2. Select "Publish to PyPI" workflow
3. Click "Run workflow"
4. Type `publish` in the confirmation field
5. Click "Run workflow"

**Usage (Automatic)**:
1. Create a new release in GitHub
2. Tag the release (e.g., `v2.1.0`)
3. Publish the release
4. The workflow will automatically trigger

**What it does**:
- Verifies release conditions
- Builds the source distribution (sdist)
- Optionally downloads pre-built wheels (if available from build-wheels.yml)
- Publishes to PyPI
- Verifies the publication by installing from PyPI

**Requirements**:
- Configure PyPI trusted publishing OR set `PYPI_API_TOKEN` secret
- Create `pypi` environment in repository settings

## Changes Made

### Fixed Issues

1. **Build Artifacts Job**: 
   - Previous: Only printed placeholder messages
   - Now: Actually builds and uploads the source distribution
   - Added GLPK system dependencies installation
   - Added Python build dependencies installation

2. **Workflow Separation**:
   - Previous: Single workflow tried to handle both TestPyPI and PyPI
   - Now: Separate workflows for testing and production
   - `test_publish.yml` for TestPyPI testing
   - `publish_pypi.yml` for production PyPI

3. **Artifact Handling**:
   - Fixed artifact download to handle missing wheels gracefully
   - Source distribution is always built and uploaded
   - Wheels are optional (can be built separately via build-wheels.yml)

### Workflow Structure

Both workflows follow similar patterns:

```
verify → build_artifacts → [download_artifacts] → publish → verify_publication
```

**verify**: Checks trigger conditions and confirmations
**build_artifacts**: Builds the source distribution
**download_artifacts**: (PyPI only) Consolidates artifacts
**publish**: Uploads to PyPI/TestPyPI
**verify_publication**: Tests installation from the repository

## PyPI Trusted Publishing

Trusted publishing is the recommended authentication method for GitHub Actions.

### Setup for PyPI:

1. Go to https://pypi.org/manage/account/publishing/
2. Add a new publisher:
   - PyPI Project Name: `benpy`
   - Owner: `markobud`
   - Repository: `benpy`
   - Workflow: `publish_pypi.yml`
   - Environment: `pypi`

### Setup for TestPyPI:

1. Go to https://test.pypi.org/manage/account/publishing/
2. Add a new publisher:
   - PyPI Project Name: `benpy`
   - Owner: `markobud`
   - Repository: `benpy`
   - Workflow: `test_publish.yml`
   - Environment: `testpypi`

## Alternative: API Token Authentication

If you prefer API tokens instead of trusted publishing:

1. Generate an API token from PyPI/TestPyPI
2. Add it as a repository secret:
   - `PYPI_API_TOKEN` for PyPI
   - `TESTPYPI_API_TOKEN` for TestPyPI
3. Uncomment the `password:` line in the workflow files

## Environments

Both workflows use GitHub Environments for additional protection:

- `pypi` environment for production publishing
- `testpypi` environment for test publishing

### Creating Environments:

1. Go to repository Settings → Environments
2. Create two environments: `pypi` and `testpypi`
3. Optionally add protection rules (e.g., required reviewers)

## Testing the Workflows

### Test with TestPyPI:

```bash
# Trigger the test workflow manually
gh workflow run test_publish.yml -f confirm=test-publish

# Check the workflow run
gh run list --workflow=test_publish.yml
```

### Verify TestPyPI Installation:

```bash
pip install --index-url https://test.pypi.org/simple/ benpy
```

Note: Dependencies might not be available on TestPyPI, which is expected.

## Building with Wheels

For a complete release including wheels:

1. First run the `build-wheels.yml` workflow to build platform-specific wheels
2. Then run the `publish_pypi.yml` workflow
3. The publish workflow will download wheels if available from the build-wheels run

Alternatively, publish just the source distribution and let users build from source.

## Troubleshooting

### "Artifact not found" Error

This was the original issue. It occurred because:
- The build_artifacts job didn't actually build anything
- Solution: We now build and upload the sdist in the build_artifacts job

### Verification Failures

If installation verification fails:
- Check if the package was actually uploaded to PyPI
- Wait longer (PyPI can take time to index new packages)
- Check for dependency issues

### Permission Denied

- Ensure trusted publishing is configured correctly
- Or ensure API tokens are set as secrets
- Check environment protection rules

## File Locations

- Test workflow: `.github/workflows/test_publish.yml`
- Production workflow: `.github/workflows/publish_pypi.yml`
- Wheel building: `.github/workflows/build-wheels.yml`

## Related Documentation

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [PyPI Publishing Guide](https://packaging.python.org/guides/publishing-package-distribution-releases-using-github-actions-ci-cd-workflows/)
- [Trusted Publishing](https://docs.pypi.org/trusted-publishers/)
