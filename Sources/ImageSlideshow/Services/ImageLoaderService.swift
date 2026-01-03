import Foundation
import AppKit

/// Protocol defining image loading operations
public protocol ImageLoaderService {
    /// Loads all supported images from a folder
    /// - Parameter url: The folder URL to scan
    /// - Returns: Array of ImageItem objects sorted alphabetically by filename
    /// - Throws: Error if folder cannot be accessed
    func loadImagesFromFolder(_ url: URL) async throws -> [ImageItem]
    
    /// Loads an NSImage from an ImageItem
    /// - Parameter item: The ImageItem to load
    /// - Returns: The loaded NSImage
    /// - Throws: Error if image cannot be loaded
    func loadImage(from item: ImageItem) async throws -> NSImage
}

/// Default implementation of ImageLoaderService
public class DefaultImageLoaderService: ImageLoaderService {
    public init() {}
    /// Supported image file extensions
    private let supportedExtensions: Set<String> = [
        "jpg", "jpeg", "png", "gif", "heic", "tiff", "bmp"
    ]
    
    /// Loads all supported images from a folder
    /// - Parameter url: The folder URL to scan
    /// - Returns: Array of ImageItem objects sorted alphabetically by filename
    /// - Throws: Error if folder cannot be accessed
    public func loadImagesFromFolder(_ url: URL) async throws -> [ImageItem] {
        let fileManager = FileManager.default
        
        // Get contents of directory
        let contents = try fileManager.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
        )
        
        // Filter for supported image formats
        let imageURLs = contents.filter { url in
            guard let isRegularFile = try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile,
                  isRegularFile else {
                return false
            }
            
            let fileExtension = url.pathExtension.lowercased()
            return supportedExtensions.contains(fileExtension)
        }
        
        // Sort alphabetically by filename
        let sortedURLs = imageURLs.sorted { url1, url2 in
            url1.lastPathComponent.localizedStandardCompare(url2.lastPathComponent) == .orderedAscending
        }
        
        // Create ImageItem objects
        let imageItems = sortedURLs.map { url in
            ImageItem(url: url, filename: url.lastPathComponent)
        }
        
        return imageItems
    }
    
    /// Loads an NSImage from an ImageItem
    /// - Parameter item: The ImageItem to load
    /// - Returns: The loaded NSImage
    /// - Throws: Error if image cannot be loaded
    public func loadImage(from item: ImageItem) async throws -> NSImage {
        guard let image = NSImage(contentsOf: item.url) else {
            throw ImageLoaderError.failedToLoadImage(filename: item.filename)
        }
        return image
    }
}

/// Errors that can occur during image loading
enum ImageLoaderError: LocalizedError {
    case failedToLoadImage(filename: String)
    
    var errorDescription: String? {
        switch self {
        case .failedToLoadImage(let filename):
            return "Failed to load image: \(filename)"
        }
    }
}
