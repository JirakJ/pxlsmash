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

        if !options.jsonOutput {
            let accel = MetalEngine.isAvailable ? "Metal GPU" : "CPU (vImage)"
            print("⚡ Processing \(files.count) file\(files.count == 1 ? "" : "s") with \(accel)...")
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
                    printFileResult(result)
                    if files.count > 1 {
                        printProgress(current: index + 1, total: files.count)
                    }
                }
            } catch {
                let fileError = FileError(
                    file: file,
                    error: (error as? ImgCrushError)?.message ?? error.localizedDescription
                )
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

    // MARK: - Progress

    private static func printProgress(current: Int, total: Int) {
        guard total > 1 else { return }
        let pct = Int(round(Double(current) / Double(total) * 100))
        let barWidth = 30
        let filled = Int(round(Double(current) / Double(total) * Double(barWidth)))
        let empty = barWidth - filled
        let bar = String(repeating: "█", count: filled) + String(repeating: "░", count: empty)
        let line = "  \(bar) \(pct)% (\(current)/\(total))\r"
        FileHandle.standardError.write(Data(line.utf8))
        if current == total {
            FileHandle.standardError.write(Data("\n".utf8))
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

public struct FileResult {
    let file: String
    let outputFile: String
    let originalSize: Int64
    let optimizedSize: Int64
    let format: String
    let timeMs: Double
    let dryRun: Bool
}

public struct FileError {
    let file: String
    let error: String
}
