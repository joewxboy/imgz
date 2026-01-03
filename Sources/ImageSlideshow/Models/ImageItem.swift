import Foundation

/// Represents an individual image file in the slideshow
public struct ImageItem: Identifiable, Equatable {
    /// Unique identifier for the image item
    public let id: UUID
    
    /// File system URL pointing to the image file
    public let url: URL
    
    /// Name of the image file
    public let filename: String
    
    /// Creates a new image item
    /// - Parameters:
    ///   - id: Unique identifier (default: new UUID)
    ///   - url: File system URL to the image
    ///   - filename: Name of the image file
    public init(id: UUID = UUID(), url: URL, filename: String) {
        self.id = id
        self.url = url
        self.filename = filename
    }
}
