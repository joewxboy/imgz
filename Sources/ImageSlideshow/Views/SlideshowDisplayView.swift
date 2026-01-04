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
                    ZStack {
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
                        
                        // Starred indicator in top-right corner
                        if viewModel.isCurrentImageStarred {
                            VStack {
                                HStack {
                                    Spacer()
                                    Image(systemName: "star.fill")
                                        .font(.title)
                                        .foregroundColor(.yellow)
                                        .padding(16)
                                        .background(
                                            Circle()
                                                .fill(Color.black.opacity(0.5))
                                        )
                                }
                                Spacer()
                            }
                        }
                        
                        // EXIF headers overlay (only when paused/idle and toggle is enabled)
                        if viewModel.configuration.showEXIFHeaders && (viewModel.state == .paused || viewModel.state == .idle),
                           let exifData = viewModel.currentImageEXIFData,
                           exifData.hasData {
                            VStack {
                                Spacer()
                                HStack {
                                    Spacer()
                                    EXIFOverlayView(exifData: exifData)
                                }
                            }
                            .padding()
                        }
                    }
                } else {
                    // Placeholder when no image is loaded
                    Text("No image loaded")
                        .foregroundColor(.white)
                }
            }
        }
        .focusable()
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

/// View that displays EXIF metadata in an overlay
struct EXIFOverlayView: View {
    let exifData: EXIFData
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // Camera information
                if let make = exifData.cameraMake, let model = exifData.cameraModel {
                    EXIFRow(label: "Camera", value: "\(make) \(model)")
                } else if let model = exifData.cameraModel {
                    EXIFRow(label: "Camera", value: model)
                }
                
                // Exposure settings
                if let iso = exifData.iso {
                    EXIFRow(label: "ISO", value: "\(iso)")
                }
                
                if let aperture = exifData.aperture {
                    EXIFRow(label: "Aperture", value: String(format: "f/%.1f", aperture))
                }
                
                if let shutterSpeed = exifData.shutterSpeed {
                    EXIFRow(label: "Shutter Speed", value: shutterSpeed)
                }
                
                if let exposureMode = exifData.exposureMode {
                    EXIFRow(label: "Exposure Mode", value: exposureMode)
                }
                
                // Lens
                if let focalLength = exifData.focalLength {
                    EXIFRow(label: "Focal Length", value: String(format: "%.0f mm", focalLength))
                }
                
                // Date
                if let dateTaken = exifData.dateTaken {
                    EXIFRow(label: "Date Taken", value: formatDate(dateTaken))
                }
                
                // GPS
                if let lat = exifData.latitude, let lon = exifData.longitude {
                    EXIFRow(label: "GPS", value: String(format: "%.6f, %.6f", lat, lon))
                }
                
                // Image dimensions
                if let width = exifData.imageWidth, let height = exifData.imageHeight {
                    EXIFRow(label: "Dimensions", value: "\(width) × \(height)")
                }
            }
            .padding(12)
        }
        .frame(maxWidth: 300, maxHeight: 400)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.75))
        )
        .foregroundColor(.white)
    }
    
    /// Formats a date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// A single row in the EXIF overlay
struct EXIFRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label + ":")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(.caption)
                .fontDesign(.monospaced)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
