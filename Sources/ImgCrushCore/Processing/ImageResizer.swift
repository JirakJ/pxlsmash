import Foundation
import CoreGraphics

/// Unified image resizer — uses Metal GPU when available, CPU (vImage) as fallback.
public enum ImageResizer {

    /// Resize an image to the given dimensions.
    public static func resize(_ image: CGImage, to spec: ResizeSpec, verbose: Bool = false) throws -> CGImage {
        if let engine = MetalEngine.shared {
            if verbose {
                FileHandle.standardError.write(Data("  [Metal] Resizing on GPU (\(engine.deviceName))\n".utf8))
            }
            return try engine.resize(image, to: spec)
        } else {
            if verbose {
                FileHandle.standardError.write(Data("  [CPU] Metal unavailable, using vImage fallback\n".utf8))
            }
            return try CPUProcessor.resize(image, to: spec)
        }
    }
}
