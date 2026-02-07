import Foundation

/// Project-level config from `.imgcrushrc` (JSON).
///
/// Example `.imgcrushrc`:
/// ```json
/// {
///   "quality": 85,
///   "format": "webp",
///   "recursive": true,
///   "output": "./optimized"
/// }
/// ```
public struct ProjectConfig: Codable {
    public var quality: Int?
    public var format: String?
    public var resize: String?
    public var output: String?
    public var recursive: Bool?
    public var verbose: Bool?

    /// Load config from `.imgcrushrc` in the given directory or any parent.
    public static func load(from directory: String = FileManager.default.currentDirectoryPath) -> ProjectConfig? {
        var dir = directory
        let fm = FileManager.default

        while true {
            let configPath = (dir as NSString).appendingPathComponent(".imgcrushrc")
            if fm.fileExists(atPath: configPath),
               let data = fm.contents(atPath: configPath),
               let config = try? JSONDecoder().decode(ProjectConfig.self, from: data) {
                return config
            }

            let parent = (dir as NSString).deletingLastPathComponent
            if parent == dir { break }
            dir = parent
        }

        return nil
    }

    /// Merge config with CLI options. CLI options take precedence.
    public func mergeWith(
        inputPath: String,
        outputFormat: OutputFormat?,
        quality: Int?,
        resize: ResizeSpec?,
        outputPath: String?,
        recursive: Bool,
        jsonOutput: Bool,
        dryRun: Bool,
        verbose: Bool,
        smartQuality: Bool = false,
        keepMetadata: Bool = false
    ) -> ProcessingOptions {
        ProcessingOptions(
            inputPath: inputPath,
            outputFormat: outputFormat ?? self.format.flatMap { OutputFormat(rawValue: $0) },
            quality: quality ?? self.quality,
            resize: resize ?? self.resize.flatMap { ResizeSpec.parse($0) },
            outputPath: outputPath ?? self.output,
            recursive: recursive || (self.recursive ?? false),
            jsonOutput: jsonOutput,
            dryRun: dryRun,
            verbose: verbose || (self.verbose ?? false),
            smartQuality: smartQuality,
            keepMetadata: keepMetadata
        )
    }
}
