import SwiftUI
import UIAI

struct SettingsView: View {
    @Binding var selectedStyleKindRaw: String
    @Binding var selectedColorSchemeRaw: String

    var body: some View {
        SettingsPanel(selectedStyleKindRaw: $selectedStyleKindRaw, selectedColorSchemeRaw: $selectedColorSchemeRaw)
    }

    private func chooseDownloadPath() {
        // Implementation of chooseDownloadPath function
    }
} 