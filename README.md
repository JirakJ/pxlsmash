# pxlsmash

**Metal-accelerated image optimizer for macOS.** 20× faster than ImageMagick.

[![CI](https://github.com/htmeta/pxlsmash/actions/workflows/ci.yml/badge.svg)](https://github.com/htmeta/pxlsmash/actions/workflows/ci.yml)

## Features

- ⚡ **Apple Metal GPU acceleration** — 10–50× speedup over CPU-only tools
- 📁 **Batch processing** with progress bar and recursive directory scan
- 🎯 **Smart quality optimization** — best compression at target quality
- 🔧 **CI/CD ready** — JSON output, proper exit codes, silent mode
- 🔄 **Format conversion** — PNG, JPEG, WebP with full control
- 📐 **GPU-accelerated resize** — bilinear interpolation via Metal compute shaders
- 🖥️ **CPU fallback** — vImage/Accelerate on Intel Macs or headless servers
- 🔑 **14-day free trial** — no credit card required

## Requirements

- macOS 13+ (Ventura or later)
- Apple Silicon recommended (Intel supported with CPU fallback)

## Installation

### Homebrew (recommended)

```bash
brew install htmeta/tap/pxlsmash
```

### Direct download

Download the latest universal binary from [GitHub Releases](https://github.com/htmeta/pxlsmash/releases) or [pxlsmash.dev](https://pxlsmash.dev).

```bash
curl -L https://github.com/htmeta/pxlsmash/releases/latest/download/pxlsmash-macos-universal.tar.gz | tar xz
sudo mv pxlsmash /usr/local/bin/
```

### Build from source

```bash
git clone https://github.com/htmeta/pxlsmash.git
cd pxlsmash
make install
```

## Quick Start

```bash
# Optimize a single image (in-place)
pxlsmash photo.png

# Convert PNG to WebP
pxlsmash photo.png --format webp

# Batch optimize entire directory
pxlsmash ./images/ --quality 85

# Recursive with resize
pxlsmash ./assets/ --recursive --resize 1200x800

# Preview changes without modifying files
pxlsmash ./images/ --dry-run

# CI/CD mode (JSON output, proper exit codes)
pxlsmash ./images/ --json
```

## CLI Reference

```
USAGE: pxlsmash <input> [options]

ARGUMENTS:
  <input>                 File or directory to optimize

OPTIONS:
  --format <format>       Output format: png, jpeg, webp
  --quality <1-100>       Compression quality (default: auto)
  --resize <WxH>          Resize to dimensions (e.g. 800x600)
  --output <dir>          Output directory (default: in-place)
  --recursive             Process subdirectories
  --json                  Output results as JSON
  --dry-run               Preview changes without writing
  --verbose               Show detailed processing info
  --activate <key>        Activate license key
  --email <email>         Email for license activation
  --license-status        Show current license status
  --version               Show version
  --help                  Show help
```

## Examples

### Batch optimize for web

```bash
pxlsmash ./public/images/ --quality 80 --format webp --recursive
```

### CI/CD integration (GitHub Actions)

```yaml
- name: Optimize images
  run: |
    brew install htmeta/tap/pxlsmash
    pxlsmash ./src/assets/ --quality 85 --json --recursive
```

### Process and resize thumbnails

```bash
pxlsmash ./uploads/ --resize 400x300 --format jpeg --quality 75 --output ./thumbs/
```

### Dry run with verbose output

```bash
pxlsmash ./images/ --dry-run --verbose
# Shows: Metal device, file sizes, estimated savings
```

## Performance

pxlsmash uses Apple Metal compute shaders for image processing, achieving
significant speedups over CPU-only tools:

| Tool | 100 PNGs (avg) | Speedup |
|------|---------------|---------|
| **pxlsmash (Metal)** | ~2.1s | **1×** |
| ImageMagick | ~38s | 18× slower |
| sharp (Node.js) | ~12s | 6× slower |
| PIL/Pillow | ~45s | 21× slower |

*Benchmarked on M2 MacBook Air, 100 × 2048×1536 PNG images.*

## Licensing

pxlsmash includes a **14-day free trial** with full functionality.

```bash
# Check license status
pxlsmash --license-status

# Activate a purchased license
pxlsmash --activate PXLS-XXXX-XXXX-XXXX-XXXX --email you@example.com
```

### Pricing

| Plan | Price | Includes |
|------|-------|----------|
| **Personal** | $29 one-time | 1 user, lifetime updates |
| **Team** | $99 one-time | 5 users, priority support |
| **Enterprise** | $249 one-time | Unlimited users, SLA |

Purchase at [pxlsmash.dev](https://pxlsmash.dev/#pricing), [Gumroad](https://htmeta.gumroad.com), or [Etsy](https://www.etsy.com/shop/htmeta).

## Troubleshooting

### Metal not available (Intel Mac)

pxlsmash automatically falls back to CPU processing via Accelerate/vImage.
Use `--verbose` to see which backend is active.

### Permission denied

Ensure you have write access to the output directory:

```bash
pxlsmash ./images/ --output ~/Desktop/optimized/
```

### Large files / memory

For very large images (>100MP), processing is done tile-by-tile to avoid
memory pressure. Use `--verbose` to monitor memory usage.

## License

Commercial software. © 2025 [HTMETA.dev](https://htmeta.dev)

See [pxlsmash.dev](https://pxlsmash.dev) for pricing and terms.
