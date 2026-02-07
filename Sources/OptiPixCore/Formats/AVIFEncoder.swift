import Foundation
import ImageIO
import UniformTypeIdentifiers

/// AVIF encoder using ImageIO (macOS 14+).
public struct AVIFEncoder {
    public static func encode(image: CGImage, quality: Int = 80, lossless: Bool = false) throws -> Data {
        guard let avifType = UTType("public.avif") else {
            throw OptiPixError.generalError("AVIF not supported on this macOS version (requires 14+)")
        }

        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, avifType.identifier as CFString, 1, nil) else {
            throw OptiPixError.generalError("Failed to create AVIF destination")
        }

        var properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: Float(quality) / 100.0,
        ]

        if lossless {
            properties[kCGImagePropertyHasAlpha] = true
        }

        CGImageDestinationAddImage(dest, image, properties as CFDictionary)

        guard CGImageDestinationFinalize(dest) else {
            throw OptiPixError.generalError("Failed to encode AVIF")
        }

        return data as Data
    }
}

/// HEIC encoder using ImageIO (macOS native).
public struct HEICEncoder {
    public static func encode(image: CGImage, quality: Int = 80) throws -> Data {
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, "public.heic" as CFString, 1, nil) else {
            throw OptiPixError.generalError("Failed to create HEIC destination")
        }

        let properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: Float(quality) / 100.0,
        ]

        CGImageDestinationAddImage(dest, image, properties as CFDictionary)

        guard CGImageDestinationFinalize(dest) else {
            throw OptiPixError.generalError("Failed to encode HEIC")
        }

        return data as Data
    }
}
