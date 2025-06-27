#!/bin/bash
# run_full_swiftuikit_migration.sh
#
# This script migrates SwiftUI Kit source files and docs from your MLXEngine repo
# to your new swift-uikit repo, then commits and pushes to GitHub.
#
# Usage: bash run_full_swiftuikit_migration.sh

set -e

# Absolute paths
SRC_DIR="/Users/stevenmoon/Documents/GitHub/mlx-engine/Sources/UIAI"
DOCS_SRC="/Users/stevenmoon/Documents/GitHub/mlx-engine/_docs/UIAI_SwiftUI_Package_Specification.md"
DEST_DIR="Sources/SwiftUIKit"
DOCS_DEST="_docs/SwiftUIKit_Package_Specification.md"
TESTS_DIR="Tests/SwiftUIKitTests"

# List of SwiftUI Kit files to migrate
FILES=(
  SettingsPanel.swift
  StyleGallery.swift
  ModelDetailView.swift
  ModelCardView.swift
  ErrorBanner.swift
  ModelSuggestionBanner.swift
  UIAIStyle.swift
  ChatView.swift
  ModelDiscoveryView.swift
  OnboardingBanner.swift
  AsyncImageView.swift
  DebugPanel.swift
  TokenProgressBar.swift
  ChatInputView.swift
  ChatSessionManager.swift
  ChatHistoryView.swift
)

echo "==> Creating destination directories if needed..."
mkdir -p "$DEST_DIR"
mkdir -p "_docs"
mkdir -p "$TESTS_DIR"

echo "==> Copying SwiftUI Kit source files..."
for file in "${FILES[@]}"; do
  src="$SRC_DIR/$file"
  dest="$DEST_DIR/$file"
  if [[ -f "$src" ]]; then
    cp -f "$src" "$dest"
    echo "  Copied $file"
  else
    echo "  Warning: $file not found in $SRC_DIR"
  fi
done

echo "==> Copying specification doc..."
if [[ -f "$DOCS_SRC" ]]; then
  cp -f "$DOCS_SRC" "$DOCS_DEST"
  echo "  Copied specification doc to $DOCS_DEST"
else
  echo "  Warning: Specification doc not found at $DOCS_SRC"
fi

echo "==> Migration complete."

# Git add, commit, and push
if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  if git status --porcelain | grep .; then
    git add .
    git commit -m "Add SwiftUI Kit source files and docs"
    git push
    echo "==> All files committed and pushed to GitHub."
  else
    echo "==> No changes to commit."
  fi
else
  echo "==> Not a git repository. Please run this script from inside your swift-uikit repo."
fi

echo "==> SwiftUIKit migration and push complete."
