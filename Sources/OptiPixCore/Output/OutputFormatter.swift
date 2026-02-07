import Foundation

/// ANSI color codes for terminal output.
enum ANSI {
    static let reset   = "\u{001B}[0m"
    static let bold    = "\u{001B}[1m"
    static let dim     = "\u{001B}[2m"
    static let red     = "\u{001B}[31m"
    static let green   = "\u{001B}[32m"
    static let yellow  = "\u{001B}[33m"
    static let blue    = "\u{001B}[34m"
    static let cyan    = "\u{001B}[36m"
}

/// Formats human-readable and JSON output for processing results.
public enum OutputFormatter {

    // MARK: - Human-readable

    /// Print a single file result line.
    public static func printFileResult(_ result: FileResult) {
        let name = (result.file as NSString).lastPathComponent
        let originalStr = formatBytes(result.originalSize)
        let optimizedStr = formatBytes(result.optimizedSize)
        let pct = result.originalSize > 0
            ? Int(round(Double(result.originalSize - result.optimizedSize) / Double(result.originalSize) * 100))
            : 0
        let time = String(format: "%.2fs", result.timeMs / 1000)

        if result.dryRun {
            print("  \(ANSI.dim)→\(ANSI.reset) \(name) \(originalStr) \(ANSI.dim)(dry run)\(ANSI.reset)")
        } else if pct > 0 {
            print("  \(ANSI.green)✓\(ANSI.reset) \(name) \(originalStr) → \(ANSI.green)\(optimizedStr)\(ANSI.reset) (\(ANSI.green)\(pct)% saved\(ANSI.reset)) \(ANSI.dim)\(time)\(ANSI.reset)")
        } else {
            print("  → \(name) \(originalStr) → \(optimizedStr) (\(pct)% saved) \(ANSI.dim)\(time)\(ANSI.reset)")
        }
    }

    /// Print a file error line.
    public static func printFileError(_ error: FileError) {
        let name = (error.file as NSString).lastPathComponent
        print("  \(ANSI.red)✗\(ANSI.reset) \(name) — \(ANSI.red)\(error.error)\(ANSI.reset)")
    }

    /// Print progress bar.
    public static func printProgress(current: Int, total: Int) {
        guard total > 1 else { return }
        let pct = Int(round(Double(current) / Double(total) * 100))
        let barWidth = 30
        let filled = Int(round(Double(current) / Double(total) * Double(barWidth)))
        let empty = barWidth - filled
        let bar = String(repeating: "█", count: filled) + String(repeating: "░", count: empty)
        let line = "  \(ANSI.dim)\(bar) \(pct)% (\(current)/\(total))\(ANSI.reset)\r"
        FileHandle.standardError.write(Data(line.utf8))
        if current == total {
            FileHandle.standardError.write(Data("\n".utf8))
        }
    }

    /// Print final summary.
    public static func printSummary(results: [FileResult], errors: [FileError], totalTimeMs: Double) {
        let totalOriginal = results.reduce(Int64(0)) { $0 + $1.originalSize }
        let totalOptimized = results.reduce(Int64(0)) { $0 + $1.optimizedSize }
        let saved = totalOriginal - totalOptimized
        let pct = totalOriginal > 0
            ? Int(round(Double(saved) / Double(totalOriginal) * 100))
            : 0
        let savedStr = formatBytes(saved)
        let time = String(format: "%.1fs", totalTimeMs / 1000)

        print("")
        print("\(ANSI.green)✓\(ANSI.reset) \(ANSI.bold)\(results.count) file\(results.count == 1 ? "" : "s") optimized\(ANSI.reset), \(savedStr) saved (\(pct)%), \(time)")
        if !errors.isEmpty {
            print("\(ANSI.red)✗\(ANSI.reset) \(errors.count) file\(errors.count == 1 ? "" : "s") failed")
        }
    }

    /// Print header line.
    public static func printHeader(fileCount: Int, accelerator: String) {
        print("\(ANSI.cyan)⚡\(ANSI.reset) Processing \(fileCount) file\(fileCount == 1 ? "" : "s") with \(ANSI.bold)\(accelerator)\(ANSI.reset)...")
    }

    /// Print verbose Metal info.
    public static func printVerboseInfo() {
        if let engine = MetalEngine.shared {
            let mem = formatBytes(Int64(engine.maxMemory))
            FileHandle.standardError.write(Data("  \(ANSI.dim)[Metal] \(engine.deviceName), \(mem) max memory\(ANSI.reset)\n".utf8))
        } else {
            FileHandle.standardError.write(Data("  \(ANSI.dim)[CPU] Metal unavailable, using vImage\(ANSI.reset)\n".utf8))
        }
    }

    // MARK: - JSON

    /// Print full JSON output.
    public static func printJSONSummary(results: [FileResult], errors: [FileError], totalTimeMs: Double) {
        let totalOriginal = results.reduce(Int64(0)) { $0 + $1.originalSize }
        let totalOptimized = results.reduce(Int64(0)) { $0 + $1.optimizedSize }
        let pct = totalOriginal > 0
            ? round(Double(totalOriginal - totalOptimized) / Double(totalOriginal) * 1000) / 10
            : 0

        var filesJSON: [String] = []
        for r in results {
            let rPct = r.originalSize > 0
                ? round(Double(r.originalSize - r.optimizedSize) / Double(r.originalSize) * 1000) / 10
                : 0
            filesJSON.append("""
            {"file":"\(escapeJSON(r.file))","output_file":"\(escapeJSON(r.outputFile))","original_size":\(r.originalSize),"optimized_size":\(r.optimizedSize),"reduction_pct":\(rPct),"format":"\(r.format)","time_ms":\(Int(r.timeMs)),"dry_run":\(r.dryRun)}
            """)
        }

        var errorsJSON: [String] = []
        for e in errors {
            errorsJSON.append("""
            {"file":"\(escapeJSON(e.file))","error":"\(escapeJSON(e.error))"}
            """)
        }

        print("""
        {"total_files":\(results.count),"total_original_bytes":\(totalOriginal),"total_optimized_bytes":\(totalOptimized),"total_reduction_pct":\(pct),"total_time_ms":\(Int(totalTimeMs)),"files":[\(filesJSON.joined(separator: ","))],"errors":[\(errorsJSON.joined(separator: ","))]}
        """)
    }

    /// Print JSON error.
    public static func printJSONError(message: String, exitCode: Int32) {
        print("""
        {"error":"\(escapeJSON(message))","exit_code":\(exitCode)}
        """)
    }

    // MARK: - Helpers

    /// Format bytes to human-readable string.
    public static func formatBytes(_ bytes: Int64) -> String {
        let abs = Swift.abs(bytes)
        let sign = bytes < 0 ? "-" : ""
        if abs < 1024 { return "\(sign)\(abs)B" }
        if abs < 1024 * 1024 { return "\(sign)\(String(format: "%.1f", Double(abs) / 1024))KB" }
        return "\(sign)\(String(format: "%.1f", Double(abs) / (1024 * 1024)))MB" }

    private static func escapeJSON(_ str: String) -> String {
        str.replacingOccurrences(of: "\\", with: "\\\\")
           .replacingOccurrences(of: "\"", with: "\\\"")
           .replacingOccurrences(of: "\n", with: "\\n")
           .replacingOccurrences(of: "\r", with: "\\r")
           .replacingOccurrences(of: "\t", with: "\\t")
    }
}
