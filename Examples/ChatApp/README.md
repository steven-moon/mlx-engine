# SampleChatApp: MLXEngine + UIAI SwiftUI Library

---

## Overview

SampleChatApp is a modern, cross-platform SwiftUI application demonstrating the use of the UIAI shared component library for building AI-powered chat and model management apps with MLXEngine.

- **Model Discovery:** Search, filter, and manage MLX-compatible models from Hugging Face.
- **Chat:** Modular, streaming chat interface with onboarding, error handling, and session reset.
- **Settings:** Model selection, max tokens, logging toggle, persistent with @AppStorage, and reset-to-defaults.
- **Diagnostics:** Debug panel, error banners, and token progress bar for robust developer and user feedback.

## Architecture

- **SwiftUI-first:** All UI is built with composable, public SwiftUI components from the UIAI library.
- **Tab-based navigation:** Chat, Models, Settings, and Debug tabs for clear separation of concerns.
- **State management:** Uses @AppStorage and ObservableObject for global and per-session state.
- **Onboarding & error handling:** Onboarding banners and error banners are integrated throughout the app.

## How to Run

1. Clone the repository and open `Examples/ChatApp/` in Xcode (15+ recommended).
2. Select the appropriate scheme (iOS, macOS, etc.) and build/run.
3. Explore the app:
   - **Chat:** Start a conversation with your selected model.
   - **Models:** Discover and download new models.
   - **Settings:** Configure preferences and reset to defaults.
   - **Debug:** View logs, generate debug reports, and troubleshoot.

## Using UIAI in Your Own Project

- Import the `UIAI` library target in your Swift Package or Xcode project.
- Use composable components like `ChatView`, `ModelDiscoveryView`, `SettingsPanel`, and `DebugPanel`.
- See `_docs/UIAI_SharedSwiftUILibrary.md` for a full component catalog and usage examples.
- All components are public, documented, and cross-platform.

## Extending the App

- Add new tabs or flows by composing UIAI components.
- Integrate with your own model sources or chat backends by conforming to the same protocols.
- Contribute improvements or new components to the UIAI library!

---

*Last updated: 2025-06-25* 