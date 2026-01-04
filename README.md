# ImageSlideshow

A native macOS application for displaying configurable image slideshows with photo starring and EXIF metadata display capabilities.

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

5. **EXIF Metadata Display** 📷
   - View EXIF headers for images (camera info, exposure settings, GPS, etc.)
   - Toggle in sidebar or press "e" key to show/hide EXIF overlay
   - Overlay only appears when slideshow is paused or idle
   - Automatically dismissed when slideshow is playing
   - Displays camera make/model, ISO, aperture, shutter speed, date taken, focal length, GPS coordinates, and image dimensions

6. **Image Display**
   - Aspect ratio preservation
   - Aspect-fit scaling
   - Full-screen display

7. **Error Handling**
   - Graceful handling of corrupted images
   - Error logging with filename information
   - Automatic recovery and continuation

8. **Multiple Instance Support**
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

## EXIF Headers Feature

### How to Use

1. **Viewing EXIF Headers**
   - Load a folder with images (preferably photos with EXIF data from a camera)
   - Pause the slideshow (or keep it in idle state)
   - Toggle "Show EXIF headers" in the Settings panel (left sidebar), or press "e" key
   - An overlay will appear in the bottom-right corner showing EXIF metadata
   - The overlay displays camera information, exposure settings, date taken, GPS coordinates (if available), and image dimensions

2. **EXIF Overlay Behavior**
   - Overlay only appears when slideshow is paused or idle
   - Overlay automatically disappears when slideshow starts playing
   - EXIF toggle automatically turns off when slideshow starts playing
   - Overlay updates when navigating to different images
   - EXIF data is cached for performance

3. **EXIF Data Displayed**
   - **Camera**: Make and model (e.g., "Canon EOS 5D Mark IV")
   - **Exposure**: ISO, Aperture (f-stop), Shutter Speed, Exposure Mode
   - **Date/Time**: When the photo was taken
   - **Lens**: Focal length in millimeters
   - **GPS**: Latitude and longitude coordinates (if available)
   - **Image**: Dimensions in pixels

4. **Keyboard Shortcut**
   - Press "e" key to toggle EXIF display on/off
   - Works in any slideshow state (but overlay only shows when paused/idle)

### Keyboard Shortcuts

- **Space**: Play/Pause slideshow
- **Left Arrow**: Previous image
- **Right Arrow**: Next image
- **s**: Star/Unstar current image (only when paused/idle)
- **u**: Unstar current image (only when paused/idle)
- **e**: Toggle EXIF headers display (overlay only shows when paused/idle)

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
