import XCTest
import CoreGraphics
import ImageIO
@testable import OptiPixCore

/// Helper to create test images.
enum TestImageFactory {

    /// Create a simple solid-color PNG at the given path.
    static func createPNG(at path: String, width: Int = 100, height: Int = 100) throws {
        let image = try createCGImage(width: width, height: height, r: 255, g: 0, b: 0)
        try saveCGImage(image, to: path, format: "public.png")
    }

    /// Create a simple solid-color JPEG at the given path.
    static func createJPEG(at path: String, width: Int = 100, height: Int = 100) throws {
        let image = try createCGImage(width: width, height: height, r: 0, g: 128, b: 255)
        try saveCGImage(image, to: path, format: "public.jpeg", quality: 0.9)
    }

    /// Create a CGImage with a solid color.
    static func createCGImage(width: Int, height: Int, r: UInt8, g: UInt8, b: UInt8) throws -> CGImage {
        let bytesPerRow = width * 4
        var data = [UInt8](repeating: 0, count: width * height * 4)
        for i in 0..<(width * height) {
            data[i * 4 + 0] = r
            data[i * 4 + 1] = g
            data[i * 4 + 2] = b
            data[i * 4 + 3] = 255
        }

        guard let context = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let image = context.makeImage() else {
            throw OptiPixError.generalError("Failed to create test image")
        }
        return image
    }

    static func saveCGImage(_ image: CGImage, to path: String, format: String, quality: Double? = nil) throws {
        let url = URL(fileURLWithPath: path) as CFURL
        guard let dest = CGImageDestinationCreateWithURL(url, format as CFString, 1, nil) else {
            throw OptiPixError.generalError("Failed to create destination")
        }
        var props: [CFString: Any] = [:]
        if let q = quality {
            props[kCGImageDestinationLossyCompressionQuality] = q
        }
        CGImageDestinationAddImage(dest, image, props as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            throw OptiPixError.generalError("Failed to finalize")
        }
    }
}
