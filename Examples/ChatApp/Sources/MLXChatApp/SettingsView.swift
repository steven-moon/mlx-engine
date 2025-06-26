import SwiftUI

struct SettingsView: View {
    @State private var enableLogging = false
    @State private var downloadPath = ""
    #if DEBUG
    @State private var showDebugPanel = false
    #endif

    var body: some View {
        VStack {
            Spacer()
            Text("Settings Coming Soon")
                .font(.title2)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .navigationTitle("Settings")
#if DEBUG
        .sheet(isPresented: $showDebugPanel) {
            DebugPanel()
        }
#endif

        Section("App Settings") {
            Toggle("Enable Logging", isOn: $enableLogging)
            #if os(macOS)
            HStack {
                Text("Download Path")
                Spacer()
                Button("Choose...") {
                    chooseDownloadPath()
                }
            }
            if !downloadPath.isEmpty {
                Text(downloadPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            #endif
            #if DEBUG
            Button("Show Debug Panel") {
                showDebugPanel = true
            }
            #endif
        }
    }

    private func chooseDownloadPath() {
        // Implementation of chooseDownloadPath function
    }
} 