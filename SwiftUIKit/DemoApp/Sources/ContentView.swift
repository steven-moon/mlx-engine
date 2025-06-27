import SwiftUI
import SwiftUIKit

struct ContentView: View {
    @AppStorage("selectedStyleKind") private var selectedStyleKindRaw: String = UIAIStyleKind.minimal.rawValue
    @AppStorage("selectedColorScheme") private var selectedColorSchemeRaw: String = UIAIColorScheme.light.rawValue
    @Environment(\.uiaiStyle) private var uiaiStyle: any UIAIStyle
    
    private var selectedStyleKind: UIAIStyleKind {
        UIAIStyleKind(rawValue: selectedStyleKindRaw) ?? .minimal
    }
    
    private var selectedColorScheme: UIAIColorScheme {
        UIAIColorScheme(rawValue: selectedColorSchemeRaw) ?? .light
    }
    
    var body: some View {
        #if os(watchOS)
        List {
            NavigationLink("Appearance", destination: AppearanceSettingsView(selectedStyleKindRaw: $selectedStyleKindRaw, selectedColorSchemeRaw: $selectedColorSchemeRaw))
            NavigationLink("Components", destination: ComponentsShowcaseView())
            NavigationLink("Examples", destination: ExamplesView())
            NavigationLink("Settings", destination: SettingsPanel(selectedStyleKindRaw: $selectedStyleKindRaw, selectedColorSchemeRaw: $selectedColorSchemeRaw))
        }
        .navigationTitle("SwiftUIKit Demo")
        #else
        TabView {
            // Default tab: Appearance - Showcase the theming system
            AppearanceSettingsView(selectedStyleKindRaw: $selectedStyleKindRaw, selectedColorSchemeRaw: $selectedColorSchemeRaw)
                .tabItem { 
                    Label("Appearance", systemImage: "paintpalette.fill") 
                }
            
            // Components showcase - Universal UI components
            ComponentsShowcaseView()
                .tabItem { 
                    Label("Components", systemImage: "square.grid.2x2.fill") 
                }
            
            // Examples - Real-world usage
            ExamplesView()
                .tabItem { 
                    Label("Examples", systemImage: "doc.text.fill") 
                }
            
            // Settings - App configuration
            SettingsPanel(selectedStyleKindRaw: $selectedStyleKindRaw, selectedColorSchemeRaw: $selectedColorSchemeRaw)
                .tabItem { 
                    Label("Settings", systemImage: "gear") 
                }
        }
        #endif
    }
}

#if DEBUG
#Preview {
    ContentView()
        .uiaiStyle(MinimalStyle(colorScheme: .light))
}
#endif 