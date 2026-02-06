# imgcrush — Implementační plán

**Produkt:** Metal-akcelerovaný image optimizer pro macOS  
**Autor:** Jakub Jirák | HTMETA.dev  
**Cíl:** CLI v1.0 → Cloud upsell → API → €10k+ MRR  

---

## Fáze 0: Projekt setup

- [ ] Inicializace Swift Package (`Package.swift`)
- [ ] Struktura adresářů (`Sources/imgcrush/`, `Sources/ImgCrushCore/`, `Tests/`)
- [ ] Přidat `swift-argument-parser` dependency
- [ ] `.gitignore` pro Swift / Xcode / .build
- [ ] Základní `README.md`
- [ ] CI: GitHub Actions workflow (`swift build` + `swift test` na macOS runner)

---

## Fáze 1: CLI skeleton + základní image loading

- [ ] `@main` entry point s ArgumentParser
- [ ] Definice CLI argumentů a flagů:
  - [ ] `<input>` — soubor nebo adresář (povinný)
  - [ ] `--format` — výstupní formát (png, jpeg, webp)
  - [ ] `--quality` — kvalita 1–100
  - [ ] `--resize` — rozměry (WxH)
  - [ ] `--output` — výstupní adresář
  - [ ] `--recursive` — zpracovat podadresáře
  - [ ] `--json` — JSON výstup pro CI/CD
  - [ ] `--dry-run` — náhled bez změn
  - [ ] `--verbose` — detailní výpis
  - [ ] `--version` — verze
- [ ] Načtení obrázku přes `CGImage` / `ImageIO`
- [ ] Detekce formátu vstupního souboru (PNG/JPEG/WebP)
- [ ] Základní validace vstupu (soubor existuje, je obrázek, permissions)
- [ ] Custom `ImgCrushError` enum s exit kódy (0/1/2/3)
- [ ] Uložení obrázku bez optimalizace (round-trip test)

---

## Fáze 2: Metal GPU engine

- [ ] `MetalEngine` — inicializace `MTLDevice`, `MTLCommandQueue`
- [ ] Detekce Metal dostupnosti (Apple Silicon vs Intel fallback)
- [ ] Metal compute kernel: `resize_bilinear` (MSL, `.metal` soubor)
- [ ] Metal compute kernel: `color_space_convert`
- [ ] `MTLTexture` ↔ `CGImage` konverze utility
- [ ] Pipeline state cache (nepřekompilovávat kernely opakovaně)
- [ ] CPU fallback cesta přes `vImage` pro Intel Macy
- [ ] Unit testy pro Metal engine (texture round-trip, resize accuracy)

---

## Fáze 3: Formátové encodéry a dekodéry

### PNG
- [ ] PNG dekodér (ImageIO)
- [ ] PNG encodér s optimalizací (compression level)
- [ ] Strip nepotřebných metadata (EXIF, ICC profily volitelně)

### JPEG
- [ ] JPEG dekodér (ImageIO)
- [ ] JPEG encodér s quality parametrem
- [ ] Progressive JPEG podpora
- [ ] Chroma subsampling optimalizace

### WebP
- [ ] WebP dekodér (ImageIO / CoreGraphics)
- [ ] WebP encodér s quality parametrem
- [ ] Lossy vs lossless detekce

### Konverze
- [ ] PNG → JPEG konverze
- [ ] PNG → WebP konverze
- [ ] JPEG → WebP konverze
- [ ] JPEG → PNG konverze
- [ ] WebP → PNG konverze
- [ ] WebP → JPEG konverze

---

## Fáze 4: Optimalizační pipeline

- [ ] `ImagePipeline` orchestrátor (load → process → encode → save)
- [ ] Smart quality — automatická detekce optimální kvality (SSIM-based)
- [ ] Resize s zachováním aspect ratio (fit, fill, exact)
- [ ] Skip already-optimized souborů (size comparison)
- [ ] Metadata preservace (volitelné zachování EXIF)
- [ ] Dry-run mode — report bez zápisu
- [ ] Statistics: original size, optimized size, % reduction, processing time

---

## Fáze 5: Batch processing

- [ ] Directory scanning (flat + recursive)
- [ ] File filtering podle přípony (png, jpg, jpeg, webp)
- [ ] Paralelní zpracování přes `TaskGroup` s concurrency limitem
- [ ] Progress bar (počet zpracovaných / celkem, elapsed time, ETA)
- [ ] Per-file výpis výsledků (název, original → optimized, % saved)
- [ ] Souhrnná statistika na konci (celkem souborů, celkem ušetřeno, čas)
- [ ] Přeskočení nesouborů a symlinků
- [ ] Graceful handling chyb per-file (nepadne celý batch)

---

## Fáze 6: Výstup a reporting

### Human-readable výstup
- [ ] Barevný terminálový výstup (ANSI colors)
- [ ] Progress bar s procenty a ETA
- [ ] Per-file řádek: `✓ image.png 2.1MB → 680KB (68% saved) 0.02s`
- [ ] Souhrnný řádek: `✓ 100 files optimized, 127MB saved (68%), 1.8s`
- [ ] Error řádky: `✗ broken.png — invalid image data`

### JSON výstup (`--json`)
- [ ] Per-file objekt: `{ "file", "original_size", "optimized_size", "reduction_pct", "format", "time_ms" }`
- [ ] Summary objekt: `{ "total_files", "total_original", "total_optimized", "total_reduction_pct", "total_time_ms" }`
- [ ] Error objekt: `{ "file", "error" }`
- [ ] Validní JSON i při chybách (partial results + errors array)

### Verbose mode
- [ ] Metal device info (GPU name, memory)
- [ ] Per-kernel timing
- [ ] Memory usage reporting

---

## Fáze 7: Error handling a edge cases

- [ ] Corrupted/invalid image soubory — graceful skip s error message
- [ ] Permission denied — jasná chybová hláška + exit code 3
- [ ] Disk full — detekce a srozumitelný error
- [ ] Prázdný adresář — info message, exit 0
- [ ] Symlinky — přeskočit nebo follow (flag?)
- [ ] Velmi velké soubory (100MB+) — memory management
- [ ] Duplicitní vstup/výstup cesta — ochrana proti přepsání originálu
- [ ] SIGINT handling (Ctrl+C) — cleanup rozpracovaných souborů
- [ ] Timeout pro stuck Metal operace

---

## Fáze 8: Performance optimization

- [ ] Benchmark suite (100 PNG, 100 JPEG, 100 WebP, mix sizes)
- [ ] Metal command buffer batching (více obrázků na command buffer)
- [ ] Memory-mapped I/O pro velké soubory
- [ ] Texture atlas pro malé obrázky (batch GPU operace)
- [ ] Profilování Instruments (Metal System Trace)
- [ ] Porovnání s ImageMagick, squoosh-cli, sharp
- [ ] Optimalizace startup time (lazy Metal init)

---

## Fáze 9: Testing

### Unit testy
- [ ] `MetalEngineTests` — device init, texture creation, resize accuracy
- [ ] `PNGEncoderTests` — round-trip, quality levels, metadata strip
- [ ] `JPEGEncoderTests` — quality levels, progressive, chroma
- [ ] `WebPEncoderTests` — lossy/lossless, quality
- [ ] `FormatConversionTests` — všechny kombinace formátů
- [ ] `ImagePipelineTests` — end-to-end single file
- [ ] `BatchProcessorTests` — directory scan, parallelism, error handling
- [ ] `CLIParserTests` — argument parsing, defaults, validation
- [ ] `OutputFormatterTests` — human-readable + JSON output
- [ ] `ErrorHandlingTests` — corrupted files, permissions, edge cases

### Fixture obrázky
- [ ] Připravit testovací sadu: malý PNG, velký PNG, JPEG, WebP, corrupted, zero-byte

### Performance testy
- [ ] `measure {}` testy pro Metal operace
- [ ] Regression benchmark (nesmí zpomalit mezi verzemi)

### Integration testy
- [ ] End-to-end CLI test (spustit binary, ověřit výstup)
- [ ] CI/CD JSON output parsing test

---

## Fáze 10: Build a distribuce

- [ ] Universal binary (arm64 + x86_64) via `swift build --arch arm64 --arch x86_64`
- [ ] Release build s optimalizacemi (`-c release`)
- [ ] Binary size check (cíl < 10 MB)
- [ ] Code signing (`codesign`)
- [ ] Notarization (`notarytool`)
- [ ] DMG nebo ZIP balíček pro přímý download
- [ ] Homebrew formula (`brew install imgcrush`)
- [ ] Homebrew tap (`htmeta/tap/imgcrush`)
- [ ] Mint support (`mint install imgcrush`)
- [ ] Automatický release via GitHub Actions (tag → build → upload → Homebrew update)

---

## Fáze 11: Licence a trial

- [ ] License key formát a generování (server-side)
- [ ] License key validace v CLI (offline-capable)
- [ ] Trial mode — 14 dní plná funkčnost bez klíče
- [ ] Trial expiration — jasná hláška + link na nákup
- [ ] Gumroad integrace (webhook → license key delivery)
- [ ] License tiers: Personal (1 user), Team (5 users), Enterprise (unlimited)
- [ ] `imgcrush --activate <KEY>` command
- [ ] `imgcrush --status` — zobrazení stavu licence

---

## Fáze 12: Dokumentace

- [ ] `README.md` — instalace, quick start, příklady, benchmarks
- [ ] `CHANGELOG.md` — seznam změn per verze
- [ ] Man page (`imgcrush.1`)
- [ ] `--help` výstup — přehledný, s příklady
- [ ] Web dokumentace na imgcrush.dev/docs (nebo v README)
- [ ] GitHub Actions usage příklad v README
- [ ] Troubleshooting sekce (Intel fallback, permissions, large files)

---

## Fáze 13: Landing page a marketing

- [x] Landing page `web/index.html` — hero, benchmarks, features, pricing, FAQ, CTA
- [ ] Demo GIF/video — terminálová session s real-time optimalizací
- [ ] OG image (`og.png`) pro social sharing
- [ ] Favicon
- [ ] Plausible analytics integrace
- [ ] Gumroad product setup (Personal €29, Team €99, Enterprise €299)
- [ ] Stripe payment flow testování
- [ ] Email capture (ConvertKit) pro Cloud waitlist
- [ ] SEO: meta tagy, structured data, sitemap

---

## Fáze 14: Launch

- [ ] Final testing na clean macOS instalaci
- [ ] HackerNews "Show HN" post draft
- [ ] Twitter/X thread draft (s demo GIF)
- [ ] Reddit posty (r/swift, r/macOS, r/webdev)
- [ ] Dev.to článek: "How I Built a 25× Faster Image Optimizer with Metal"
- [ ] ProductHunt listing příprava
- [ ] Launch day checklist:
  - [ ] Homebrew formula publikovaná
  - [ ] GitHub release vytvořen
  - [ ] Landing page live
  - [ ] Payment flow otestován
  - [ ] Email sequence připravena
  - [ ] Social posty naplánované

---

## Fáze 15: Post-launch email sequence

- [ ] Day 0: Welcome email (download link, quick start)
- [ ] Day 3: Tips email (--json, --quality 85, --format webp)
- [ ] Day 7: Cloud upsell email (web dashboard, API)
- [ ] Day 14: API upsell email (developer tier €29/mo)
- [ ] ConvertKit automation setup

---

## Fáze 16: imgcrush Cloud (SaaS upsell)

### Backend
- [ ] Cloudflare Workers API (`POST /optimize`)
- [ ] R2 storage pro upload/download obrázků
- [ ] Processing queue (Cloudflare Queues nebo Durable Objects)
- [ ] Image processing backend (libvips fallback, nebo macOS server s Metal)
- [ ] API key management (generování, validace, rate limiting)
- [ ] Usage tracking per API key (images/month)
- [ ] Webhook notifikace po dokončení

### Web Dashboard
- [ ] Next.js + Tailwind frontend
- [ ] Auth (Clerk nebo NextAuth)
- [ ] Drag & drop upload
- [ ] Optimalizace nastavení (formát, kvalita, resize)
- [ ] Historie zpracovaných obrázků
- [ ] Usage dashboard (images used / limit)
- [ ] Download optimalizovaných obrázků (single + ZIP)
- [ ] Team management (Pro tier)

### API
- [ ] REST API dokumentace (OpenAPI spec)
- [ ] API key dashboard (vytvoření, revokace, rate limit)
- [ ] Endpointy:
  - [ ] `POST /optimize` — upload + optimize
  - [ ] `GET /status/:id` — stav zpracování
  - [ ] `GET /download/:id` — stažení výsledku
  - [ ] `GET /usage` — usage statistics
- [ ] SDK / code examples (curl, Node.js, Python)
- [ ] Rate limiting per tier (Starter: 100 req/min, Pro: 500, Business: 2000)

### Pricing tiers
- [ ] Starter €9/mo — 1,000 images, API, 7-day history
- [ ] Pro €29/mo — 10,000 images, team, CDN, 90-day history
- [ ] Business €99/mo — 100,000 images, custom domain, SLA
- [ ] Stripe Billing integrace (subscriptions, invoices)

---

## Fáze 17: v1.1 — AVIF a rozšíření

- [ ] AVIF dekodér podpora
- [ ] AVIF encodér (lossy + lossless)
- [ ] `--format avif` flag
- [ ] HEIC input podpora (macOS native)
- [ ] SVG → PNG/WebP rasterizace
- [ ] Watch mode (`--watch`) — sledování adresáře pro nové soubory
- [ ] Config file (`.imgcrushrc`) — defaultní nastavení per-projekt
- [ ] Plugin systém pro custom processing steps

---

## Fáze 18: Ongoing

- [ ] Customer support (email, GitHub Issues)
- [ ] Bug fixes a patch releases
- [ ] Performance monitoring a optimalizace
- [ ] Churn prevention (usage alerts, feature teasing)
- [ ] Annual plan nabídka (2 měsíce zdarma)
- [ ] Cross-sell s TypeFlow (25% discount)
- [ ] Community building (Discord nebo GitHub Discussions)
- [ ] Paid acquisition start (Google Ads, Twitter Ads — měsíc 2+)

---

## Poznámky

- **Performance je priorita #1** — Metal GPU cesta vždy preferovaná
- **Zero external dependencies kde možné** — systémové frameworky (Metal, ImageIO, CoreGraphics, vImage)
- **Binary < 10 MB** (universal arm64 + x86_64)
- **macOS 13+ (Ventura)** minimální verze
- **MRR fokus** — CLI je door opener, Cloud a API jsou recurring revenue
