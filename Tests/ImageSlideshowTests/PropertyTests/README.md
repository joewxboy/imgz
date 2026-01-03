# Property-Based Tests

## Running Property Tests

Due to known compatibility issues between SwiftCheck and Swift Package Manager's command-line test runner, property-based tests must be run through Xcode.

### To run tests:

1. Open the package in Xcode:
```bash
open Package.swift
```

2. Wait for Xcode to resolve dependencies

3. Run tests using:
   - Test Navigator (⌘+U)
   - Product > Test menu
   - Or click the diamond icon next to individual test methods

## Test Files

### ImageLoadingPropertyTests.swift

Contains property-based tests for image loading functionality:

- **testImageFilteringBySupportedFormats**: Validates Property 1 from the design document
  - Tests that only supported image formats (jpg, jpeg, png, gif, heic, tiff, bmp) are returned
  - Generates random folders with mixed file types
  - Verifies filtering and counting logic
  - **Validates: Requirements 1.2**

- **testAlphabeticalImageOrdering**: Validates Property 2 from the design document
  - Tests that images are returned in alphabetical order by filename
  - Generates random sets of filenames with diverse patterns (uppercase, lowercase, numbers, spaces)
  - Verifies both exact ordering and adjacent pair ordering
  - Uses localizedStandardCompare for proper alphabetical sorting
  - **Validates: Requirements 1.4**

### ConfigurationPropertyTests.swift

Contains property-based tests for configuration persistence:

- **testConfigurationPersistenceRoundTrip**: Validates Property 8 from the design document
  - Tests configuration save/load round-trip
  - **Validates: Requirements 6.1, 6.2**

### ScalingPropertyTests.swift

Contains property-based tests for image scaling and aspect ratio preservation:

- **testImageScalingPreservesAspectRatio**: Validates Property 7 from the design document
  - Tests that aspect-fit scaling preserves the original image aspect ratio
  - Generates random image dimensions (10-2000 pixels) and window sizes (100-2000 pixels)
  - Verifies three properties:
    1. Aspect ratio is preserved within 0.01% tolerance
    2. Scaled image fits within the window bounds
    3. At least one dimension touches the container edge (aspect-fit behavior)
  - **Validates: Requirements 5.1, 5.2, 5.3**

## Test Configuration

All property-based tests are configured to run a minimum of 100 iterations to ensure comprehensive coverage across the input space.
