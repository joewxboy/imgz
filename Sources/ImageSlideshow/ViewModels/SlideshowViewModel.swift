import Foundation
import AppKit
import Combine

/// Central state manager for the slideshow application
@MainActor
public class SlideshowViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Array of all loaded images
    @Published var images: [ImageItem] = []
    
    /// Current index in the images array
    @Published var currentIndex: Int = 0
    
    /// Currently displayed image
    @Published var currentImage: NSImage?
    
    /// Current playback state
    @Published var state: SlideshowState = .idle
    
    /// Current configuration settings
    @Published var configuration: SlideshowConfiguration
    
    /// Error message to display to user
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    
    private let configurationService: ConfigurationService
    private let imageLoaderService: ImageLoaderService
    private let starringService: StarringService
    private var slideshowTimer: Timer?
    
    /// Original unfiltered images array (used when filtering by starred status)
    private var originalImages: [ImageItem] = []
    
    // MARK: - Initialization
    
    /// Initializes the view model with required services
    /// - Parameters:
    ///   - configurationService: Service for persisting configuration
    ///   - imageLoaderService: Service for loading images
    ///   - starringService: Service for managing starred images
    ///   - instanceId: Optional instance identifier for configuration isolation.
    ///                 If provided, a UserDefaultsConfigurationService will be created with this instance ID.
    ///                 If nil and no configurationService is provided, uses shared configuration (backward compatible).
    public init(
        configurationService: ConfigurationService? = nil,
        imageLoaderService: ImageLoaderService = DefaultImageLoaderService(),
        starringService: StarringService? = nil,
        instanceId: String? = nil
    ) {
        // Use provided configuration service, or create one with instance ID if provided
        if let configurationService = configurationService {
            self.configurationService = configurationService
        } else {
            self.configurationService = UserDefaultsConfigurationService(instanceId: instanceId)
        }
        self.imageLoaderService = imageLoaderService
        
        // Use provided starring service or create default one
        if let starringService = starringService {
            self.starringService = starringService
        } else {
            self.starringService = UserDefaultsStarringService()
        }
        
        // Load saved configuration
        self.configuration = self.configurationService.loadConfiguration()
    }
    
    // MARK: - Folder Selection
    
    /// Presents a folder selection dialog and loads images from the selected folder
    func selectFolder() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.message = "Select a folder containing images"
        openPanel.prompt = "Select"
        
        // Use runModal for synchronous presentation
        let response = openPanel.runModal()
        
        if response == .OK, let url = openPanel.url {
            Task { @MainActor in
                await self.loadImagesFromFolder(url)
            }
        }
    }
    
    /// Loads images from the specified folder (public method for SwiftUI fileImporter)
    /// - Parameter url: The folder URL to load images from
    public func loadFolder(_ url: URL) async {
        await loadImagesFromFolder(url)
    }
    
    /// Loads images from the specified folder
    /// - Parameter url: The folder URL to load images from
    private func loadImagesFromFolder(_ url: URL) async {
        do {
            // Load images from folder
            let loadedImages = try await imageLoaderService.loadImagesFromFolder(url)
            
            // Check if folder is empty
            if loadedImages.isEmpty {
                errorMessage = "The selected folder contains no supported image formats (jpg, jpeg, png, gif, heic, tiff, bmp)"
                return
            }
            
            // Store original images (unfiltered)
            originalImages = loadedImages
            
            // Apply filter if enabled
            if configuration.showOnlyStarred {
                applyStarredFilter()
            } else {
                images = loadedImages
            }
            
            // Reset index and validate
            currentIndex = 0
            if currentIndex >= images.count && !images.isEmpty {
                currentIndex = 0
            }
            
            // Clear any previous error messages
            errorMessage = nil
            
            // If filter is enabled but no starred images, show message (not error)
            if images.isEmpty && configuration.showOnlyStarred {
                errorMessage = "No starred images found in this folder"
            }
            
            // Update configuration with selected folder path
            configuration.lastSelectedFolderPath = url.path
            try? configurationService.saveConfiguration(configuration)
            
            // Load first image
            if !images.isEmpty {
                await loadCurrentImage()
            }
        } catch {
            errorMessage = "Failed to load images from folder: \(error.localizedDescription)"
        }
    }
    
    /// Loads the image at the current index
    private func loadCurrentImage() async {
        guard currentIndex >= 0 && currentIndex < images.count else {
            currentImage = nil
            return
        }
        
        let imageItem = images[currentIndex]
        
        do {
            currentImage = try await imageLoaderService.loadImage(from: imageItem)
        } catch {
            // Log error with filename
            print("Error loading image \(imageItem.filename): \(error.localizedDescription)")
            errorMessage = "Failed to load image: \(imageItem.filename)"
        }
    }
    
    // MARK: - Playback Control
    
    /// Starts the slideshow playback
    func startSlideshow() {
        guard !images.isEmpty else { return }
        
        state = .playing
        startTimer()
    }
    
    /// Pauses the slideshow playback
    func pauseSlideshow() {
        state = .paused
        stopTimer()
    }
    
    /// Resumes the slideshow playback
    func resumeSlideshow() {
        guard state == .paused else { return }
        
        state = .playing
        startTimer()
    }
    
    /// Starts the timer for automatic image advancement
    private func startTimer() {
        stopTimer() // Stop any existing timer
        
        slideshowTimer = Timer.scheduledTimer(
            withTimeInterval: configuration.transitionDuration,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.advanceToNextImage()
            }
        }
    }
    
    /// Stops the timer
    private func stopTimer() {
        slideshowTimer?.invalidate()
        slideshowTimer = nil
    }
    
    /// Advances to the next image automatically
    private func advanceToNextImage() async {
        guard state == .playing else { return }
        await nextImage()
    }
    
    // MARK: - Manual Navigation
    
    /// Advances to the next image
    func nextImage() async {
        guard !images.isEmpty else { return }
        
        // Move to next index, wrapping around to 0 if at the end
        currentIndex = (currentIndex + 1) % images.count
        
        // Try to load the image, skip to next if it fails
        await loadCurrentImageWithErrorRecovery()
    }
    
    /// Goes back to the previous image
    func previousImage() async {
        guard !images.isEmpty else { return }
        
        // Move to previous index, wrapping around to last if at the beginning
        currentIndex = currentIndex == 0 ? images.count - 1 : currentIndex - 1
        
        // Try to load the image, skip to previous if it fails
        await loadCurrentImageWithErrorRecovery()
    }
    
    /// Loads the current image with error recovery
    /// If loading fails, attempts to skip to the next valid image
    private func loadCurrentImageWithErrorRecovery() async {
        guard !images.isEmpty else { return }
        
        let startIndex = currentIndex
        var attemptsRemaining = images.count
        
        while attemptsRemaining > 0 {
            let imageItem = images[currentIndex]
            
            do {
                currentImage = try await imageLoaderService.loadImage(from: imageItem)
                errorMessage = nil
                return // Successfully loaded
            } catch {
                // Log error with filename
                print("Error loading image \(imageItem.filename): \(error.localizedDescription)")
                
                // If playing, continue to next image
                if state == .playing {
                    currentIndex = (currentIndex + 1) % images.count
                    attemptsRemaining -= 1
                    
                    // If we've tried all images, stop playback
                    if currentIndex == startIndex {
                        errorMessage = "Unable to load any images. Stopping playback."
                        state = .idle
                        stopTimer()
                        return
                    }
                } else {
                    // If not playing, just show the error
                    errorMessage = "Failed to load image: \(imageItem.filename)"
                    return
                }
            }
        }
    }
    
    // MARK: - Starring
    
    /// Published property to track starred state changes
    @Published var starredStateChanged: Bool = false
    
    /// Checks if the current image is starred
    var isCurrentImageStarred: Bool {
        guard currentIndex >= 0 && currentIndex < images.count,
              let folderPath = configuration.lastSelectedFolderPath else {
            return false
        }
        let imageItem = images[currentIndex]
        return starringService.isStarred(imageUrl: imageItem.url, inFolder: folderPath)
    }
    
    /// Stars the current image (only works when paused or idle)
    func starCurrentImage() {
        guard (state == .paused || state == .idle),
              currentIndex >= 0 && currentIndex < images.count,
              let folderPath = configuration.lastSelectedFolderPath else {
            return
        }
        
        let imageItem = images[currentIndex]
        starringService.starImage(at: imageItem.url, inFolder: folderPath)
        
        // Notify SwiftUI that the starred state has changed
        starredStateChanged.toggle()
        objectWillChange.send()
        
        // If filter is active, update the filtered images array
        if configuration.showOnlyStarred {
            // Re-apply filter to include the newly starred image
            applyStarredFilter()
            // Ensure current index is still valid
            if currentIndex >= images.count && !images.isEmpty {
                currentIndex = 0
            }
        }
    }
    
    /// Unstars the current image (only works when paused or idle)
    func unstarCurrentImage() {
        guard (state == .paused || state == .idle),
              currentIndex >= 0 && currentIndex < images.count,
              let folderPath = configuration.lastSelectedFolderPath else {
            return
        }
        
        let imageItem = images[currentIndex]
        starringService.unstarImage(at: imageItem.url, inFolder: folderPath)
        
        // Notify SwiftUI that the starred state has changed
        starredStateChanged.toggle()
        objectWillChange.send()
        
        // If filter is active, update the filtered images array
        if configuration.showOnlyStarred {
            let previousIndex = currentIndex
            // Re-apply filter to exclude the newly unstarred image
            applyStarredFilter()
            
            // Adjust current index if needed
            if images.isEmpty {
                currentIndex = 0
                currentImage = nil
                errorMessage = "No starred images remaining"
            } else {
                errorMessage = nil // Clear error if images are available
                if previousIndex >= images.count {
                    // If we were at the end and it got removed, move to last image
                    currentIndex = max(0, images.count - 1)
                    Task {
                        await loadCurrentImage()
                    }
                } else if previousIndex < images.count {
                    // Try to maintain position, but load the image at the new index
                    Task {
                        await loadCurrentImage()
                    }
                }
            }
        }
    }
    
    /// Applies the starred filter to the images array
    private func applyStarredFilter() {
        guard let folderPath = configuration.lastSelectedFolderPath else {
            images = originalImages
            return
        }
        
        let starredUrls = starringService.getStarredImageUrls(forFolder: folderPath)
        images = originalImages.filter { starredUrls.contains($0.url) }
    }
    
    /// Toggles the show-only-starred filter
    func toggleShowOnlyStarred() {
        var newConfig = configuration
        newConfig.showOnlyStarred.toggle()
        updateConfiguration(newConfig)
    }
    
    // MARK: - Configuration Management
    
    /// Updates the slideshow configuration
    /// - Parameter newConfig: The new configuration to apply
    func updateConfiguration(_ newConfig: SlideshowConfiguration) {
        let wasFiltering = configuration.showOnlyStarred
        let willFilter = newConfig.showOnlyStarred
        
        // Save configuration
        do {
            try configurationService.saveConfiguration(newConfig)
            configuration = newConfig
            
            // If filter state changed, apply or remove filter
            if wasFiltering != willFilter {
                if willFilter {
                    // Enable filter
                    applyStarredFilter()
                    // Validate current index
                    if currentIndex >= images.count {
                        currentIndex = 0
                    }
                    if images.isEmpty {
                        errorMessage = "No starred images found in this folder"
                        currentImage = nil
                        // Clear error after a moment so user can still interact
                    } else {
                        errorMessage = nil // Clear any previous error
                        Task {
                            await loadCurrentImage()
                        }
                    }
                } else {
                    // Disable filter - restore original images
                    images = originalImages
                    // Validate current index
                    if currentIndex >= images.count {
                        currentIndex = 0
                    }
                    errorMessage = nil
                    Task {
                        await loadCurrentImage()
                    }
                }
            }
            
            // If slideshow is playing, restart timer with new duration
            if state == .playing {
                startTimer()
            }
        } catch {
            errorMessage = "Failed to save configuration: \(error.localizedDescription)"
        }
    }
}
