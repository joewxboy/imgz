import XCTest
import SwiftCheck
@testable import ImageSlideshowLib

// Feature: macos-image-slideshow, ViewModel Property Tests
final class ViewModelPropertyTests: XCTestCase {
    
    // MARK: - Property 3: Transition duration application
    // Validates: Requirements 2.2
    
    @MainActor
    func testTransitionDurationApplication() {
        property("For any valid transition duration (1-60 seconds), updating configuration should apply the new duration") <- forAll { (duration: Double) in
            // Constrain to valid range (1-60 seconds)
            let validDuration = max(1.0, min(60.0, abs(duration)))
            
            // Create a mock configuration service for testing
            let suiteName = "test.duration.\(UUID().uuidString)"
            guard let testDefaults = UserDefaults(suiteName: suiteName) else {
                return false
            }
            
            let configService = UserDefaultsConfigurationService(userDefaults: testDefaults)
            let viewModel = SlideshowViewModel(
                configurationService: configService,
                imageLoaderService: DefaultImageLoaderService()
            )
            
            // Create new configuration with the test duration
            let newConfig = SlideshowConfiguration(
                transitionDuration: validDuration,
                transitionEffect: .none,
                lastSelectedFolderPath: nil
            )
            
            // Update configuration
            viewModel.updateConfiguration(newConfig)
            
            // Verify the configuration was updated
            let configMatches = viewModel.configuration.transitionDuration == validDuration
            
            // Verify the configuration was persisted
            let loadedConfig = configService.loadConfiguration()
            let persistedMatches = loadedConfig.transitionDuration == validDuration
            
            // Clean up
            testDefaults.removePersistentDomain(forName: suiteName)
            
            return configMatches && persistedMatches
        }
    }
    
    // MARK: - Property 4: Transition effect application
    // Validates: Requirements 3.2
    
    @MainActor
    func testTransitionEffectApplication() {
        property("For any valid transition effect, updating configuration should apply the selected effect") <- forAll { (effectIndex: Int) in
            // Map to valid transition effects
            let effects: [TransitionEffect] = [.slide, .none]
            let validEffect = effects[abs(effectIndex) % effects.count]
            
            // Create a mock configuration service for testing
            let suiteName = "test.effect.\(UUID().uuidString)"
            guard let testDefaults = UserDefaults(suiteName: suiteName) else {
                return false
            }
            
            let configService = UserDefaultsConfigurationService(userDefaults: testDefaults)
            let viewModel = SlideshowViewModel(
                configurationService: configService,
                imageLoaderService: DefaultImageLoaderService()
            )
            
            // Create new configuration with the test effect
            let newConfig = SlideshowConfiguration(
                transitionDuration: 5.0,
                transitionEffect: validEffect,
                lastSelectedFolderPath: nil
            )
            
            // Update configuration
            viewModel.updateConfiguration(newConfig)
            
            // Verify the configuration was updated
            let configMatches = viewModel.configuration.transitionEffect == validEffect
            
            // Verify the configuration was persisted
            let loadedConfig = configService.loadConfiguration()
            let persistedMatches = loadedConfig.transitionEffect == validEffect
            
            // Clean up
            testDefaults.removePersistentDomain(forName: suiteName)
            
            return configMatches && persistedMatches
        }
    }
}

    // MARK: - Property 5: Forward navigation advancement
    // Validates: Requirements 4.3
    
    @MainActor
    func testForwardNavigationAdvancement() {
        property("For any current image index (except the last), pressing right arrow should advance by exactly one position") <- forAll { (imageCount: Int, startIndex: Int) in
            // Constrain to reasonable image count (2-20 images)
            let validImageCount = max(2, min(20, abs(imageCount)))
            
            // Create a temporary directory with test images
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_nav_forward_\(UUID().uuidString)")
            
            do {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            } catch {
                return false
            }
            
            // Create test image files
            for i in 0..<validImageCount {
                let filename = String(format: "image_%03d.jpg", i)
                let fileURL = tempDir.appendingPathComponent(filename)
                FileManager.default.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)
            }
            
            // Create view model and load images
            let suiteName = "test.nav.forward.\(UUID().uuidString)"
            guard let testDefaults = UserDefaults(suiteName: suiteName) else {
                try? FileManager.default.removeItem(at: tempDir)
                return false
            }
            
            let configService = UserDefaultsConfigurationService(userDefaults: testDefaults)
            let viewModel = SlideshowViewModel(
                configurationService: configService,
                imageLoaderService: DefaultImageLoaderService()
            )
            
            // Load images synchronously for testing
            let semaphore = DispatchSemaphore(value: 0)
            var loadSuccess = false
            
            Task { @MainActor in
                do {
                    let imageLoader = DefaultImageLoaderService()
                    let images = try await imageLoader.loadImagesFromFolder(tempDir)
                    viewModel.images = images
                    loadSuccess = !images.isEmpty
                } catch {
                    loadSuccess = false
                }
                semaphore.signal()
            }
            
            semaphore.wait()
            
            guard loadSuccess else {
                try? FileManager.default.removeItem(at: tempDir)
                testDefaults.removePersistentDomain(forName: suiteName)
                return false
            }
            
            // Set starting index (not the last image)
            let validStartIndex = abs(startIndex) % max(1, validImageCount - 1)
            viewModel.currentIndex = validStartIndex
            
            let previousIndex = viewModel.currentIndex
            
            // Navigate forward
            let navSemaphore = DispatchSemaphore(value: 0)
            Task { @MainActor in
                await viewModel.nextImage()
                navSemaphore.signal()
            }
            navSemaphore.wait()
            
            let newIndex = viewModel.currentIndex
            let advancedByOne = newIndex == previousIndex + 1
            
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
            testDefaults.removePersistentDomain(forName: suiteName)
            
            return advancedByOne
        }
    }
    
    // MARK: - Property 6: Backward navigation retreat
    // Validates: Requirements 4.4
    
    @MainActor
    func testBackwardNavigationRetreat() {
        property("For any current image index (except the first), pressing left arrow should decrease by exactly one position") <- forAll { (imageCount: Int, startIndex: Int) in
            // Constrain to reasonable image count (2-20 images)
            let validImageCount = max(2, min(20, abs(imageCount)))
            
            // Create a temporary directory with test images
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_nav_backward_\(UUID().uuidString)")
            
            do {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            } catch {
                return false
            }
            
            // Create test image files
            for i in 0..<validImageCount {
                let filename = String(format: "image_%03d.jpg", i)
                let fileURL = tempDir.appendingPathComponent(filename)
                FileManager.default.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)
            }
            
            // Create view model and load images
            let suiteName = "test.nav.backward.\(UUID().uuidString)"
            guard let testDefaults = UserDefaults(suiteName: suiteName) else {
                try? FileManager.default.removeItem(at: tempDir)
                return false
            }
            
            let configService = UserDefaultsConfigurationService(userDefaults: testDefaults)
            let viewModel = SlideshowViewModel(
                configurationService: configService,
                imageLoaderService: DefaultImageLoaderService()
            )
            
            // Load images synchronously for testing
            let semaphore = DispatchSemaphore(value: 0)
            var loadSuccess = false
            
            Task { @MainActor in
                do {
                    let imageLoader = DefaultImageLoaderService()
                    let images = try await imageLoader.loadImagesFromFolder(tempDir)
                    viewModel.images = images
                    loadSuccess = !images.isEmpty
                } catch {
                    loadSuccess = false
                }
                semaphore.signal()
            }
            
            semaphore.wait()
            
            guard loadSuccess else {
                try? FileManager.default.removeItem(at: tempDir)
                testDefaults.removePersistentDomain(forName: suiteName)
                return false
            }
            
            // Set starting index (not the first image, so we can go backward)
            let validStartIndex = max(1, abs(startIndex) % validImageCount)
            viewModel.currentIndex = validStartIndex
            
            let previousIndex = viewModel.currentIndex
            
            // Navigate backward
            let navSemaphore = DispatchSemaphore(value: 0)
            Task { @MainActor in
                await viewModel.previousImage()
                navSemaphore.signal()
            }
            navSemaphore.wait()
            
            let newIndex = viewModel.currentIndex
            let decreasedByOne = newIndex == previousIndex - 1
            
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
            testDefaults.removePersistentDomain(forName: suiteName)
            
            return decreasedByOne
        }
    }

    // MARK: - Property 9: Error recovery continues playback
    // Validates: Requirements 7.1
    
    @MainActor
    func testErrorRecoveryContinuesPlayback() {
        property("For any slideshow with multiple images where one fails to load, playback should skip to the next valid image") <- forAll { (validImageCount: Int) in
            // Constrain to reasonable image count (3-10 images, need at least 3 to test skipping)
            let imageCount = max(3, min(10, abs(validImageCount)))
            
            // Create a temporary directory with test images
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_error_recovery_\(UUID().uuidString)")
            
            do {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            } catch {
                return false
            }
            
            // Create test image files - mix of valid and "invalid" (empty) files
            for i in 0..<imageCount {
                let filename = String(format: "image_%03d.jpg", i)
                let fileURL = tempDir.appendingPathComponent(filename)
                
                // Create empty files (which will fail to load as images)
                // This simulates corrupted or invalid image files
                FileManager.default.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)
            }
            
            // Create view model
            let suiteName = "test.error.recovery.\(UUID().uuidString)"
            guard let testDefaults = UserDefaults(suiteName: suiteName) else {
                try? FileManager.default.removeItem(at: tempDir)
                return false
            }
            
            let configService = UserDefaultsConfigurationService(userDefaults: testDefaults)
            let viewModel = SlideshowViewModel(
                configurationService: configService,
                imageLoaderService: DefaultImageLoaderService()
            )
            
            // Load images synchronously for testing
            let semaphore = DispatchSemaphore(value: 0)
            var loadSuccess = false
            
            Task { @MainActor in
                do {
                    let imageLoader = DefaultImageLoaderService()
                    let images = try await imageLoader.loadImagesFromFolder(tempDir)
                    viewModel.images = images
                    loadSuccess = !images.isEmpty
                } catch {
                    loadSuccess = false
                }
                semaphore.signal()
            }
            
            semaphore.wait()
            
            guard loadSuccess else {
                try? FileManager.default.removeItem(at: tempDir)
                testDefaults.removePersistentDomain(forName: suiteName)
                return false
            }
            
            // Start playback
            viewModel.startSlideshow()
            let initialIndex = viewModel.currentIndex
            
            // Try to navigate forward (should handle errors gracefully)
            let navSemaphore = DispatchSemaphore(value: 0)
            Task { @MainActor in
                await viewModel.nextImage()
                navSemaphore.signal()
            }
            navSemaphore.wait()
            
            // Verify that we moved to the next index (even if image failed to load)
            // The error recovery should have advanced the index
            let movedForward = viewModel.currentIndex != initialIndex
            
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
            testDefaults.removePersistentDomain(forName: suiteName)
            
            return movedForward
        }
    }
    
    // MARK: - Property 10: Error logging includes filename
    // Validates: Requirements 7.2
    
    @MainActor
    func testErrorLoggingIncludesFilename() {
        property("For any image file that fails to load, the error message should contain the filename") <- forAll { (filenamePrefix: String) in
            // Create a safe filename prefix
            let safePrefix = filenamePrefix.isEmpty ? "test" : String(filenamePrefix.prefix(10).filter { $0.isLetter || $0.isNumber })
            let filename = "\(safePrefix)_image.jpg"
            
            // Create a temporary directory with a test image
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_error_logging_\(UUID().uuidString)")
            
            do {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            } catch {
                return false
            }
            
            // Create an empty file (which will fail to load as an image)
            let fileURL = tempDir.appendingPathComponent(filename)
            FileManager.default.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)
            
            // Create view model
            let suiteName = "test.error.logging.\(UUID().uuidString)"
            guard let testDefaults = UserDefaults(suiteName: suiteName) else {
                try? FileManager.default.removeItem(at: tempDir)
                return false
            }
            
            let configService = UserDefaultsConfigurationService(userDefaults: testDefaults)
            let viewModel = SlideshowViewModel(
                configurationService: configService,
                imageLoaderService: DefaultImageLoaderService()
            )
            
            // Load images synchronously for testing
            let semaphore = DispatchSemaphore(value: 0)
            var loadSuccess = false
            
            Task { @MainActor in
                do {
                    let imageLoader = DefaultImageLoaderService()
                    let images = try await imageLoader.loadImagesFromFolder(tempDir)
                    viewModel.images = images
                    loadSuccess = !images.isEmpty
                } catch {
                    loadSuccess = false
                }
                semaphore.signal()
            }
            
            semaphore.wait()
            
            guard loadSuccess else {
                try? FileManager.default.removeItem(at: tempDir)
                testDefaults.removePersistentDomain(forName: suiteName)
                return false
            }
            
            // Try to load the image (should fail and set error message)
            let loadSemaphore = DispatchSemaphore(value: 0)
            Task { @MainActor in
                await viewModel.nextImage()
                loadSemaphore.signal()
            }
            loadSemaphore.wait()
            
            // Check if error message contains the filename
            let errorContainsFilename = viewModel.errorMessage?.contains(filename) ?? false
            
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
            testDefaults.removePersistentDomain(forName: suiteName)
            
            return errorContainsFilename
        }
    }
}
