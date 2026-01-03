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
    private var slideshowTimer: Timer?
    
    // MARK: - Initialization
    
    /// Initializes the view model with required services
    /// - Parameters:
    ///   - configurationService: Service for persisting configuration
    ///   - imageLoaderService: Service for loading images
    ///   - instanceId: Optional instance identifier for configuration isolation.
    ///                 If provided, a UserDefaultsConfigurationService will be created with this instance ID.
    ///                 If nil and no configurationService is provided, uses shared configuration (backward compatible).
    public init(
        configurationService: ConfigurationService? = nil,
        imageLoaderService: ImageLoaderService = DefaultImageLoaderService(),
        instanceId: String? = nil
    ) {
        // Use provided configuration service, or create one with instance ID if provided
        if let configurationService = configurationService {
            self.configurationService = configurationService
        } else {
            self.configurationService = UserDefaultsConfigurationService(instanceId: instanceId)
        }
        self.imageLoaderService = imageLoaderService
        
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
            
            // Update images array
            images = loadedImages
            currentIndex = 0
            errorMessage = nil
            
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
    
    // MARK: - Configuration Management
    
    /// Updates the slideshow configuration
    /// - Parameter newConfig: The new configuration to apply
    func updateConfiguration(_ newConfig: SlideshowConfiguration) {
        // Save configuration
        do {
            try configurationService.saveConfiguration(newConfig)
            configuration = newConfig
            
            // If slideshow is playing, restart timer with new duration
            if state == .playing {
                startTimer()
            }
        } catch {
            errorMessage = "Failed to save configuration: \(error.localizedDescription)"
        }
    }
}
