# Unit Tests for ImageLoaderService

## Overview

This directory contains unit tests for the ImageLoaderService implementation.

## Test Coverage

### ImageLoaderServiceTests.swift

Tests for the `DefaultImageLoaderService` class covering:

1. **Empty Folder Handling** (Requirement 1.3)
   - `testLoadImagesFromEmptyFolder()` - Verifies that an empty folder returns an empty array

2. **Folder with No Valid Images** (Requirement 1.3)
   - `testLoadImagesFromFolderWithNoValidImages()` - Tests folder containing only non-image files (txt, pdf, doc)
   - `testLoadImagesFromFolderWithMixedFiles()` - Tests folder with both valid and invalid files

3. **Error Logging for Failed Image Loads** (Requirements 7.1, 7.2)
   - `testLoadImageFromCorruptedFile()` - Verifies error handling for corrupted image files
   - `testLoadImageFromNonExistentFile()` - Verifies error handling for non-existent files
   - Both tests verify that the error message includes the filename (Requirement 7.2)

## Running Tests

Due to SwiftCheck/SPM compatibility issues, tests should be run through Xcode:

```bash
open Package.swift
```

Then use Xcode's test navigator (⌘+U) to run all tests, or right-click on `ImageLoaderServiceTests` to run just these unit tests.

## Test Implementation Details

- Tests use temporary directories created in `setUp()` and cleaned up in `tearDown()`
- Each test is isolated with its own temporary directory
- Tests use real file system operations (no mocks) to validate actual functionality
- Helper method `createMinimalJPEGData()` creates valid 1x1 pixel JPEG images for testing
