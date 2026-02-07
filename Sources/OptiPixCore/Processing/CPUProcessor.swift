import Foundation
import CoreGraphics
import Accelerate

/// CPU-based image processing fallback using vImage (for Intel Macs without Metal).
public enum CPUProcessor {

    /// Resize an image using vImage (CPU, Accelerate framework).
    public static func resize(_ image: CGImage, to size: ResizeSpec) throws -> CGImage {
        let srcWidth = image.width
        let srcHeight = image.height

        guard srcWidth > 0 && srcHeight > 0 else {
            throw OptiPixError.invalidInput("Invalid image dimensions: \(srcWidth)x\(srcHeight)")
        }

        let bytesPerPixel = 4
        let srcBytesPerRow = bytesPerPixel * srcWidth
        let dstBytesPerRow = bytesPerPixel * size.width

        // Source pixel buffer
        var srcData = [UInt8](repeating: 0, count: srcHeight * srcBytesPerRow)
        guard let srcContext = CGContext(
            data: &srcData,
            width: srcWidth,
            height: srcHeight,
            bitsPerComponent: 8,
            bytesPerRow: srcBytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw OptiPixError.generalError("Failed to create source context for resize")
        }
        srcContext.draw(image, in: CGRect(x: 0, y: 0, width: srcWidth, height: srcHeight))

        // Destination pixel buffer
        var dstData = [UInt8](repeating: 0, count: size.height * dstBytesPerRow)

        // vImage buffers
        var srcBuffer = vImage_Buffer(
            data: &srcData,
            height: vImagePixelCount(srcHeight),
            width: vImagePixelCount(srcWidth),
            rowBytes: srcBytesPerRow
        )
        var dstBuffer = vImage_Buffer(
            data: &dstData,
            height: vImagePixelCount(size.height),
            width: vImagePixelCount(size.width),
            rowBytes: dstBytesPerRow
        )

        let error = vImageScale_ARGB8888(&srcBuffer, &dstBuffer, nil, vImage_Flags(kvImageHighQualityResampling))
        guard error == kvImageNoError else {
            throw OptiPixError.generalError("vImage resize failed with error \(error)")
        }

        // Extract result
        guard let dstContext = CGContext(
            data: &dstData,
            width: size.width,
            height: size.height,
            bitsPerComponent: 8,
            bytesPerRow: dstBytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw OptiPixError.generalError("Failed to create destination context for resize")
        }

        guard let result = dstContext.makeImage() else {
            throw OptiPixError.generalError("Failed to extract resized image")
        }

        return result
    }
}
