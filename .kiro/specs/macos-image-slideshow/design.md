# Design Document

## Overview

The macOS Image Slideshow Application will be built as a native macOS application using Swift and SwiftUI. The application will provide a clean, intuitive interface for selecting image folders, configuring slideshow parameters, and displaying images with smooth transitions. The architecture follows the Model-View-ViewModel (MVVM) pattern to separate concerns and maintain testability.

## Architecture

The application consists of four main layers:

1. **Presentation Layer (SwiftUI Views)**: User interface components including the main slideshow window, configuration panel, and folder selection dialog
2. **ViewModel Layer**: Business logic and state management that bridges the UI and model layers
3. **Model Layer**: Core data structures representing slideshow state, configuration, and image metadata
4. **Service Layer**: File system operations, image loading, persistence, and configuration management

### Technology Stack

- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Minimum macOS Version**: macOS 15.0 (Sequoia)
- **Persistence**: UserDefaults for configuration storage
- **Image Loading**: NSImage with async loading
- **Testing**: XCTest for unit tests, swift-check for property-based testing

## Components and Interfaces

### 1. Models

#### SlideshowConfiguration
```swift
struct SlideshowConfiguration: Codable {
    var transitionDuration: TimeInterval // 1-60 seconds
    var transitionEffect: TransitionEffect
    var lastSelectedFolderPath: String?
}

enum TransitionEffect: String, Codable {
    case slide
    case none
}
```

#### ImageItem
```swift
struct ImageItem: Identifiable {
    let id: UUID
    let url: URL
    let filename: String
}
```

#### SlideshowState
```swift
enum SlideshowState {
    case idle
    case playing
    case paused
}
```

### 2. Services

#### ImageLoaderService
Responsible for scanning folders and loading images.

```swift
protocol ImageLoaderService {
    func loadImagesFromFolder(_ url: URL) async throws -> [ImageItem]
    func loadImage(from item: ImageItem) async throws -> NSImage
}
```

#### ConfigurationService
Handles persistence and retrieval of user configuration.

```swift
protocol ConfigurationService {
    func saveConfiguration(_ config: SlideshowConfiguration) throws
    func loadConfiguration() -> SlideshowConfiguration
}
```

### 3. ViewModels

#### SlideshowViewModel
Central state manager for the slideshow application.

```swift
class SlideshowViewModel: ObservableObject {
    @Published var images: [ImageItem] = []
    @Published var currentIndex: Int = 0
    @Published var currentImage: NSImage?
    @Published var state: SlideshowState = .idle
    @Published var configuration: SlideshowConfiguration
    @Published var errorMessage: String?
    
    func selectFolder()
    func startSlideshow()
    func pauseSlideshow()
    func resumeSlideshow()
    func nextImage()
    func previousImage()
    func updateConfiguration(_ config: SlideshowConfiguration)
}
```

### 4. Views

#### MainView
The root view containing the slideshow display and controls.

#### SlideshowDisplayView
Displays the current image with proper scaling and centering.

#### ControlPanelView
Provides playback controls (play, pause, next, previous).

#### ConfigurationView
Settings panel for adjusting transition duration and effects.

#### FolderSelectionView
Dialog for selecting the image folder.

## Data Models

### Image Loading Pipeline

1. User selects folder via NSOpenPanel
2. ImageLoaderService scans folder for supported formats (jpg, jpeg, png, gif, heic, tiff, bmp)
3. Files are sorted alphabetically by filename
4. ImageItem objects are created with file URLs
5. Images are loaded on-demand as they're displayed

### Configuration Persistence

Configuration is stored in UserDefaults with the following keys:
- `slideshow.transitionDuration`: Double
- `slideshow.transitionEffect`: String
- `slideshow.lastFolderPath`: String

Default values:
- transitionDuration: 5.0 seconds
- transitionEffect: "fade"
- lastFolderPath: nil

## Data Flow

1. **Application Launch**:
   - ConfigurationService loads saved settings
   - SlideshowViewModel initializes with loaded configuration
   - MainView displays folder selection prompt

2. **Folder Selection**:
   - User selects folder via NSOpenPanel
   - ImageLoaderService scans and sorts images
   - ViewModel updates images array
   - First image is loaded and displayed

3. **Slideshow Playback**:
   - Timer fires based on transitionDuration
   - ViewModel advances currentIndex
   - New image is loaded asynchronously
   - Transition animation is applied
   - Loop back to first image after last

4. **Configuration Changes**:
   - User modifies settings in ConfigurationView
   - ViewModel updates configuration
   - ConfigurationService persists changes
   - New settings apply to subsequent transitions


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Image filtering by supported formats

*For any* folder containing files of various types, when the ImageLoaderService scans the folder, all returned ImageItem objects should have file extensions that match the Supported Image Formats (jpg, jpeg, png, gif, heic, tiff, bmp).

**Validates: Requirements 1.2**

### Property 2: Alphabetical image ordering

*For any* set of image files in a folder, when the ImageLoaderService loads the images, the resulting ImageItem array should be sorted in alphabetical order by filename.

**Validates: Requirements 1.4**

### Property 3: Transition duration application

*For any* valid transition duration value between 1 and 60 seconds, when the user updates the configuration, subsequent image transitions should use the new duration value.

**Validates: Requirements 2.2**

### Property 4: Transition effect application

*For any* valid transition effect (fade, slide, none), when the user selects that effect in the configuration, subsequent image transitions should apply the selected effect.

**Validates: Requirements 3.2**

### Property 5: Forward navigation advancement

*For any* current image index in the slideshow (except the last), when the user presses the right arrow key, the current index should advance by exactly one position.

**Validates: Requirements 4.3**

### Property 6: Backward navigation retreat

*For any* current image index in the slideshow (except the first), when the user presses the left arrow key, the current index should decrease by exactly one position.

**Validates: Requirements 4.4**

### Property 7: Image scaling preserves aspect ratio

*For any* image with dimensions (width, height) and any window size, when the image is scaled to fit the window, the ratio of scaled width to scaled height should equal the ratio of original width to original height within a small tolerance.

**Validates: Requirements 5.1, 5.2, 5.3**

### Property 8: Configuration persistence round-trip

*For any* valid SlideshowConfiguration object, when it is saved via ConfigurationService and then loaded, the loaded configuration should be equal to the original configuration.

**Validates: Requirements 6.1, 6.2**

### Property 9: Error recovery continues playback

*For any* slideshow with multiple images where one image fails to load, when the slideshow encounters the failed image, it should skip to the next valid image and continue playback without stopping.

**Validates: Requirements 7.1**

### Property 10: Error logging includes filename

*For any* image file that fails to load, when the error occurs, the logged error message should contain the filename of the failed image.

**Validates: Requirements 7.2**

## Error Handling

The application implements defensive error handling at multiple levels:

### File System Errors
- **Folder Access**: If the selected folder becomes inaccessible, display an alert and return to folder selection
- **Image Loading**: If an individual image fails to load, log the error, skip the image, and continue with the next
- **Permission Denied**: If folder permissions are insufficient, display a clear error message with instructions

### Configuration Errors
- **Invalid Values**: Validate all configuration inputs and reject invalid values with user feedback
- **Persistence Failures**: If configuration cannot be saved, log the error and continue with in-memory settings
- **Corrupted Data**: If saved configuration is corrupted, fall back to default values

### Memory Management
- **Large Images**: Load images asynchronously to prevent UI blocking
- **Memory Pressure**: Release previous images from memory when advancing to the next
- **Batch Loading**: Load only the current and next image to minimize memory footprint

### User Feedback
- All errors display user-friendly messages in alerts
- Critical errors (folder inaccessible) stop playback and prompt for action
- Non-critical errors (single image load failure) are logged but don't interrupt playback

## Testing Strategy

The application will use a dual testing approach combining unit tests and property-based tests to ensure comprehensive coverage.

### Unit Testing

Unit tests will verify specific examples and integration points:

- **Configuration Defaults**: Verify default values are correctly set on first launch
- **UI State Transitions**: Test state changes between idle, playing, and paused
- **Boundary Conditions**: Test navigation at first and last image positions
- **Error Scenarios**: Test specific error conditions like empty folders and invalid file types
- **Integration Points**: Test ViewModel coordination with Services

### Property-Based Testing

Property-based tests will verify universal properties across many inputs using **swift-check**, a QuickCheck-style property testing library for Swift.

**Configuration**:
- Each property-based test will run a minimum of 100 iterations
- Tests will use smart generators that constrain inputs to valid ranges
- Each test will be tagged with a comment referencing the design document property

**Test Tagging Format**:
```swift
// Feature: macos-image-slideshow, Property 1: Image filtering by supported formats
func testImageFilteringProperty() { ... }
```

**Property Test Coverage**:
- Property 1: Generate random folder structures with mixed file types
- Property 2: Generate random sets of filenames and verify sorting
- Property 3: Generate random valid duration values (1-60 seconds)
- Property 4: Test all transition effect enum values
- Property 5 & 6: Generate random slideshow positions and test navigation
- Property 7: Generate random image dimensions and window sizes
- Property 8: Generate random valid configuration objects for round-trip testing
- Property 9 & 10: Generate slideshows with intentionally corrupted images

**Generator Strategy**:
- Use constrained generators for valid input ranges (e.g., duration 1-60)
- Create custom generators for domain objects (ImageItem, SlideshowConfiguration)
- Use file system mocking for folder scanning tests
- Generate edge cases automatically (empty arrays, boundary values)

### Test Organization

```
Tests/
├── UnitTests/
│   ├── ViewModelTests.swift
│   ├── ConfigurationServiceTests.swift
│   └── ImageLoaderServiceTests.swift
└── PropertyTests/
    ├── ImageLoadingPropertyTests.swift
    ├── NavigationPropertyTests.swift
    ├── ConfigurationPropertyTests.swift
    └── ScalingPropertyTests.swift
```

### Testing Principles

- Write implementation code first, then tests
- Property tests verify universal correctness across many inputs
- Unit tests verify specific examples and edge cases
- Both test types are complementary and essential
- Tests should not use mocks for core logic - test real functionality
- Failed tests indicate bugs in the implementation, not necessarily the tests
