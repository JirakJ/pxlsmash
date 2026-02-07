# optipix — Gumroad Product Setup

## Product: optipix Personal License

**URL slug:** `optipix`
**Price:** €29 (one-time)

### Title
optipix — Metal GPU Image Optimizer for macOS

### Short description
Optimize images 25× faster with Apple Metal GPU acceleration. One command, batch processing, CI/CD ready.

### Full description
```
⚡ optipix — Metal-accelerated image optimizer for macOS

Optimize PNG, JPEG, WebP, AVIF, and HEIC images up to 25× faster than ImageMagick using Apple Metal GPU acceleration.

WHAT YOU GET:
━━━━━━━━━━━━━
✓ Universal macOS binary (Apple Silicon + Intel)
✓ Personal license — 1 developer, lifetime updates
✓ License key delivered instantly after purchase
✓ 14-day money-back guarantee

KEY FEATURES:
━━━━━━━━━━━━━
⚡ Metal GPU acceleration — 25× faster than ImageMagick
📦 Batch processing — hundreds of images in seconds
🔄 Format conversion — PNG, JPEG, WebP, AVIF, HEIC
🧠 Smart quality — SSIM-based auto-optimization
📊 JSON output — CI/CD pipeline ready
👁 Watch mode — auto-optimize on file changes
📁 Config files — .optipixrc per-project settings
🔐 Metadata preservation — keep EXIF data intact

SYSTEM REQUIREMENTS:
━━━━━━━━━━━━━━━━━━━
• macOS 13 (Ventura) or later
• Apple Silicon or Intel Mac
• Metal GPU recommended (CPU fallback available)

HOW IT WORKS:
━━━━━━━━━━━━━
1. Download the zip file
2. Extract and copy optipix to /usr/local/bin/
3. Activate: optipix --activate YOUR-KEY --email you@example.com
4. Done! Start optimizing: optipix ./images/ --recursive

QUICK START:
━━━━━━━━━━━━
  $ optipix photo.png                        # optimize single file
  $ optipix ./images/ --recursive            # batch optimize
  $ optipix ./assets/ --format webp -q 85    # convert to WebP
  $ optipix photo.jpg --smart-quality        # auto-detect best quality
  $ optipix ./dir/ --json                    # CI/CD output

DOCUMENTATION:
━━━━━━━━━━━━━━
  https://optipix.dev/docs

SUPPORT:
━━━━━━━━
  Email: support@optipix.dev
  GitHub: github.com/optipix/optipix

Built by HTMETA.dev
```

### Tags
`macos, image-optimization, cli, metal-gpu, developer-tools, webp, png, jpeg, avif, swift`

### Content delivery
Digital download — ZIP file containing:
- `optipix` universal binary
- `README.md`
- `CHANGELOG.md`
- `INSTALL.txt`
- `optipix.1` man page

### Custom fields
- **License Key** — auto-generated, format: `OPTX-AXXX-XXXX-XXXX-XXXX`
- **Delivery email** — include install instructions + license key

### Post-purchase message
```
Thank you for purchasing optipix! 🎉

Your license key: {license_key}

Quick install:
  curl -fsSL https://optipix.dev/install.sh | sh

Activate:
  optipix --activate {license_key} --email {email}

Documentation: https://optipix.dev/docs
Support: support@optipix.dev
```

---

## Product: optipix Team License

**URL slug:** `optipix-team`
**Price:** €99 (one-time)

### Title
optipix Team License — 5 Developers

### Description
Same as Personal, but with:
- Up to 5 developer seats
- Priority email support
- License keys: 5× `OPTX-GXXX-XXXX-XXXX-XXXX` format

---

## Product: optipix Enterprise License

**URL slug:** `optipix-enterprise`
**Price:** €299 (one-time)

### Title
optipix Enterprise License — Unlimited Developers

### Description
Same as Personal, but with:
- Unlimited developer seats
- Priority support + SLA
- License keys: `OPTX-NXXX-XXXX-XXXX-XXXX` format
- Custom integration support

---

## Gumroad Settings

### Profile
- **Name:** HTMETA.dev
- **URL:** htmeta.gumroad.com
- **Bio:** Developer tools built with ❤️ on Apple platforms
- **Profile image:** optipix logo

### Payment
- Currency: EUR
- Payout: bank transfer (SEPA)

### Workflow
- Auto-deliver ZIP file on purchase
- Send license key in confirmation email
- Enable "Pay what you want" above minimum price
