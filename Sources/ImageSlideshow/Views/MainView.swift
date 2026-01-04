import SwiftUI
import AppKit
import Combine

/// Root view that composes all slideshow components
public struct MainView: View {
    @StateObject public var viewModel: SlideshowViewModel
    
    public init(viewModel: SlideshowViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    @State private var showingConfiguration = false
    @State private var showingError = false
    @State private var showingFolderPicker = false
    @State private var keyMonitor: Any?
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .automatic
    
    public var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            // Sidebar with configuration
            ConfigurationView(viewModel: viewModel)
        } detail: {
            // Main content area
            VStack(spacing: 0) {
                // Slideshow display
                SlideshowDisplayView(viewModel: viewModel)
                
                // Control panel
                ControlPanelView(viewModel: viewModel)
                    .background(Color(NSColor.controlBackgroundColor))
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button(action: {
                        presentFolderPicker()
                    }) {
                        Label("Select Folder", systemImage: "folder")
                    }
                    .help("Select a folder containing images")
                }
            }
        }
        .onAppear {
            updateWindowTitle()
            setupKeyboardMonitoring()
            // Make window accept first responder for keyboard events
            DispatchQueue.main.async {
                if let window = NSApplication.shared.windows.first {
                    window.makeFirstResponder(window.contentView)
                }
            }
        }
        .onDisappear {
            removeKeyboardMonitoring()
        }
        .onChange(of: viewModel.configuration.lastSelectedFolderPath) { _ in
            updateWindowTitle()
        }
        .onChange(of: viewModel.images.isEmpty) { _ in
            updateWindowTitle()
        }
        .alert("Error", isPresented: $showingError, presenting: viewModel.errorMessage) { _ in
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: { errorMessage in
            Text(errorMessage)
        }
        .onChange(of: viewModel.errorMessage) { newValue in
            showingError = newValue != nil
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ToggleSidebar"))) { _ in
            toggleSidebar()
        }
    }
    
    /// Toggles the sidebar visibility
    private func toggleSidebar() {
        withAnimation {
            if sidebarVisibility == .detailOnly {
                sidebarVisibility = .doubleColumn
            } else {
                sidebarVisibility = .detailOnly
            }
        }
    }
    
    /// Updates the window title based on the current folder or default name
    private func updateWindowTitle() {
        DispatchQueue.main.async {
            if let window = NSApplication.shared.windows.first {
                if let folderPath = viewModel.configuration.lastSelectedFolderPath,
                   !viewModel.images.isEmpty {
                    let folderName = URL(fileURLWithPath: folderPath).lastPathComponent
                    window.title = "ImageSlideshow - \(folderName)"
                } else {
                    window.title = "ImageSlideshow"
                }
            }
        }
    }
    
    /// Presents the folder picker using NSOpenPanel
    private func presentFolderPicker() {
        // Dispatch to next run loop to ensure we're not in the middle of a view update
        DispatchQueue.main.async {
            // Activate the application to ensure it's in the foreground
            NSApplication.shared.activate(ignoringOtherApps: true)
            
            let openPanel = NSOpenPanel()
            openPanel.canChooseFiles = false
            openPanel.canChooseDirectories = true
            openPanel.allowsMultipleSelection = false
            openPanel.message = "Select a folder containing images"
            openPanel.prompt = "Select"
            openPanel.canCreateDirectories = false
            
            // Use runModal for reliable presentation
            let response = openPanel.runModal()
            
            if response == .OK, let url = openPanel.url {
                Task { @MainActor in
                    await self.viewModel.loadFolder(url)
                }
            }
        }
    }
    
    /// Sets up keyboard event monitoring for starring shortcuts
    private func setupKeyboardMonitoring() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak viewModel] event in
            guard let viewModel = viewModel else { return event }
            
            // Get the key character, handling both regular and special keys
            let keyChar = event.charactersIgnoringModifiers?.lowercased() ?? ""
            
            // Handle 'e' key to toggle EXIF display (works in any state)
            if keyChar == "e" {
                viewModel.toggleEXIFDisplay()
                return nil // Consume the event
            }
            
            // Only handle starring shortcuts when paused/idle and images are loaded
            guard (viewModel.state == .paused || viewModel.state == .idle),
                  !viewModel.images.isEmpty,
                  viewModel.currentImage != nil else {
                return event
            }
            
            // Handle 's' key to star/unstar
            if keyChar == "s" {
                if viewModel.isCurrentImageStarred {
                    viewModel.unstarCurrentImage()
                } else {
                    viewModel.starCurrentImage()
                }
                return nil // Consume the event
            }
            
            // Handle 'u' key to unstar
            if keyChar == "u" {
                viewModel.unstarCurrentImage()
                return nil // Consume the event
            }
            
            return event
        }
    }
    
    /// Removes keyboard event monitoring
    private func removeKeyboardMonitoring() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }
}

