# imgcrush

Metal-accelerated image optimizer for macOS. 20× faster than ImageMagick.

## Features

- ⚡ Apple Metal GPU acceleration (10–50× speedup)
- 📁 Batch processing with progress bar
- 🎯 Smart quality optimization
- 🔧 CI/CD ready (JSON output, proper exit codes)
- 🔄 Format conversion (PNG, JPEG, WebP)
- 📐 GPU-accelerated resize

## Requirements

- macOS 13+ (Ventura)
- Apple Silicon recommended (Intel supported with CPU fallback)

## Installation

```bash
brew install imgcrush
```

Or download from [imgcrush.dev](https://imgcrush.dev).

## Usage

```bash
imgcrush ./images/                        # Batch optimize
imgcrush input.png --format webp          # Convert format
imgcrush ./images/ --quality 85           # Set quality
imgcrush ./images/ --json                 # CI/CD output
imgcrush hero.png --resize 800x600       # Resize
imgcrush ./images/ --dry-run              # Preview changes
```

## Building from source

```bash
swift build -c release
```

## License

Commercial software. See [imgcrush.dev](https://imgcrush.dev) for pricing.

© 2025 HTMETA.dev
