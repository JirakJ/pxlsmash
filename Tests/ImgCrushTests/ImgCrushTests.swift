import XCTest
@testable import ImgCrushCore

final class ImgCrushTests: XCTestCase {

    func testResizeSpecParse() {
        let spec = ResizeSpec.parse("800x600")
        XCTAssertNotNil(spec)
        XCTAssertEqual(spec?.width, 800)
        XCTAssertEqual(spec?.height, 600)
    }

    func testResizeSpecParseInvalid() {
        XCTAssertNil(ResizeSpec.parse("invalid"))
        XCTAssertNil(ResizeSpec.parse("0x100"))
        XCTAssertNil(ResizeSpec.parse("100x0"))
        XCTAssertNil(ResizeSpec.parse("100"))
        XCTAssertNil(ResizeSpec.parse(""))
    }

    func testOutputFormat() {
        XCTAssertEqual(OutputFormat(rawValue: "png"), .png)
        XCTAssertEqual(OutputFormat(rawValue: "jpeg"), .jpeg)
        XCTAssertEqual(OutputFormat(rawValue: "webp"), .webp)
        XCTAssertNil(OutputFormat(rawValue: "bmp"))
    }

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

    func testImgCrushErrorExitCodes() {
        let general = ImgCrushError.generalError("test")
        XCTAssertEqual(general.exitCode, 1)
        XCTAssertEqual(general.message, "test")

        let invalid = ImgCrushError.invalidInput("bad")
        XCTAssertEqual(invalid.exitCode, 2)

        let perm = ImgCrushError.permissionDenied("denied")
        XCTAssertEqual(perm.exitCode, 3)
    }
}
