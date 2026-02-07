# Contributing to optipix

Thank you for your interest in optipix!

## Bug Reports

Please use the [bug report template](https://github.com/htmeta/optipix/issues/new?template=bug_report.yml) and include:
- optipix version (`optipix --version`)
- macOS version
- Hardware (Apple Silicon or Intel)
- Verbose output (`optipix ... --verbose`)

## Feature Requests

Use the [feature request template](https://github.com/htmeta/optipix/issues/new?template=feature_request.yml).

## Development

### Setup

```bash
git clone https://github.com/htmeta/optipix.git
cd optipix
swift build
swift test
```

### Project Structure

```
Sources/
  optipix/           CLI entry point (ArgumentParser)
  OptiPixCore/
    Config/           .optipixrc config file
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
- Error handling via `OptiPixError` enum

### Testing

```bash
swift test
```

Tests create images programmatically — no fixture files needed.

## License

optipix is commercial software. Contributing code means you agree
to assign copyright to HTMETA.dev for inclusion in the product.
