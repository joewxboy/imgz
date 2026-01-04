import Foundation
import ImageIO
import CoreGraphics

/// Represents EXIF metadata extracted from an image
public struct EXIFData {
    /// Camera make (e.g., "Canon", "Nikon")
    public let cameraMake: String?
    
    /// Camera model (e.g., "Canon EOS 5D Mark IV")
    public let cameraModel: String?
    
    /// ISO sensitivity value
    public let iso: Int?
    
    /// Aperture value (f-stop, e.g., 2.8)
    public let aperture: Double?
    
    /// Shutter speed value (e.g., 1/60)
    public let shutterSpeed: String?
    
    /// Exposure mode (e.g., "Auto", "Manual")
    public let exposureMode: String?
    
    /// Date and time when the image was taken
    public let dateTaken: Date?
    
    /// Focal length in millimeters
    public let focalLength: Double?
    
    /// GPS latitude coordinate
    public let latitude: Double?
    
    /// GPS longitude coordinate
    public let longitude: Double?
    
    /// Image width in pixels
    public let imageWidth: Int?
    
    /// Image height in pixels
    public let imageHeight: Int?
    
    /// Orientation of the image
    public let orientation: Int?
    
    /// Creates a new EXIFData instance
    public init(
        cameraMake: String? = nil,
        cameraModel: String? = nil,
        iso: Int? = nil,
        aperture: Double? = nil,
        shutterSpeed: String? = nil,
        exposureMode: String? = nil,
        dateTaken: Date? = nil,
        focalLength: Double? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        imageWidth: Int? = nil,
        imageHeight: Int? = nil,
        orientation: Int? = nil
    ) {
        self.cameraMake = cameraMake
        self.cameraModel = cameraModel
        self.iso = iso
        self.aperture = aperture
        self.shutterSpeed = shutterSpeed
        self.exposureMode = exposureMode
        self.dateTaken = dateTaken
        self.focalLength = focalLength
        self.latitude = latitude
        self.longitude = longitude
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.orientation = orientation
    }
    
    /// Returns true if any EXIF data is available
    public var hasData: Bool {
        return cameraMake != nil ||
               cameraModel != nil ||
               iso != nil ||
               aperture != nil ||
               shutterSpeed != nil ||
               exposureMode != nil ||
               dateTaken != nil ||
               focalLength != nil ||
               latitude != nil ||
               longitude != nil ||
               imageWidth != nil ||
               imageHeight != nil ||
               orientation != nil
    }
}

/// Protocol for extracting EXIF metadata from images
public protocol EXIFService {
    /// Extracts EXIF metadata from an image file
    /// - Parameter imageUrl: The URL of the image file
    /// - Returns: EXIFData containing extracted metadata, or nil if extraction fails
    func extractEXIF(from imageUrl: URL) async -> EXIFData?
}

/// Implementation of EXIFService using ImageIO framework
public class ImageIOEXIFService: EXIFService {
    public init() {}
    
    public func extractEXIF(from imageUrl: URL) async -> EXIFData? {
        guard let imageSource = CGImageSourceCreateWithURL(imageUrl as CFURL, nil) else {
            return nil
        }
        
        guard let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] else {
            return nil
        }
        
        // Extract EXIF dictionary
        let exifDict = imageProperties[kCGImagePropertyExifDictionary as String] as? [String: Any]
        
        // Extract TIFF dictionary (contains camera make/model)
        let tiffDict = imageProperties[kCGImagePropertyTIFFDictionary as String] as? [String: Any]
        
        // Extract GPS dictionary
        let gpsDict = imageProperties[kCGImagePropertyGPSDictionary as String] as? [String: Any]
        
        // Extract image dimensions
        let width = imageProperties[kCGImagePropertyPixelWidth as String] as? Int
        let height = imageProperties[kCGImagePropertyPixelHeight as String] as? Int
        let orientation = imageProperties[kCGImagePropertyOrientation as String] as? Int
        
        // Extract camera make and model from TIFF
        let cameraMake = tiffDict?[kCGImagePropertyTIFFMake as String] as? String
        let cameraModel = tiffDict?[kCGImagePropertyTIFFModel as String] as? String
        
        // Extract ISO
        let iso = exifDict?[kCGImagePropertyExifISOSpeedRatings as String] as? [Int]
        let isoValue = iso?.first
        
        // Extract aperture (f-number)
        let apertureValue = exifDict?[kCGImagePropertyExifFNumber as String] as? Double
        let aperture = apertureValue
        
        // Extract shutter speed
        let exposureTime = exifDict?[kCGImagePropertyExifExposureTime as String] as? Double
        let shutterSpeed = formatShutterSpeed(exposureTime)
        
        // Extract exposure mode
        let exposureModeValue = exifDict?[kCGImagePropertyExifExposureMode as String] as? Int
        let exposureMode = formatExposureMode(exposureModeValue)
        
        // Extract date taken
        let dateTimeOriginal = exifDict?[kCGImagePropertyExifDateTimeOriginal as String] as? String
        let dateTaken = parseEXIFDate(dateTimeOriginal)
        
        // Extract focal length
        let focalLength = exifDict?[kCGImagePropertyExifFocalLength as String] as? Double
        
        // Extract GPS coordinates
        let (latitude, longitude) = extractGPSCoordinates(from: gpsDict)
        
        return EXIFData(
            cameraMake: cameraMake,
            cameraModel: cameraModel,
            iso: isoValue,
            aperture: aperture,
            shutterSpeed: shutterSpeed,
            exposureMode: exposureMode,
            dateTaken: dateTaken,
            focalLength: focalLength,
            latitude: latitude,
            longitude: longitude,
            imageWidth: width,
            imageHeight: height,
            orientation: orientation
        )
    }
    
    /// Formats shutter speed from exposure time value
    /// - Parameter exposureTime: Exposure time in seconds (e.g., 0.016666 for 1/60)
    /// - Returns: Formatted string (e.g., "1/60s")
    private func formatShutterSpeed(_ exposureTime: Double?) -> String? {
        guard let exposureTime = exposureTime else { return nil }
        
        if exposureTime >= 1.0 {
            // For exposures >= 1 second, show as decimal
            return String(format: "%.1fs", exposureTime)
        } else {
            // For exposures < 1 second, show as fraction
            let denominator = Int(1.0 / exposureTime)
            return "1/\(denominator)s"
        }
    }
    
    /// Formats exposure mode from numeric value
    /// - Parameter mode: Exposure mode value (0=Auto, 1=Manual, 2=AutoBracket)
    /// - Returns: Human-readable string
    private func formatExposureMode(_ mode: Int?) -> String? {
        guard let mode = mode else { return nil }
        
        switch mode {
        case 0:
            return "Auto"
        case 1:
            return "Manual"
        case 2:
            return "Auto Bracket"
        default:
            return "Unknown"
        }
    }
    
    /// Parses EXIF date string into Date object
    /// - Parameter dateString: EXIF date string (format: "YYYY:MM:DD HH:MM:SS")
    /// - Returns: Date object or nil if parsing fails
    private func parseEXIFDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        
        return formatter.date(from: dateString)
    }
    
    /// Extracts GPS coordinates from GPS dictionary
    /// - Parameter gpsDict: GPS dictionary from image properties
    /// - Returns: Tuple of (latitude, longitude) or (nil, nil) if not available
    private func extractGPSCoordinates(from gpsDict: [String: Any]?) -> (Double?, Double?) {
        guard let gpsDict = gpsDict else { return (nil, nil) }
        
        // Extract latitude
        let latitudeRef = gpsDict[kCGImagePropertyGPSLatitudeRef as String] as? String
        let latitudeValue = gpsDict[kCGImagePropertyGPSLatitude as String] as? Double
        var latitude: Double? = nil
        if let lat = latitudeValue {
            latitude = (latitudeRef == "S") ? -lat : lat
        }
        
        // Extract longitude
        let longitudeRef = gpsDict[kCGImagePropertyGPSLongitudeRef as String] as? String
        let longitudeValue = gpsDict[kCGImagePropertyGPSLongitude as String] as? Double
        var longitude: Double? = nil
        if let lon = longitudeValue {
            longitude = (longitudeRef == "W") ? -lon : lon
        }
        
        return (latitude, longitude)
    }
}

