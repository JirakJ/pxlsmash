import Foundation
import CoreGraphics
import ImageIO

/// PNG encoder with optimization options.
public enum PNGEncoder {

    public struct Options {
        /// Whether to strip metadata (EXIF, ICC profiles).
        public var stripMetadata: Bool
        /// Compression filter (default: automatic).
        public var interlaced: Bool

        public init(stripMetadata: Bool = true, interlaced: Bool = false) {
            self.stripMetadata = stripMetadata
            self.interlaced = interlaced
        }
    }

    /// Encode a CGImage as PNG data.
    public static func encode(_ image: CGImage, options: Options = Options()) throws -> Data {
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data as CFMutableData, "public.png" as CFString, 1, nil) else {
            throw OptiPixError.generalError("Failed to create PNG encoder")
        }

        var properties: [CFString: Any] = [:]
        if options.interlaced {
            properties[kCGImagePropertyPNGInterlaceType] = 1
        }

        var imageProperties: [CFString: Any] = [:]
        if !properties.isEmpty {
            imageProperties[kCGImagePropertyPNGDictionary] = properties
        }

        CGImageDestinationAddImage(dest, image, imageProperties as CFDictionary)

        guard CGImageDestinationFinalize(dest) else {
            throw OptiPixError.generalError("Failed to finalize PNG encoding")
        }

        return data as Data
    }

    /// Save a CGImage as PNG to file.
    public static func save(_ image: CGImage, to path: String, options: Options = Options()) throws {
        let data = try encode(image, options: options)
        try data.write(to: URL(fileURLWithPath: path))
    }
}
