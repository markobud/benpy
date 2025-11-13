#!/usr/bin/env bash
# Script to create a GitHub Release from the release-candidate tag
# Requires: gh (GitHub CLI) to be installed and authenticated

set -e

TAG_NAME="release-candidate"
REPO="markobud/benpy"
RELEASE_TITLE="Release Candidate: benpy 2.1.0"
PRERELEASE="true"  # Mark as pre-release
MAX_TAG_MESSAGE_LINES=999  # Maximum lines to read from tag annotation

echo "=========================================="
echo "Create GitHub Release from Tag"
echo "=========================================="
echo ""
echo "Tag: $TAG_NAME"
echo "Repository: $REPO"
echo "Pre-release: $PRERELEASE"
echo ""

# Check if gh is installed
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed."
    echo "Install it from: https://cli.github.com/"
    echo ""
    echo "Alternative: Create release manually at:"
    echo "  https://github.com/$REPO/releases/new?tag=$TAG_NAME"
    exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
    echo "Error: Not authenticated with GitHub CLI."
    echo "Run: gh auth login"
    exit 1
fi

# Check if tag exists on remote
echo "Checking if tag exists on remote..."
if ! git ls-remote --tags https://github.com/$REPO | grep -q "refs/tags/$TAG_NAME"; then
    echo "Error: Tag '$TAG_NAME' does not exist on remote."
    echo ""
    echo "Push the tag first:"
    echo "  git push origin $TAG_NAME"
    echo ""
    echo "Or use the workflow:"
    echo "  gh workflow run push-release-candidate-tag.yml"
    exit 1
fi

echo "✓ Tag exists on remote"
echo ""

# Get tag annotation for release notes
echo "Fetching tag annotation..."
TAG_MESSAGE=$(git tag -l -n${MAX_TAG_MESSAGE_LINES} "$TAG_NAME" 2>/dev/null || echo "")

if [ -z "$TAG_MESSAGE" ]; then
    # Tag might not be fetched locally, fetch it
    git fetch --tags
    TAG_MESSAGE=$(git tag -l -n${MAX_TAG_MESSAGE_LINES} "$TAG_NAME")
fi

# Extract just the message part (remove first line with tag name)
RELEASE_NOTES=$(echo "$TAG_MESSAGE" | tail -n +2)

echo "Creating GitHub release..."
echo ""

# Build the gh release create command based on PRERELEASE flag
GH_CMD="gh release create \"$TAG_NAME\" \
    --repo \"$REPO\" \
    --title \"$RELEASE_TITLE\" \
    --notes \"$RELEASE_NOTES\""

if [ "$PRERELEASE" = "true" ]; then
    GH_CMD="$GH_CMD --prerelease"
fi

# Create the release
eval "$GH_CMD"

echo ""
echo "✅ GitHub release created successfully!"
echo ""
echo "View the release at:"
echo "  https://github.com/$REPO/releases/tag/$TAG_NAME"
echo ""
echo "Next steps:"
echo "1. Review the release on GitHub"
echo "2. Edit release notes if needed"
echo "3. Attach any additional assets (wheels, docs)"
echo "4. When ready, publish to PyPI"
