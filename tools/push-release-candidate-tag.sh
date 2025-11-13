#!/bin/bash
# Script to push the release-candidate tag to the remote repository
# This script should be run with appropriate GitHub credentials

set -e

TAG_NAME="release-candidate"
BRANCH="development"

echo "=========================================="
echo "Push Release Candidate Tag"
echo "=========================================="
echo ""
echo "Tag: $TAG_NAME"
echo "Branch: $BRANCH"
echo ""

# Check if tag exists
if ! git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
    echo "Error: Tag '$TAG_NAME' does not exist locally."
    echo "Please create the tag first using:"
    echo "  git tag -a $TAG_NAME $BRANCH -F <annotation-file>"
    exit 1
fi

# Show tag details
echo "Tag details:"
echo "----------------------------------------"
git show "$TAG_NAME" --no-patch
echo "----------------------------------------"
echo ""

# Confirm before pushing
read -p "Do you want to push this tag to the remote repository? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Push cancelled."
    exit 0
fi

# Push the tag
echo "Pushing tag to remote..."
git push origin "$TAG_NAME"

echo ""
echo "✓ Tag pushed successfully!"
echo ""
echo "View tag at:"
echo "  https://github.com/markobud/benpy/releases/tag/$TAG_NAME"
echo ""
echo "To create a GitHub release from this tag, visit:"
echo "  https://github.com/markobud/benpy/releases/new?tag=$TAG_NAME"
