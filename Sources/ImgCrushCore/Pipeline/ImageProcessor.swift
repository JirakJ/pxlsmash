import Foundation
import CoreGraphics

/// Main entry point for image processing.
public enum ImageProcessor {

    /// Maximum concurrent file operations.
    private static let maxConcurrency = ProcessInfo.processInfo.activeProcessorCount

    /// Temp files being written — cleaned up on SIGINT.
    private static var tempFiles: [String] = []
    private static let tempFilesLock = NSLock()
    private static var sigintInstalled = false

    /// Run imgcrush with the given options.
    public static func run(with options: ProcessingOptions) throws {
        installSIGINTHandler()

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

        // Check disk space before batch processing
        if let outputDir = options.outputPath {
            try checkDiskSpace(at: outputDir)
        }

        if !options.jsonOutput {
            let accel = MetalEngine.isAvailable ? "Metal GPU" : "CPU (vImage)"
            OutputFormatter.printHeader(fileCount: files.count, accelerator: accel)
            if options.verbose {
                OutputFormatter.printVerboseInfo()
            }
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        let (results, errors) = processFiles(files, options: options)

        let totalTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000

        if options.jsonOutput {
            OutputFormatter.printJSONSummary(results: results, errors: errors, totalTimeMs: totalTime)
        } else {
            OutputFormatter.printSummary(results: results, errors: errors, totalTimeMs: totalTime)
        }
    }

    // MARK: - Parallel processing

    private static func processFiles(_ files: [String], options: ProcessingOptions) -> ([FileResult], [FileError]) {
        let pipeline = OptimizationPipeline(options: options)
        var results: [FileResult] = []
        var errors: [FileError] = []

        // Use parallel processing for large batches (>4 files), sequential for small
        if files.count > 4 && !options.dryRun {
            let resultsLock = NSLock()
            let completed = NSAtomicCounter()

            DispatchQueue.concurrentPerform(iterations: files.count) { index in
                let file = files[index]
                do {
                    let result = try pipeline.process(filePath: file)
                    resultsLock.lock()
                    results.append(result)
                    resultsLock.unlock()

                    if !options.jsonOutput {
                        resultsLock.lock()
                        OutputFormatter.printFileResult(result)
                        let done = completed.increment()
                        OutputFormatter.printProgress(current: done, total: files.count)
                        resultsLock.unlock()
                    }
                } catch {
                    let fileError = FileError(
                        file: file,
                        error: (error as? ImgCrushError)?.message ?? error.localizedDescription
                    )
                    resultsLock.lock()
                    errors.append(fileError)
                    if !options.jsonOutput {
                        OutputFormatter.printFileError(fileError)
                        let done = completed.increment()
                        OutputFormatter.printProgress(current: done, total: files.count)
                    }
                    resultsLock.unlock()
                }
            }
        } else {
            // Sequential for small batches / dry-run
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
        }

        return (results, errors)
    }

    // MARK: - SIGINT handling

    private static func installSIGINTHandler() {
        guard !sigintInstalled else { return }
        sigintInstalled = true

        signal(SIGINT) { _ in
            // Clean up temp files
            ImageProcessor.tempFilesLock.lock()
            let files = ImageProcessor.tempFiles
            ImageProcessor.tempFilesLock.unlock()

            for file in files {
                try? FileManager.default.removeItem(atPath: file)
            }

            FileHandle.standardError.write(Data("\n⚠️  Interrupted — cleaned up \(files.count) temp file(s)\n".utf8))
            exit(130)
        }
    }

    /// Register a temp file for cleanup on SIGINT.
    public static func registerTempFile(_ path: String) {
        tempFilesLock.lock()
        tempFiles.append(path)
        tempFilesLock.unlock()
    }

    /// Unregister a temp file after successful write.
    public static func unregisterTempFile(_ path: String) {
        tempFilesLock.lock()
        tempFiles.removeAll { $0 == path }
        tempFilesLock.unlock()
    }

    // MARK: - Disk space check

    private static func checkDiskSpace(at path: String) throws {
        let url = URL(fileURLWithPath: path)
        if let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey]),
           let available = values.volumeAvailableCapacityForImportantUsage {
            // Warn if less than 100MB free
            if available < 100 * 1024 * 1024 {
                throw ImgCrushError.diskFull("Less than 100MB disk space available at \(path)")
            }
        }
    }

    // MARK: - File collection

    static func collectFiles(in directory: String, recursive: Bool) throws -> [String] {
        let fm = FileManager.default
        let supportedExtensions: Set<String> = ["png", "jpg", "jpeg", "webp", "avif", "heic", "heif"]

        var files: [String] = []

        if recursive {
            guard let enumerator = fm.enumerator(atPath: directory) else {
                throw ImgCrushError.permissionDenied("Cannot read directory: \(directory)")
            }
            while let relative = enumerator.nextObject() as? String {
                let full = (directory as NSString).appendingPathComponent(relative)

                // Skip symlinks
                if isSymlink(at: full) { continue }

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

                // Skip symlinks
                if isSymlink(at: full) { continue }

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

    /// Check if a path is a symbolic link.
    private static func isSymlink(at path: String) -> Bool {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let type = attrs[.type] as? FileAttributeType else {
            return false
        }
        return type == .typeSymbolicLink
    }
}

// MARK: - Atomic counter for parallel progress

final class NSAtomicCounter: @unchecked Sendable {
    private var value = 0
    private let lock = NSLock()

    @discardableResult
    func increment() -> Int {
        lock.lock()
        value += 1
        let v = value
        lock.unlock()
        return v
    }
}

// MARK: - Result types

public struct FileResult: Sendable {
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

public struct FileError: Sendable {
    public let file: String
    public let error: String

    public init(file: String, error: String) {
        self.file = file
        self.error = error
    }
}
