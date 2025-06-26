#!/bin/bash
set -e

# Root directories
SRC_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
CHATAPP_ROOT="$SRC_ROOT/Examples/ChatApp/Sources/MLXChatApp"
LLMCLUSTER_SRC="$SRC_ROOT/sample-code/LLMClusterApp/Sources/Core"

# Create required directories
mkdir -p "$CHATAPP_ROOT/Core/Networking"
mkdir -p "$CHATAPP_ROOT/Core/Inference"
mkdir -p "$CHATAPP_ROOT/Core/ModelManager"
mkdir -p "$CHATAPP_ROOT/Core/Design"
mkdir -p "$CHATAPP_ROOT/Core/Utils"
mkdir -p "$CHATAPP_ROOT/Features/Onboarding"
mkdir -p "$CHATAPP_ROOT/Features/Chat"
mkdir -p "$CHATAPP_ROOT/Features/ModelHub"
mkdir -p "$CHATAPP_ROOT/Features/Settings"
mkdir -p "$CHATAPP_ROOT/Shared/iOS"
mkdir -p "$CHATAPP_ROOT/Shared/macOS"

# Copy core logic
cp -v "$LLMCLUSTER_SRC/Networking/HuggingFaceAPI.swift" "$CHATAPP_ROOT/Core/Networking/"
cp -v "$LLMCLUSTER_SRC/Networking/MLXModelSearchUtility.swift" "$CHATAPP_ROOT/Core/Networking/"
cp -v "$LLMCLUSTER_SRC/Inference/InferenceEngine.swift" "$CHATAPP_ROOT/Core/Inference/"
cp -vr "$LLMCLUSTER_SRC/ModelManager/." "$CHATAPP_ROOT/Core/ModelManager/"
cp -vr "$LLMCLUSTER_SRC/Design/." "$CHATAPP_ROOT/Core/Design/"
if [ -d "$LLMCLUSTER_SRC/Utils" ]; then
  cp -vr "$LLMCLUSTER_SRC/Utils/." "$CHATAPP_ROOT/Core/Utils/"
fi

# Optionally copy UI patterns and onboarding
if [ -d "$LLMCLUSTER_SRC/Views" ]; then
  cp -vr "$LLMCLUSTER_SRC/Views/." "$CHATAPP_ROOT/Features/Chat/"
fi
if [ -d "$LLMCLUSTER_SRC/Onboarding" ]; then
  cp -vr "$LLMCLUSTER_SRC/Onboarding/." "$CHATAPP_ROOT/Features/Onboarding/"
fi

# Print next steps
cat <<EOF

✅ LLMClusterApp production components copied to ChatApp.

Next steps:
1. Open Examples/ChatApp/Package.swift and ensure it includes MLX, MLXLLM, and MLXLMCommon dependencies as shown in the documentation.
2. Open the ChatApp Xcode project and add all new files/folders to the MLXChatApp target.
3. Clean and build the project in Xcode.
4. Run the app and enjoy the production-ready MLX chat experience!

If you encounter any build errors, paste them here for troubleshooting.
EOF 