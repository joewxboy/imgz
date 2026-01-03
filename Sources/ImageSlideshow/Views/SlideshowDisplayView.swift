import SwiftUI
import AppKit

/// View that displays the current slideshow image with proper scaling and transitions
struct SlideshowDisplayView: View {
    @ObservedObject var viewModel: SlideshowViewModel
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background color for letterboxing
                Color.black
                    .ignoresSafeArea()
                
                // Display current image if available
                if let nsImage = viewModel.currentImage {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height
                        )
                        .transition(transitionForEffect(viewModel.configuration.transitionEffect))
                        .id(viewModel.currentIndex) // Key for transitions
                        .animation(.easeInOut(duration: 0.5), value: viewModel.currentIndex)
                } else {
                    // Placeholder when no image is loaded
                    Text("No image loaded")
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    /// Returns the appropriate SwiftUI transition based on the configuration
    /// - Parameter effect: The transition effect from configuration
    /// - Returns: A SwiftUI AnyTransition
    private func transitionForEffect(_ effect: TransitionEffect) -> AnyTransition {
        switch effect {
        case .slide:
            return .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        case .none:
            return .identity
        }
    }
}
