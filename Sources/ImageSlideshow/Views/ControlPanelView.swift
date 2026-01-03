import SwiftUI

/// View that provides playback controls for the slideshow
struct ControlPanelView: View {
    @ObservedObject var viewModel: SlideshowViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            // Folder selection button
            Button(action: {
                viewModel.selectFolder()
            }) {
                Label("Select Folder", systemImage: "folder")
            }
            .help("Select a folder containing images")
            
            Spacer()
            
            // Previous button
            Button(action: {
                Task {
                    await viewModel.previousImage()
                }
            }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
            }
            .keyboardShortcut(.leftArrow, modifiers: [])
            .help("Previous image (Left Arrow)")
            .disabled(viewModel.images.isEmpty)
            
            // Play/Pause button
            Button(action: {
                togglePlayback()
            }) {
                Image(systemName: playPauseIcon)
                    .font(.title)
            }
            .keyboardShortcut(.space, modifiers: [])
            .help(playPauseHelpText)
            .disabled(viewModel.images.isEmpty)
            
            // Next button
            Button(action: {
                Task {
                    await viewModel.nextImage()
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.title2)
            }
            .keyboardShortcut(.rightArrow, modifiers: [])
            .help("Next image (Right Arrow)")
            .disabled(viewModel.images.isEmpty)
        }
        .padding()
    }
    
    /// Returns the appropriate icon for the play/pause button based on current state
    private var playPauseIcon: String {
        switch viewModel.state {
        case .idle, .paused:
            return "play.fill"
        case .playing:
            return "pause.fill"
        }
    }
    
    /// Returns the help text for the play/pause button based on current state
    private var playPauseHelpText: String {
        switch viewModel.state {
        case .idle, .paused:
            return "Play slideshow (Space)"
        case .playing:
            return "Pause slideshow (Space)"
        }
    }
    
    /// Toggles between play and pause states
    private func togglePlayback() {
        switch viewModel.state {
        case .idle, .paused:
            viewModel.startSlideshow()
        case .playing:
            viewModel.pauseSlideshow()
        }
    }
}
