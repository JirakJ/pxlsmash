import Foundation
import CoreGraphics

/// Main entry point for image processing.
public enum ImageProcessor {

    /// Run imgcrush with the given options.
    public static func run(with options: ProcessingOptions) throws {
        let path = (options.inputPath as NSString).expandingTildeInPath
        let fileManager = FileManager.default

        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDir) else {
            throw ImgCrushError.invalidInput("Path not found: \(path)")
        }

        let files: [String]
        if isDir.boolValue {
            files = try collectFiles(in: path, recursive: options.recursive)
        } else {
            files = [path]
        }

        if files.isEmpty {
            if options.jsonOutput {
                print("""
                {"total_files":0,"total_original_bytes":0,"total_optimized_bytes":0,"total_reduction_pct":0,"total_time_ms":0,"files":[],"errors":[]}
                """)
            } else {
                print("No image files found.")
            }
            return
        }

        let startTime = CFAbsoluteTimeGetCurrent()
        var results: [FileResult] = []
        var errors: [FileError] = []

        for file in files {
            do {
                let result = try processFile(file, options: options)
                results.append(result)

                if !options.jsonOutput {
                    printFileResult(result)
                }
            } catch {
                let fileError = FileError(file: file, error: error.localizedDescription)
                errors.append(fileError)

                if !options.jsonOutput {
                    printFileError(fileError)
                }
            }
        }

        let totalTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

        if options.jsonOutput {
            printJSONSummary(results: results, errors: errors, totalTimeMs: totalTime)
        } else {
            printSummary(results: results, errors: errors, totalTimeMs: totalTime)
        }
    }

    // MARK: - File collection

    private static func collectFiles(in directory: String, recursive: Bool) throws -> [String] {
        let fm = FileManager.default
        let supportedExtensions: Set<String> = ["png", "jpg", "jpeg", "webp"]

        var files: [String] = []

        if recursive {
            guard let enumerator = fm.enumerator(atPath: directory) else {
                throw ImgCrushError.permissionDenied("Cannot read directory: \(directory)")
            }
            while let relative = enumerator.nextObject() as? String {
                let full = (directory as NSString).appendingPathComponent(relative)
                let ext = (relative as NSString).pathExtension.lowercased()
                if supportedExtensions.contains(ext) {
                    files.append(full)
                }
            }
        } else {
            let contents = try fm.contentsOfDirectory(atPath: directory)
            for item in contents {
                let ext = (item as NSString).pathExtension.lowercased()
                if supportedExtensions.contains(ext) {
                    files.append((directory as NSString).appendingPathComponent(item))
                }
            }
        }

        return files.sorted()
    }

    // MARK: - Single file processing

    private static func processFile(_ path: String, options: ProcessingOptions) throws -> FileResult {
        let fileStart = CFAbsoluteTimeGetCurrent()
        let fm = FileManager.default

        let originalSize = try fileSize(at: path)
        let format = try ImageFormatDetector.detect(at: path)

        guard format != .unknown else {
            throw ImgCrushError.invalidInput("Unsupported format: \(path)")
        }

        let outputFormat = options.outputFormat ?? outputFormatFromDetected(format)
        let outputPath = resolveOutputPath(input: path, outputDir: options.outputPath, format: outputFormat)

        if options.dryRun {
            let timeMs = (CFAbsoluteTimeGetCurrent() - fileStart) * 1000
            return FileResult(
                file: path,
                outputFile: outputPath,
                originalSize: originalSize,
                optimizedSize: originalSize,
                format: outputFormat.rawValue,
                timeMs: timeMs,
                dryRun: true
            )
        }

        let image = try ImageLoader.load(at: path)

        // TODO: Metal resize will be added in Phase 2
        let processedImage = image

        // Ensure output directory exists
        let outputDir = (outputPath as NSString).deletingLastPathComponent
        if !fm.fileExists(atPath: outputDir) {
            try fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)
        }

        try ImageSaver.save(processedImage, to: outputPath, format: outputFormat, quality: options.quality)

        let optimizedSize = try fileSize(at: outputPath)
        let timeMs = (CFAbsoluteTimeGetCurrent() - fileStart) * 1000

        return FileResult(
            file: path,
            outputFile: outputPath,
            originalSize: originalSize,
            optimizedSize: optimizedSize,
            format: outputFormat.rawValue,
            timeMs: timeMs,
            dryRun: false
        )
    }

    // MARK: - Helpers

    private static func fileSize(at path: String) throws -> Int64 {
        let attrs = try FileManager.default.attributesOfItem(atPath: path)
        return (attrs[.size] as? Int64) ?? 0
    }

    private static func outputFormatFromDetected(_ detected: ImageFormatDetector.DetectedFormat) -> OutputFormat {
        switch detected {
        case .png: return .png
        case .jpeg: return .jpeg
        case .webp: return .webp
        case .unknown: return .png
        }
    }

    private static func resolveOutputPath(input: String, outputDir: String?, format: OutputFormat) -> String {
        let baseName = ((input as NSString).lastPathComponent as NSString).deletingPathExtension
        let newExtension: String
        switch format {
        case .png: newExtension = "png"
        case .jpeg: newExtension = "jpg"
        case .webp: newExtension = "webp"
        }

        let fileName = "\(baseName).\(newExtension)"

        if let dir = outputDir {
            return (dir as NSString).appendingPathComponent(fileName)
        } else {
            let dir = (input as NSString).deletingLastPathComponent
            return (dir as NSString).appendingPathComponent(fileName)
        }
    }

    // MARK: - Output

    private static func printFileResult(_ result: FileResult) {
        let originalKB = formatBytes(result.originalSize)
        let optimizedKB = formatBytes(result.optimizedSize)
        let pct = result.originalSize > 0
            ? Int(round(Double(result.originalSize - result.optimizedSize) / Double(result.originalSize) * 100))
            : 0
        let time = String(format: "%.2fs", result.timeMs / 1000)
        let name = (result.file as NSString).lastPathComponent

        if result.dryRun {
            print("  → \(name) \(originalKB) (dry run)")
        } else {
            let symbol = pct >= 0 ? "\u{001B}[32m✓\u{001B}[0m" : "→"
            print("  \(symbol) \(name) \(originalKB) → \(optimizedKB) (\(pct)% saved) \(time)")
        }
    }

    private static func printFileError(_ error: FileError) {
        let name = (error.file as NSString).lastPathComponent
        print("  \u{001B}[31m✗\u{001B}[0m \(name) — \(error.error)")
    }

    private static func printSummary(results: [FileResult], errors: [FileError], totalTimeMs: Double) {
        let totalOriginal = results.reduce(0) { $0 + $1.originalSize }
        let totalOptimized = results.reduce(0) { $0 + $1.optimizedSize }
        let pct = totalOriginal > 0
            ? Int(round(Double(totalOriginal - totalOptimized) / Double(totalOriginal) * 100))
            : 0
        let saved = formatBytes(totalOriginal - totalOptimized)
        let time = String(format: "%.1fs", totalTimeMs / 1000)

        print("")
        print("\u{001B}[32m✓\u{001B}[0m \(results.count) files optimized, \(saved) saved (\(pct)%), \(time)")
        if !errors.isEmpty {
            print("\u{001B}[31m✗\u{001B}[0m \(errors.count) files failed")
        }
    }

    private static func printJSONSummary(results: [FileResult], errors: [FileError], totalTimeMs: Double) {
        let totalOriginal = results.reduce(0) { $0 + $1.originalSize }
        let totalOptimized = results.reduce(0) { $0 + $1.optimizedSize }
        let pct = totalOriginal > 0
            ? round(Double(totalOriginal - totalOptimized) / Double(totalOriginal) * 100 * 10) / 10
            : 0

        var filesJSON: [String] = []
        for r in results {
            let rPct = r.originalSize > 0
                ? round(Double(r.originalSize - r.optimizedSize) / Double(r.originalSize) * 100 * 10) / 10
                : 0
            filesJSON.append("""
            {"file":"\(r.file)","output_file":"\(r.outputFile)","original_size":\(r.originalSize),"optimized_size":\(r.optimizedSize),"reduction_pct":\(rPct),"format":"\(r.format)","time_ms":\(Int(r.timeMs)),"dry_run":\(r.dryRun)}
            """)
        }

        var errorsJSON: [String] = []
        for e in errors {
            errorsJSON.append("""
            {"file":"\(e.file)","error":"\(e.error)"}
            """)
        }

        print("""
        {"total_files":\(results.count),"total_original_bytes":\(totalOriginal),"total_optimized_bytes":\(totalOptimized),"total_reduction_pct":\(pct),"total_time_ms":\(Int(totalTimeMs)),"files":[\(filesJSON.joined(separator: ","))],"errors":[\(errorsJSON.joined(separator: ","))]}
        """)
    }

    private static func formatBytes(_ bytes: Int64) -> String {
        if bytes < 1024 { return "\(bytes)B" }
        if bytes < 1024 * 1024 { return String(format: "%.1fKB", Double(bytes) / 1024) }
        return String(format: "%.1fMB", Double(bytes) / (1024 * 1024))
    }
}

// MARK: - Result types

struct FileResult {
    let file: String
    let outputFile: String
    let originalSize: Int64
    let optimizedSize: Int64
    let format: String
    let timeMs: Double
    let dryRun: Bool
}

struct FileError {
    let file: String
    let error: String
}
