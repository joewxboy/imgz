import SwiftUI
import AppKit
@_exported import ImageSlideshowLib

class AppDelegate: NSObject, NSApplicationDelegate {
    // Generate a unique instance ID for this app instance
    // This allows multiple instances to have isolated configurations
    let instanceId: String = UUID().uuidString
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure the app is a regular app with proper activation
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct ImageSlideshowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            MainView(viewModel: SlideshowViewModel(
                configurationService: nil,
                imageLoaderService: DefaultImageLoaderService(),
                instanceId: appDelegate.instanceId
            ))
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            ViewCommands()
        }
    }
}

/// Commands for the View menu
struct ViewCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .toolbar) {
            Divider()
            Button("Toggle Sidebar") {
                NotificationCenter.default.post(name: NSNotification.Name("ToggleSidebar"), object: nil)
            }
            .keyboardShortcut("s", modifiers: [.command, .option])
        }
    }
}
