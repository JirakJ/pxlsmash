# imgcrush — Implementační plán

**Produkt:** Metal-akcelerovaný image optimizer pro macOS  
**Autor:** Jakub Jirák | HTMETA.dev  
**Cíl:** CLI v1.0 → Cloud upsell → API → €10k+ MRR  

---

## Fáze 0: Projekt setup

- [x] Inicializace Swift Package (`Package.swift`)
- [x] Struktura adresářů (`Sources/imgcrush/`, `Sources/ImgCrushCore/`, `Tests/`)
- [x] Přidat `swift-argument-parser` dependency
- [x] `.gitignore` pro Swift / Xcode / .build
- [x] Základní `README.md`
- [x] CI: GitHub Actions workflow (`swift build` + `swift test` na macOS runner)

---

## Fáze 1: CLI skeleton + základní image loading

- [x] `@main` entry point s ArgumentParser
- [x] Definice CLI argumentů a flagů:
  - [ ] `<input>` — soubor nebo adresář (povinný)
  - [x] `--format` — výstupní formát (png, jpeg, webp)
  - [x] `--quality` — kvalita 1–100
  - [x] `--resize` — rozměry (WxH)
  - [x] `--output` — výstupní adresář
  - [x] `--recursive` — zpracovat podadresáře
  - [x] `--json` — JSON výstup pro CI/CD
  - [x] `--dry-run` — náhled bez změn
  - [x] `--verbose` — detailní výpis
  - [x] `--version` — verze
- [x] Načtení obrázku přes `CGImage` / `ImageIO`
- [x] Detekce formátu vstupního souboru (PNG/JPEG/WebP)
- [x] Základní validace vstupu (soubor existuje, je obrázek, permissions)
- [x] Custom `ImgCrushError` enum s exit kódy (0/1/2/3)
- [x] Uložení obrázku bez optimalizace (round-trip test)

---

## Fáze 2: Metal GPU engine

- [x] `MetalEngine` — inicializace `MTLDevice`, `MTLCommandQueue`
- [x] Detekce Metal dostupnosti (Apple Silicon vs Intel fallback)
- [x] Metal compute kernel: `resize_bilinear` (MSL, `.metal` soubor)
- [x] Metal compute kernel: `color_space_convert`
- [x] `MTLTexture` ↔ `CGImage` konverze utility
- [x] Pipeline state cache (nepřekompilovávat kernely opakovaně)
- [x] CPU fallback cesta přes `vImage` pro Intel Macy
- [x] Unit testy pro Metal engine (texture round-trip, resize accuracy)

---

## Fáze 3: Formátové encodéry a dekodéry

### PNG
- [x] PNG dekodér (ImageIO)
- [x] PNG encodér s optimalizací (compression level)
- [x] Strip nepotřebných metadata (EXIF, ICC profily volitelně)

### JPEG
- [x] JPEG dekodér (ImageIO)
- [x] JPEG encodér s quality parametrem
- [x] Progressive JPEG podpora
- [x] Chroma subsampling optimalizace

### WebP
- [x] WebP dekodér (ImageIO / CoreGraphics)
- [x] WebP encodér s quality parametrem
- [x] Lossy vs lossless detekce

### Konverze
- [x] PNG → JPEG konverze
- [x] PNG → WebP konverze
- [x] JPEG → WebP konverze
- [x] JPEG → PNG konverze
- [x] WebP → PNG konverze
- [x] WebP → JPEG konverze

---

## Fáze 4: Optimalizační pipeline

- [x] `ImagePipeline` orchestrátor (load → process → encode → save)
- [x] Smart quality — automatická detekce optimální kvality (SSIM-based)
- [x] Resize s zachováním aspect ratio (fit, fill, exact)
- [x] Skip already-optimized souborů (size comparison)
- [x] Metadata preservace (volitelné zachování EXIF)
- [x] Dry-run mode — report bez zápisu
- [x] Statistics: original size, optimized size, % reduction, processing time

---

## Fáze 5: Batch processing

- [x] Directory scanning (flat + recursive)
- [x] File filtering podle přípony (png, jpg, jpeg, webp)
- [x] Paralelní zpracování přes `DispatchQueue.concurrentPerform` s auto concurrency
- [x] Progress bar (počet zpracovaných / celkem, elapsed time, ETA)
- [x] Per-file výpis výsledků (název, original → optimized, % saved)
- [x] Souhrnná statistika na konci (celkem souborů, celkem ušetřeno, čas)
- [x] Přeskočení nesouborů a symlinků
- [x] Graceful handling chyb per-file (nepadne celý batch)

---

## Fáze 6: Výstup a reporting

### Human-readable výstup
- [x] Barevný terminálový výstup (ANSI colors)
- [x] Progress bar s procenty a ETA
- [x] Per-file řádek: `✓ image.png 2.1MB → 680KB (68% saved) 0.02s`
- [x] Souhrnný řádek: `✓ 100 files optimized, 127MB saved (68%), 1.8s`
- [x] Error řádky: `✗ broken.png — invalid image data`

### JSON výstup (`--json`)
- [x] Per-file objekt: `{ "file", "original_size", "optimized_size", "reduction_pct", "format", "time_ms" }`
- [x] Summary objekt: `{ "total_files", "total_original", "total_optimized", "total_reduction_pct", "total_time_ms" }`
- [x] Error objekt: `{ "file", "error" }`
- [x] Validní JSON i při chybách (partial results + errors array)

### Verbose mode
- [x] Metal device info (GPU name, memory)
- [x] Per-kernel timing
- [x] Memory usage reporting

---

## Fáze 7: Error handling a edge cases

- [x] Corrupted/invalid image soubory — graceful skip s error message
- [x] Permission denied — jasná chybová hláška + exit code 3
- [x] Disk full — detekce a srozumitelný error
- [x] Prázdný adresář — info message, exit 0
- [x] Symlinky — přeskočit (auto)
- [x] Velmi velké soubory (100MB+) — per-file error handling
- [x] Duplicitní vstup/výstup cesta — ochrana proti přepsání originálu
- [x] SIGINT handling (Ctrl+C) — cleanup rozpracovaných souborů
- [ ] Timeout pro stuck Metal operace

---

## Fáze 8: Performance optimization

- [x] Benchmark suite (100 PNG, 100 JPEG, 100 WebP, mix sizes)
- [ ] Metal command buffer batching (více obrázků na command buffer)
- [ ] Memory-mapped I/O pro velké soubory
- [ ] Texture atlas pro malé obrázky (batch GPU operace)
- [ ] Profilování Instruments (Metal System Trace)
- [ ] Porovnání s ImageMagick, squoosh-cli, sharp
- [x] Optimalizace startup time (lazy Metal init)

---

## Fáze 9: Testing

### Unit testy
- [x] `MetalEngineTests` — device init, texture creation, resize accuracy
- [x] `PNGEncoderTests` — round-trip, quality levels, metadata strip
- [x] `JPEGEncoderTests` — quality levels, progressive, chroma
- [ ] `WebPEncoderTests` — lossy/lossless, quality
- [x] `FormatConversionTests` — všechny kombinace formátů
- [x] `ImagePipelineTests` — end-to-end single file
- [x] `BatchProcessorTests` — directory scan, parallelism, error handling
- [x] `CLIParserTests` — argument parsing, defaults, validation
- [x] `OutputFormatterTests` — human-readable + JSON output
- [x] `ErrorHandlingTests` — corrupted files, permissions, edge cases

### Fixture obrázky
- [x] Připravit testovací sadu: malý PNG, velký PNG, JPEG, WebP, corrupted, zero-byte

### Performance testy
- [x] `measure {}` testy pro Metal operace
- [ ] Regression benchmark (nesmí zpomalit mezi verzemi)

### Integration testy
- [ ] End-to-end CLI test (spustit binary, ověřit výstup)
- [ ] CI/CD JSON output parsing test

---

## Fáze 10: Build a distribuce

- [x] Universal binary (arm64 + x86_64) via `swift build --arch arm64 --arch x86_64`
- [x] Release build s optimalizacemi (`-c release`)
- [x] Binary size check (cíl < 10 MB)
- [x] Code signing (`codesign`)
- [ ] Notarization (`notarytool`)
- [x] DMG nebo ZIP balíček pro přímý download
- [x] Homebrew formula (`brew install imgcrush`)
- [ ] Homebrew tap (`htmeta/tap/imgcrush`)
- [ ] Mint support (`mint install imgcrush`)
- [x] Automatický release via GitHub Actions (tag → build → upload → Homebrew update)

---

## Fáze 11: Licence a trial

- [x] License key formát a generování (server-side)
- [x] License key validace v CLI (offline-capable)
- [x] Trial mode — 14 dní plná funkčnost bez klíče
- [x] Trial expiration — jasná hláška + link na nákup
- [ ] Gumroad integrace (webhook → license key delivery)
- [ ] Etsy listing setup (Personal €29, Team €99, Enterprise €299)
- [x] License tiers: Personal (1 user), Team (5 users), Enterprise (unlimited)
- [x] `imgcrush --activate <KEY>` command
- [x] `imgcrush --status` — zobrazení stavu licence

---

## Fáze 12: Dokumentace

- [x] `README.md` — instalace, quick start, příklady, benchmarks
- [x] `CHANGELOG.md` — seznam změn per verze
- [x] Man page (`imgcrush.1`)
- [x] `--help` výstup — přehledný, s příklady
- [ ] Web dokumentace na imgcrush.dev/docs (nebo v README)
- [x] GitHub Actions usage příklad v README
- [x] Troubleshooting sekce (Intel fallback, permissions, large files)

---

## Fáze 13: Landing page a marketing

- [x] Landing page `web/index.html` — hero, benchmarks, features, pricing, FAQ, CTA
- [x] Demo GIF/video — terminálová session s real-time optimalizací
- [x] OG image (`og.png`) pro social sharing
- [x] Favicon
- [x] Plausible analytics integrace
- [x] Gumroad product setup (Personal €29, Team €99, Enterprise €299)
- [ ] Etsy product listings (Personal €29, Team €99, Enterprise €299)
- [ ] Stripe payment flow testování
- [ ] Email capture (ConvertKit) pro Cloud waitlist
- [x] SEO: meta tagy, structured data, sitemap

---

## Fáze 14: Launch

- [ ] Final testing na clean macOS instalaci
- [x] HackerNews "Show HN" post draft
- [x] Twitter/X thread draft (s demo GIF)
- [x] Reddit posty (r/swift, r/macOS, r/webdev)
- [x] Dev.to článek: "How I Built a 25× Faster Image Optimizer with Metal"
- [ ] ProductHunt listing příprava
- [x] Launch day checklist:
  - [ ] Homebrew formula publikovaná
  - [ ] GitHub release vytvořen
  - [ ] Landing page live
  - [ ] Payment flow otestován
  - [ ] Email sequence připravena
  - [ ] Social posty naplánované

---

## Fáze 15: Post-launch email sequence

- [x] Day 0: Welcome email (download link, quick start)
- [x] Day 3: Tips email (--json, --quality 85, --format webp)
- [x] Day 7: Cloud upsell email (web dashboard, API)
- [x] Day 14: API upsell email (developer tier €29/mo)
- [ ] ConvertKit automation setup

---

## Fáze 16: imgcrush Cloud (SaaS upsell)

### Backend
- [x] Cloudflare Workers API (`POST /optimize`)
- [x] R2 storage pro upload/download obrázků
- [ ] Processing queue (Cloudflare Queues nebo Durable Objects)
- [ ] Image processing backend (libvips fallback, nebo macOS server s Metal)
- [x] API key management (generování, validace, rate limiting)
- [x] Usage tracking per API key (images/month)
- [ ] Webhook notifikace po dokončení

### Web Dashboard
- [x] Next.js + Tailwind frontend
- [ ] Auth (Clerk nebo NextAuth)
- [x] Drag & drop upload
- [x] Optimalizace nastavení (formát, kvalita, resize)
- [ ] Historie zpracovaných obrázků
- [x] Usage dashboard (images used / limit)
- [ ] Download optimalizovaných obrázků (single + ZIP)
- [ ] Team management (Pro tier)

### API
- [x] REST API dokumentace (OpenAPI spec)
- [x] API key dashboard (vytvoření, revokace, rate limit)
- [x] Endpointy:
  - [x] `POST /optimize` — upload + optimize
  - [x] `GET /status/:id` — stav zpracování
  - [x] `GET /download/:id` — stažení výsledku
  - [x] `GET /usage` — usage statistics
- [x] SDK / code examples (curl, Node.js, Python)
- [ ] Rate limiting per tier (Starter: 100 req/min, Pro: 500, Business: 2000)

### Pricing tiers
- [ ] Starter €9/mo — 1,000 images, API, 7-day history
- [ ] Pro €29/mo — 10,000 images, team, CDN, 90-day history
- [ ] Business €99/mo — 100,000 images, custom domain, SLA
- [ ] Stripe Billing integrace (subscriptions, invoices)

---

## Fáze 17: v1.1 — AVIF a rozšíření

- [x] AVIF dekodér podpora
- [x] AVIF encodér (lossy + lossless)
- [x] `--format avif` flag
- [x] HEIC input podpora (macOS native)
- [ ] SVG → PNG/WebP rasterizace
- [x] Watch mode (`--watch`) — sledování adresáře pro nové soubory
- [x] Config file (`.imgcrushrc`) — defaultní nastavení per-projekt
- [ ] Plugin systém pro custom processing steps

---

## Fáze 18: Ongoing

- [x] Customer support (email, GitHub Issues)
- [ ] Bug fixes a patch releases
- [ ] Performance monitoring a optimalizace
- [ ] Churn prevention (usage alerts, feature teasing)
- [ ] Annual plan nabídka (2 měsíce zdarma)
- [ ] Cross-sell s TypeFlow (25% discount)
- [x] Community building (Discord nebo GitHub Discussions)
- [ ] Paid acquisition start (Google Ads, Twitter Ads — měsíc 2+)

---

## Poznámky

- **Performance je priorita #1** — Metal GPU cesta vždy preferovaná
- **Zero external dependencies kde možné** — systémové frameworky (Metal, ImageIO, CoreGraphics, vImage)
- **Binary < 10 MB** (universal arm64 + x86_64)
- **macOS 13+ (Ventura)** minimální verze
- **MRR fokus** — CLI je door opener, Cloud a API jsou recurring revenue
