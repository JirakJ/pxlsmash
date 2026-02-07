import Foundation
import CoreGraphics
import Accelerate

/// SSIM-based smart quality optimizer.
/// Finds the lowest quality that maintains SSIM above a threshold.
public struct SmartQuality {

    /// Default SSIM threshold (0.95 = visually near-identical).
    public static let defaultThreshold: Double = 0.95

    /// Find optimal quality for a given image and format.
    /// Uses binary search over quality values to find the lowest quality
    /// that keeps SSIM above the threshold.
    public static func findOptimalQuality(
        for image: CGImage,
        format: OutputFormat,
        threshold: Double = defaultThreshold,
        minQuality: Int = 30,
        maxQuality: Int = 95
    ) -> Int {
        // Only lossy formats benefit from smart quality
        guard format == .jpeg || format == .webp || format == .avif || format == .heic else {
            return 100
        }

        var low = minQuality
        var high = maxQuality
        var bestQuality = maxQuality

        while low <= high {
            let mid = (low + high) / 2
            let ssim = encodeAndMeasureSSIM(image: image, format: format, quality: mid)

            if ssim >= threshold {
                bestQuality = mid
                high = mid - 1
            } else {
                low = mid + 1
            }
        }

        return bestQuality
    }

    /// Encode at given quality, decode back, measure SSIM against original.
    private static func encodeAndMeasureSSIM(
        image: CGImage,
        format: OutputFormat,
        quality: Int
    ) -> Double {
        do {
            let data: Data
            switch format {
            case .jpeg:
                let opts = JPEGEncoder.Options(quality: Double(quality) / 100.0, stripMetadata: true, progressive: false)
                data = try JPEGEncoder.encode(image, options: opts)
            case .webp:
                let opts = WebPEncoder.Options(quality: Double(quality) / 100.0, stripMetadata: true)
                data = try WebPEncoder.encode(image, options: opts)
            case .avif:
                data = try AVIFEncoder.encode(image: image, quality: quality)
            case .heic:
                data = try HEICEncoder.encode(image: image, quality: quality)
            default:
                return 1.0
            }

            // Decode the compressed image
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let decoded = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
                return 0.0
            }

            return computeSSIM(original: image, compressed: decoded)
        } catch {
            return 0.0
        }
    }

    /// Compute Structural Similarity Index (SSIM) between two images.
    /// Returns value in [0, 1] where 1 = identical.
    public static func computeSSIM(original: CGImage, compressed: CGImage) -> Double {
        let width = min(original.width, compressed.width)
        let height = min(original.height, compressed.height)

        guard width > 0, height > 0 else { return 0.0 }

        guard let origPixels = extractGrayscale(from: original, width: width, height: height),
              let compPixels = extractGrayscale(from: compressed, width: width, height: height) else {
            return 0.0
        }

        let count = width * height

        // SSIM constants (based on dynamic range L=255)
        let c1: Double = 6.5025    // (0.01 * 255)^2
        let c2: Double = 58.5225   // (0.03 * 255)^2

        var muX: Double = 0, muY: Double = 0
        for i in 0..<count {
            muX += origPixels[i]
            muY += compPixels[i]
        }
        muX /= Double(count)
        muY /= Double(count)

        var sigmaX2: Double = 0, sigmaY2: Double = 0, sigmaXY: Double = 0
        for i in 0..<count {
            let dx = origPixels[i] - muX
            let dy = compPixels[i] - muY
            sigmaX2 += dx * dx
            sigmaY2 += dy * dy
            sigmaXY += dx * dy
        }
        sigmaX2 /= Double(count)
        sigmaY2 /= Double(count)
        sigmaXY /= Double(count)

        let numerator = (2.0 * muX * muY + c1) * (2.0 * sigmaXY + c2)
        let denominator = (muX * muX + muY * muY + c1) * (sigmaX2 + sigmaY2 + c2)

        return numerator / denominator
    }

    /// Extract grayscale pixel values as [Double] in [0, 255].
    private static func extractGrayscale(from image: CGImage, width: Int, height: Int) -> [Double]? {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bytesPerRow = width
        var pixels = [UInt8](repeating: 0, count: width * height)

        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        return pixels.map { Double($0) }
    }
}
