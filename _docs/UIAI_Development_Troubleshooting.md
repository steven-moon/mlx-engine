# UIAI/MLXEngine SwiftUI Development & Troubleshooting Guide

---

## 1. Workspace Cleanup & Reboot

- Remove build artifacts and resolved packages:
  ```bash
  rm -rf .build Package.resolved
  ```
- Deinitialize and reinitialize all submodules:
  ```bash
  git submodule deinit -f .
  git submodule update --init --recursive
  ```
- Force a fresh dependency resolution:
  ```bash
  swift package resolve
  swift package update
  ```

## 2. Resolving SwiftPM & Submodule Errors

- If you see errors about missing submodules or fetch-pack failures:
  - Check directory permissions on `.build` and your workspace.
  - Try cloning the problematic repo manually:
    ```bash
    git clone --recurse-submodules https://github.com/ml-explore/mlx-swift.git
    ```
  - Update your git client to the latest version.
  - Check for disk space and inode exhaustion.
  - If a submodule fails, try removing its folder in `.build/checkouts/` and re-running `swift package resolve`.

## 3. Style System Integration Hints

- Use the `UIAIStyle` protocol for all style/theme logic.
- Inject the current style at the root of your app with `.uiaiStyle(...)`.
- Use `@Environment(\.uiaiStyle)` in all UIAI components for consistent appearance.
- Support runtime switching by storing the selected style and color scheme in `@AppStorage`.
- Register custom styles with `UIAIStyleRegistry.register(...)`.
- Add doc-comments (`///`) to all public types and properties.

## 4. Cursor Rules for UIAI/MLXEngine

- All public types must have `///` doc-comments.
- Use `any UIAIStyle` for protocol-typed values (Swift 6+).
- Keep style logic modular and extensible; never hard-code style IDs outside the registry.
- Use Swift Concurrency for async work; avoid legacy callbacks.
- Keep files < 400 LOC; split extensions into separate files if needed.
- Use 4-space indentation, 120-char line limit, and end files with a single newline.
- Reference internal code with Cursor-style citations and external docs with markdown links.

## 5. Testing, Building, and Debugging

- Build for iOS Simulator with the correct scheme and device ID:
  ```bash
  xcodebuild -scheme MLXChatApp-iOS -workspace MLXChatApp/MLXChatApp.xcodeproj/project.xcworkspace -destination 'platform=iOS Simulator,name=iPhone 16' build
  ```
- Run tests with:
  ```bash
  swift test --enable-code-coverage
  ```
- If tests fail due to dependency errors, repeat the cleanup steps above.
- For UI issues, use SwiftUI previews and check that `.uiaiStyle` is injected at the correct level.

## 6. Reference Links

- [Apple Human Interface Guidelines: Color and Themes](https://developer.apple.com/design/human-interface-guidelines/color)
- [SwiftUI Environment Documentation](https://developer.apple.com/documentation/swiftui/environment)
- [UIAI Style System Design](UIAI_StyleSystem_Design.md)

---

*Last updated: 2024-06-26* 