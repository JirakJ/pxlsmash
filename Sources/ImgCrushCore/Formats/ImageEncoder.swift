import Foundation
import CoreGraphics

/// Unified image encoder — dispatches to format-specific encoders.
public enum ImageEncoder {

    /// Encode and save an image to disk with format-specific optimization.
    public static func save(
        _ image: CGImage,
        to path: String,
        format: OutputFormat,
        quality: Int?,
        stripMetadata: Bool = true
    ) throws {
        let normalizedQuality = quality.map { max(0.0, min(1.0, Double($0) / 100.0)) }

        switch format {
        case .png:
            let opts = PNGEncoder.Options(stripMetadata: stripMetadata)
            try PNGEncoder.save(image, to: path, options: opts)

        case .jpeg:
            let opts = JPEGEncoder.Options(
                quality: normalizedQuality ?? 0.85,
                stripMetadata: stripMetadata,
                progressive: false
            )
            try JPEGEncoder.save(image, to: path, options: opts)

        case .webp:
            let opts = WebPEncoder.Options(
                quality: normalizedQuality ?? 0.85,
                stripMetadata: stripMetadata
            )
            try WebPEncoder.save(image, to: path, options: opts)
        }
    }
}
