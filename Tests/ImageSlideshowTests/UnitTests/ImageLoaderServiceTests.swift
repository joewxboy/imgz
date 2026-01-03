import XCTest
@testable import ImageSlideshowLib

final class ImageLoaderServiceTests: XCTestCase {
    
    var service: DefaultImageLoaderService!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        service = DefaultImageLoaderService()
        
        // Create a temporary directory for test files
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ImageLoaderServiceTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() async throws {
        // Clean up temporary directory
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        service = nil
        tempDirectory = nil
        try await super.tearDown()
    }
    
    // MARK: - Test Empty Folder Handling
    // Requirements: 1.3
    
    func testLoadImagesFromEmptyFolder() async throws {
        // Given: An empty folder
        // (tempDirectory is already empty from setUp)
        
        // When: Loading images from the empty folder
        let images = try await service.loadImagesFromFolder(tempDirectory)
        
        // Then: Should return an empty array
        XCTAssertTrue(images.isEmpty, "Empty folder should return empty array")
    }
    
    // MARK: - Test Folder with No Valid Images
    // Requirements: 1.3
    
    func testLoadImagesFromFolderWithNoValidImages() async throws {
        // Given: A folder with only non-image files
        let textFileURL = tempDirectory.appendingPathComponent("document.txt")
        let pdfFileURL = tempDirectory.appendingPathComponent("document.pdf")
        let docFileURL = tempDirectory.appendingPathComponent("document.doc")
        
        try "Some text content".write(to: textFileURL, atomically: true, encoding: .utf8)
        try "PDF content".write(to: pdfFileURL, atomically: true, encoding: .utf8)
        try "Doc content".write(to: docFileURL, atomically: true, encoding: .utf8)
        
        // When: Loading images from the folder
        let images = try await service.loadImagesFromFolder(tempDirectory)
        
        // Then: Should return an empty array
        XCTAssertTrue(images.isEmpty, "Folder with no valid images should return empty array")
    }
    
    func testLoadImagesFromFolderWithMixedFiles() async throws {
        // Given: A folder with both valid and invalid files
        let textFileURL = tempDirectory.appendingPathComponent("document.txt")
        let imageFileURL = tempDirectory.appendingPathComponent("image.jpg")
        
        try "Some text content".write(to: textFileURL, atomically: true, encoding: .utf8)
        
        // Create a minimal valid JPEG file (1x1 pixel red image)
        let imageData = createMinimalJPEGData()
        try imageData.write(to: imageFileURL)
        
        // When: Loading images from the folder
        let images = try await service.loadImagesFromFolder(tempDirectory)
        
        // Then: Should return only the valid image
        XCTAssertEqual(images.count, 1, "Should return only valid image files")
        XCTAssertEqual(images.first?.filename, "image.jpg")
    }
    
    // MARK: - Test Error Logging for Failed Image Loads
    // Requirements: 7.1, 7.2
    
    func testLoadImageFromCorruptedFile() async throws {
        // Given: A file with image extension but corrupted/invalid content
        let corruptedImageURL = tempDirectory.appendingPathComponent("corrupted.jpg")
        try "This is not a valid image".write(to: corruptedImageURL, atomically: true, encoding: .utf8)
        
        let imageItem = ImageItem(url: corruptedImageURL, filename: "corrupted.jpg")
        
        // When/Then: Loading the corrupted image should throw an error
        do {
            _ = try await service.loadImage(from: imageItem)
            XCTFail("Should throw error for corrupted image")
        } catch let error as ImageLoaderError {
            // Verify error contains filename (Requirement 7.2)
            switch error {
            case .failedToLoadImage(let filename):
                XCTAssertEqual(filename, "corrupted.jpg", "Error should include the filename")
                XCTAssertTrue(error.localizedDescription.contains("corrupted.jpg"), 
                            "Error description should contain filename")
            }
        } catch {
            XCTFail("Should throw ImageLoaderError, got: \(error)")
        }
    }
    
    func testLoadImageFromNonExistentFile() async throws {
        // Given: An ImageItem pointing to a non-existent file
        let nonExistentURL = tempDirectory.appendingPathComponent("nonexistent.png")
        let imageItem = ImageItem(url: nonExistentURL, filename: "nonexistent.png")
        
        // When/Then: Loading the non-existent image should throw an error
        do {
            _ = try await service.loadImage(from: imageItem)
            XCTFail("Should throw error for non-existent image")
        } catch let error as ImageLoaderError {
            // Verify error contains filename (Requirement 7.2)
            switch error {
            case .failedToLoadImage(let filename):
                XCTAssertEqual(filename, "nonexistent.png", "Error should include the filename")
            }
        } catch {
            XCTFail("Should throw ImageLoaderError, got: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Creates minimal valid JPEG data for testing
    /// Returns a 1x1 pixel red JPEG image
    private func createMinimalJPEGData() -> Data {
        // Create a 1x1 red image using NSImage
        let size = NSSize(width: 1, height: 1)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        
        // Convert to JPEG data
        guard let tiffData = image.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapImage.representation(using: .jpeg, properties: [:]) else {
            fatalError("Failed to create JPEG data")
        }
        
        return jpegData
    }
}
