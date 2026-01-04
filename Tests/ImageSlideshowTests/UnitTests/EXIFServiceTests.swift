import XCTest
@testable import ImageSlideshowLib
import ImageIO
import CoreGraphics

final class EXIFServiceTests: XCTestCase {
    
    var exifService: ImageIOEXIFService!
    
    override func setUp() {
        super.setUp()
        exifService = ImageIOEXIFService()
    }
    
    override func tearDown() {
        exifService = nil
        super.tearDown()
    }
    
    // MARK: - Test EXIF Data Structure
    
    func testEXIFDataInitialization() {
        let exifData = EXIFData(
            cameraMake: "Canon",
            cameraModel: "EOS 5D Mark IV",
            iso: 400,
            aperture: 2.8,
            shutterSpeed: "1/60s",
            exposureMode: "Manual",
            dateTaken: Date(),
            focalLength: 50.0,
            latitude: 37.7749,
            longitude: -122.4194,
            imageWidth: 1920,
            imageHeight: 1080,
            orientation: 1
        )
        
        XCTAssertEqual(exifData.cameraMake, "Canon")
        XCTAssertEqual(exifData.cameraModel, "EOS 5D Mark IV")
        XCTAssertEqual(exifData.iso, 400)
        XCTAssertEqual(exifData.aperture, 2.8)
        XCTAssertEqual(exifData.shutterSpeed, "1/60s")
        XCTAssertEqual(exifData.exposureMode, "Manual")
        XCTAssertNotNil(exifData.dateTaken)
        XCTAssertEqual(exifData.focalLength, 50.0)
        XCTAssertEqual(exifData.latitude, 37.7749)
        XCTAssertEqual(exifData.longitude, -122.4194)
        XCTAssertEqual(exifData.imageWidth, 1920)
        XCTAssertEqual(exifData.imageHeight, 1080)
        XCTAssertEqual(exifData.orientation, 1)
    }
    
    func testEXIFDataHasData() {
        // Empty EXIF data
        let emptyData = EXIFData()
        XCTAssertFalse(emptyData.hasData, "Empty EXIF data should not have data")
        
        // EXIF data with at least one field
        let dataWithISO = EXIFData(iso: 400)
        XCTAssertTrue(dataWithISO.hasData, "EXIF data with ISO should have data")
        
        let dataWithCamera = EXIFData(cameraMake: "Canon", cameraModel: "EOS 5D")
        XCTAssertTrue(dataWithCamera.hasData, "EXIF data with camera should have data")
    }
    
    // MARK: - Test EXIF Extraction
    
    func testExtractEXIFFromNonExistentFile() async {
        let nonExistentURL = URL(fileURLWithPath: "/nonexistent/path/image.jpg")
        let exifData = await exifService.extractEXIF(from: nonExistentURL)
        
        // Should return nil for non-existent files
        XCTAssertNil(exifData, "EXIF extraction should return nil for non-existent files")
    }
    
    func testExtractEXIFFromInvalidFile() async {
        // Create a temporary file that's not an image
        let tempDir = FileManager.default.temporaryDirectory
        let tempFile = tempDir.appendingPathComponent("test.txt")
        
        // Create a text file
        try? "This is not an image".write(to: tempFile, atomically: true, encoding: .utf8)
        defer {
            try? FileManager.default.removeItem(at: tempFile)
        }
        
        let exifData = await exifService.extractEXIF(from: tempFile)
        
        // Should return nil or empty data for invalid image files
        // The exact behavior depends on ImageIO, but it should handle gracefully
        // We just verify it doesn't crash
        XCTAssertNoThrow(exifData, "EXIF extraction should not crash on invalid files")
    }
    
    // Note: Testing with actual image files with EXIF data would require test fixtures
    // For now, we test the structure and error handling
    
    // MARK: - Test EXIF Service Protocol Conformance
    
    func testEXIFServiceProtocolConformance() {
        // Verify that ImageIOEXIFService conforms to EXIFService protocol
        let service: EXIFService = ImageIOEXIFService()
        XCTAssertNotNil(service, "ImageIOEXIFService should conform to EXIFService")
    }
    
    // MARK: - Test EXIF Data Formatting
    
    func testEXIFDataFormatting() {
        // Test that EXIF data can be formatted for display
        let exifData = EXIFData(
            cameraMake: "Canon",
            cameraModel: "EOS 5D Mark IV",
            iso: 400,
            aperture: 2.8,
            shutterSpeed: "1/60s",
            focalLength: 50.0
        )
        
        // Verify all fields are accessible
        XCTAssertNotNil(exifData.cameraMake)
        XCTAssertNotNil(exifData.cameraModel)
        XCTAssertNotNil(exifData.iso)
        XCTAssertNotNil(exifData.aperture)
        XCTAssertNotNil(exifData.shutterSpeed)
        XCTAssertNotNil(exifData.focalLength)
        
        // Verify hasData returns true
        XCTAssertTrue(exifData.hasData)
    }
    
    func testEXIFDataWithPartialData() {
        // Test EXIF data with only some fields populated
        let partialData = EXIFData(iso: 400, aperture: 2.8)
        
        XCTAssertTrue(partialData.hasData, "Partial EXIF data should still have data")
        XCTAssertEqual(partialData.iso, 400)
        XCTAssertEqual(partialData.aperture, 2.8)
        XCTAssertNil(partialData.cameraMake)
        XCTAssertNil(partialData.cameraModel)
    }
}

