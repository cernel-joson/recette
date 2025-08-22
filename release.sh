#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Prompt for the version number
read -p "Enter the version for this release (e.g., 0.3.1): " VERSION

if [ -z "$VERSION" ]; then
  echo "Version number cannot be empty."
  exit 1
fi

echo "Creating and pushing git tag v$VERSION..."
git tag "v$VERSION"
git push origin "v$VERSION"

echo "Triggering the 'Versioned Release' workflow for v$VERSION..."
gh workflow run "Versioned Release" --ref "v$VERSION" -f version="$VERSION"

echo "✅ Done! Monitor the workflow progress on GitHub."