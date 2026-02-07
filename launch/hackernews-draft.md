# Show HN: pxlsmash — Metal GPU-accelerated image optimizer for macOS (20× faster)

I built pxlsmash because I got tired of waiting for ImageMagick to process
hundreds of product images. On my M2 MacBook Air, it was taking 30+ seconds
for a batch of 100 PNGs. I thought: "my GPU is sitting idle, why not use it?"

pxlsmash uses Apple Metal compute shaders for image processing — resize,
format conversion, and quality optimization all happen on the GPU. The
result: ~2 seconds for the same 100 images. That's roughly 20× faster.

**What it does:**
- Optimizes PNG, JPEG, WebP images with Metal GPU acceleration
- Batch processing with progress bar
- Format conversion (e.g. PNG → WebP in one command)
- GPU-accelerated resize via Metal compute shaders
- JSON output for CI/CD integration
- Automatic CPU fallback on Intel Macs (via Accelerate/vImage)

**Quick start:**
```
brew install htmeta/tap/pxlsmash
pxlsmash ./images/ --quality 85 --format webp --recursive
```

**How it works:**
1. Images are loaded via ImageIO (Apple's native framework)
2. Pixel data → MTLTexture on GPU
3. Metal compute kernel processes (resize, color convert)
4. Encoded back to target format
5. Written to disk

The whole pipeline stays on the GPU until the final write.

**Pricing:** 14-day free trial, then $29 one-time for personal use.
The CLI is the core product; I'm working on a Cloud API for teams.

Source + binary: https://github.com/htmeta/pxlsmash
Website: https://pxlsmash.dev

Happy to answer questions about Metal compute shaders, Swift performance,
or the architecture decisions.
