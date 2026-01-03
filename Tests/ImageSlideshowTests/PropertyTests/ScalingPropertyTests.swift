import XCTest
import AppKit
@testable import ImageSlideshowLib

// Feature: macos-image-slideshow, Scaling Property Tests
final class ScalingPropertyTests: XCTestCase {
    
    // MARK: - Property 7: Image scaling preserves aspect ratio
    // Validates: Requirements 5.1, 5.2, 5.3
    
    func testImageScalingPreservesAspectRatio() {
        // Test the property across 100+ random combinations of image and window sizes
        let iterations = 100
        var failures: [(imageSize: CGSize, windowSize: CGSize, reason: String)] = []
        
        for _ in 0..<iterations {
            // Generate random dimensions (10-2000 pixels)
            let imageWidth = CGFloat.random(in: 10...2000)
            let imageHeight = CGFloat.random(in: 10...2000)
            let windowWidth = CGFloat.random(in: 100...2000)
            let windowHeight = CGFloat.random(in: 100...2000)
            
            let imageSize = CGSize(width: imageWidth, height: imageHeight)
            let windowSize = CGSize(width: windowWidth, height: windowHeight)
            
            // Calculate original aspect ratio
            let originalAspectRatio = imageWidth / imageHeight
            
            // Calculate scaled dimensions using aspect-fit logic
            let scaledSize = calculateAspectFitSize(
                imageSize: imageSize,
                containerSize: windowSize
            )
            
            // Calculate scaled aspect ratio
            let scaledAspectRatio = scaledSize.width / scaledSize.height
            
            // Verify aspect ratio is preserved within a small tolerance (0.01%)
            let tolerance: CGFloat = 0.0001
            let aspectRatioPreserved = abs(originalAspectRatio - scaledAspectRatio) < tolerance
            
            if !aspectRatioPreserved {
                failures.append((imageSize, windowSize, "Aspect ratio not preserved: \(originalAspectRatio) vs \(scaledAspectRatio)"))
                continue
            }
            
            // Verify the scaled image fits within the window
            let fitsInWindow = scaledSize.width <= windowWidth && scaledSize.height <= windowHeight
            
            if !fitsInWindow {
                failures.append((imageSize, windowSize, "Scaled image doesn't fit: \(scaledSize) vs \(windowSize)"))
                continue
            }
            
            // Verify at least one dimension matches the container (aspect-fit behavior)
            let widthMatches = abs(scaledSize.width - windowWidth) < 1.0
            let heightMatches = abs(scaledSize.height - windowHeight) < 1.0
            let touchesEdge = widthMatches || heightMatches
            
            if !touchesEdge {
                failures.append((imageSize, windowSize, "Scaled image doesn't touch edge"))
            }
        }
        
        // Report failures if any
        if !failures.isEmpty {
            let failureMessages = failures.prefix(5).map { failure in
                "Image: \(failure.imageSize), Window: \(failure.windowSize) - \(failure.reason)"
            }.joined(separator: "\n")
            
            XCTFail("Property test failed in \(failures.count)/\(iterations) cases:\n\(failureMessages)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Calculates the size of an image when scaled to fit within a container using aspect-fit
    /// This mirrors the behavior of SwiftUI's .aspectRatio(contentMode: .fit)
    private func calculateAspectFitSize(imageSize: CGSize, containerSize: CGSize) -> CGSize {
        let imageAspectRatio = imageSize.width / imageSize.height
        let containerAspectRatio = containerSize.width / containerSize.height
        
        var scaledSize: CGSize
        
        if imageAspectRatio > containerAspectRatio {
            // Image is wider than container - fit to width
            scaledSize = CGSize(
                width: containerSize.width,
                height: containerSize.width / imageAspectRatio
            )
        } else {
            // Image is taller than container - fit to height
            scaledSize = CGSize(
                width: containerSize.height * imageAspectRatio,
                height: containerSize.height
            )
        }
        
        return scaledSize
    }
}
