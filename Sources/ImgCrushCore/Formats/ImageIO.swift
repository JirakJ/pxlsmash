import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

/// Detects image format from file data or extension.
public enum ImageFormatDetector {

    /// Detected image format.
    public enum DetectedFormat: String, Sendable {
        case png, jpeg, webp, avif, heic, unknown
    }

    /// Detect format from file path using both magic bytes and extension.
    public static func detect(at path: String) throws -> DetectedFormat {
        let url = URL(fileURLWithPath: path)

        guard FileManager.default.fileExists(atPath: path) else {
            throw ImgCrushError.invalidInput("File not found: \(path)")
        }

        guard FileManager.default.isReadableFile(atPath: path) else {
            throw ImgCrushError.permissionDenied("Cannot read file: \(path)")
        }

        // Try magic bytes first
        if let format = detectByMagicBytes(at: url) {
            return format
        }

        // Fallback to extension
        return detectByExtension(url.pathExtension)
    }

    private static func detectByMagicBytes(at url: URL) -> DetectedFormat? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { handle.closeFile() }

        let header = handle.readData(ofLength: 16)
        guard header.count >= 4 else { return nil }

        let bytes = [UInt8](header)

        // PNG: 89 50 4E 47
        if bytes.count >= 4 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 {
            return .png
        }

        // JPEG: FF D8 FF
        if bytes.count >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
            return .jpeg
        }

        // WebP: RIFF....WEBP
        if bytes.count >= 12 && bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46
            && bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50 {
            return .webp
        }

        // HEIC/AVIF: ftyp box (offset 4)
        if bytes.count >= 12 && bytes[4] == 0x66 && bytes[5] == 0x74 && bytes[6] == 0x79 && bytes[7] == 0x70 {
            // Check brand
            let brand = String(bytes: Array(bytes[8..<12]), encoding: .ascii) ?? ""
            if brand.hasPrefix("heic") || brand.hasPrefix("heix") || brand.hasPrefix("mif1") {
                return .heic
            }
            if brand.hasPrefix("avif") || brand.hasPrefix("avis") {
                return .avif
            }
        }

        return nil
    }

    private static func detectByExtension(_ ext: String) -> DetectedFormat {
        switch ext.lowercased() {
        case "png": return .png
        case "jpg", "jpeg": return .jpeg
        case "webp": return .webp
        case "avif": return .avif
        case "heic", "heif": return .heic
        default: return .unknown
        }
    }
}

/// Loads a CGImage from a file path.
public enum ImageLoader {

    /// Load a CGImage from the given path.
    public static func load(at path: String) throws -> CGImage {
        let url = URL(fileURLWithPath: path) as CFURL
        guard let source = CGImageSourceCreateWithURL(url, nil) else {
            throw ImgCrushError.invalidInput("Cannot create image source: \(path)")
        }
        guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            throw ImgCrushError.invalidInput("Cannot decode image: \(path)")
        }
        return image
    }
}

/// Saves a CGImage to a file path in the specified format.
public enum ImageSaver {

    /// Save a CGImage to disk.
    public static func save(_ image: CGImage, to path: String, format: OutputFormat, quality: Int?) throws {
        let url = URL(fileURLWithPath: path) as CFURL
        let uti = utiForFormat(format)

        guard let dest = CGImageDestinationCreateWithURL(url, uti as CFString, 1, nil) else {
            throw ImgCrushError.generalError("Cannot create image destination: \(path)")
        }

        var properties: [CFString: Any] = [:]
        if let q = quality {
            let normalized = max(0.0, min(1.0, Double(q) / 100.0))
            properties[kCGImageDestinationLossyCompressionQuality] = normalized
        }

        CGImageDestinationAddImage(dest, image, properties as CFDictionary)

        guard CGImageDestinationFinalize(dest) else {
            throw ImgCrushError.generalError("Failed to write image: \(path)")
        }
    }

    private static func utiForFormat(_ format: OutputFormat) -> String {
        switch format {
        case .png: return "public.png"
        case .jpeg: return "public.jpeg"
        case .webp: return "public.webp"
        case .avif: return "public.avif"
        case .heic: return "public.heic"
        }
    }
}
