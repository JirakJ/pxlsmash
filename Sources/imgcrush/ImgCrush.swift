import Foundation
import ArgumentParser
import ImgCrushCore

@main
struct ImgCrush: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "imgcrush",
        abstract: "Metal-accelerated image optimizer for macOS",
        version: "1.0.0"
    )

    @Argument(help: "Input file or directory to optimize")
    var input: String

    @Option(name: .long, help: "Output format (png, jpeg, webp)")
    var format: String?

    @Option(name: .long, help: "Output quality (1-100)")
    var quality: Int?

    @Option(name: .long, help: "Resize dimensions (WxH)")
    var resize: String?

    @Option(name: .long, help: "Output directory")
    var output: String?

    @Flag(name: .long, help: "Process subdirectories recursively")
    var recursive = false

    @Flag(name: .long, help: "Output results as JSON")
    var json = false

    @Flag(name: .long, help: "Preview changes without modifying files")
    var dryRun = false

    @Flag(name: .long, help: "Show detailed processing information")
    var verbose = false

    func validate() throws {
        if let q = quality {
            guard q >= 1 && q <= 100 else {
                throw ValidationError("Quality must be between 1 and 100 (got \(q))")
            }
        }
        if let f = format {
            guard OutputFormat(rawValue: f) != nil else {
                throw ValidationError("Unsupported format '\(f)'. Use: png, jpeg, webp")
            }
        }
        if let r = resize {
            guard ResizeSpec.parse(r) != nil else {
                throw ValidationError("Invalid resize format '\(r)'. Use: WxH (e.g. 800x600)")
            }
        }
    }

    func run() throws {
        let options = ProcessingOptions(
            inputPath: input,
            outputFormat: format.flatMap { OutputFormat(rawValue: $0) },
            quality: quality,
            resize: resize.flatMap { ResizeSpec.parse($0) },
            outputPath: output,
            recursive: recursive,
            jsonOutput: json,
            dryRun: dryRun,
            verbose: verbose
        )

        do {
            try ImageProcessor.run(with: options)
        } catch let error as ImgCrushError {
            if json {
                printErrorJSON(error)
            } else {
                printError(error)
            }
            throw ExitCode(rawValue: error.exitCode)
        }
    }

    private func printError(_ error: ImgCrushError) {
        FileHandle.standardError.write(Data("error: \(error.message)\n".utf8))
    }

    private func printErrorJSON(_ error: ImgCrushError) {
        OutputFormatter.printJSONError(message: error.message, exitCode: error.exitCode)
    }
}
