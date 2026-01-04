import Foundation

/// Represents the transition effect used when changing between images
public enum TransitionEffect: String, Codable {
    case slide
    case none
}

/// Configuration settings for the slideshow application
public struct SlideshowConfiguration: Codable, Equatable {
    /// Duration in seconds between image transitions (1-60 seconds)
    public var transitionDuration: TimeInterval
    
    /// Visual effect applied during image transitions
    public var transitionEffect: TransitionEffect
    
    /// Path to the last selected folder, if any
    public var lastSelectedFolderPath: String?
    
    /// Whether to show only starred photos in the slideshow
    public var showOnlyStarred: Bool
    
    /// Whether to show EXIF headers overlay when paused
    public var showEXIFHeaders: Bool
    
    /// Creates a new slideshow configuration
    /// - Parameters:
    ///   - transitionDuration: Duration between transitions (default: 5.0 seconds)
    ///   - transitionEffect: Transition effect to apply (default: .none)
    ///   - lastSelectedFolderPath: Optional path to last selected folder
    ///   - showOnlyStarred: Whether to show only starred photos (default: false)
    ///   - showEXIFHeaders: Whether to show EXIF headers overlay (default: false)
    public init(
        transitionDuration: TimeInterval = 5.0,
        transitionEffect: TransitionEffect = .none,
        lastSelectedFolderPath: String? = nil,
        showOnlyStarred: Bool = false,
        showEXIFHeaders: Bool = false
    ) {
        self.transitionDuration = transitionDuration
        self.transitionEffect = transitionEffect
        self.lastSelectedFolderPath = lastSelectedFolderPath
        self.showOnlyStarred = showOnlyStarred
        self.showEXIFHeaders = showEXIFHeaders
    }
}
