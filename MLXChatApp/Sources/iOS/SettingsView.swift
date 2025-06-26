import SwiftUI
import UIAI

struct SettingsView: View {
    @State private var enableLogging = false
    @State private var downloadPath = ""
    #if DEBUG
    @State private var showDebugPanel = false
    #endif

    var body: some View {
        SettingsPanel()
    }

    private func chooseDownloadPath() {
        // Implementation of chooseDownloadPath function
    }
} 