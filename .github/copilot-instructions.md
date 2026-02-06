# Copilot Instructions – imgcrush

## Projekt

**imgcrush** je Metal-akcelerovaný image optimizer pro macOS napsaný ve Swiftu. CLI nástroj využívá Apple Metal GPU pro 10–50× rychlejší zpracování obrázků oproti ImageMagick. Cílí na vývojáře, designéry a CI/CD pipeline.

## Tech Stack

- **Jazyk:** Swift 5.9+
- **Build systém:** Swift Package Manager (SwiftPM)
- **Platforma:** macOS (Apple Silicon nativně, Intel s CPU fallback)
- **GPU:** Apple Metal framework pro compute kernely (resize, compression)
- **CLI framework:** swift-argument-parser
- **Formáty:** PNG, JPEG, WebP (AVIF plánován pro v1.1)
- **Image I/O:** CGImage, ImageIO framework, vImage
- **Výstup:** human-readable (default) + JSON (--json flag) pro CI/CD

## Architektura

```
Sources/
├── imgcrush/          # CLI entry point, argument parsing
├── ImgCrushCore/      # Core business logic
│   ├── Pipeline/      # Optimization pipeline orchestrace
│   ├── Metal/         # Metal compute kernely a GPU engine
│   ├── Formats/       # PNG, JPEG, WebP encodéry/dekodéry
│   ├── Processing/    # Resize, quality optimization, batch processing
│   └── Output/        # JSON formatter, progress bar, reporting
└── ImgCrushTests/     # Testy
```

## Konvence

### Swift kód
- Používej Swift concurrency (async/await) pro I/O operace
- Metal kernely piš v MSL (Metal Shading Language) v `.metal` souborech
- Batch processing přes DispatchQueue / TaskGroup pro paralelní zpracování
- Všechny public API musí mít dokumentační komentáře (///)
- Error handling přes custom enum `ImgCrushError` (ne force unwrap)
- Exit kódy: 0 = success, 1 = general error, 2 = invalid input, 3 = permission error

### CLI interface
```bash
imgcrush <input>                     # Optimize single file or directory
imgcrush <input> --format webp       # Convert format
imgcrush <input> --quality 85        # Set quality (1-100)
imgcrush <input> --resize 800x600    # Resize
imgcrush <input> --json              # JSON output for CI/CD
imgcrush <input> --dry-run           # Preview without changes
imgcrush <input> --output <dir>      # Output directory
imgcrush <input> --recursive         # Process subdirectories
```

### Naming
- Typy: `PascalCase` (MetalEngine, ImagePipeline)
- Funkce/proměnné: `camelCase` (optimizeImage, compressionQuality)
- Konstanty: `camelCase` (maxBatchSize, defaultQuality)
- Metal kernely: `snake_case` (resize_bilinear, compress_jpeg)

### Testování
- Unit testy ve `Tests/` složce, pojmenované `*Tests.swift`
- Testuj s fixture obrázky v `Tests/Fixtures/`
- Performance testy pro Metal operace s `measure {}`
- `swift test` musí projít před každým commitem

### Git
- Commit messages v angličtině, imperativ ("Add WebP encoder", "Fix Metal buffer alignment")
- Feature branches: `feature/<name>`, bugfix: `fix/<name>`
- Žádné force push na `main`

## Business kontext

- Produkt je komerční CLI tool s licenčním modelem (Personal €29, Team €99, Enterprise €299)
- Plánovaný SaaS upsell: imgcrush Cloud (API + web dashboard)
- Landing page: imgcrush.dev
- Cílová audience: macOS vývojáři, designéři, CI/CD pipelines
- Klíčový selling point: rychlost díky Metal GPU vs CPU-based alternativy

## Důležité

- **Performance je priorita #1** — vždy preferuj Metal GPU cestu, CPU fallback jen pro Intel Macy
- **Necommituj** licence klíče, API keys, ani credentials
- **Binary size** — drž CLI binary pod 10 MB (universal)
- **Kompatibilita** — macOS 13+ (Ventura), podporuj arm64 i x86_64
- **Zero dependencies kde možné** — preferuj systémové frameworky (Metal, ImageIO, CoreGraphics) před externími knihovnami
