import Foundation

/// Watch mode: monitors a directory for new/changed image files and processes them automatically.
public final class FileWatcher {
    private let path: String
    private let options: ProcessingOptions
    private let extensions = ["png", "jpg", "jpeg", "webp", "avif", "heic"]
    private var knownFiles: [String: Date] = [:]
    private var running = false

    public init(path: String, options: ProcessingOptions) {
        self.path = path
        self.options = options
    }

    /// Start watching. Blocks until interrupted.
    public func start() throws {
        let fm = FileManager.default
        var isDir: ObjCBool = false

        guard fm.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue else {
            throw ImgCrushError.invalidInput("Watch target must be a directory: \(path)")
        }

        running = true
        print("\(ANSI.cyan)👁️\(ANSI.reset) Watching \(path) for changes...")
        print("   Press Ctrl+C to stop\n")

        // Initial scan
        scanAndProcess()

        // Poll every 2 seconds
        while running {
            Thread.sleep(forTimeInterval: 2.0)
            scanAndProcess()
        }
    }

    public func stop() {
        running = false
    }

    private func scanAndProcess() {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: options.recursive ? [] : [.skipsSubdirectoryDescendants]
        ) else { return }

        for case let fileURL as URL in enumerator {
            let ext = fileURL.pathExtension.lowercased()
            guard extensions.contains(ext) else { continue }

            let filePath = fileURL.path

            guard let attrs = try? fm.attributesOfItem(atPath: filePath),
                  let modDate = attrs[.modificationDate] as? Date else { continue }

            if let known = knownFiles[filePath], known >= modDate {
                continue
            }

            knownFiles[filePath] = modDate

            do {
                let pipeline = OptimizationPipeline(options: options)
                let result = try pipeline.process(filePath: filePath)
                OutputFormatter.printFileResult(result)
            } catch {
                let name = (filePath as NSString).lastPathComponent
                print("  \(ANSI.red)✗\(ANSI.reset) \(name) — \(error.localizedDescription)")
            }
        }
    }
}
