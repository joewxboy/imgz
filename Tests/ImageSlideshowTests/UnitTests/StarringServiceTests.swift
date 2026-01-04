import XCTest
@testable import ImageSlideshowLib

final class StarringServiceTests: XCTestCase {
    
    // MARK: - Test Starring and Unstarring
    
    func testStarImage() {
        // Create a unique UserDefaults suite for this test
        let suiteName = "test.star.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let service = UserDefaultsStarringService(userDefaults: testDefaults)
        let folderPath = "/Users/test/Pictures"
        let imageUrl = URL(fileURLWithPath: "/Users/test/Pictures/image1.jpg")
        
        // Star the image
        service.starImage(at: imageUrl, inFolder: folderPath)
        
        // Verify it's starred
        XCTAssertTrue(service.isStarred(imageUrl: imageUrl, inFolder: folderPath), "Image should be starred")
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    func testUnstarImage() {
        // Create a unique UserDefaults suite for this test
        let suiteName = "test.unstar.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let service = UserDefaultsStarringService(userDefaults: testDefaults)
        let folderPath = "/Users/test/Pictures"
        let imageUrl = URL(fileURLWithPath: "/Users/test/Pictures/image1.jpg")
        
        // Star the image first
        service.starImage(at: imageUrl, inFolder: folderPath)
        XCTAssertTrue(service.isStarred(imageUrl: imageUrl, inFolder: folderPath), "Image should be starred")
        
        // Unstar the image
        service.unstarImage(at: imageUrl, inFolder: folderPath)
        
        // Verify it's not starred
        XCTAssertFalse(service.isStarred(imageUrl: imageUrl, inFolder: folderPath), "Image should not be starred")
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    func testIsStarredReturnsFalseForUnstarredImage() {
        // Create a unique UserDefaults suite for this test
        let suiteName = "test.unstarred.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let service = UserDefaultsStarringService(userDefaults: testDefaults)
        let folderPath = "/Users/test/Pictures"
        let imageUrl = URL(fileURLWithPath: "/Users/test/Pictures/image1.jpg")
        
        // Verify unstarred image returns false
        XCTAssertFalse(service.isStarred(imageUrl: imageUrl, inFolder: folderPath), "Unstarred image should return false")
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    // MARK: - Test Per-Folder Isolation
    
    func testStarredImagesAreIsolatedPerFolder() {
        // Create a unique UserDefaults suite for this test
        let suiteName = "test.isolation.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let service = UserDefaultsStarringService(userDefaults: testDefaults)
        let folder1Path = "/Users/test/Pictures1"
        let folder2Path = "/Users/test/Pictures2"
        let image1Url = URL(fileURLWithPath: "/Users/test/Pictures1/image1.jpg")
        let image2Url = URL(fileURLWithPath: "/Users/test/Pictures2/image1.jpg")
        
        // Star image in folder 1
        service.starImage(at: image1Url, inFolder: folder1Path)
        
        // Verify it's starred in folder 1
        XCTAssertTrue(service.isStarred(imageUrl: image1Url, inFolder: folder1Path), "Image should be starred in folder 1")
        
        // Verify it's not starred in folder 2 (different folder)
        XCTAssertFalse(service.isStarred(imageUrl: image1Url, inFolder: folder2Path), "Image should not be starred in folder 2")
        
        // Star image in folder 2
        service.starImage(at: image2Url, inFolder: folder2Path)
        
        // Verify both are starred in their respective folders
        XCTAssertTrue(service.isStarred(imageUrl: image1Url, inFolder: folder1Path), "Image 1 should be starred in folder 1")
        XCTAssertTrue(service.isStarred(imageUrl: image2Url, inFolder: folder2Path), "Image 2 should be starred in folder 2")
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    // MARK: - Test Get Starred Image URLs
    
    func testGetStarredImageUrls() {
        // Create a unique UserDefaults suite for this test
        let suiteName = "test.getstarred.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let service = UserDefaultsStarringService(userDefaults: testDefaults)
        let folderPath = "/Users/test/Pictures"
        let image1Url = URL(fileURLWithPath: "/Users/test/Pictures/image1.jpg")
        let image2Url = URL(fileURLWithPath: "/Users/test/Pictures/image2.jpg")
        let image3Url = URL(fileURLWithPath: "/Users/test/Pictures/image3.jpg")
        
        // Initially, no starred images
        var starredUrls = service.getStarredImageUrls(forFolder: folderPath)
        XCTAssertEqual(starredUrls.count, 0, "Initially no images should be starred")
        
        // Star two images
        service.starImage(at: image1Url, inFolder: folderPath)
        service.starImage(at: image2Url, inFolder: folderPath)
        
        // Get starred URLs
        starredUrls = service.getStarredImageUrls(forFolder: folderPath)
        XCTAssertEqual(starredUrls.count, 2, "Should have 2 starred images")
        XCTAssertTrue(starredUrls.contains(image1Url), "Should contain image1")
        XCTAssertTrue(starredUrls.contains(image2Url), "Should contain image2")
        XCTAssertFalse(starredUrls.contains(image3Url), "Should not contain image3")
        
        // Unstar one image
        service.unstarImage(at: image1Url, inFolder: folderPath)
        
        // Get starred URLs again
        starredUrls = service.getStarredImageUrls(forFolder: folderPath)
        XCTAssertEqual(starredUrls.count, 1, "Should have 1 starred image")
        XCTAssertFalse(starredUrls.contains(image1Url), "Should not contain image1")
        XCTAssertTrue(starredUrls.contains(image2Url), "Should contain image2")
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    func testGetStarredImageUrlsReturnsEmptySetForEmptyFolder() {
        // Create a unique UserDefaults suite for this test
        let suiteName = "test.empty.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let service = UserDefaultsStarringService(userDefaults: testDefaults)
        let folderPath = "/Users/test/Pictures"
        
        // Get starred URLs for folder with no starred images
        let starredUrls = service.getStarredImageUrls(forFolder: folderPath)
        XCTAssertEqual(starredUrls.count, 0, "Should return empty set for folder with no starred images")
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    // MARK: - Test Persistence
    
    func testStarredStatePersistsAcrossServiceInstances() {
        // Create a unique UserDefaults suite for this test
        let suiteName = "test.persistence.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let folderPath = "/Users/test/Pictures"
        let imageUrl = URL(fileURLWithPath: "/Users/test/Pictures/image1.jpg")
        
        // Create first service instance and star an image
        let service1 = UserDefaultsStarringService(userDefaults: testDefaults)
        service1.starImage(at: imageUrl, inFolder: folderPath)
        
        // Create second service instance with same UserDefaults
        let service2 = UserDefaultsStarringService(userDefaults: testDefaults)
        
        // Verify second service can see the starred state
        XCTAssertTrue(service2.isStarred(imageUrl: imageUrl, inFolder: folderPath), "Starred state should persist across service instances")
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    // MARK: - Test Edge Cases
    
    func testUnstarringUnstarredImageDoesNotError() {
        // Create a unique UserDefaults suite for this test
        let suiteName = "test.unstarred.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let service = UserDefaultsStarringService(userDefaults: testDefaults)
        let folderPath = "/Users/test/Pictures"
        let imageUrl = URL(fileURLWithPath: "/Users/test/Pictures/image1.jpg")
        
        // Unstar an image that was never starred (should not error)
        service.unstarImage(at: imageUrl, inFolder: folderPath)
        
        // Verify it's still not starred
        XCTAssertFalse(service.isStarred(imageUrl: imageUrl, inFolder: folderPath), "Unstarring unstarred image should not error")
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
    
    func testStarringSameImageTwice() {
        // Create a unique UserDefaults suite for this test
        let suiteName = "test.double.\(UUID().uuidString)"
        guard let testDefaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create test UserDefaults")
            return
        }
        
        let service = UserDefaultsStarringService(userDefaults: testDefaults)
        let folderPath = "/Users/test/Pictures"
        let imageUrl = URL(fileURLWithPath: "/Users/test/Pictures/image1.jpg")
        
        // Star the image twice
        service.starImage(at: imageUrl, inFolder: folderPath)
        service.starImage(at: imageUrl, inFolder: folderPath)
        
        // Verify it's still starred (idempotent)
        XCTAssertTrue(service.isStarred(imageUrl: imageUrl, inFolder: folderPath), "Starring twice should still result in starred state")
        
        // Verify only one entry in starred set
        let starredUrls = service.getStarredImageUrls(forFolder: folderPath)
        XCTAssertEqual(starredUrls.count, 1, "Should only have one starred image even after starring twice")
        
        // Clean up
        testDefaults.removePersistentDomain(forName: suiteName)
    }
}

