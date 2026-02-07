# Contributing to pxlsmash

Thank you for your interest in pxlsmash!

## Bug Reports

Please use the [bug report template](https://github.com/htmeta/pxlsmash/issues/new?template=bug_report.yml) and include:
- pxlsmash version (`pxlsmash --version`)
- macOS version
- Hardware (Apple Silicon or Intel)
- Verbose output (`pxlsmash ... --verbose`)

## Feature Requests

Use the [feature request template](https://github.com/htmeta/pxlsmash/issues/new?template=feature_request.yml).

## Development

### Setup

```bash
git clone https://github.com/htmeta/pxlsmash.git
cd pxlsmash
swift build
swift test
```

### Project Structure

```
Sources/
  pxlsmash/           CLI entry point (ArgumentParser)
  PxlSmashCore/
    Config/           .pxlsmashrc config file
    Formats/          Image encoders (PNG, JPEG, WebP, AVIF, HEIC)
    License/          License key validation & trial
    Metal/            Metal GPU engine & compute shaders
    Output/           Terminal output formatting
    Pipeline/         Processing pipeline & batch orchestration
    Processing/       CPU fallback (vImage)
```

### Code Style

- Swift standard naming conventions
- Minimal comments (only where clarification needed)
- `public` access for anything used across targets
- Error handling via `PxlSmashError` enum

### Testing

```bash
swift test
```

Tests create images programmatically — no fixture files needed.

## License

pxlsmash is commercial software. Contributing code means you agree
to assign copyright to HTMETA.dev for inclusion in the product.
