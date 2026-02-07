# imgcrush — Gumroad Product Setup

## Product: imgcrush Personal License

**URL slug:** `imgcrush`
**Price:** €29 (one-time)

### Title
imgcrush — Metal GPU Image Optimizer for macOS

### Short description
Optimize images 25× faster with Apple Metal GPU acceleration. One command, batch processing, CI/CD ready.

### Full description
```
⚡ imgcrush — Metal-accelerated image optimizer for macOS

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
📁 Config files — .imgcrushrc per-project settings
🔐 Metadata preservation — keep EXIF data intact

SYSTEM REQUIREMENTS:
━━━━━━━━━━━━━━━━━━━
• macOS 13 (Ventura) or later
• Apple Silicon or Intel Mac
• Metal GPU recommended (CPU fallback available)

HOW IT WORKS:
━━━━━━━━━━━━━
1. Download the zip file
2. Extract and copy imgcrush to /usr/local/bin/
3. Activate: imgcrush --activate YOUR-KEY --email you@example.com
4. Done! Start optimizing: imgcrush ./images/ --recursive

QUICK START:
━━━━━━━━━━━━
  $ imgcrush photo.png                        # optimize single file
  $ imgcrush ./images/ --recursive            # batch optimize
  $ imgcrush ./assets/ --format webp -q 85    # convert to WebP
  $ imgcrush photo.jpg --smart-quality        # auto-detect best quality
  $ imgcrush ./dir/ --json                    # CI/CD output

DOCUMENTATION:
━━━━━━━━━━━━━━
  https://imgcrush.dev/docs

SUPPORT:
━━━━━━━━
  Email: support@imgcrush.dev
  GitHub: github.com/imgcrush/imgcrush

Built by HTMETA.dev
```

### Tags
`macos, image-optimization, cli, metal-gpu, developer-tools, webp, png, jpeg, avif, swift`

### Content delivery
Digital download — ZIP file containing:
- `imgcrush` universal binary
- `README.md`
- `CHANGELOG.md`
- `INSTALL.txt`
- `imgcrush.1` man page

### Custom fields
- **License Key** — auto-generated, format: `IMGC-AXXX-XXXX-XXXX-XXXX`
- **Delivery email** — include install instructions + license key

### Post-purchase message
```
Thank you for purchasing imgcrush! 🎉

Your license key: {license_key}

Quick install:
  curl -fsSL https://imgcrush.dev/install.sh | sh

Activate:
  imgcrush --activate {license_key} --email {email}

Documentation: https://imgcrush.dev/docs
Support: support@imgcrush.dev
```

---

## Product: imgcrush Team License

**URL slug:** `imgcrush-team`
**Price:** €99 (one-time)

### Title
imgcrush Team License — 5 Developers

### Description
Same as Personal, but with:
- Up to 5 developer seats
- Priority email support
- License keys: 5× `IMGC-GXXX-XXXX-XXXX-XXXX` format

---

## Product: imgcrush Enterprise License

**URL slug:** `imgcrush-enterprise`
**Price:** €299 (one-time)

### Title
imgcrush Enterprise License — Unlimited Developers

### Description
Same as Personal, but with:
- Unlimited developer seats
- Priority support + SLA
- License keys: `IMGC-NXXX-XXXX-XXXX-XXXX` format
- Custom integration support

---

## Gumroad Settings

### Profile
- **Name:** HTMETA.dev
- **URL:** htmeta.gumroad.com
- **Bio:** Developer tools built with ❤️ on Apple platforms
- **Profile image:** imgcrush logo

### Payment
- Currency: EUR
- Payout: bank transfer (SEPA)

### Workflow
- Auto-deliver ZIP file on purchase
- Send license key in confirmation email
- Enable "Pay what you want" above minimum price
