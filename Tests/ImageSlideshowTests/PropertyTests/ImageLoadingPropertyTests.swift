import XCTest
import SwiftCheck
@testable import ImageSlideshowLib

// Feature: macos-image-slideshow, Property 1: Image filtering by supported formats
final class ImageLoadingPropertyTests: XCTestCase {
    
    // MARK: - Property 1: Image filtering by supported formats
    // Validates: Requirements 1.2
    
    func testImageFilteringBySupportedFormats() {
        property("For any folder with mixed file types, only supported image formats should be returned") <- forAll { (fileCount: Int, seed: Int) in
            // Constrain to reasonable file count (1-50 files)
            let validFileCount = max(1, min(50, abs(fileCount)))
            
            // Create a temporary directory for testing
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_images_\(UUID().uuidString)")
            
            do {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            } catch {
                return false
            }
            
            // Define supported and unsupported extensions
            let supportedExtensions = ["jpg", "jpeg", "png", "gif", "heic", "tiff", "bmp"]
            let unsupportedExtensions = ["txt", "pdf", "doc", "mp4", "zip", "exe", "dmg"]
            let allExtensions = supportedExtensions + unsupportedExtensions
            
            // Create test files with various extensions
            var createdSupportedFiles = 0
            for i in 0..<validFileCount {
                let extensionIndex = (abs(seed) + i) % allExtensions.count
                let ext = allExtensions[extensionIndex]
                let filename = "file_\(i).\(ext)"
                let fileURL = tempDir.appendingPathComponent(filename)
                
                // Create empty file
                FileManager.default.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)
                
                if supportedExtensions.contains(ext) {
                    createdSupportedFiles += 1
                }
            }
            
            // Load images using the service
            let service = DefaultImageLoaderService()
            let imageItems: [ImageItem]
            
            // Use a semaphore to wait for async operation
            let semaphore = DispatchSemaphore(value: 0)
            var result: [ImageItem]?
            var loadError: Error?
            
            Task {
                do {
                    result = try await service.loadImagesFromFolder(tempDir)
                } catch {
                    loadError = error
                }
                semaphore.signal()
            }
            
            semaphore.wait()
            
            guard let imageItems = result, loadError == nil else {
                // Clean up
                try? FileManager.default.removeItem(at: tempDir)
                return false
            }
            
            // Verify all returned items have supported extensions
            let allHaveSupportedExtensions = imageItems.allSatisfy { item in
                let ext = item.url.pathExtension.lowercased()
                return supportedExtensions.contains(ext)
            }
            
            // Verify count matches expected supported files
            let countMatches = imageItems.count == createdSupportedFiles
            
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
            
            return allHaveSupportedExtensions && countMatches
        }
    }
    
    // MARK: - Property 2: Alphabetical image ordering
    // Validates: Requirements 1.4
    
    func testAlphabeticalImageOrdering() {
        property("For any set of image files, the returned ImageItem array should be sorted alphabetically by filename") <- forAll { (fileCount: Int, seed: Int) in
            // Constrain to reasonable file count (2-30 files to ensure we have multiple files to sort)
            let validFileCount = max(2, min(30, abs(fileCount)))
            
            // Create a temporary directory for testing
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("test_ordering_\(UUID().uuidString)")
            
            do {
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            } catch {
                return false
            }
            
            // Use only supported extensions for this test
            let supportedExtensions = ["jpg", "jpeg", "png", "gif"]
            
            // Generate random filenames with various patterns
            var filenames: [String] = []
            for i in 0..<validFileCount {
                // Create diverse filename patterns to test sorting
                let nameVariations = [
                    "image_\(i)",
                    "photo\(i)",
                    "IMG_\(String(format: "%04d", i))",
                    "Picture \(i)",
                    "a\(i)",
                    "Z\(i)",
                    "test\(i)"
                ]
                let nameIndex = (abs(seed) + i) % nameVariations.count
                let baseName = nameVariations[nameIndex]
                let extIndex = i % supportedExtensions.count
                let ext = supportedExtensions[extIndex]
                filenames.append("\(baseName).\(ext)")
            }
            
            // Create files in random order
            for filename in filenames {
                let fileURL = tempDir.appendingPathComponent(filename)
                FileManager.default.createFile(atPath: fileURL.path, contents: Data(), attributes: nil)
            }
            
            // Load images using the service
            let service = DefaultImageLoaderService()
            let imageItems: [ImageItem]
            
            // Use a semaphore to wait for async operation
            let semaphore = DispatchSemaphore(value: 0)
            var result: [ImageItem]?
            var loadError: Error?
            
            Task {
                do {
                    result = try await service.loadImagesFromFolder(tempDir)
                } catch {
                    loadError = error
                }
                semaphore.signal()
            }
            
            semaphore.wait()
            
            guard let imageItems = result, loadError == nil else {
                // Clean up
                try? FileManager.default.removeItem(at: tempDir)
                return false
            }
            
            // Verify the items are sorted alphabetically by filename
            let returnedFilenames = imageItems.map { $0.filename }
            let expectedSortedFilenames = filenames.sorted { name1, name2 in
                name1.localizedStandardCompare(name2) == .orderedAscending
            }
            
            let isSorted = returnedFilenames == expectedSortedFilenames
            
            // Additional check: verify each adjacent pair is in correct order
            let adjacentPairsCorrect = zip(returnedFilenames.dropLast(), returnedFilenames.dropFirst()).allSatisfy { first, second in
                first.localizedStandardCompare(second) == .orderedAscending
            }
            
            // Clean up
            try? FileManager.default.removeItem(at: tempDir)
            
            return isSorted && adjacentPairsCorrect
        }
    }
}
