import Foundation
import Metal
import CoreGraphics

/// Metal GPU engine for hardware-accelerated image processing.
public final class MetalEngine: @unchecked Sendable {

    /// Shared singleton instance (nil if Metal is unavailable).
    public static let shared: MetalEngine? = {
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        return try? MetalEngine(device: device)
    }()

    /// Whether Metal GPU acceleration is available.
    public static var isAvailable: Bool { shared != nil }

    public let device: MTLDevice
    public let commandQueue: MTLCommandQueue
    private let resizePipeline: MTLComputePipelineState

    private init(device: MTLDevice) throws {
        self.device = device

        guard let queue = device.makeCommandQueue() else {
            throw OptiPixError.generalError("Failed to create Metal command queue")
        }
        self.commandQueue = queue

        // Load shader library from bundle or default
        let library: MTLLibrary
        if let bundlePath = Bundle.module.path(forResource: "Resize", ofType: "metal"),
           let source = try? String(contentsOfFile: bundlePath) {
            library = try device.makeLibrary(source: source, options: nil)
        } else if let defaultLib = try? device.makeDefaultLibrary(bundle: Bundle.module) {
            library = defaultLib
        } else {
            // Compile from embedded source as last resort
            library = try device.makeLibrary(source: MetalEngine.resizeShaderSource, options: nil)
        }

        guard let resizeFunc = library.makeFunction(name: "resize_bilinear") else {
            throw OptiPixError.generalError("Metal shader function 'resize_bilinear' not found")
        }
        self.resizePipeline = try device.makeComputePipelineState(function: resizeFunc)
    }

    /// GPU device name.
    public var deviceName: String { device.name }

    /// Recommended maximum memory (bytes).
    public var maxMemory: UInt64 { device.recommendedMaxWorkingSetSize }

    // MARK: - Resize

    /// Resize an image using Metal GPU.
    public func resize(_ image: CGImage, to size: ResizeSpec) throws -> CGImage {
        let srcTexture = try makeTexture(from: image)
        let dstTexture = try makeEmptyTexture(width: size.width, height: size.height)

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            throw OptiPixError.generalError("Failed to create Metal command buffer")
        }

        encoder.setComputePipelineState(resizePipeline)
        encoder.setTexture(srcTexture, index: 0)
        encoder.setTexture(dstTexture, index: 1)

        let threadgroupSize = MTLSize(
            width: min(16, resizePipeline.threadExecutionWidth),
            height: min(16, resizePipeline.maxTotalThreadsPerThreadgroup / min(16, resizePipeline.threadExecutionWidth)),
            depth: 1
        )
        let threadgroups = MTLSize(
            width: (size.width + threadgroupSize.width - 1) / threadgroupSize.width,
            height: (size.height + threadgroupSize.height - 1) / threadgroupSize.height,
            depth: 1
        )

        encoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadgroupSize)
        encoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        if let error = commandBuffer.error {
            throw OptiPixError.generalError("Metal processing failed: \(error.localizedDescription)")
        }

        return try extractCGImage(from: dstTexture)
    }

    // MARK: - Texture helpers

    private func makeTexture(from image: CGImage) throws -> MTLTexture {
        let width = image.width
        let height = image.height

        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead]

        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw OptiPixError.generalError("Failed to create Metal texture (\(width)x\(height))")
        }

        // Convert CGImage to RGBA8 pixel data
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw OptiPixError.generalError("Failed to create bitmap context")
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        texture.replace(
            region: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0,
            withBytes: pixelData,
            bytesPerRow: bytesPerRow
        )

        return texture
    }

    private func makeEmptyTexture(width: Int, height: Int) throws -> MTLTexture {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: width,
            height: height,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .shaderWrite]

        guard let texture = device.makeTexture(descriptor: descriptor) else {
            throw OptiPixError.generalError("Failed to create output texture (\(width)x\(height))")
        }
        return texture
    }

    private func extractCGImage(from texture: MTLTexture) throws -> CGImage {
        let width = texture.width
        let height = texture.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        texture.getBytes(
            &pixelData,
            bytesPerRow: bytesPerRow,
            from: MTLRegionMake2D(0, 0, width, height),
            mipmapLevel: 0
        )

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw OptiPixError.generalError("Failed to create output bitmap context")
        }

        guard let cgImage = context.makeImage() else {
            throw OptiPixError.generalError("Failed to extract CGImage from Metal texture")
        }

        return cgImage
    }

    // MARK: - Embedded shader source (fallback)

    private static let resizeShaderSource = """
    #include <metal_stdlib>
    using namespace metal;

    kernel void resize_bilinear(
        texture2d<float, access::read> input [[texture(0)]],
        texture2d<float, access::write> output [[texture(1)]],
        uint2 gid [[thread_position_in_grid]]
    ) {
        if (gid.x >= output.get_width() || gid.y >= output.get_height()) {
            return;
        }
        float2 inputSize = float2(input.get_width(), input.get_height());
        float2 outputSize = float2(output.get_width(), output.get_height());
        float2 scale = inputSize / outputSize;
        float2 coord = float2(gid) * scale;
        uint2 c00 = uint2(floor(coord));
        uint2 c11 = min(c00 + 1, uint2(inputSize - 1));
        uint2 c01 = uint2(c00.x, c11.y);
        uint2 c10 = uint2(c11.x, c00.y);
        float2 frac = coord - float2(c00);
        float4 p00 = input.read(c00);
        float4 p10 = input.read(c10);
        float4 p01 = input.read(c01);
        float4 p11 = input.read(c11);
        float4 top = mix(p00, p10, frac.x);
        float4 bottom = mix(p01, p11, frac.x);
        float4 result = mix(top, bottom, frac.y);
        output.write(result, gid);
    }
    """
}
