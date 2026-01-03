import XCTest
@testable import ImageSlideshowLib

// Unit tests for SlideshowViewModel
// Requirements: 4.1, 4.2, 4.5, 7.3
final class SlideshowViewModelTests: XCTestCase {
    
    // MARK: - Test State Transitions
    // Requirements: 4.1, 4.2
    
    @MainActor
    func testStateTransitionFromIdleToPlaying() {
        // Create view model
        let suiteName = "test.state.idle.playing.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let configService = UserDefaultsConfigurationService(userDefaults: testDefaults)
        let viewModel = SlideshowViewModel(
            configurationService: configService,
            imageLoaderService: DefaultImageLoaderService()
        )
        
        // Create temporary directory with test images
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_state_\(UUID().uuidString)")
        
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            // Create test image files
            for i in 0..<3 {
                let filename = "image_\(i).jpg"
                let fileURL = tempDir.appendingPathComponent(filename)
                FileManager.default.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)
            }
            
            // Load images
            let semaphore = DispatchSemaphore(value: 0)
            Task { @MainActor in
                let imageLoader = DefaultImageLoaderService()
                let images = try await imageLoader.loadImagesFromFolder(tempDir)
                viewModel.images = images
                semaphore.signal()
            }
            semaphore.wait()
            
            // Verify initial state is idle
            XCTAssertEqual(viewModel.state, .idle, "Initial state should be idle")
            
            // Start slideshow
            viewModel.startSlideshow()
            
            // Verify state changed to playing
            XCTAssertEqual(viewModel.state, .playing, "State should be playing after starting slideshow")
            
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
            testDefaults.removePersistentDomain(forName: suiteName)
        } catch {
            XCTFail("Failed to set up test: \(error)")
        }
    }
    
    @MainActor
    func testStateTransitionFromPlayingToPaused() {
        // Create view model
        let suiteName = "test.state.playing.paused.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let configService = UserDefaultsConfigurationService(userDefaults: testDefaults)
        let viewModel = SlideshowViewModel(
            configurationService: configService,
            imageLoaderService: DefaultImageLoaderService()
        )
        
        // Create temporary directory with test images
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_pause_\(UUID().uuidString)")
        
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            // Create test image files
            for i in 0..<3 {
                let filename = "image_\(i).jpg"
                let fileURL = tempDir.appendingPathComponent(filename)
                FileManager.default.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)
            }
            
            // Load images
            let semaphore = DispatchSemaphore(value: 0)
            Task { @MainActor in
                let imageLoader = DefaultImageLoaderService()
                let images = try await imageLoader.loadImagesFromFolder(tempDir)
                viewModel.images = images
                semaphore.signal()
            }
            semaphore.wait()
            
            // Start slideshow
            viewModel.startSlideshow()
            XCTAssertEqual(viewModel.state, .playing, "State should be playing")
            
            // Pause slideshow
            viewModel.pauseSlideshow()
            
            // Verify state changed to paused
            XCTAssertEqual(viewModel.state, .paused, "State should be paused after pausing slideshow")
            
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
            testDefaults.removePersistentDomain(forName: suiteName)
        } catch {
            XCTFail("Failed to set up test: \(error)")
        }
    }
    
    @MainActor
    func testStateTransitionFromPausedToPlaying() {
        // Create view model
        let suiteName = "test.state.paused.playing.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let configService = UserDefaultsConfigurationService(userDefaults: testDefaults)
        let viewModel = SlideshowViewModel(
            configurationService: configService,
            imageLoaderService: DefaultImageLoaderService()
        )
        
        // Create temporary directory with test images
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_resume_\(UUID().uuidString)")
        
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            // Create test image files
            for i in 0..<3 {
                let filename = "image_\(i).jpg"
                let fileURL = tempDir.appendingPathComponent(filename)
                FileManager.default.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)
            }
            
            // Load images
            let semaphore = DispatchSemaphore(value: 0)
            Task { @MainActor in
                let imageLoader = DefaultImageLoaderService()
                let images = try await imageLoader.loadImagesFromFolder(tempDir)
                viewModel.images = images
                semaphore.signal()
            }
            semaphore.wait()
            
            // Start and pause slideshow
            viewModel.startSlideshow()
            viewModel.pauseSlideshow()
            XCTAssertEqual(viewModel.state, .paused, "State should be paused")
            
            // Resume slideshow
            viewModel.resumeSlideshow()
            
            // Verify state changed back to playing
            XCTAssertEqual(viewModel.state, .playing, "State should be playing after resuming slideshow")
            
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
            testDefaults.removePersistentDomain(forName: suiteName)
        } catch {
            XCTFail("Failed to set up test: \(error)")
        }
    }
    
    // MARK: - Test Boundary Navigation
    // Requirements: 4.5
    
    @MainActor
    func testNavigationAtFirstImage() async {
        // Create view model
        let suiteName = "test.boundary.first.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let configService = UserDefaultsConfigurationService(userDefaults: testDefaults)
        let viewModel = SlideshowViewModel(
            configurationService: configService,
            imageLoaderService: DefaultImageLoaderService()
        )
        
        // Create temporary directory with test images
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_first_\(UUID().uuidString)")
        
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            // Create test image files
            for i in 0..<5 {
                let filename = String(format: "image_%03d.jpg", i)
                let fileURL = tempDir.appendingPathComponent(filename)
                FileManager.default.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)
            }
            
            // Load images
            let imageLoader = DefaultImageLoaderService()
            let images = try await imageLoader.loadImagesFromFolder(tempDir)
            viewModel.images = images
            
            // Verify we're at the first image
            XCTAssertEqual(viewModel.currentIndex, 0, "Should start at first image")
            
            // Navigate backward from first image (should wrap to last)
            await viewModel.previousImage()
            
            // Verify we wrapped to the last image
            XCTAssertEqual(viewModel.currentIndex, images.count - 1, "Should wrap to last image when going backward from first")
            
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
            testDefaults.removePersistentDomain(forName: suiteName)
        } catch {
            XCTFail("Failed to set up test: \(error)")
        }
    }
    
    @MainActor
    func testNavigationAtLastImage() async {
        // Create view model
        let suiteName = "test.boundary.last.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let configService = UserDefaultsConfigurationService(userDefaults: testDefaults)
        let viewModel = SlideshowViewModel(
            configurationService: configService,
            imageLoaderService: DefaultImageLoaderService()
        )
        
        // Create temporary directory with test images
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_last_\(UUID().uuidString)")
        
        do {
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            // Create test image files
            for i in 0..<5 {
                let filename = String(format: "image_%03d.jpg", i)
                let fileURL = tempDir.appendingPathComponent(filename)
                FileManager.default.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)
            }
            
            // Load images
            let imageLoader = DefaultImageLoaderService()
            let images = try await imageLoader.loadImagesFromFolder(tempDir)
            viewModel.images = images
            
            // Navigate to last image
            viewModel.currentIndex = images.count - 1
            
            // Navigate forward from last image (should wrap to first)
            await viewModel.nextImage()
            
            // Verify we wrapped to the first image
            XCTAssertEqual(viewModel.currentIndex, 0, "Should wrap to first image when going forward from last")
            
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
            testDefaults.removePersistentDomain(forName: suiteName)
        } catch {
            XCTFail("Failed to set up test: \(error)")
        }
    }
}
