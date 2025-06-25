#!/usr/bin/env bash
set -euo pipefail
echo "⏳  Building & testing MLXEngine…"
swift test
echo "⏳  Building MLXChatApp example…"
( cd Examples/MLXChatApp && swift build )
echo "✅  All good!"
