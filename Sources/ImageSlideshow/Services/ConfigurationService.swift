import Foundation

/// Protocol for managing slideshow configuration persistence
public protocol ConfigurationService {
    /// Saves the configuration to persistent storage
    /// - Parameter config: The configuration to save
    /// - Throws: An error if the configuration cannot be saved
    func saveConfiguration(_ config: SlideshowConfiguration) throws
    
    /// Loads the configuration from persistent storage
    /// - Returns: The saved configuration, or default values if none exists
    func loadConfiguration() -> SlideshowConfiguration
}

/// Implementation of ConfigurationService using UserDefaults
public class UserDefaultsConfigurationService: ConfigurationService {
    private let userDefaults: UserDefaults
    private let instanceId: String?
    
    // UserDefaults keys (base keys, will be prefixed with instance ID if provided)
    private enum BaseKeys {
        static let transitionDuration = "transitionDuration"
        static let transitionEffect = "transitionEffect"
        static let lastFolderPath = "lastFolderPath"
    }
    
    // Default configuration values
    private enum Defaults {
        static let transitionDuration: TimeInterval = 5.0
        static let transitionEffect: TransitionEffect = .none
    }
    
    /// Initializes the configuration service
    /// - Parameters:
    ///   - userDefaults: The UserDefaults instance to use (defaults to .standard)
    ///   - instanceId: Optional instance identifier for instance-specific configuration isolation.
    ///                 If provided, configuration will be stored with instance-specific keys.
    ///                 If nil, uses shared configuration keys (backward compatible).
    public init(userDefaults: UserDefaults = .standard, instanceId: String? = nil) {
        self.userDefaults = userDefaults
        self.instanceId = instanceId
    }
    
    /// Generates a UserDefaults key with optional instance ID prefix
    /// - Parameter baseKey: The base key name
    /// - Returns: The full key with instance ID prefix if instance ID is provided
    private func makeKey(_ baseKey: String) -> String {
        if let instanceId = instanceId {
            return "slideshow.\(instanceId).\(baseKey)"
        } else {
            return "slideshow.\(baseKey)"
        }
    }
    
    public func saveConfiguration(_ config: SlideshowConfiguration) throws {
        userDefaults.set(config.transitionDuration, forKey: makeKey(BaseKeys.transitionDuration))
        userDefaults.set(config.transitionEffect.rawValue, forKey: makeKey(BaseKeys.transitionEffect))
        userDefaults.set(config.lastSelectedFolderPath, forKey: makeKey(BaseKeys.lastFolderPath))
    }
    
    public func loadConfiguration() -> SlideshowConfiguration {
        // Load transition duration, using default if not found
        let transitionDuration: TimeInterval
        let durationKey = makeKey(BaseKeys.transitionDuration)
        if userDefaults.object(forKey: durationKey) != nil {
            transitionDuration = userDefaults.double(forKey: durationKey)
        } else {
            transitionDuration = Defaults.transitionDuration
        }
        
        // Load transition effect, using default if not found or invalid
        let transitionEffect: TransitionEffect
        let effectKey = makeKey(BaseKeys.transitionEffect)
        if let effectString = userDefaults.string(forKey: effectKey),
           let effect = TransitionEffect(rawValue: effectString) {
            transitionEffect = effect
        } else {
            transitionEffect = Defaults.transitionEffect
        }
        
        // Load last folder path (optional)
        let lastFolderPath = userDefaults.string(forKey: makeKey(BaseKeys.lastFolderPath))
        
        return SlideshowConfiguration(
            transitionDuration: transitionDuration,
            transitionEffect: transitionEffect,
            lastSelectedFolderPath: lastFolderPath
        )
    }
}
