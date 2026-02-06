# How I Built a 25× Faster Image Optimizer with Apple Metal

*A deep dive into using Metal compute shaders for image processing in Swift.*

---

## The Problem

I was processing 500+ product images daily for an e-commerce client. ImageMagick took over 3 minutes. I knew my M2 MacBook had a powerful GPU sitting idle during this process.

What if I could use it?

## The Architecture

imgcrush is a Swift CLI that pushes image processing to the GPU via Apple Metal compute shaders:

```
Input Image → ImageIO → MTLTexture → Metal Compute → Encode → Output
```

### 1. Loading: ImageIO (Apple's Native Framework)

Instead of depending on libpng or libjpeg, imgcrush uses ImageIO — Apple's built-in image framework that supports every format macOS can read. This means zero external dependencies and automatic HEIC, TIFF, and RAW support for free.

### 2. GPU Transfer: CGImage → MTLTexture

The loaded image data gets pushed to a Metal texture on the GPU. The key insight: once data is on the GPU, all processing happens there without round-tripping to CPU memory.

### 3. Metal Compute Shaders

The resize operation uses a custom Metal compute shader with bilinear interpolation:

```metal
kernel void bilinearResize(
    texture2d<float, access::read> input [[texture(0)]],
    texture2d<float, access::write> output [[texture(1)]],
    uint2 gid [[thread_position_in_grid]])
{
    float2 scale = float2(input.get_width(), input.get_height())
                 / float2(output.get_width(), output.get_height());
    float2 coord = (float2(gid) + 0.5) * scale;

    // Bilinear interpolation
    float2 base = floor(coord - 0.5);
    float2 frac = coord - 0.5 - base;

    // Sample 4 neighbors and blend
    float4 tl = input.read(uint2(base));
    float4 tr = input.read(uint2(base) + uint2(1, 0));
    float4 bl = input.read(uint2(base) + uint2(0, 1));
    float4 br = input.read(uint2(base) + uint2(1, 1));

    float4 result = mix(mix(tl, tr, frac.x),
                        mix(bl, br, frac.x), frac.y);
    output.write(result, gid);
}
```

### 4. CPU Fallback

Not everyone has a Metal-capable GPU (Intel Macs in headless mode, CI servers). imgcrush detects this and falls back to Accelerate/vImage — Apple's SIMD-optimized CPU framework. Still faster than ImageMagick, just not as fast as Metal.

## Results

Benchmarked on M2 MacBook Air with 100 × 2048×1536 PNG images:

| Tool | Time | Relative |
|------|------|----------|
| **imgcrush (Metal)** | 2.1s | 1× |
| sharp (Node.js) | 12s | 5.7× |
| ImageMagick | 38s | 18× |
| PIL/Pillow | 45s | 21× |

## Lessons Learned

1. **Metal shader loading is tricky in CLI tools.** SPM bundles resources differently than Xcode projects. I ended up with a 3-tier fallback: bundle resource → default library → embedded shader source string.

2. **Swift Concurrency + Metal needs care.** MTLDevice and MTLCommandQueue are thread-safe in practice but aren't marked `Sendable`. Using `@unchecked Sendable` on the engine wrapper solved the compiler warnings.

3. **ImageIO is underrated.** Most Swift developers reach for third-party image libraries, but ImageIO handles PNG, JPEG, WebP, HEIC, TIFF, and more — with zero dependencies.

## Try It

```bash
brew install htmeta/tap/imgcrush
imgcrush ./images/ --quality 85 --format webp
```

14-day free trial, then $29 one-time.

- **Website:** [imgcrush.dev](https://imgcrush.dev)
- **GitHub:** [github.com/htmeta/imgcrush](https://github.com/htmeta/imgcrush)

---

*Jakub Jirák — [HTMETA.dev](https://htmeta.dev)*
