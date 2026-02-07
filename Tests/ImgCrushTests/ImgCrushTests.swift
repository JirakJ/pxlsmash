import XCTest
@testable import ImgCrushCore

final class ImgCrushTests: XCTestCase {

    // MARK: - ResizeSpec

    func testResizeSpecParse() {
        let spec = ResizeSpec.parse("800x600")
        XCTAssertNotNil(spec)
        XCTAssertEqual(spec?.width, 800)
        XCTAssertEqual(spec?.height, 600)
    }

    func testResizeSpecParseCaseInsensitive() {
        let spec = ResizeSpec.parse("1920X1080")
        XCTAssertNotNil(spec)
        XCTAssertEqual(spec?.width, 1920)
        XCTAssertEqual(spec?.height, 1080)
    }

    func testResizeSpecParseInvalid() {
        XCTAssertNil(ResizeSpec.parse("invalid"))
        XCTAssertNil(ResizeSpec.parse("0x100"))
        XCTAssertNil(ResizeSpec.parse("100x0"))
        XCTAssertNil(ResizeSpec.parse("100"))
        XCTAssertNil(ResizeSpec.parse(""))
        XCTAssertNil(ResizeSpec.parse("axb"))
        XCTAssertNil(ResizeSpec.parse("-100x200"))
    }

    // MARK: - OutputFormat

    func testOutputFormat() {
        XCTAssertEqual(OutputFormat(rawValue: "png"), .png)
        XCTAssertEqual(OutputFormat(rawValue: "jpeg"), .jpeg)
        XCTAssertEqual(OutputFormat(rawValue: "webp"), .webp)
        XCTAssertNil(OutputFormat(rawValue: "bmp"))
        XCTAssertNil(OutputFormat(rawValue: ""))
    }

    // MARK: - ProcessingOptions

    func testProcessingOptionsDefaults() {
        let opts = ProcessingOptions(inputPath: "/tmp/test.png")
        XCTAssertEqual(opts.inputPath, "/tmp/test.png")
        XCTAssertNil(opts.outputFormat)
        XCTAssertNil(opts.quality)
        XCTAssertNil(opts.resize)
        XCTAssertNil(opts.outputPath)
        XCTAssertFalse(opts.recursive)
        XCTAssertFalse(opts.jsonOutput)
        XCTAssertFalse(opts.dryRun)
        XCTAssertFalse(opts.verbose)
    }

    func testProcessingOptionsCustom() {
        let opts = ProcessingOptions(
            inputPath: "/tmp/dir",
            outputFormat: .webp,
            quality: 85,
            resize: ResizeSpec(width: 800, height: 600),
            outputPath: "/tmp/out",
            recursive: true,
            jsonOutput: true,
            dryRun: false,
            verbose: true
        )
        XCTAssertEqual(opts.outputFormat, .webp)
        XCTAssertEqual(opts.quality, 85)
        XCTAssertEqual(opts.resize?.width, 800)
        XCTAssertTrue(opts.recursive)
        XCTAssertTrue(opts.jsonOutput)
    }

    // MARK: - ImgCrushError

    func testImgCrushErrorExitCodes() {
        let general = ImgCrushError.generalError("test")
        XCTAssertEqual(general.exitCode, 1)
        XCTAssertEqual(general.message, "test")

        let invalid = ImgCrushError.invalidInput("bad")
        XCTAssertEqual(invalid.exitCode, 2)

        let perm = ImgCrushError.permissionDenied("denied")
        XCTAssertEqual(perm.exitCode, 3)

        let disk = ImgCrushError.diskFull("full")
        XCTAssertEqual(disk.exitCode, 1)
        XCTAssertEqual(disk.message, "full")
    }

    func testImgCrushErrorDescription() {
        let err = ImgCrushError.invalidInput("test message")
        XCTAssertEqual(String(describing: err), "test message")
    }

    // MARK: - Format detection

    func testFormatDetectionPNG() throws {
        let dir = NSTemporaryDirectory() + "imgcrush_test_\(UUID().uuidString)/"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }

        let path = dir + "test.png"
        try TestImageFactory.createPNG(at: path)

        let format = try ImageFormatDetector.detect(at: path)
        XCTAssertEqual(format, .png)
    }

    func testFormatDetectionJPEG() throws {
        let dir = NSTemporaryDirectory() + "imgcrush_test_\(UUID().uuidString)/"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }

        let path = dir + "test.jpg"
        try TestImageFactory.createJPEG(at: path)

        let format = try ImageFormatDetector.detect(at: path)
        XCTAssertEqual(format, .jpeg)
    }

    func testFormatDetectionMissing() {
        XCTAssertThrowsError(try ImageFormatDetector.detect(at: "/nonexistent/file.png")) { error in
            XCTAssertTrue(error is ImgCrushError)
        }
    }

    // MARK: - Image loading

    func testImageLoading() throws {
        let dir = NSTemporaryDirectory() + "imgcrush_test_\(UUID().uuidString)/"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }

        let path = dir + "test.png"
        try TestImageFactory.createPNG(at: path, width: 200, height: 150)

        let image = try ImageLoader.load(at: path)
        XCTAssertEqual(image.width, 200)
        XCTAssertEqual(image.height, 150)
    }

    func testImageLoadingInvalid() {
        XCTAssertThrowsError(try ImageLoader.load(at: "/nonexistent.png"))
    }

    // MARK: - File collection

    func testCollectFilesFlat() throws {
        let dir = NSTemporaryDirectory() + "imgcrush_test_\(UUID().uuidString)/"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }

        try TestImageFactory.createPNG(at: dir + "a.png")
        try TestImageFactory.createJPEG(at: dir + "b.jpg")
        try "not an image".write(toFile: dir + "c.txt", atomically: true, encoding: .utf8)

        let files = try ImageProcessor.collectFiles(in: dir, recursive: false)
        XCTAssertEqual(files.count, 2)
        XCTAssertTrue(files[0].hasSuffix("a.png"))
        XCTAssertTrue(files[1].hasSuffix("b.jpg"))
    }

    func testCollectFilesRecursive() throws {
        let dir = NSTemporaryDirectory() + "imgcrush_test_\(UUID().uuidString)/"
        let subdir = dir + "sub/"
        try FileManager.default.createDirectory(atPath: subdir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }

        try TestImageFactory.createPNG(at: dir + "a.png")
        try TestImageFactory.createPNG(at: subdir + "b.png")

        let flat = try ImageProcessor.collectFiles(in: dir, recursive: false)
        XCTAssertEqual(flat.count, 1)

        let recursive = try ImageProcessor.collectFiles(in: dir, recursive: true)
        XCTAssertEqual(recursive.count, 2)
    }

    // MARK: - Pipeline

    func testPipelineSingleFile() throws {
        let dir = NSTemporaryDirectory() + "imgcrush_test_\(UUID().uuidString)/"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }

        let inputPath = dir + "input.png"
        try TestImageFactory.createPNG(at: inputPath, width: 200, height: 200)

        let outDir = dir + "out/"
        let opts = ProcessingOptions(inputPath: inputPath, outputPath: outDir)
        let pipeline = OptimizationPipeline(options: opts)
        let result = try pipeline.process(filePath: inputPath)

        XCTAssertFalse(result.dryRun)
        XCTAssertTrue(result.originalSize > 0)
        XCTAssertTrue(result.optimizedSize > 0)
        XCTAssertEqual(result.format, "png")
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.outputFile))
    }

    func testPipelineDryRun() throws {
        let dir = NSTemporaryDirectory() + "imgcrush_test_\(UUID().uuidString)/"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }

        let inputPath = dir + "input.png"
        try TestImageFactory.createPNG(at: inputPath)

        let opts = ProcessingOptions(inputPath: inputPath, dryRun: true)
        let pipeline = OptimizationPipeline(options: opts)
        let result = try pipeline.process(filePath: inputPath)

        XCTAssertTrue(result.dryRun)
        XCTAssertEqual(result.originalSize, result.optimizedSize)
    }

    func testPipelineFormatConversion() throws {
        let dir = NSTemporaryDirectory() + "imgcrush_test_\(UUID().uuidString)/"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }

        let inputPath = dir + "input.png"
        try TestImageFactory.createPNG(at: inputPath, width: 100, height: 100)

        let outDir = dir + "out/"
        let opts = ProcessingOptions(inputPath: inputPath, outputFormat: .jpeg, quality: 80, outputPath: outDir)
        let pipeline = OptimizationPipeline(options: opts)
        let result = try pipeline.process(filePath: inputPath)

        XCTAssertEqual(result.format, "jpeg")
        XCTAssertTrue(result.outputFile.hasSuffix(".jpg"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.outputFile))
    }

    // MARK: - Output formatter

    func testFormatBytes() {
        XCTAssertEqual(OutputFormatter.formatBytes(0), "0B")
        XCTAssertEqual(OutputFormatter.formatBytes(512), "512B")
        XCTAssertEqual(OutputFormatter.formatBytes(1024), "1.0KB")
        XCTAssertEqual(OutputFormatter.formatBytes(1536), "1.5KB")
        XCTAssertEqual(OutputFormatter.formatBytes(1048576), "1.0MB")
        XCTAssertEqual(OutputFormatter.formatBytes(1572864), "1.5MB")
    }

    // MARK: - Metal engine

    func testMetalAvailability() {
        // On Apple Silicon this should be true; on CI it may not be
        if MetalEngine.isAvailable {
            let engine = MetalEngine.shared!
            XCTAssertFalse(engine.deviceName.isEmpty)
            XCTAssertTrue(engine.maxMemory > 0)
        }
    }

    // MARK: - SmartQuality SSIM

    func testSSIMIdentical() throws {
        let image = try TestImageFactory.createCGImage(width: 64, height: 64, r: 200, g: 100, b: 50)
        let ssim = SmartQuality.computeSSIM(original: image, compressed: image)
        XCTAssertEqual(ssim, 1.0, accuracy: 0.001)
    }

    func testSSIMDifferent() throws {
        let image1 = try TestImageFactory.createCGImage(width: 64, height: 64, r: 255, g: 0, b: 0)
        let image2 = try TestImageFactory.createCGImage(width: 64, height: 64, r: 0, g: 255, b: 0)
        let ssim = SmartQuality.computeSSIM(original: image1, compressed: image2)
        XCTAssertLessThan(ssim, 1.0)
    }

    func testSmartQualityPNG() throws {
        let image = try TestImageFactory.createCGImage(width: 64, height: 64, r: 128, g: 128, b: 128)
        let quality = SmartQuality.findOptimalQuality(for: image, format: .png)
        // PNG is lossless, should return 100
        XCTAssertEqual(quality, 100)
    }

    func testSmartQualityJPEG() throws {
        let image = try TestImageFactory.createCGImage(width: 64, height: 64, r: 128, g: 128, b: 128)
        let quality = SmartQuality.findOptimalQuality(for: image, format: .jpeg)
        XCTAssertTrue(quality >= 30 && quality <= 95)
    }

    // MARK: - MetadataHandler

    func testMetadataExtract() throws {
        let dir = NSTemporaryDirectory() + "imgcrush_test_\(UUID().uuidString)/"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }

        let path = dir + "test.jpg"
        try TestImageFactory.createJPEG(at: path)

        // Should succeed without crash regardless of EXIF presence
        let metadata = MetadataHandler.extractMetadata(from: path)
        XCTAssertNotNil(metadata)
    }

    func testMetadataCopy() throws {
        let dir = NSTemporaryDirectory() + "imgcrush_test_\(UUID().uuidString)/"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }

        let srcPath = dir + "src.jpg"
        let dstPath = dir + "dst.jpg"
        try TestImageFactory.createJPEG(at: srcPath)
        try TestImageFactory.createJPEG(at: dstPath)

        // Should not throw
        try MetadataHandler.copyMetadata(from: srcPath, to: dstPath)
        XCTAssertTrue(FileManager.default.fileExists(atPath: dstPath))
    }

    // MARK: - ProcessingOptions new fields

    func testProcessingOptionsSmartQuality() {
        let opts = ProcessingOptions(inputPath: "/tmp/test.png", smartQuality: true, keepMetadata: true)
        XCTAssertTrue(opts.smartQuality)
        XCTAssertTrue(opts.keepMetadata)
    }

    func testProcessingOptionsSmartQualityDefaults() {
        let opts = ProcessingOptions(inputPath: "/tmp/test.png")
        XCTAssertFalse(opts.smartQuality)
        XCTAssertFalse(opts.keepMetadata)
    }

    // MARK: - OutputFormat AVIF/HEIC

    func testOutputFormatAVIF() {
        XCTAssertEqual(OutputFormat(rawValue: "avif"), .avif)
        XCTAssertEqual(OutputFormat(rawValue: "heic"), .heic)
    }

    // MARK: - E2E Pipeline with smart quality

    func testPipelineSmartQuality() throws {
        let dir = NSTemporaryDirectory() + "imgcrush_test_\(UUID().uuidString)/"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }

        let inputPath = dir + "input.jpg"
        try TestImageFactory.createJPEG(at: inputPath, width: 100, height: 100)

        let outDir = dir + "out/"
        let opts = ProcessingOptions(inputPath: inputPath, outputFormat: .jpeg, outputPath: outDir, smartQuality: true)
        let pipeline = OptimizationPipeline(options: opts)
        let result = try pipeline.process(filePath: inputPath)

        XCTAssertFalse(result.dryRun)
        XCTAssertTrue(result.optimizedSize > 0)
        XCTAssertEqual(result.format, "jpeg")
    }

    func testPipelineKeepMetadata() throws {
        let dir = NSTemporaryDirectory() + "imgcrush_test_\(UUID().uuidString)/"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }

        let inputPath = dir + "input.jpg"
        try TestImageFactory.createJPEG(at: inputPath, width: 100, height: 100)

        let outDir = dir + "out/"
        let opts = ProcessingOptions(inputPath: inputPath, outputFormat: .jpeg, quality: 80, outputPath: outDir, keepMetadata: true)
        let pipeline = OptimizationPipeline(options: opts)
        let result = try pipeline.process(filePath: inputPath)

        XCTAssertFalse(result.dryRun)
        XCTAssertTrue(FileManager.default.fileExists(atPath: result.outputFile))
    }

    // MARK: - OutputPath resolution

    func testResolveOutputPathFormats() {
        let path = OptimizationPipeline.resolveOutputPath(input: "/dir/photo.png", outputDir: "/out", format: .webp)
        XCTAssertEqual(path, "/out/photo.webp")

        let jpegPath = OptimizationPipeline.resolveOutputPath(input: "/dir/photo.png", outputDir: nil, format: .jpeg)
        XCTAssertEqual(jpegPath, "/dir/photo.jpg")

        let avifPath = OptimizationPipeline.resolveOutputPath(input: "/dir/photo.png", outputDir: "/out", format: .avif)
        XCTAssertEqual(avifPath, "/out/photo.avif")

        let heicPath = OptimizationPipeline.resolveOutputPath(input: "/dir/photo.png", outputDir: "/out", format: .heic)
        XCTAssertEqual(heicPath, "/out/photo.heic")
    }

    // MARK: - JSON output format

    func testJSONOutputFormatter() {
        // Test that OutputFormatter.formatBytes returns consistent results
        XCTAssertEqual(OutputFormatter.formatBytes(10485760), "10.0MB")
        // formatBytes uses MB as the largest unit
        XCTAssertEqual(OutputFormatter.formatBytes(1073741824), "1024.0MB")
    }

    // MARK: - Performance tests

    func testPerformancePipelinePNG() throws {
        let dir = NSTemporaryDirectory() + "imgcrush_perf_\(UUID().uuidString)/"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }

        let inputPath = dir + "perf.png"
        try TestImageFactory.createPNG(at: inputPath, width: 512, height: 512)

        let outDir = dir + "out/"
        let opts = ProcessingOptions(inputPath: inputPath, outputPath: outDir)
        let pipeline = OptimizationPipeline(options: opts)

        measure {
            _ = try? pipeline.process(filePath: inputPath)
        }
    }

    func testPerformancePipelineJPEG() throws {
        let dir = NSTemporaryDirectory() + "imgcrush_perf_\(UUID().uuidString)/"
        try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(atPath: dir) }

        let inputPath = dir + "perf.jpg"
        try TestImageFactory.createJPEG(at: inputPath, width: 512, height: 512)

        let outDir = dir + "out/"
        let opts = ProcessingOptions(inputPath: inputPath, outputFormat: .jpeg, quality: 85, outputPath: outDir)
        let pipeline = OptimizationPipeline(options: opts)

        measure {
            _ = try? pipeline.process(filePath: inputPath)
        }
    }

    func testPerformanceSSIM() throws {
        let image = try TestImageFactory.createCGImage(width: 256, height: 256, r: 128, g: 64, b: 200)

        measure {
            _ = SmartQuality.computeSSIM(original: image, compressed: image)
        }
    }
}
