# ImageSlideshow - Photo Starring Feature

## Background and Motivation

The user has requested a new feature to allow starring and unstarring individual photos in the slideshow. This feature will enable users to mark favorite photos for later review or filtering. The feature should work when the slideshow is paused, with both UI controls and keyboard shortcuts. Additionally, users should be able to filter the slideshow to show only starred photos.

## Key Challenges and Analysis

### Current State Analysis

After reviewing the codebase, the following observations were made:

1. **ImageItem Model**: Currently contains `id`, `url`, and `filename`. No starred state exists.

2. **State Management**: `SlideshowViewModel` manages the images array and current index. Starred state needs to be persisted separately from the ImageItem model to maintain immutability and separation of concerns.

3. **Persistence**: The app uses `UserDefaults` for configuration. Starred state should be persisted per folder/directory to allow different starred sets for different folders.

4. **UI Components**: 
   - `ControlPanelView` contains playback controls
   - `ConfigurationView` contains settings
   - `SlideshowDisplayView` shows the current image
   - Keyboard shortcuts are handled via `.keyboardShortcut()` modifier

5. **Image Loading**: `ImageLoaderService` loads images from folders. Filtering logic will need to be added to show only starred images when the filter is enabled.

6. **Paused State**: The slideshow has a `SlideshowState.paused` state that can be checked to conditionally show starring controls.

### Key Challenges

1. **Persistence Strategy**: Need to store starred state per folder. Options:
   - UserDefaults with folder path as key
   - Separate file per folder (e.g., `.starred.json` in each folder)
   - Single UserDefaults entry mapping folder paths to sets of starred image URLs/IDs
   - **Recommended**: UserDefaults with folder path as part of key (simplest, consistent with existing approach)

2. **State Synchronization**: When starring/unstarring, need to:
   - Update persisted state immediately
   - Update displayed images if filter is active
   - Handle edge cases (e.g., starring when filter is on)

3. **Filtering Logic**: When "show only starred" is enabled:
   - Filter the images array
   - Handle currentIndex to prevent out-of-bounds
   - Update when starring/unstarring while filter is active
   - Maintain original full image list for toggling filter

4. **UI Placement**: Star button should:
   - Only appear when slideshow is paused
   - Be clearly visible and accessible
   - Show current starred state (filled vs outline star icon)

5. **Keyboard Shortcuts**: Need to handle:
   - "s" key to star current image
   - "u" key to unstar current image
   - Only work when paused
   - Not conflict with existing shortcuts

## High-level Task Breakdown

### Task 1: Create Starring Service
**Goal**: Create a service to manage starred state persistence
**Success Criteria**:
- Service can mark images as starred/unstarred
- Starred state persists across app restarts
- Starred state is per-folder (different folders have independent starred sets)
- Service can query if an image is starred
- Service can get all starred image IDs for a folder

**Approach**:
- Create `StarringService` protocol
- Create `UserDefaultsStarringService` implementation
- Use UserDefaults with key format: `"starred.\(folderPath).\(imageId)"` or `"starred.\(folderPath)"` as a Set<String>
- Store image identifiers (URL path or UUID) for starred images per folder

**Implementation Details**:
- Protocol methods: `starImage(_:inFolder:)`, `unstarImage(_:inFolder:)`, `isStarred(_:inFolder:)`, `getStarredImageIds(forFolder:)`
- Use Set<String> to store starred image identifiers (use URL.path as identifier for uniqueness)
- Handle folder path normalization for consistent keys

### Task 2: Update ImageItem Model (Optional Enhancement)
**Goal**: Consider if ImageItem needs changes (likely not needed if we use service pattern)
**Success Criteria**:
- ImageItem remains immutable and simple
- Starred state managed separately via service

**Approach**:
- Keep ImageItem as-is (no starred property needed)
- Starred state managed by StarringService, not in model

### Task 3: Integrate StarringService into SlideshowViewModel
**Goal**: Add starring functionality to the view model
**Success Criteria**:
- ViewModel can star/unstar current image
- Starred state persists when changed
- ViewModel can check if current image is starred
- ViewModel can filter images to show only starred ones
- Filter toggle updates displayed images correctly

**Approach**:
- Add `StarringService` property to ViewModel
- Add `starCurrentImage()` and `unstarCurrentImage()` methods
- Add `isCurrentImageStarred` computed property
- Add `showOnlyStarred` boolean property
- Add `toggleShowOnlyStarred()` method
- Modify image loading/filtering logic to respect `showOnlyStarred` flag
- Store original full images array when filtering

**Implementation Details**:
- When `showOnlyStarred` is enabled, filter `images` array to only include starred images
- When toggling filter off, restore full images array
- Update `currentIndex` when filtering to prevent out-of-bounds
- When starring/unstarring with filter active, update filtered array accordingly

### Task 4: Add Star Button to ControlPanelView
**Goal**: Add UI button for starring/unstarring
**Success Criteria**:
- Button only visible when slideshow is paused
- Button shows correct icon (filled star if starred, outline if not)
- Button toggles starred state when clicked
- Button is properly disabled when no images are loaded
- Button has appropriate help text

**Approach**:
- Add star button to `ControlPanelView`
- Conditionally show based on `viewModel.state == .paused`
- Use SF Symbol: `star.fill` for starred, `star` for unstarred
- Call `viewModel.starCurrentImage()` or `viewModel.unstarCurrentImage()` based on current state

**Implementation Details**:
- Place button near play/pause controls for easy access
- Use `.disabled(viewModel.images.isEmpty || viewModel.currentImage == nil)` to disable when appropriate
- Add help text: "Star image (only when paused)"

### Task 5: Add Keyboard Shortcuts for Starring
**Goal**: Add "s" and "u" key shortcuts for starring/unstarring
**Success Criteria**:
- "s" key stars current image (only when paused)
- "u" key unstars current image (only when paused)
- Shortcuts don't interfere with existing keyboard shortcuts
- Shortcuts are disabled when slideshow is playing or no images loaded

**Approach**:
- Add keyboard event handling in `MainView` or `SlideshowDisplayView`
- Use `.onKeyPress` modifier or `NSEvent` monitoring
- Check if slideshow is paused before processing
- Call appropriate ViewModel methods

**Implementation Details**:
- Use SwiftUI's `.onKeyPress` modifier (available in macOS 14+)
- Or use `NSEvent.addLocalMonitorForEvents` for broader compatibility
- Check `viewModel.state == .paused` before executing
- Check `!viewModel.images.isEmpty` before executing

### Task 6: Add Filter Toggle to ConfigurationView
**Goal**: Add option to show only starred photos
**Success Criteria**:
- Toggle switch/checkbox in ConfigurationView
- Toggle filters images to show only starred ones
- Toggle state persists in configuration
- When enabled, slideshow only shows starred images
- When disabled, shows all images again

**Approach**:
- Add `showOnlyStarred` boolean to `SlideshowConfiguration` model
- Add toggle control to `ConfigurationView`
- Update ViewModel when toggle changes
- ViewModel applies filter when `showOnlyStarred` is true

**Implementation Details**:
- Add `showOnlyStarred: Bool = false` to `SlideshowConfiguration`
- Add Toggle to ConfigurationView UI
- When toggled, call ViewModel method to update filter
- ViewModel filters images array and updates currentIndex if needed

### Task 7: Handle Edge Cases and State Management
**Goal**: Ensure robust behavior in all scenarios
**Success Criteria**:
- Starring/unstarring works correctly when filter is active
- Current index stays valid when filtering
- Filter updates immediately when toggled
- Starred state persists correctly per folder
- Switching folders clears/resets filter appropriately

**Approach**:
- When filter is active and user stars/unstars, update filtered array
- When filtering, if current image becomes invalid, move to first valid image
- When loading new folder, reset filter to false (or persist per-folder preference)
- Handle case where all images are unstarred and filter is enabled (show empty state)

**Implementation Details**:
- After starring/unstarring with filter active, re-filter images array
- Check `currentIndex` validity after filtering
- When `showOnlyStarred` is true but no starred images, show appropriate message
- Consider per-folder filter preference vs global preference

### Task 8: Write Tests for Starring Feature
**Goal**: Ensure starring functionality works correctly
**Success Criteria**:
- Tests for StarringService (star, unstar, isStarred, getStarredImageIds)
- Tests for ViewModel starring methods
- Tests for filtering logic
- Tests for edge cases (empty starred set, all starred, etc.)

**Approach**:
- Create `StarringServiceTests.swift`
- Add tests to `SlideshowViewModelTests.swift` for starring functionality
- Test filtering behavior
- Test persistence across service instances

**Implementation Details**:
- Test that starring persists across service instances
- Test that different folders have independent starred sets
- Test filtering with various scenarios
- Test keyboard shortcut handling (if testable)

### Task 9: Update Documentation
**Goal**: Document the new starring feature
**Success Criteria**:
- README.md updated with starring feature description
- Keyboard shortcuts documented
- User-facing help text is clear

**Approach**:
- Update README.md with new feature
- Document keyboard shortcuts ("s" to star, "u" to unstar)
- Document filter toggle functionality

## Project Status Board

- [x] Task 1: Create Starring Service
- [x] Task 2: Update ImageItem Model (Optional Enhancement - No changes needed)
- [x] Task 3: Integrate StarringService into SlideshowViewModel
- [x] Task 4: Add Star Button to ControlPanelView
- [x] Task 5: Add Keyboard Shortcuts for Starring
- [x] Task 6: Add Filter Toggle to ConfigurationView
- [x] Task 7: Handle Edge Cases and State Management
- [ ] Task 8: Write Tests for Starring Feature
- [ ] Task 9: Update Documentation

## Current Status / Progress Tracking

**Status**: IMPLEMENTATION IN PROGRESS - Core Features Complete

### Task 1 Results (Completed):
- **StarringService Protocol Created**: Defined protocol with methods for star/unstar/isStarred/getStarredImageUrls
- **UserDefaultsStarringService Implemented**: Full implementation using UserDefaults with per-folder isolation
- **Tests Created**: Comprehensive test suite in `StarringServiceTests.swift` covering all functionality
- **Build Verification**: Service compiles and is ready for use

### Task 2 Results (Completed):
- **ImageItem Model Reviewed**: Confirmed no changes needed - model remains immutable and simple
- **Design Decision**: Starred state managed separately via service (separation of concerns)

### Task 3 Results (Completed):
- **SlideshowConfiguration Updated**: Added `showOnlyStarred: Bool` property with default `false`
- **ConfigurationService Updated**: Added save/load support for `showOnlyStarred` property
- **SlideshowViewModel Updated**: 
  - Added `starringService` property with dependency injection support
  - Added `originalImages` array to store unfiltered images
  - Added `isCurrentImageStarred` computed property
  - Added `starCurrentImage()` and `unstarCurrentImage()` methods (only work when paused)
  - Added `applyStarredFilter()` method for filtering logic
  - Added `toggleShowOnlyStarred()` method
  - Updated `loadImagesFromFolder()` to apply filter if enabled
  - Updated `updateConfiguration()` to handle filter state changes
- **Edge Cases Handled**:
  - Starring/unstarring when filter is active updates filtered array
  - Current index validation after filtering
  - Empty starred set shows appropriate error message
  - Filter state persists globally (not per-folder)
- **Build Verification**: All changes compile successfully

### Task 4 Results (Completed):
- **Star Button Added to ControlPanelView**: 
  - Button only visible when `viewModel.state == .paused`
  - Shows filled star (yellow) when starred, outline star when not
  - Properly disabled when no images or no current image
  - Help text indicates "only when paused"
- **UI Integration**: Button placed before previous/next controls for easy access

### Task 5 Results (Completed):
- **Keyboard Shortcuts Implemented in MainView**:
  - "s" key toggles star/unstar (only when paused)
  - "u" key unstars (only when paused)
  - Uses NSEvent monitoring for compatibility with macOS 13+
  - Properly cleaned up on view disappearance
- **Event Handling**: Only processes when paused and images are loaded

### Task 6 Results (Completed):
- **ConfigurationView Updated**: Added toggle for "Show only starred photos"
- **State Management**: Toggle state synced with configuration
- **UI Integration**: Toggle placed after transition effect picker in settings panel

### Task 7 Results (Completed):
- **Edge Cases Handled**:
  - ✅ Starring/unstarring works correctly when filter is active (re-filters array)
  - ✅ Current index stays valid when filtering (validated and adjusted)
  - ✅ Filter updates immediately when toggled (in updateConfiguration)
  - ✅ Starred state persists correctly per folder (via StarringService)
  - ✅ Switching folders maintains filter preference (global, not per-folder)
  - ✅ Empty starred set shows error message when filter enabled
  - ✅ Index adjustment when current image is removed by filter
- **State Management**: All state transitions handled correctly

### Task 7 Additional Fixes (Completed):
- **Button State Fix**: Changed button to work in both `.idle` and `.paused` states (was only working in `.paused`)
- **UI Update Fix**: Added `@Published starredStateChanged` property and `objectWillChange.send()` to ensure SwiftUI updates when starring state changes
- **Keyboard Shortcuts Fix**: Updated to work in both `.idle` and `.paused` states
- **Visual Indicator**: Added star overlay in top-right corner of image when starred
- **Error Handling**: Improved error messages for empty starred sets (shows message instead of throwing error)

### Task 9 Results (Completed):
- **README.md Updated**: 
  - Added comprehensive Photo Starring Feature section
  - Documented all starring functionality (starring, unstarring, filtering, keyboard shortcuts)
  - Added usage instructions and keyboard shortcuts reference
  - Updated features list to include starring
- **AGENT.md Updated**:
  - Added starring feature to implementation status
  - Updated project structure to include StarringService
  - Added starring to features list
  - Updated test file listing to include StarringServiceTests
  - Added starring to keyboard shortcuts section

### Remaining Tasks:
- Task 8: Write Tests (StarringService tests already created, need ViewModel tests for starring functionality)

### Planning Results:
- **Architecture Analysis**: Reviewed current codebase structure
- **Service Pattern**: Decided to use separate StarringService for persistence (consistent with ConfigurationService pattern)
- **State Management**: Starred state will be managed in ViewModel with service for persistence
- **UI Design**: Star button in ControlPanelView (paused only), filter toggle in ConfigurationView
- **Keyboard Shortcuts**: "s" for star, "u" for unstar (paused only)
- **Persistence Strategy**: UserDefaults with folder path as key component

## Executor's Feedback or Assistance Requests

None at this time. Awaiting user approval to proceed with implementation.

## Lessons

- Keep ImageItem model simple and immutable
- Use service pattern for cross-cutting concerns (configuration, starring)
- Persist state per-folder to allow independent starred sets
- Filter logic should maintain original array for toggling

## Design Decisions

### Starring State Persistence

**Decision**: Use UserDefaults with folder path as key component

**Rationale**:
- Consistent with existing ConfigurationService pattern
- Simple implementation
- No file system management needed
- Persists across app restarts
- Allows per-folder starred sets

**Alternative Considered**: Store `.starred.json` file in each folder
- More complex (file I/O, error handling)
- Requires write permissions to image folders
- Users might accidentally delete or move files
- Better for sharing starred state across instances (not needed here)

### Starred State Storage Format

**Decision**: Store Set<String> of image identifiers (URL paths) per folder

**Rationale**:
- URLs are unique identifiers
- Set provides O(1) lookup for "is starred" checks
- Easy to serialize/deserialize
- Works even if images are moved (if we use absolute paths)

**Key Format**: `"starred.\(normalizedFolderPath)"` -> Set<String> of image URL paths

### Filter Behavior

**Decision**: Global filter toggle (not per-folder preference)

**Rationale**:
- Simpler UX
- User can easily toggle on/off
- Per-folder preference would be more complex and less commonly needed

**Alternative Considered**: Per-folder filter preference
- More complex state management
- Less intuitive UX
- Can be added later if needed

### ImageItem Model

**Decision**: Keep ImageItem immutable, don't add starred property

**Rationale**:
- Separation of concerns (model vs state)
- Starred state is UI/persistence concern, not model concern
- Allows same ImageItem to have different starred states in different contexts (if needed)
- Keeps model simple and testable

## Technical Implementation Notes

### Key Changes Required

1. **New StarringService Protocol and Implementation**:
   - `StarringService` protocol with methods for star/unstar/isStarred
   - `UserDefaultsStarringService` implementation
   - Store starred image IDs per folder in UserDefaults

2. **SlideshowViewModel Updates**:
   - Add `starringService` property
   - Add `starCurrentImage()`, `unstarCurrentImage()`, `isCurrentImageStarred` computed property
   - Add `showOnlyStarred` property and filtering logic
   - Store original images array when filtering
   - Update `loadImagesFromFolder` to apply filter if enabled

3. **SlideshowConfiguration Updates**:
   - Add `showOnlyStarred: Bool` property

4. **ControlPanelView Updates**:
   - Add star button (visible only when paused)
   - Button shows filled/outline star based on current image starred state

5. **ConfigurationView Updates**:
   - Add toggle for "Show only starred photos"

6. **MainView or SlideshowDisplayView Updates**:
   - Add keyboard event handling for "s" and "u" keys
   - Check paused state before processing

7. **Tests**:
   - StarringServiceTests
   - ViewModel starring tests
   - Filtering tests

### Backward Compatibility

- Existing configurations will work (showOnlyStarred defaults to false)
- Existing starred state (none) will work correctly
- No breaking changes to existing APIs

## Open Questions

1. Should the filter preference persist per-folder or be global? (Decision: Global for simplicity)
2. What happens when user switches folders with filter enabled? (Should reset filter or maintain? Decision: Reset to false for simplicity)
3. Should there be a visual indicator (badge/count) showing how many images are starred? (Not in initial implementation, can be added later)
4. Should starred state be exportable/importable? (Not in initial implementation, can be added later)
