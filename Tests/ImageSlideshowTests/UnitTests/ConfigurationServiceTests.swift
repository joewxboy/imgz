import XCTest
@testable import ImageSlideshowLib

final class ConfigurationServiceTests: XCTestCase {
    
    // MARK: - Test Default Values
    // Requirements: 6.3
    
    func testLoadConfigurationReturnsDefaultsWhenNoSavedConfiguration() {
        // Create a unique UserDefaults suite for this test
        let suiteName = "test.defaults.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        // Create service with empty UserDefaults
        let service = UserDefaultsConfigurationService(userDefaults: testDefaults)
        
        // Load configuration (should return defaults)
        let config = service.loadConfiguration()
        
        // Verify default values
        XCTAssertEqual(config.transitionDuration, 5.0, "Default transition duration should be 5.0 seconds")
        XCTAssertEqual(config.transitionEffect, .none, "Default transition effect should be none")
        XCTAssertNil(config.lastSelectedFolderPath, "Default folder path should be nil")
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    // MARK: - Test Persistence
    // Requirements: 6.1, 6.2
    
    func testSaveAndLoadConfiguration() {
        // Create a unique UserDefaults suite for this test
        let suiteName = "test.persistence.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let service = UserDefaultsConfigurationService(userDefaults: testDefaults)
        
        // Create a custom configuration
        let customConfig = SlideshowConfiguration(
            transitionDuration: 10.0,
            transitionEffect: .slide,
            lastSelectedFolderPath: "/Users/test/Pictures"
        )
        
        // Save configuration
        do {
            try service.saveConfiguration(customConfig)
        } catch {
            XCTFail("Failed to save configuration: \(error)")
        }
        
        // Load configuration
        let loadedConfig = service.loadConfiguration()
        
        // Verify loaded values match saved values
        XCTAssertEqual(loadedConfig.transitionDuration, customConfig.transitionDuration)
        XCTAssertEqual(loadedConfig.transitionEffect, customConfig.transitionEffect)
        XCTAssertEqual(loadedConfig.lastSelectedFolderPath, customConfig.lastSelectedFolderPath)
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    func testSaveConfigurationWithNilFolderPath() {
        // Create a unique UserDefaults suite for this test
        let suiteName = "test.nilpath.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let service = UserDefaultsConfigurationService(userDefaults: testDefaults)
        
        // Create configuration with nil folder path
        let config = SlideshowConfiguration(
            transitionDuration: 15.0,
            transitionEffect: .none,
            lastSelectedFolderPath: nil
        )
        
        // Save configuration
        do {
            try service.saveConfiguration(config)
        } catch {
            XCTFail("Failed to save configuration: \(error)")
        }
        
        // Load configuration
        let loadedConfig = service.loadConfiguration()
        
        // Verify values
        XCTAssertEqual(loadedConfig.transitionDuration, 15.0)
        XCTAssertEqual(loadedConfig.transitionEffect, .none)
        XCTAssertNil(loadedConfig.lastSelectedFolderPath)
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    // MARK: - Test Instance Isolation
    // Tests for multiple instance support
    
    func testInstanceIsolationWithDifferentInstanceIds() {
        // Create a unique UserDefaults suite for this test
        let suiteName = "test.isolation.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let instanceId1 = UUID().uuidString
        let instanceId2 = UUID().uuidString
        
        // Create two services with different instance IDs
        let service1 = UserDefaultsConfigurationService(userDefaults: testDefaults, instanceId: instanceId1)
        let service2 = UserDefaultsConfigurationService(userDefaults: testDefaults, instanceId: instanceId2)
        
        // Save different configurations for each instance
        let config1 = SlideshowConfiguration(
            transitionDuration: 10.0,
            transitionEffect: .slide,
            lastSelectedFolderPath: "/Users/test/Pictures1"
        )
        
        let config2 = SlideshowConfiguration(
            transitionDuration: 20.0,
            transitionEffect: .none,
            lastSelectedFolderPath: "/Users/test/Pictures2"
        )
        
        do {
            try service1.saveConfiguration(config1)
            try service2.saveConfiguration(config2)
        } catch {
            XCTFail("Failed to save configuration: \(error)")
        }
        
        // Load configurations and verify they are isolated
        let loadedConfig1 = service1.loadConfiguration()
        let loadedConfig2 = service2.loadConfiguration()
        
        // Verify instance 1 configuration
        XCTAssertEqual(loadedConfig1.transitionDuration, 10.0, "Instance 1 should have its own duration")
        XCTAssertEqual(loadedConfig1.transitionEffect, .slide, "Instance 1 should have its own effect")
        XCTAssertEqual(loadedConfig1.lastSelectedFolderPath, "/Users/test/Pictures1", "Instance 1 should have its own folder path")
        
        // Verify instance 2 configuration
        XCTAssertEqual(loadedConfig2.transitionDuration, 20.0, "Instance 2 should have its own duration")
        XCTAssertEqual(loadedConfig2.transitionEffect, .none, "Instance 2 should have its own effect")
        XCTAssertEqual(loadedConfig2.lastSelectedFolderPath, "/Users/test/Pictures2", "Instance 2 should have its own folder path")
        
        // Verify configurations don't interfere with each other
        XCTAssertNotEqual(loadedConfig1.transitionDuration, loadedConfig2.transitionDuration)
        XCTAssertNotEqual(loadedConfig1.transitionEffect, loadedConfig2.transitionEffect)
        XCTAssertNotEqual(loadedConfig1.lastSelectedFolderPath, loadedConfig2.lastSelectedFolderPath)
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    func testSharedConfigurationWhenNoInstanceId() {
        // Create a unique UserDefaults suite for this test
        let suiteName = "test.shared.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        // Create two services without instance IDs (backward compatibility)
        let service1 = UserDefaultsConfigurationService(userDefaults: testDefaults, instanceId: nil)
        let service2 = UserDefaultsConfigurationService(userDefaults: testDefaults, instanceId: nil)
        
        // Save configuration from service1
        let config = SlideshowConfiguration(
            transitionDuration: 15.0,
            transitionEffect: .slide,
            lastSelectedFolderPath: "/Users/test/SharedPictures"
        )
        
        do {
            try service1.saveConfiguration(config)
        } catch {
            XCTFail("Failed to save configuration: \(error)")
        }
        
        // Load from service2 and verify it gets the same configuration (shared)
        let loadedConfig2 = service2.loadConfiguration()
        
        XCTAssertEqual(loadedConfig2.transitionDuration, 15.0, "Services without instance ID should share configuration")
        XCTAssertEqual(loadedConfig2.transitionEffect, .slide, "Services without instance ID should share configuration")
        XCTAssertEqual(loadedConfig2.lastSelectedFolderPath, "/Users/test/SharedPictures", "Services without instance ID should share configuration")
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    func testInstanceIsolationDoesNotAffectSharedConfiguration() {
        // Create a unique UserDefaults suite for this test
        let suiteName = "test.mixed.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let instanceId = UUID().uuidString
        
        // Create services: one with instance ID, one without (shared)
        let sharedService = UserDefaultsConfigurationService(userDefaults: testDefaults, instanceId: nil)
        let instanceService = UserDefaultsConfigurationService(userDefaults: testDefaults, instanceId: instanceId)
        
        // Save different configurations
        let sharedConfig = SlideshowConfiguration(
            transitionDuration: 5.0,
            transitionEffect: .none,
            lastSelectedFolderPath: "/Users/test/Shared"
        )
        
        let instanceConfig = SlideshowConfiguration(
            transitionDuration: 30.0,
            transitionEffect: .slide,
            lastSelectedFolderPath: "/Users/test/Instance"
        )
        
        do {
            try sharedService.saveConfiguration(sharedConfig)
            try instanceService.saveConfiguration(instanceConfig)
        } catch {
            XCTFail("Failed to save configuration: \(error)")
        }
        
        // Verify they are isolated
        let loadedShared = sharedService.loadConfiguration()
        let loadedInstance = instanceService.loadConfiguration()
        
        // Shared service should have shared config
        XCTAssertEqual(loadedShared.transitionDuration, 5.0)
        XCTAssertEqual(loadedShared.transitionEffect, .none)
        XCTAssertEqual(loadedShared.lastSelectedFolderPath, "/Users/test/Shared")
        
        // Instance service should have instance config
        XCTAssertEqual(loadedInstance.transitionDuration, 30.0)
        XCTAssertEqual(loadedInstance.transitionEffect, .slide)
        XCTAssertEqual(loadedInstance.lastSelectedFolderPath, "/Users/test/Instance")
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
}
