import Foundation
import CoreGraphics
import ImageIO

/// WebP encoder using ImageIO (macOS 14+ has native WebP support).
public enum WebPEncoder {

    public struct Options {
        /// Quality 0.0–1.0 (for lossy). nil = lossless.
        public var quality: Double?
        /// Whether to strip metadata.
        public var stripMetadata: Bool

        /// Lossy encoding with given quality.
        public init(quality: Double = 0.85, stripMetadata: Bool = true) {
            self.quality = max(0, min(1, quality))
            self.stripMetadata = stripMetadata
        }

        /// Lossless encoding.
        public static func lossless(stripMetadata: Bool = true) -> Options {
            var opts = Options()
            opts.quality = nil
            opts.stripMetadata = stripMetadata
            return opts
        }
    }

    /// Encode a CGImage as WebP data.
    public static func encode(_ image: CGImage, options: Options = Options()) throws -> Data {
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data as CFMutableData, "public.webp" as CFString, 1, nil) else {
            throw OptiPixError.generalError("Failed to create WebP encoder (macOS 14+ required for native WebP)")
        }

        var properties: [CFString: Any] = [:]
        if let quality = options.quality {
            properties[kCGImageDestinationLossyCompressionQuality] = quality
        } else {
            properties[kCGImageDestinationLossyCompressionQuality] = 1.0
        }

        CGImageDestinationAddImage(dest, image, properties as CFDictionary)

        guard CGImageDestinationFinalize(dest) else {
            throw OptiPixError.generalError("Failed to finalize WebP encoding")
        }

        return data as Data
    }

    /// Save a CGImage as WebP to file.
    public static func save(_ image: CGImage, to path: String, options: Options = Options()) throws {
        let data = try encode(image, options: options)
        try data.write(to: URL(fileURLWithPath: path))
    }
}
