#!/bin/bash
# run_full_swiftuikit_migration.sh
#
# This script automates the migration and push of the SwiftUIKit package.
#
# Usage: bash run_full_swiftuikit_migration.sh

set -e

SRC_SCRIPT="/Users/stevenmoon/Documents/GitHub/mlx-engine/SwiftUIKit/migrate_from_mlxengine.sh"
DEST_SCRIPT="./migrate_from_mlxengine.sh"

# 1. Copy the migration script
if [[ -f "$SRC_SCRIPT" ]]; then
  cp "$SRC_SCRIPT" "$DEST_SCRIPT"
  echo "Copied migrate_from_mlxengine.sh to current directory."
else
  echo "ERROR: Source migration script not found at $SRC_SCRIPT"
  exit 1
fi

# 2. Make it executable
chmod +x "$DEST_SCRIPT"
echo "Made migrate_from_mlxengine.sh executable."

# 3. Run the migration script
./migrate_from_mlxengine.sh --force

echo "Migration script completed."

# 4. Git add, commit, and push
if git status --porcelain | grep .; then
  git add .
  git commit -m "Initial commit: Universal SwiftUI Kit"
  git push -u origin main
  echo "All files committed and pushed to GitHub."
else
  echo "No changes to commit."
fi

echo "SwiftUIKit migration and push complete." 