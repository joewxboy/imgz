# Project Setup Instructions

## Overview

This project is set up as a Swift Package with SwiftUI for macOS. The project structure follows best practices with organized folders for Models, ViewModels, Views, Services, and Tests.

## Project Structure

The project has been configured with:
- **Minimum deployment target**: macOS 13.0
- **Swift version**: 5.9+
- **UI Framework**: SwiftUI
- **Testing Framework**: XCTest + SwiftCheck for property-based testing

## Directory Structure

```
Sources/ImageSlideshow/
├── Models/              # Core data models
├── ViewModels/          # Business logic and state management  
├── Views/               # SwiftUI views
├── Services/            # File system and persistence services
└── ImageSlideshow.swift # App entry point

Tests/ImageSlideshowTests/
├── UnitTests/           # Unit tests for specific examples
├── PropertyTests/       # Property-based tests using SwiftCheck
└── ImageSlideshowTests.swift
```

## Dependencies

The project includes SwiftCheck for property-based testing:
- **SwiftCheck**: Property-based testing framework (master branch)

## Building the Project

### Command Line
```bash
swift build
```

### Running the Application
```bash
swift run
```

## Testing

### Important Note about SwiftCheck
SwiftCheck has known compatibility issues with Swift Package Manager's command-line test runner. The tests will work correctly when run through Xcode.

### To run tests via Xcode:

1. Open the package in Xcode:
```bash
open Package.swift
```

2. Wait for Xcode to resolve dependencies (this may take a moment)

3. Run tests using Xcode's test navigator (⌘+U) or Product > Test

### Alternative: Run tests without SwiftCheck
If you need to run tests from the command line during development, you can temporarily comment out the SwiftCheck dependency in Package.swift and run:
```bash
swift test
```

## Next Steps

The project structure is now ready for implementation. The next tasks will involve:
1. Implementing core data models
2. Creating service layer components
3. Building the ViewModel
4. Developing SwiftUI views
5. Writing comprehensive tests (unit + property-based)

## Configuration

The Package.swift file is configured with:
- macOS 13.0 as the minimum platform
- SwiftCheck dependency for property-based testing
- Proper test target configuration
- Organized source and test directories
