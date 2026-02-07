import Foundation
import CoreGraphics
import ImageIO

/// Preserves or strips EXIF/metadata from image files.
public enum MetadataHandler {

    /// Copy metadata from source image file to destination.
    public static func copyMetadata(from sourcePath: String, to destPath: String) throws {
        let sourceURL = URL(fileURLWithPath: sourcePath) as CFURL
        let destURL = URL(fileURLWithPath: destPath) as CFURL

        guard let source = CGImageSourceCreateWithURL(sourceURL, nil) else { return }
        guard let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) else { return }

        guard let destSource = CGImageSourceCreateWithURL(destURL, nil) else { return }
        guard let destImage = CGImageSourceCreateImageAtIndex(destSource, 0, nil) else { return }

        let destType = CGImageSourceGetType(destSource) ?? ("public.jpeg" as CFString)

        guard let dest = CGImageDestinationCreateWithURL(destURL, destType, 1, nil) else { return }

        CGImageDestinationAddImage(dest, destImage, metadata)

        guard CGImageDestinationFinalize(dest) else {
            throw ImgCrushError.generalError("Failed to write metadata to: \(destPath)")
        }
    }

    /// Extract metadata dictionary from an image file.
    public static func extractMetadata(from path: String) -> [String: Any]? {
        let url = URL(fileURLWithPath: path) as CFURL
        guard let source = CGImageSourceCreateWithURL(url, nil) else { return nil }
        guard let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else { return nil }
        return props
    }

    /// Check if an image file contains EXIF data.
    public static func hasEXIF(at path: String) -> Bool {
        guard let metadata = extractMetadata(from: path) else { return false }
        return metadata[kCGImagePropertyExifDictionary as String] != nil
    }
}
