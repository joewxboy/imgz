import Foundation

/// Protocol for managing starred image state persistence
public protocol StarringService {
    /// Marks an image as starred in the specified folder
    /// - Parameters:
    ///   - imageUrl: The URL of the image to star
    ///   - folderPath: The path of the folder containing the image
    func starImage(at imageUrl: URL, inFolder folderPath: String)
    
    /// Removes the starred status from an image in the specified folder
    /// - Parameters:
    ///   - imageUrl: The URL of the image to unstar
    ///   - folderPath: The path of the folder containing the image
    func unstarImage(at imageUrl: URL, inFolder folderPath: String)
    
    /// Checks if an image is starred in the specified folder
    /// - Parameters:
    ///   - imageUrl: The URL of the image to check
    ///   - folderPath: The path of the folder containing the image
    /// - Returns: True if the image is starred, false otherwise
    func isStarred(imageUrl: URL, inFolder folderPath: String) -> Bool
    
    /// Gets all starred image URLs for a specific folder
    /// - Parameter folderPath: The path of the folder
    /// - Returns: Set of image URLs that are starred in this folder
    func getStarredImageUrls(forFolder folderPath: String) -> Set<URL>
}

/// Implementation of StarringService using UserDefaults
public class UserDefaultsStarringService: StarringService {
    private let userDefaults: UserDefaults
    
    /// Initializes the starring service
    /// - Parameter userDefaults: The UserDefaults instance to use (defaults to .standard)
    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    /// Generates a UserDefaults key for starred images in a folder
    /// - Parameter folderPath: The folder path
    /// - Returns: The key for storing starred images for this folder
    private func makeKey(forFolder folderPath: String) -> String {
        // Normalize the folder path to ensure consistent keys
        let normalizedPath = (folderPath as NSString).standardizingPath
        return "starred.\(normalizedPath)"
    }
    
    /// Gets the set of starred image URLs for a folder
    /// - Parameter folderPath: The folder path
    /// - Returns: Set of image URL paths (as strings) that are starred
    private func getStarredImagePaths(forFolder folderPath: String) -> Set<String> {
        let key = makeKey(forFolder: folderPath)
        if let array = userDefaults.array(forKey: key) as? [String] {
            return Set(array)
        }
        return Set<String>()
    }
    
    /// Saves the set of starred image paths for a folder
    /// - Parameters:
    ///   - starredPaths: The set of image paths to save
    ///   - folderPath: The folder path
    private func saveStarredImagePaths(_ starredPaths: Set<String>, forFolder folderPath: String) {
        let key = makeKey(forFolder: folderPath)
        if starredPaths.isEmpty {
            // Remove the key if no starred images
            userDefaults.removeObject(forKey: key)
        } else {
            userDefaults.set(Array(starredPaths), forKey: key)
        }
    }
    
    public func starImage(at imageUrl: URL, inFolder folderPath: String) {
        var starredPaths = getStarredImagePaths(forFolder: folderPath)
        // Use the absolute path as the identifier
        let imagePath = imageUrl.path
        starredPaths.insert(imagePath)
        saveStarredImagePaths(starredPaths, forFolder: folderPath)
    }
    
    public func unstarImage(at imageUrl: URL, inFolder folderPath: String) {
        var starredPaths = getStarredImagePaths(forFolder: folderPath)
        let imagePath = imageUrl.path
        starredPaths.remove(imagePath)
        saveStarredImagePaths(starredPaths, forFolder: folderPath)
    }
    
    public func isStarred(imageUrl: URL, inFolder folderPath: String) -> Bool {
        let starredPaths = getStarredImagePaths(forFolder: folderPath)
        let imagePath = imageUrl.path
        return starredPaths.contains(imagePath)
    }
    
    public func getStarredImageUrls(forFolder folderPath: String) -> Set<URL> {
        let starredPaths = getStarredImagePaths(forFolder: folderPath)
        return Set(starredPaths.compactMap { URL(fileURLWithPath: $0) })
    }
}

