# ImageSlideshow

A native macOS application for displaying configurable image slideshows with photo starring capabilities.

## Features

### Core Functionality

1. **Folder-based Image Selection**
   - Select a folder containing images
   - Automatic filtering of supported formats (jpg, jpeg, png, gif, heic, tiff, bmp)
   - Alphabetical ordering of images

2. **Configurable Slideshow**
   - Transition duration: 1-60 seconds
   - Transition effects: slide, none
   - Configuration persistence across sessions

3. **Playback Controls**
   - Play/Pause
   - Next/Previous navigation
   - Keyboard shortcuts support

4. **Photo Starring** ⭐
   - Star and unstar individual photos when slideshow is paused or idle
   - Visual indicators: star button in control panel and star overlay on images
   - Keyboard shortcuts: "s" to star/unstar, "u" to unstar
   - Per-folder starred state persistence
   - Filter to show only starred photos

5. **Image Display**
   - Aspect ratio preservation
   - Aspect-fit scaling
   - Full-screen display

6. **Error Handling**
   - Graceful handling of corrupted images
   - Error logging with filename information
   - Automatic recovery and continuation

7. **Multiple Instance Support**
   - Run multiple slideshow instances simultaneously
   - Each instance has isolated configuration

## Photo Starring Feature

### How to Use

1. **Starring Photos**
   - Load a folder with images
   - Pause the slideshow (or keep it in idle state)
   - Click the star button in the control panel, or press "s" key
   - The star icon will fill yellow to indicate the photo is starred
   - A star overlay will appear in the top-right corner of the image

2. **Unstarring Photos**
   - With a starred photo displayed, click the star button again, or press "s" key
   - Press "u" key to unstar (only works when paused/idle)
   - The star icon will return to outline and the overlay will disappear

3. **Filtering Starred Photos**
   - Go to Settings panel (left sidebar)
   - Toggle "Show only starred photos"
   - The slideshow will only display photos you've starred
   - Toggle off to show all photos again

4. **Starred State Persistence**
   - Starred state is saved per folder
   - Your starred photos persist across app restarts
   - Each folder maintains its own independent set of starred photos

### Keyboard Shortcuts

- **Space**: Play/Pause slideshow
- **Left Arrow**: Previous image
- **Right Arrow**: Next image
- **s**: Star/Unstar current image (only when paused/idle)
- **u**: Unstar current image (only when paused/idle)

## Building and Running

### Build
```bash
swift build
```

### Run
```bash
swift run ImageSlideshow
```

## Requirements

- macOS 13.0 or later
- Swift 5.9 or later

## Project Structure

- `Sources/ImageSlideshow/`: Core library with models, views, view models, and services
- `Sources/ImageSlideshowApp/`: Application entry point
- `Tests/`: Comprehensive test suite

For detailed documentation, see `AGENT.md`.
