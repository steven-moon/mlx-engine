import SwiftUI
import SwiftUIKit

@main
struct SwiftUIKitDemoApp: App {
    @AppStorage("selectedStyleKind") private var selectedStyleKindRaw: String = UIAIStyleKind.minimal.rawValue
    @AppStorage("selectedColorScheme") private var selectedColorSchemeRaw: String = UIAIColorScheme.light.rawValue
    
    private var selectedStyleKind: UIAIStyleKind {
        UIAIStyleKind(rawValue: selectedStyleKindRaw) ?? .minimal
    }
    
    private var selectedColorScheme: UIAIColorScheme {
        UIAIColorScheme(rawValue: selectedColorSchemeRaw) ?? .light
    }
    
    private var currentStyle: any UIAIStyle {
        UIAIStyleRegistry.style(for: selectedStyleKind, colorScheme: selectedColorScheme)
    }
    
    var body: some Scene {
        #if os(watchOS)
        WindowGroup {
            NavigationView {
                ContentView()
                    .uiaiStyle(currentStyle)
            }
        }
        #else
        WindowGroup {
            ContentView()
                .uiaiStyle(currentStyle)
        }
        #endif
    }
} 