# pxlsmash — Gumroad Product Setup

## Product: pxlsmash Personal License

**URL slug:** `pxlsmash`
**Price:** €29 (one-time)

### Title
pxlsmash — Metal GPU Image Optimizer for macOS

### Short description
Optimize images 25× faster with Apple Metal GPU acceleration. One command, batch processing, CI/CD ready.

### Full description
```
⚡ pxlsmash — Metal-accelerated image optimizer for macOS

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
📁 Config files — .pxlsmashrc per-project settings
🔐 Metadata preservation — keep EXIF data intact

SYSTEM REQUIREMENTS:
━━━━━━━━━━━━━━━━━━━
• macOS 13 (Ventura) or later
• Apple Silicon or Intel Mac
• Metal GPU recommended (CPU fallback available)

HOW IT WORKS:
━━━━━━━━━━━━━
1. Download the zip file
2. Extract and copy pxlsmash to /usr/local/bin/
3. Activate: pxlsmash --activate YOUR-KEY --email you@example.com
4. Done! Start optimizing: pxlsmash ./images/ --recursive

QUICK START:
━━━━━━━━━━━━
  $ pxlsmash photo.png                        # optimize single file
  $ pxlsmash ./images/ --recursive            # batch optimize
  $ pxlsmash ./assets/ --format webp -q 85    # convert to WebP
  $ pxlsmash photo.jpg --smart-quality        # auto-detect best quality
  $ pxlsmash ./dir/ --json                    # CI/CD output

DOCUMENTATION:
━━━━━━━━━━━━━━
  https://pxlsmash.dev/docs

SUPPORT:
━━━━━━━━
  Email: support@pxlsmash.dev
  GitHub: github.com/pxlsmash/pxlsmash

Built by HTMETA.dev
```

### Tags
`macos, image-optimization, cli, metal-gpu, developer-tools, webp, png, jpeg, avif, swift`

### Content delivery
Digital download — ZIP file containing:
- `pxlsmash` universal binary
- `README.md`
- `CHANGELOG.md`
- `INSTALL.txt`
- `pxlsmash.1` man page

### Custom fields
- **License Key** — auto-generated, format: `PXLS-AXXX-XXXX-XXXX-XXXX`
- **Delivery email** — include install instructions + license key

### Post-purchase message
```
Thank you for purchasing pxlsmash! 🎉

Your license key: {license_key}

Quick install:
  curl -fsSL https://pxlsmash.dev/install.sh | sh

Activate:
  pxlsmash --activate {license_key} --email {email}

Documentation: https://pxlsmash.dev/docs
Support: support@pxlsmash.dev
```

---

## Product: pxlsmash Team License

**URL slug:** `pxlsmash-team`
**Price:** €99 (one-time)

### Title
pxlsmash Team License — 5 Developers

### Description
Same as Personal, but with:
- Up to 5 developer seats
- Priority email support
- License keys: 5× `PXLS-GXXX-XXXX-XXXX-XXXX` format

---

## Product: pxlsmash Enterprise License

**URL slug:** `pxlsmash-enterprise`
**Price:** €299 (one-time)

### Title
pxlsmash Enterprise License — Unlimited Developers

### Description
Same as Personal, but with:
- Unlimited developer seats
- Priority support + SLA
- License keys: `PXLS-NXXX-XXXX-XXXX-XXXX` format
- Custom integration support

---

## Gumroad Settings

### Profile
- **Name:** HTMETA.dev
- **URL:** htmeta.gumroad.com
- **Bio:** Developer tools built with ❤️ on Apple platforms
- **Profile image:** pxlsmash logo

### Payment
- Currency: EUR
- Payout: bank transfer (SEPA)

### Workflow
- Auto-deliver ZIP file on purchase
- Send license key in confirmation email
- Enable "Pay what you want" above minimum price
