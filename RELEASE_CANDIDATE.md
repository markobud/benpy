# Release Candidate: benpy 2.1.0

## ⚠️ IMPORTANT: Tag Push Required

The `release-candidate` tag has been **created locally** but needs to be pushed to the remote repository.

**Current Status:** ✓ Tag created locally | ⏳ Awaiting push to remote

## Overview

The `release-candidate` tag has been created on the `development` branch to mark the commit ready for the benpy 2.1.0 release.

**Tag Details:**
- **Tag Name:** `release-candidate`
- **Branch:** `development`
- **Commit:** `c3480246f6f33459d38a4a20b558088b59cf2359`
- **Created:** 2025-11-13 19:58:12 UTC
- **Version:** 2.1.0
- **Local Tag Ref:** `108b6bde3c416319380c210744ab10d014f3dbf2`

## Tag Information

The tag has been created locally with comprehensive annotations including:
- Release candidate date and commit hash
- Summary of all changes since v1.0.3
- Major features and improvements
- Critical bug fixes
- Testing status
- Migration notes
- Next steps for release

To view the complete tag annotation:
```bash
git show release-candidate --no-patch
```

## 🚀 Pushing the Tag (REQUIRED)

**The tag exists locally but is NOT yet on the remote repository.** You must push it to make it available on GitHub.

There are three methods to accomplish this:

### Method 1: Using the Helper Script (Recommended)

Run the provided script from the repository root:
```bash
./tools/push-release-candidate-tag.sh
```

This script will:
1. Verify the tag exists
2. Display the tag details
3. Confirm before pushing
4. Push the tag to origin
5. Provide links to view the tag and create a release

### Method 2: Manual Push (Quickest)

If you have write access to the repository, this is the fastest method:
```bash
git fetch origin development
git push origin release-candidate
```

**Verification:**
After pushing, verify the tag appears on GitHub:
```bash
git ls-remote --tags origin | grep release-candidate
```

Expected output:
```
108b6bde3c416319380c210744ab10d014f3dbf2  refs/tags/release-candidate
```

### Method 3: Using GitHub Actions

A workflow has been created at `.github/workflows/push-release-candidate-tag.yml` that can be triggered manually to push the tag. This is useful if you want to push the tag through CI/CD with proper permissions.

**To trigger the workflow:**

1. Via GitHub web interface:
   - Go to: https://github.com/markobud/benpy/actions/workflows/push-release-candidate-tag.yml
   - Click "Run workflow"
   - Select branch: `development`
   - Enter tag name: `release-candidate`
   - Click "Run workflow"

2. Via GitHub CLI:
   ```bash
   gh workflow run push-release-candidate-tag.yml \
     --ref development \
     -f tag_name=release-candidate \
     -f dry_run=false
   ```

The workflow includes:
- Tag verification
- Dry-run mode for testing
- Remote existence check
- Push verification
- Links to create GitHub release

## Creating a GitHub Release (Optional)

After pushing the tag, you can create a GitHub release to make it more visible:

### Option 1: Using the Helper Script
```bash
./tools/create-github-release.sh
```

This script will:
- Verify the tag exists on remote
- Extract the tag annotation as release notes
- Create a pre-release on GitHub
- Provide links to view and manage the release

### Option 2: Manual Creation
Visit: https://github.com/markobud/benpy/releases/new?tag=release-candidate

The tag annotation will be pre-filled as the release description.

## Release Candidate Summary

### Major Changes Since v1.0.3

This release candidate represents a significant upgrade:

**Performance Improvements:**
- New in-memory interface provides 2-3x faster solving
- GIL release for better multi-threaded performance

**API Enhancements:**
- `solve_direct()` renamed to `solve()` as the new default
- Enhanced solution objects with status strings and vertex counts
- Direct access to problem and solution data structures

**Platform Support:**
- Cross-platform CI/CD pipeline (Linux, macOS, Windows)
- Python 3.9-3.12 compatibility
- Multi-platform wheel building

**Critical Fixes:**
- Windows crash fixes for unbounded/no-vertex problems
- Memory leak fixes in problem and solution cleanup
- Solve consistency improvements
- File handle issue resolutions

**Infrastructure:**
- Comprehensive test suite (60+ test cases)
- Extensive documentation (In-Memory Interface, Threading Safety, etc.)
- Example notebooks for various problem types

### Testing Status

✓ Multi-platform testing (Linux, macOS, Windows)  
✓ Python 3.9, 3.10, 3.11, 3.12 compatibility  
✓ Cross-platform wheel builds  
✓ Comprehensive unit tests  
✓ Integration tests with various problem types  
✓ Memory leak tests  
✓ Threading safety tests  

## Next Steps

After pushing the tag:

1. **Verify Tag on GitHub:**
   - Visit: https://github.com/markobud/benpy/tags
   - Confirm `release-candidate` tag appears

2. **Create GitHub Release (Optional):**
   - Visit: https://github.com/markobud/benpy/releases/new?tag=release-candidate
   - Add release notes (can use tag annotation)
   - Mark as pre-release if desired

3. **Final Testing:**
   - Perform integration testing
   - User acceptance testing
   - Performance validation

4. **Prepare for PyPI:**
   - Review documentation
   - Verify wheel builds
   - Prepare publishing credentials

5. **Manual Publishing:**
   - When ready, publish to PyPI following the manual publishing workflow
   - Update version tags (e.g., v2.1.0)
   - Merge to master branch if appropriate

## Related Files

- `CHANGELOG.md` - Detailed changelog for version 2.1.0
- `pyproject.toml` - Project metadata (version: 2.1.0)
- `tools/push-release-candidate-tag.sh` - Script to push the tag
- `.github/workflows/push-release-candidate-tag.yml` - Workflow to push the tag

## Viewing Tag Details

### Show Full Annotation
```bash
git show release-candidate --no-patch
```

### Show Tagged Commit
```bash
git log release-candidate -1
```

### List All Tags
```bash
git tag -l
```

### Compare with Previous Release
```bash
git log v1.0.3..release-candidate --oneline
```

## Support

For questions or issues related to this release candidate:
- Check the comprehensive CHANGELOG.md
- Review documentation in the `doc/` directory
- Consult example notebooks in `notebooks/`
- Review test cases in `tests/` for usage examples

---

**Note:** This is a release candidate tag marking the development branch commit as ready for release. Final release publishing to PyPI will be done manually following approval and any additional testing.
