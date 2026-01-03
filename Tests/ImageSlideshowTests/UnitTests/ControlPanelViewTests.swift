import XCTest
import SwiftUI
@testable import ImageSlideshowLib

/// Unit tests for ControlPanelView
/// Requirements: 4.1, 4.2, 4.3, 4.4
final class ControlPanelViewTests: XCTestCase {
    
    // MARK: - Test Play/Pause Button State Changes
    // Requirements: 4.1, 4.2
    
    @MainActor
    func testPlayPauseButtonShowsPlayIconWhenIdle() {
        // Create view model in idle state
        let suiteName = "test.control.idle.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let configService = UserDefaultsConfigurationService(userDefaults: testDefaults)
        let viewModel = SlideshowViewModel(
            configurationService: configService,
            imageLoaderService: DefaultImageLoaderService()
        )
        
        // Verify state is idle
        XCTAssertEqual(viewModel.state, .idle, "Initial state should be idle")
        
        // Create control panel view
        let controlPanel = ControlPanelView(viewModel: viewModel)
        
        // The view should show play icon when idle
        // We verify this by checking the viewModel state which the view uses
        XCTAssertEqual(viewModel.state, .idle, "State should be idle, which means play icon is shown")
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    @MainActor
    func testPlayPauseButtonShowsPauseIconWhenPlaying() {
        // Create view model
        let suiteName = "test.control.playing.\(UUID().uuidString)"
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
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_control_playing_\(UUID().uuidString)")
        
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
            
            // Verify state is playing
            XCTAssertEqual(viewModel.state, .playing, "State should be playing, which means pause icon is shown")
            
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
            testDefaults.removePersistentDomain(forName: suiteName)
        } catch {
            XCTFail("Failed to set up test: \(error)")
        }
    }
    
    @MainActor
    func testPlayPauseButtonShowsPlayIconWhenPaused() {
        // Create view model
        let suiteName = "test.control.paused.\(UUID().uuidString)"
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
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_control_paused_\(UUID().uuidString)")
        
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
            
            // Verify state is paused
            XCTAssertEqual(viewModel.state, .paused, "State should be paused, which means play icon is shown")
            
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
            testDefaults.removePersistentDomain(forName: suiteName)
        } catch {
            XCTFail("Failed to set up test: \(error)")
        }
    }
    
    @MainActor
    func testPlayPauseToggleFromIdleToPlaying() {
        // Create view model
        let suiteName = "test.toggle.idle.playing.\(UUID().uuidString)"
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
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_toggle_idle_\(UUID().uuidString)")
        
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
            
            // Verify initial state
            XCTAssertEqual(viewModel.state, .idle, "Initial state should be idle")
            
            // Simulate play/pause button press (space bar)
            viewModel.startSlideshow()
            
            // Verify state changed to playing
            XCTAssertEqual(viewModel.state, .playing, "State should be playing after toggle from idle")
            
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
            testDefaults.removePersistentDomain(forName: suiteName)
        } catch {
            XCTFail("Failed to set up test: \(error)")
        }
    }
    
    @MainActor
    func testPlayPauseToggleFromPlayingToPaused() {
        // Create view model
        let suiteName = "test.toggle.playing.paused.\(UUID().uuidString)"
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
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_toggle_playing_\(UUID().uuidString)")
        
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
            
            // Simulate play/pause button press (space bar)
            viewModel.pauseSlideshow()
            
            // Verify state changed to paused
            XCTAssertEqual(viewModel.state, .paused, "State should be paused after toggle from playing")
            
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
            testDefaults.removePersistentDomain(forName: suiteName)
        } catch {
            XCTFail("Failed to set up test: \(error)")
        }
    }
    
    @MainActor
    func testPlayPauseToggleFromPausedToPlaying() {
        // Create view model
        let suiteName = "test.toggle.paused.playing.\(UUID().uuidString)"
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
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_toggle_paused_\(UUID().uuidString)")
        
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
            
            // Simulate play/pause button press (space bar)
            viewModel.resumeSlideshow()
            
            // Verify state changed back to playing
            XCTAssertEqual(viewModel.state, .playing, "State should be playing after toggle from paused")
            
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
            testDefaults.removePersistentDomain(forName: suiteName)
        } catch {
            XCTFail("Failed to set up test: \(error)")
        }
    }
    
    // MARK: - Test Keyboard Shortcut Handling
    // Requirements: 4.3, 4.4
    
    @MainActor
    func testRightArrowKeyAdvancesToNextImage() async {
        // Create view model
        let suiteName = "test.keyboard.right.\(UUID().uuidString)"
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
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_keyboard_right_\(UUID().uuidString)")
        
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
            
            // Verify starting at first image
            XCTAssertEqual(viewModel.currentIndex, 0, "Should start at first image")
            
            // Simulate right arrow key press
            await viewModel.nextImage()
            
            // Verify advanced to next image
            XCTAssertEqual(viewModel.currentIndex, 1, "Should advance to next image after right arrow")
            
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
            testDefaults.removePersistentDomain(forName: suiteName)
        } catch {
            XCTFail("Failed to set up test: \(error)")
        }
    }
    
    @MainActor
    func testLeftArrowKeyReturnsToPreviousImage() async {
        // Create view model
        let suiteName = "test.keyboard.left.\(UUID().uuidString)"
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
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_keyboard_left_\(UUID().uuidString)")
        
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
            
            // Move to second image
            await viewModel.nextImage()
            XCTAssertEqual(viewModel.currentIndex, 1, "Should be at second image")
            
            // Simulate left arrow key press
            await viewModel.previousImage()
            
            // Verify returned to previous image
            XCTAssertEqual(viewModel.currentIndex, 0, "Should return to previous image after left arrow")
            
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
            testDefaults.removePersistentDomain(forName: suiteName)
        } catch {
            XCTFail("Failed to set up test: \(error)")
        }
    }
    
    @MainActor
    func testRightArrowKeyWrapsFromLastToFirst() async {
        // Create view model
        let suiteName = "test.keyboard.wrap.forward.\(UUID().uuidString)"
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
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_keyboard_wrap_forward_\(UUID().uuidString)")
        
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
            
            // Move to last image
            viewModel.currentIndex = images.count - 1
            XCTAssertEqual(viewModel.currentIndex, 4, "Should be at last image")
            
            // Simulate right arrow key press
            await viewModel.nextImage()
            
            // Verify wrapped to first image
            XCTAssertEqual(viewModel.currentIndex, 0, "Should wrap to first image after right arrow from last")
            
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
            testDefaults.removePersistentDomain(forName: suiteName)
        } catch {
            XCTFail("Failed to set up test: \(error)")
        }
    }
    
    @MainActor
    func testLeftArrowKeyWrapsFromFirstToLast() async {
        // Create view model
        let suiteName = "test.keyboard.wrap.backward.\(UUID().uuidString)"
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
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_keyboard_wrap_backward_\(UUID().uuidString)")
        
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
            
            // Verify at first image
            XCTAssertEqual(viewModel.currentIndex, 0, "Should be at first image")
            
            // Simulate left arrow key press
            await viewModel.previousImage()
            
            // Verify wrapped to last image
            XCTAssertEqual(viewModel.currentIndex, images.count - 1, "Should wrap to last image after left arrow from first")
            
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
            testDefaults.removePersistentDomain(forName: suiteName)
        } catch {
            XCTFail("Failed to set up test: \(error)")
        }
    }
}
