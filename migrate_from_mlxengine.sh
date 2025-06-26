#!/bin/bash
# migrate_from_mlxengine.sh
#
# Usage: ./migrate_from_mlxengine.sh [--force]
#
# Copies all SwiftUI-related files from the MLXEngine repo (Sources/UIAI/) to the new SwiftUIKit package structure.
# If --force is passed, existing files will be overwritten.

set -e

SRC_DIR="../Sources/UIAI"
DEST_DIR="Sources/SwiftUIKit"
DOCS_SRC="../_docs/UIAI_SwiftUI_Package_Specification.md"
DOCS_DEST="_docs/SwiftUIKit_Package_Specification.md"
TESTS_DIR="Tests/SwiftUIKitTests"

FORCE=0
if [[ "$1" == "--force" ]]; then
  FORCE=1
fi

mkdir -p "$DEST_DIR"
mkdir -p "_docs"
mkdir -p "$TESTS_DIR"

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

for file in "${FILES[@]}"; do
  src="$SRC_DIR/$file"
  dest="$DEST_DIR/$file"
  if [[ -f "$src" ]]; then
    if [[ -f "$dest" && $FORCE -eq 0 ]]; then
      echo "Skipping $file (already exists, use --force to overwrite)"
    else
      cp -f "$src" "$dest"
      echo "Copied $file"
    fi
  else
    echo "Warning: $file not found in $SRC_DIR"
  fi
done

# Copy the specification doc
if [[ -f "$DOCS_SRC" ]]; then
  cp -f "$DOCS_SRC" "$DOCS_DEST"
  echo "Copied specification doc to $DOCS_DEST"
else
  echo "Warning: Specification doc not found at $DOCS_SRC"
fi

echo "Migration complete." 