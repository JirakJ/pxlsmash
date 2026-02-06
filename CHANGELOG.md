# Changelog

All notable changes to imgcrush will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] — Unreleased

### Added

- Metal GPU-accelerated image processing (bilinear resize compute shader)
- CPU fallback via Accelerate/vImage for Intel Macs
- Format support: PNG, JPEG, WebP (read & write)
- Format conversion between all supported formats
- Batch processing with recursive directory scan
- Progress bar with per-file status
- Quality control (1–100) for lossy formats
- Resize with `--resize WxH` flag
- Dry-run mode (`--dry-run`) for previewing changes
- JSON output (`--json`) for CI/CD pipelines
- Verbose mode (`--verbose`) with Metal device info
- ANSI-colored terminal output
- License system with 14-day trial
- License activation via `--activate` / `--email`
- License status check via `--license-status`
- Homebrew formula for easy installation
- GitHub Actions CI/CD (build + test + release)
- Makefile with build/install/dist targets
- Universal binary support (arm64 + x86_64)

### Technical

- Swift 6 with SwiftPM
- macOS 13+ (Ventura) minimum deployment target
- swift-argument-parser for CLI interface
- Metal compute shaders for GPU processing
- CommonCrypto for license key validation
