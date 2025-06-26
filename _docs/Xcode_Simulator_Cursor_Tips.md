# Xcode, iOS Simulator & Cursor: Productivity Tips for MLXEngine

---

## What's New (2024–2025)

- **Advanced Simulator CLI:** simctl push, privacy, video recording, status bar overrides, CA certs
- **Xcode 15/16/26 Features:** Multi-simulator, pointer/trackpad, AI tools, live previews, dark/light mode
- **Productivity:** More shortcuts, view debugger hotkey, automation (Fastlane, CI/CD)
- **Testing/Profiling:** XCTest, Instruments, memory/network debugging, parallel tests
- **SwiftUI/iOS 26:** Incremental state, Apple Intelligence, universal APIs
- **Accessibility:** Inspector, color blindness, theme switching
- **Troubleshooting:** DerivedData, reset simulator, dependency update
- **Quick Reference Table & FAQ**

---

## 1. Quick Reference Table

| Task/Feature                | Command/Shortcut/Tip                                                                 |
|----------------------------|------------------------------------------------------------------------------------|
| Open file                   | `Cmd+Shift+O`                                                                       |
| Show code snippet library   | `Cmd+Shift+L`                                                                       |
| Multi-cursor editing        | `Option+Click`                                                                      |
| Jump to method/symbol       | `Ctrl+6`                                                                            |
| Toggle comment              | `Cmd+/`                                                                             |
| Toggle debug area           | `Cmd+Y`                                                                             |
| View debugger hotkey        | (Set up global shortcut, e.g. `Ctrl+Shift+D`)                                       |
| Clean build folder          | `Shift+Cmd+K`                                                                       |
| Clear Derived Data          | `rm -rf ~/Library/Developer/Xcode/DerivedData`                                      |
| Run tests                   | `swift test --enable-code-coverage`                                                 |
| Regenerate Xcode project    | `xcodegen generate`                                                                 |
| Push notification (simctl)  | `xcrun simctl push booted <bundle-id> payload.apns`                                 |
| Grant permission (simctl)   | `xcrun simctl privacy booted grant location <bundle-id>`                            |
| Record video (simctl)       | `xcrun simctl io booted recordVideo output.mp4`                                     |
| Override status bar         | `xcrun simctl status_bar booted override --time 9:41 --batteryState charged`        |
| Add CA cert (simctl)        | `xcrun simctl keychain booted add-root-cert myCA.pem`                              |
| Reset Simulator             | Menu: Device > Erase All Content and Settings                                       |

---

## 2. Building, Running & Debugging SwiftUI Apps

- **Clean builds:**
  ```bash
  rm -rf .build Package.resolved
  swift package resolve
  swift package update
  ```
- **Xcode build for iOS Simulator:**
  ```bash
  xcodebuild -scheme MLXChatApp-iOS \
    -workspace MLXChatApp/MLXChatApp.xcodeproj/project.xcworkspace \
    -destination 'platform=iOS Simulator,name=iPhone 16' build
  ```
- **Run tests with coverage:**
  ```bash
  swift test --enable-code-coverage
  ```
- **SwiftUI Previews:** Use Previews for rapid UI iteration. Ensure `.uiaiStyle` is injected at the correct level.

---

## 3. Advanced Simulator Features & simctl Tips

- **Simulate push notifications:**
  ```bash
  xcrun simctl push booted <bundle-id> payload.apns
  ```
- **Grant/revoke permissions:**
  ```bash
  xcrun simctl privacy booted grant location <bundle-id>
  xcrun simctl privacy booted revoke camera <bundle-id>
  ```
- **Record video directly from Simulator:**
  ```bash
  xcrun simctl io booted recordVideo output.mp4
  ```
- **Override status bar for screenshots:**
  ```bash
  xcrun simctl status_bar booted override --time 9:41 --batteryState charged
  ```
- **Add root CA certificates:**
  ```bash
  xcrun simctl keychain booted add-root-cert myCA.pem
  ```
- **Multi-device testing:** Run and test on several devices at once (iPhone, iPad, Watch).
- **Pointer/trackpad simulation:** Test iPad pointer support directly in Simulator.
- **Resizable windows:** Use physical, point-accurate, and pixel-accurate scaling for device previews.
- **Dark/Light mode toggling:** Quickly switch appearance from the Features menu or with keyboard shortcuts.
- **Reference:** [WWDC20: Become a Simulator Expert](https://developer.apple.com/videos/play/wwdc2020/10647/)

---

## 4. Xcode 15/16/26 Features & Productivity

- **AI-powered code completion and refactoring** (Xcode 26+): Leverage new AI tools for code suggestions, documentation, and test generation.
- **Multiple Simulators:** Run and test on several devices at once.
- **SwiftUI live previews:** Use `.uiaiStyle` and environment injection for accurate theming in Previews.
- **Tabs and workspace organization:** Use tabs to manage multiple files and contexts.
- **Swift Package Manager:** Use SPM for dependency management.
- **Automate repetitive tasks:** Use Fastlane, Xcode build scripts, or GitHub Actions for CI/CD and screenshots.

---

## 5. Productivity & Debugging Shortcuts

- **Essential Xcode shortcuts:**
  - `Cmd+Shift+O`: Open quickly
  - `Cmd+Shift+L`: Show code snippet library
  - `Ctrl+6`: Jump to method/symbol
  - `Cmd+Option+Shift+J`: Jump to last edit
  - `Cmd+/`: Toggle comment
  - `Cmd+Y`: Toggle debug area
  - `Option+Click`: Multi-cursor editing
- **View Debugger Hotkey:**
  - Use a global shortcut (e.g., `Ctrl+Shift+D`) to trigger "Capture View Hierarchy" while interacting with Simulator ([see guide](https://simonbs.dev/posts/running-xcodes-view-debugger-while-interacting-with-the-simulator/)).
- **Automate repetitive tasks:**
  - Use Fastlane, Xcode build scripts, or GitHub Actions for CI/CD and screenshots.

---

## 6. Testing, Profiling, and Performance

- **XCTest improvements:** Use new assertions, performance tests, and parallel test execution.
- **Instruments:** Profile memory, CPU, and network directly from Xcode for both Simulator and device.
- **Memory graph debugger:** Visualize retain cycles and leaks.
- **Network inspector:** Debug HTTP traffic in real time.
- **Optimize build settings:**
  - Enable incremental builds, build active architecture only, and clear derived data regularly.

---

## 7. SwiftUI & iOS 26+ Best Practices

- **SwiftUI performance:** Use new incremental state APIs for large lists and animations (iOS 26+).
- **Apple Intelligence API:** Mention on-device AI features and privacy improvements.
- **Universal APIs:** Highlight cross-platform consistency (iOS, macOS, watchOS).
- **Update dependencies regularly:**
  ```bash
  swift package update
  xcodegen generate
  ```

---

## 8. Accessibility & Theming

- **Test accessibility in Simulator:** Use Accessibility Inspector and test with VoiceOver.
- **Color blindness simulation:** Use Simulator's options to preview color accessibility.
- **Theme switching:** Test dark/light mode and high-contrast themes.
- **Reference:** [Apple Human Interface Guidelines: Color and Themes](https://developer.apple.com/design/human-interface-guidelines/color)

---

## 9. Troubleshooting & Maintenance

- **Clear Derived Data:**
  ```bash
  rm -rf ~/Library/Developer/Xcode/DerivedData
  ```
- **Reset Simulator content and settings:**
  - Menu: Device > Erase All Content and Settings
- **Update dependencies regularly:**
  ```bash
  swift package update
  xcodegen generate
  ```
- **DebugPanel:** Use the in-app DebugPanel (Settings → Show Debug Panel) to view logs and generate reports.

---

## 10. Reference & Learning Resources

- [Apple Developer Simulator Guide](https://developer.apple.com/documentation/xcode/simulating-your-app-s-environment)
- [Xcode Release Notes](https://developer.apple.com/documentation/xcode-release-notes)
- [SwiftUI Performance Best Practices](https://developer.apple.com/documentation/swiftui/performance)
- [Fastlane for iOS](https://docs.fastlane.tools/getting-started/ios/setup/)
- [UIAI/MLXEngine SwiftUI Development & Troubleshooting Guide](UIAI_Development_Troubleshooting.md)
- [Cursor Docs](https://docs.cursor.com/)

---

## 11. FAQ

**Q: Why is my app slow in Simulator?**
- Simulator is not as fast as real devices, especially for GPU/ML workloads. Try smaller models, close other apps, and profile with Instruments.

**Q: How do I test push notifications?**
- Use `xcrun simctl push booted <bundle-id> payload.apns` with a valid APNS payload.

**Q: How do I reset permissions in Simulator?**
- Use `xcrun simctl privacy booted reset all` or reset Simulator content and settings.

**Q: How do I debug memory leaks?**
- Use the Memory Graph Debugger in Xcode and Instruments.

**Q: How do I automate screenshots or deployments?**
- Use Fastlane or Xcode build scripts for automation.

**Q: How do I test accessibility?**
- Use Accessibility Inspector and enable VoiceOver in Simulator.

---

## 12. Best Practices for Model Development

- **Keep model download logic in `ModelDownloader`**—never spread across files.
- **Use Swift Concurrency** (`async/await`, `AsyncSequence`) for all async work.
- **Maintain `ModelRegistry.swift`** for static model configs; do not hard-code IDs elsewhere.
- **Unit tests**: Test only the public API; use `MockLLMEngine` for simulator CI.

---
*Last updated: 2024-06-27* 