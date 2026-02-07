import Foundation
import CoreGraphics
import ImageIO

/// JPEG encoder with quality and progressive support.
public enum JPEGEncoder {

    public struct Options {
        /// Quality 0.0–1.0.
        public var quality: Double
        /// Whether to strip metadata.
        public var stripMetadata: Bool
        /// Progressive JPEG.
        public var progressive: Bool

        public init(quality: Double = 0.85, stripMetadata: Bool = true, progressive: Bool = false) {
            self.quality = max(0, min(1, quality))
            self.stripMetadata = stripMetadata
            self.progressive = progressive
        }
    }

    /// Encode a CGImage as JPEG data.
    public static func encode(_ image: CGImage, options: Options = Options()) throws -> Data {
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data as CFMutableData, "public.jpeg" as CFString, 1, nil) else {
            throw PxlSmashError.generalError("Failed to create JPEG encoder")
        }

        var properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: options.quality
        ]

        if options.progressive {
            let jfifProps: [CFString: Any] = [
                kCGImagePropertyJFIFIsProgressive: true
            ]
            properties[kCGImagePropertyJFIFDictionary] = jfifProps
        }

        CGImageDestinationAddImage(dest, image, properties as CFDictionary)

        guard CGImageDestinationFinalize(dest) else {
            throw PxlSmashError.generalError("Failed to finalize JPEG encoding")
        }

        return data as Data
    }

    /// Save a CGImage as JPEG to file.
    public static func save(_ image: CGImage, to path: String, options: Options = Options()) throws {
        let data = try encode(image, options: options)
        try data.write(to: URL(fileURLWithPath: path))
    }
}
