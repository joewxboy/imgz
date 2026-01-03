import XCTest
import SwiftCheck
@testable import ImageSlideshowLib

// Feature: macos-image-slideshow, Property 8: Configuration persistence round-trip
final class ConfigurationPropertyTests: XCTestCase {
    
    // MARK: - Property 8: Configuration persistence round-trip
    // Validates: Requirements 6.1, 6.2
    
    func testConfigurationPersistenceRoundTrip() {
        property("For any valid SlideshowConfiguration, saving and loading should return equal configuration") <- forAll { (duration: Double, effectIndex: Int, hasPath: Bool, pathSeed: String) in
            // Constrain duration to valid range (1-60 seconds)
            let validDuration = max(1.0, min(60.0, abs(duration)))
            
            // Map effectIndex to valid TransitionEffect
            let effects: [TransitionEffect] = [.slide, .none]
            let effect = effects[abs(effectIndex) % effects.count]
            
            // Create optional path
            let folderPath = hasPath ? "/Users/test/\(pathSeed)" : nil
            
            // Create configuration
            let originalConfig = SlideshowConfiguration(
                transitionDuration: validDuration,
                transitionEffect: effect,
                lastSelectedFolderPath: folderPath
            )
            
            // Use a unique UserDefaults suite for this test to avoid conflicts
            let suiteName = "test.suite.\(UUID().uuidString)"
            guard let testDefaults = UserDefaults(suiteName: suiteName) else {
                return false
            }
            
            // Create service with test UserDefaults
            let service = UserDefaultsConfigurationService(userDefaults: testDefaults)
            
            // Save configuration
            do {
                try service.saveConfiguration(originalConfig)
            } catch {
                // If save fails, the test should fail
                testDefaults.removePersistentDomain(forName: suiteName)
                return false
            }
            
            // Load configuration
            let loadedConfig = service.loadConfiguration()
            
            // Clean up
            testDefaults.removePersistentDomain(forName: suiteName)
            
            // Verify round-trip equality
            return loadedConfig.transitionDuration == originalConfig.transitionDuration &&
                   loadedConfig.transitionEffect == originalConfig.transitionEffect &&
                   loadedConfig.lastSelectedFolderPath == originalConfig.lastSelectedFolderPath
        }
    }
}
