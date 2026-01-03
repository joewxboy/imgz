import XCTest
import SwiftUI
@testable import ImageSlideshowLib

/// Unit tests for ConfigurationView
/// Requirements: 2.1, 3.1
final class ConfigurationViewTests: XCTestCase {
    
    // MARK: - Test Duration Slider Bounds Validation
    // Requirements: 2.1
    
    @MainActor
    func testDurationSliderMinimumBound() {
        // Create view model with default configuration
        let suiteName = "test.config.min.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let configService = UserDefaultsConfigurationService(userDefaults: testDefaults)
        let viewModel = SlideshowViewModel(
            configurationService: configService,
            imageLoaderService: DefaultImageLoaderService()
        )
        
        // Set duration to minimum value (1 second)
        let minConfig = SlideshowConfiguration(
            transitionDuration: 1.0,
            transitionEffect: .none,
            lastSelectedFolderPath: nil
        )
        viewModel.updateConfiguration(minConfig)
        
        // Verify minimum bound is respected
        XCTAssertEqual(viewModel.configuration.transitionDuration, 1.0, "Duration should accept minimum value of 1 second")
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    @MainActor
    func testDurationSliderMaximumBound() {
        // Create view model with default configuration
        let suiteName = "test.config.max.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let configService = UserDefaultsConfigurationService(userDefaults: testDefaults)
        let viewModel = SlideshowViewModel(
            configurationService: configService,
            imageLoaderService: DefaultImageLoaderService()
        )
        
        // Set duration to maximum value (60 seconds)
        let maxConfig = SlideshowConfiguration(
            transitionDuration: 60.0,
            transitionEffect: .none,
            lastSelectedFolderPath: nil
        )
        viewModel.updateConfiguration(maxConfig)
        
        // Verify maximum bound is respected
        XCTAssertEqual(viewModel.configuration.transitionDuration, 60.0, "Duration should accept maximum value of 60 seconds")
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    @MainActor
    func testDurationSliderMidRangeValue() {
        // Create view model with default configuration
        let suiteName = "test.config.mid.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let configService = UserDefaultsConfigurationService(userDefaults: testDefaults)
        let viewModel = SlideshowViewModel(
            configurationService: configService,
            imageLoaderService: DefaultImageLoaderService()
        )
        
        // Set duration to mid-range value (30 seconds)
        let midConfig = SlideshowConfiguration(
            transitionDuration: 30.0,
            transitionEffect: .none,
            lastSelectedFolderPath: nil
        )
        viewModel.updateConfiguration(midConfig)
        
        // Verify mid-range value is accepted
        XCTAssertEqual(viewModel.configuration.transitionDuration, 30.0, "Duration should accept mid-range value of 30 seconds")
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    // MARK: - Test Effect Picker Options
    // Requirements: 3.1
    
    @MainActor
    func testEffectPickerSlideOption() {
        // Create view model with default configuration
        let suiteName = "test.effect.slide.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let configService = UserDefaultsConfigurationService(userDefaults: testDefaults)
        let viewModel = SlideshowViewModel(
            configurationService: configService,
            imageLoaderService: DefaultImageLoaderService()
        )
        
        // Set effect to slide
        let slideConfig = SlideshowConfiguration(
            transitionDuration: 5.0,
            transitionEffect: .slide,
            lastSelectedFolderPath: nil
        )
        viewModel.updateConfiguration(slideConfig)
        
        // Verify slide effect is set
        XCTAssertEqual(viewModel.configuration.transitionEffect, .slide, "Effect picker should accept slide option")
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    @MainActor
    func testEffectPickerNoneOption() {
        // Create view model with default configuration
        let suiteName = "test.effect.none.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let configService = UserDefaultsConfigurationService(userDefaults: testDefaults)
        let viewModel = SlideshowViewModel(
            configurationService: configService,
            imageLoaderService: DefaultImageLoaderService()
        )
        
        // Set effect to none
        let noneConfig = SlideshowConfiguration(
            transitionDuration: 5.0,
            transitionEffect: .none,
            lastSelectedFolderPath: nil
        )
        viewModel.updateConfiguration(noneConfig)
        
        // Verify none effect is set
        XCTAssertEqual(viewModel.configuration.transitionEffect, .none, "Effect picker should accept none option")
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    @MainActor
    func testEffectPickerToggleBetweenOptions() {
        // Create view model with default configuration
        let suiteName = "test.effect.toggle.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let configService = UserDefaultsConfigurationService(userDefaults: testDefaults)
        let viewModel = SlideshowViewModel(
            configurationService: configService,
            imageLoaderService: DefaultImageLoaderService()
        )
        
        // Start with slide effect
        let slideConfig = SlideshowConfiguration(
            transitionDuration: 5.0,
            transitionEffect: .slide,
            lastSelectedFolderPath: nil
        )
        viewModel.updateConfiguration(slideConfig)
        XCTAssertEqual(viewModel.configuration.transitionEffect, .slide, "Should start with slide effect")
        
        // Toggle to none effect
        let noneConfig = SlideshowConfiguration(
            transitionDuration: 5.0,
            transitionEffect: .none,
            lastSelectedFolderPath: nil
        )
        viewModel.updateConfiguration(noneConfig)
        XCTAssertEqual(viewModel.configuration.transitionEffect, .none, "Should toggle to none effect")
        
        // Toggle back to slide effect
        viewModel.updateConfiguration(slideConfig)
        XCTAssertEqual(viewModel.configuration.transitionEffect, .slide, "Should toggle back to slide effect")
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
}
