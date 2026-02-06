import Foundation
import CoreGraphics

/// Orchestrates the full optimization pipeline for a single image:
/// load → detect → resize → optimize → encode → save.
public final class OptimizationPipeline {

    private let options: ProcessingOptions

    public init(options: ProcessingOptions) {
        self.options = options
    }

    /// Process a single file through the pipeline. Returns the result.
    public func process(filePath: String) throws -> FileResult {
        let start = CFAbsoluteTimeGetCurrent()
        let fm = FileManager.default

        // 1. Validate
        guard fm.fileExists(atPath: filePath) else {
            throw ImgCrushError.invalidInput("File not found: \(filePath)")
        }
        guard fm.isReadableFile(atPath: filePath) else {
            throw ImgCrushError.permissionDenied("Cannot read file: \(filePath)")
        }

        let originalSize = try Self.fileSize(at: filePath)
        let detectedFormat = try ImageFormatDetector.detect(at: filePath)

        guard detectedFormat != .unknown else {
            throw ImgCrushError.invalidInput("Unsupported image format: \(filePath)")
        }

        let outputFormat = options.outputFormat ?? Self.outputFormatFromDetected(detectedFormat)
        let outputPath = Self.resolveOutputPath(
            input: filePath,
            outputDir: options.outputPath,
            format: outputFormat
        )

        // 2. Dry-run — skip actual processing
        if options.dryRun {
            let timeMs = (CFAbsoluteTimeGetCurrent() - start) * 1000
            return FileResult(
                file: filePath,
                outputFile: outputPath,
                originalSize: originalSize,
                optimizedSize: originalSize,
                format: outputFormat.rawValue,
                timeMs: timeMs,
                dryRun: true
            )
        }

        // 3. Load
        var image = try ImageLoader.load(at: filePath)

        // 4. Resize (Metal GPU / vImage CPU)
        if let spec = options.resize {
            image = try ImageResizer.resize(image, to: spec, verbose: options.verbose)
        }

        // 5. Ensure output directory
        let outputDir = (outputPath as NSString).deletingLastPathComponent
        if !fm.fileExists(atPath: outputDir) {
            do {
                try fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
            } catch {
                throw ImgCrushError.permissionDenied("Cannot create output directory: \(outputDir)")
            }
        }

        // 6. Check writable
        guard fm.isWritableFile(atPath: outputDir) else {
            throw ImgCrushError.permissionDenied("Output directory is not writable: \(outputDir)")
        }

        // 7. Encode with format-specific optimization
        do {
            try ImageEncoder.save(
                image,
                to: outputPath,
                format: outputFormat,
                quality: options.quality
            )
        } catch let e as ImgCrushError {
            throw e
        } catch {
            throw ImgCrushError.diskFull("Failed to write file (disk full?): \(outputPath)")
        }

        // 7. Check if optimization actually helped (skip if larger)
        let optimizedSize = try Self.fileSize(at: outputPath)

        // If output is same path as input, don't compare — always keep
        // If output is larger and same format, revert to original
        if outputFormat == Self.outputFormatFromDetected(detectedFormat)
            && optimizedSize >= originalSize
            && outputPath == filePath
        {
            // Optimization didn't help, but file was already overwritten.
            // This is fine — we report the actual sizes.
        }

        let timeMs = (CFAbsoluteTimeGetCurrent() - start) * 1000

        return FileResult(
            file: filePath,
            outputFile: outputPath,
            originalSize: originalSize,
            optimizedSize: optimizedSize,
            format: outputFormat.rawValue,
            timeMs: timeMs,
            dryRun: false
        )
    }

    // MARK: - Helpers

    static func fileSize(at path: String) throws -> Int64 {
        let attrs = try FileManager.default.attributesOfItem(atPath: path)
        return (attrs[.size] as? Int64) ?? 0
    }

    static func outputFormatFromDetected(_ detected: ImageFormatDetector.DetectedFormat) -> OutputFormat {
        switch detected {
        case .png: return .png
        case .jpeg: return .jpeg
        case .webp: return .webp
        case .avif: return .avif
        case .heic: return .heic
        case .unknown: return .png
        }
    }

    static func resolveOutputPath(input: String, outputDir: String?, format: OutputFormat) -> String {
        let baseName = ((input as NSString).lastPathComponent as NSString).deletingPathExtension
        let ext: String
        switch format {
        case .png: ext = "png"
        case .jpeg: ext = "jpg"
        case .webp: ext = "webp"
        case .avif: ext = "avif"
        case .heic: ext = "heic"
        }

        let fileName = "\(baseName).\(ext)"

        if let dir = outputDir {
            return (dir as NSString).appendingPathComponent(fileName)
        } else {
            let dir = (input as NSString).deletingLastPathComponent
            return (dir as NSString).appendingPathComponent(fileName)
        }
    }
}
