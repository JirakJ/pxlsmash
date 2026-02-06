import Foundation

/// Supported output image formats.
public enum OutputFormat: String, Sendable {
    case png
    case jpeg
    case webp
    case avif
    case heic
}

/// Resize specification.
public struct ResizeSpec: Sendable {
    public let width: Int
    public let height: Int

    public init(width: Int, height: Int) {
        self.width = width
        self.height = height
    }

    /// Parse a "WxH" string.
    public static func parse(_ string: String) -> ResizeSpec? {
        let parts = string.lowercased().split(separator: "x")
        guard parts.count == 2,
              let w = Int(parts[0]), w > 0,
              let h = Int(parts[1]), h > 0 else {
            return nil
        }
        return ResizeSpec(width: w, height: h)
    }
}

/// All processing options from CLI arguments.
public struct ProcessingOptions: Sendable {
    public let inputPath: String
    public let outputFormat: OutputFormat?
    public let quality: Int?
    public let resize: ResizeSpec?
    public let outputPath: String?
    public let recursive: Bool
    public let jsonOutput: Bool
    public let dryRun: Bool
    public let verbose: Bool

    public init(
        inputPath: String,
        outputFormat: OutputFormat? = nil,
        quality: Int? = nil,
        resize: ResizeSpec? = nil,
        outputPath: String? = nil,
        recursive: Bool = false,
        jsonOutput: Bool = false,
        dryRun: Bool = false,
        verbose: Bool = false
    ) {
        self.inputPath = inputPath
        self.outputFormat = outputFormat
        self.quality = quality
        self.resize = resize
        self.outputPath = outputPath
        self.recursive = recursive
        self.jsonOutput = jsonOutput
        self.dryRun = dryRun
        self.verbose = verbose
    }
}
