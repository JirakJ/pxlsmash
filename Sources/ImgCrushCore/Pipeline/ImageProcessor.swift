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
                OutputFormatter.printJSONSummary(results: [], errors: [], totalTimeMs: 0)
            } else {
                print("No image files found.")
            }
            return
        }

        if !options.jsonOutput {
            let accel = MetalEngine.isAvailable ? "Metal GPU" : "CPU (vImage)"
            OutputFormatter.printHeader(fileCount: files.count, accelerator: accel)
            if options.verbose {
                OutputFormatter.printVerboseInfo()
            }
        }

        let startTime = CFAbsoluteTimeGetCurrent()
        let pipeline = OptimizationPipeline(options: options)
        var results: [FileResult] = []
        var errors: [FileError] = []

        for (index, file) in files.enumerated() {
            do {
                let result = try pipeline.process(filePath: file)
                results.append(result)

                if !options.jsonOutput {
                    OutputFormatter.printFileResult(result)
                    if files.count > 1 {
                        OutputFormatter.printProgress(current: index + 1, total: files.count)
                    }
                }
            } catch {
                let fileError = FileError(
                    file: file,
                    error: (error as? ImgCrushError)?.message ?? error.localizedDescription
                )
                errors.append(fileError)

                if !options.jsonOutput {
                    OutputFormatter.printFileError(fileError)
                }
            }
        }

        let totalTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

        if options.jsonOutput {
            OutputFormatter.printJSONSummary(results: results, errors: errors, totalTimeMs: totalTime)
        } else {
            OutputFormatter.printSummary(results: results, errors: errors, totalTimeMs: totalTime)
        }
    }

    // MARK: - File collection

    static func collectFiles(in directory: String, recursive: Bool) throws -> [String] {
        let fm = FileManager.default
        let supportedExtensions: Set<String> = ["png", "jpg", "jpeg", "webp"]

        var files: [String] = []

        if recursive {
            guard let enumerator = fm.enumerator(atPath: directory) else {
                throw ImgCrushError.permissionDenied("Cannot read directory: \(directory)")
            }
            while let relative = enumerator.nextObject() as? String {
                let full = (directory as NSString).appendingPathComponent(relative)
                var isDir: ObjCBool = false
                if fm.fileExists(atPath: full, isDirectory: &isDir), !isDir.boolValue {
                    let ext = (relative as NSString).pathExtension.lowercased()
                    if supportedExtensions.contains(ext) {
                        files.append(full)
                    }
                }
            }
        } else {
            let contents = try fm.contentsOfDirectory(atPath: directory)
            for item in contents {
                let full = (directory as NSString).appendingPathComponent(item)
                var isDir: ObjCBool = false
                if fm.fileExists(atPath: full, isDirectory: &isDir), !isDir.boolValue {
                    let ext = (item as NSString).pathExtension.lowercased()
                    if supportedExtensions.contains(ext) {
                        files.append(full)
                    }
                }
            }
        }

        return files.sorted()
    }
}

// MARK: - Result types

public struct FileResult {
    public let file: String
    public let outputFile: String
    public let originalSize: Int64
    public let optimizedSize: Int64
    public let format: String
    public let timeMs: Double
    public let dryRun: Bool

    public init(file: String, outputFile: String, originalSize: Int64, optimizedSize: Int64, format: String, timeMs: Double, dryRun: Bool) {
        self.file = file
        self.outputFile = outputFile
        self.originalSize = originalSize
        self.optimizedSize = optimizedSize
        self.format = format
        self.timeMs = timeMs
        self.dryRun = dryRun
    }
}

public struct FileError {
    public let file: String
    public let error: String

    public init(file: String, error: String) {
        self.file = file
        self.error = error
    }
}
