import Foundation

/// Represents the current playback state of the slideshow
public enum SlideshowState: Equatable {
    /// Slideshow is not active
    case idle
    
    /// Slideshow is actively playing and advancing through images
    case playing
    
    /// Slideshow is paused and not advancing
    case paused
}
