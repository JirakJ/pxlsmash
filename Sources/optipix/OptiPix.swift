import Foundation
import ArgumentParser
import OptiPixCore

@main
struct OptiPix: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "optipix",
        abstract: "Metal-accelerated image optimizer for macOS",
        version: "1.0.0"
    )

    @Argument(help: "Input file or directory to optimize")
    var input: String?

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

    @Flag(name: .long, help: "Auto-detect optimal quality (SSIM-based)")
    var smartQuality = false

    @Flag(name: .long, help: "Preserve EXIF/metadata in output")
    var keepMetadata = false

    @Flag(name: .long, help: "Watch directory for changes")
    var watch = false

    @Option(name: .long, help: "Activate license key")
    var activate: String?

    @Option(name: .long, help: "Email for license activation")
    var email: String?

    @Flag(name: .long, help: "Show license status")
    var licenseStatus = false

    func validate() throws {
        // License commands don't need input
        if activate != nil || licenseStatus {
            if activate != nil && email == nil {
                throw ValidationError("--email is required with --activate")
            }
            return
        }

        guard input != nil else {
            throw ValidationError("Missing expected argument '<input>'")
        }

        if let q = quality {
            guard q >= 1 && q <= 100 else {
                throw ValidationError("Quality must be between 1 and 100 (got \(q))")
            }
        }
        if let f = format {
            guard OutputFormat(rawValue: f) != nil else {
                throw ValidationError("Unsupported format '\(f)'. Use: png, jpeg, webp, avif, heic")
            }
        }
        if let r = resize {
            guard ResizeSpec.parse(r) != nil else {
                throw ValidationError("Invalid resize format '\(r)'. Use: WxH (e.g. 800x600)")
            }
        }
    }

    func run() throws {
        // Handle license activation
        if let key = activate, let mail = email {
            let info = try LicenseManager.shared.activate(key: key, email: mail)
            print("✅ License activated successfully!")
            print("   Tier: \(info.tier.rawValue)")
            print("   Email: \(info.email)")
            return
        }

        // Handle license status
        if licenseStatus {
            switch LicenseManager.shared.checkAccess() {
            case .licensed(let info):
                print("✅ Licensed (\(info.tier.rawValue))")
                print("   Email: \(info.email)")
                print("   Key: \(info.key)")
            case .trial(let trial):
                print("⏳ Trial active — \(trial.daysRemaining) days remaining")
            case .expired:
                print(LicenseManager.shared.trialExpirationMessage())
            case .none:
                print("❌ No license or trial found")
                print("   Start trial: run any optipix command")
                print("   Buy: https://optipix.dev/pricing | htmeta.gumroad.com | etsy.com/shop/htmeta")
            }
            return
        }

        guard let inputPath = input else {
            throw ValidationError("Missing expected argument '<input>'")
        }

        // Check license/trial before processing
        let access = LicenseManager.shared.checkAccess()
        switch access {
        case .licensed:
            break
        case .trial(let trial):
            if !json {
                FileHandle.standardError.write(
                    Data("⏳ Trial: \(trial.daysRemaining) days remaining\n".utf8))
            }
        case .expired:
            throw OptiPixError.licenseInvalid(
                message: LicenseManager.shared.trialExpirationMessage())
        case .none:
            let trial = LicenseManager.shared.startTrial()
            if !json {
                FileHandle.standardError.write(
                    Data("🎉 14-day trial started! \(trial.daysRemaining) days remaining\n".utf8))
            }
        }

        // Build options — merge with .optipixrc if present
        let config = ProjectConfig.load()
        let options: ProcessingOptions
        if let config = config {
            options = config.mergeWith(
                inputPath: inputPath,
                outputFormat: format.flatMap { OutputFormat(rawValue: $0) },
                quality: quality,
                resize: resize.flatMap { ResizeSpec.parse($0) },
                outputPath: output,
                recursive: recursive,
                jsonOutput: json,
                dryRun: dryRun,
                verbose: verbose,
                smartQuality: smartQuality,
                keepMetadata: keepMetadata
            )
        } else {
            options = ProcessingOptions(
                inputPath: inputPath,
                outputFormat: format.flatMap { OutputFormat(rawValue: $0) },
                quality: quality,
                resize: resize.flatMap { ResizeSpec.parse($0) },
                outputPath: output,
                recursive: recursive,
                jsonOutput: json,
                dryRun: dryRun,
                verbose: verbose,
                smartQuality: smartQuality,
                keepMetadata: keepMetadata
            )
        }

        // Watch mode
        if watch {
            let watcher = FileWatcher(path: inputPath, options: options)
            try watcher.start()
            return
        }

        do {
            try ImageProcessor.run(with: options)
        } catch let error as OptiPixError {
            if json {
                printErrorJSON(error)
            } else {
                printError(error)
            }
            throw ExitCode(rawValue: error.exitCode)
        }
    }

    private func printError(_ error: OptiPixError) {
        FileHandle.standardError.write(Data("error: \(error.message)\n".utf8))
    }

    private func printErrorJSON(_ error: OptiPixError) {
        OutputFormatter.printJSONError(message: error.message, exitCode: error.exitCode)
    }
}
