# Image Slideshow - macOS Application

A native macOS application built with Swift and SwiftUI for displaying configurable image slideshows.

## Project Structure

```
ImageSlideshow/
├── Sources/ImageSlideshow/
│   ├── Models/              # Core data models
│   │   ├── SlideshowConfiguration.swift
│   │   ├── ImageItem.swift
│   │   └── SlideshowState.swift
│   ├── ViewModels/          # Business logic and state management
│   │   └── SlideshowViewModel.swift
│   ├── Views/               # SwiftUI views
│   │   ├── MainView.swift
│   │   ├── SlideshowDisplayView.swift
│   │   ├── ControlPanelView.swift
│   │   └── ConfigurationView.swift
│   ├── Services/            # File system and persistence services
│   │   ├── ImageLoaderService.swift
│   │   └── ConfigurationService.swift
│   └── ImageSlideshow.swift # App entry point
└── Tests/ImageSlideshowTests/
    ├── UnitTests/           # Unit tests for specific examples
    └── PropertyTests/       # Property-based tests using SwiftCheck
```

## Requirements

- macOS 13.0 or later
- Swift 5.9+
- Xcode 15.0+

## Dependencies

- [SwiftCheck](https://github.com/typelift/SwiftCheck) - Property-based testing framework

## Building

```bash
swift build
```

## Running

```bash
swift run
```

### Running Multiple Instances

The application supports running multiple instances simultaneously, each with its own isolated configuration:

**From command line:**
```bash
# First instance
swift run

# Second instance (in another terminal)
swift run
```

**For app bundles:**
```bash
# Launch a new instance even if one is already running
open -n ImageSlideshow.app

# Or from Applications folder
open -n -a /Applications/ImageSlideshow.app
```

Each instance will have its own:
- Configuration settings (transition duration, effect)
- Selected folder
- Playback state
- Window title showing the current folder name

## Testing

```bash
swift test
```

## Features

- Folder-based image selection
- Configurable transition duration (1-60 seconds)
- Multiple transition effects (slide, none)
- Manual playback controls (play, pause, next, previous)
- Keyboard shortcuts for navigation
- Aspect ratio preservation
- Configuration persistence
- Graceful error handling
- **Multiple instance support**: Run multiple slideshow instances simultaneously, each with its own isolated configuration and folder selection
