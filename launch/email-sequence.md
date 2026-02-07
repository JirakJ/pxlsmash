# pxlsmash — Post-Launch Email Sequence

Templates for ConvertKit / email marketing automation.
Trigger: User downloads pxlsmash or starts trial.

---

## Email 1: Welcome (Day 0 — immediate)

**Subject:** 🚀 pxlsmash is ready — here's your quick start

**Body:**

Hey {first_name},

Welcome to pxlsmash! Here's everything you need to get started.

### Install

```bash
brew install htmeta/tap/pxlsmash
```

Or download the binary: https://pxlsmash.dev/download

### Quick Start (30 seconds)

```bash
# Optimize all images in a directory
pxlsmash ./images/ --quality 85

# Convert PNG → WebP (smaller files, same quality)
pxlsmash ./images/ --format webp --recursive
```

### Your Trial

You have **14 days** of full access. No credit card required.
After that, a personal license is just $29 — one-time, forever.

Need help? Reply to this email — I read every message.

Cheers,
Jakub

---

## Email 2: Power Tips (Day 3)

**Subject:** 3 pxlsmash tricks you probably missed

**Body:**

Hey {first_name},

Now that you've had a few days with pxlsmash, here are 3 power-user tips:

### 1. CI/CD Integration

Add image optimization to your build pipeline:

```yaml
# GitHub Actions
- name: Optimize images
  run: pxlsmash ./public/ --json --recursive --quality 80
```

The `--json` flag outputs machine-readable results with exit codes.

### 2. Smart Quality

For web images, `--quality 85` is usually the sweet spot — visually
identical to 100 but 40-60% smaller files.

```bash
pxlsmash ./assets/ --quality 85 --format webp
```

### 3. Dry Run First

Preview exactly what will change before committing:

```bash
pxlsmash ./images/ --dry-run --verbose
```

Shows file sizes, estimated savings, and which Metal device will be used.

How's pxlsmash working for you? Hit reply — I'd love to hear your use case.

Jakub

---

## Email 3: Cloud Upsell (Day 7)

**Subject:** Process images from anywhere — pxlsmash Cloud (early access)

**Body:**

Hey {first_name},

Quick question: do you ever need to optimize images on a server,
in a web app, or from a team that doesn't all use macOS?

I'm building **pxlsmash Cloud** — the same optimization engine,
accessible via API from anywhere:

```bash
curl -X POST https://api.pxlsmash.dev/optimize \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -F "image=@photo.png" \
  -F "quality=85" \
  -F "format=webp"
```

**Early access features:**
- REST API with the same quality as the CLI
- Web dashboard for drag & drop
- Webhook notifications when processing completes
- Team accounts with usage analytics

**Interested?** Reply "cloud" and I'll add you to the early access list.
Early access users get 50% off the first 6 months.

Jakub

---

## Email 4: Trial Ending (Day 12 — 2 days before expiry)

**Subject:** ⏰ Your pxlsmash trial ends in 2 days

**Body:**

Hey {first_name},

Your 14-day pxlsmash trial ends in 2 days.

If pxlsmash has been useful, grab a license to keep it running:

🔗 **https://pxlsmash.dev/pricing**

Also available on:
- 🛒 **Gumroad:** https://htmeta.gumroad.com
- 🧡 **Etsy:** https://www.etsy.com/shop/htmeta

| Plan | Price | For |
|------|-------|-----|
| Personal | $29 | 1 user, lifetime |
| Team | $99 | 5 users, priority support |
| Enterprise | $249 | Unlimited, SLA |

All plans are **one-time** — no subscription, no recurring fees.

After purchase, activate in 10 seconds:

```bash
pxlsmash --activate PXLS-XXXX-XXXX-XXXX-XXXX --email you@example.com
```

Questions? Just reply.

Jakub

---

## Email 5: API Developer Upsell (Day 14)

**Subject:** pxlsmash API — automate image optimization at scale

**Body:**

Hey {first_name},

If you're processing images programmatically (e.g., user uploads,
e-commerce catalogs, content pipelines), the pxlsmash API might
save you serious infrastructure time:

**What you get:**
- `POST /optimize` endpoint with format/quality/resize params
- Process up to 10,000 images/month on Starter plan
- 99.9% uptime SLA
- SDKs for Node.js, Python, Go

**Pricing:**
- Starter: $29/mo (10k images)
- Pro: $99/mo (100k images)
- Scale: $249/mo (1M images)

14-day free trial on all API plans too.

🔗 **https://pxlsmash.dev/api**

Jakub

---

## ConvertKit Automation Notes

- **Trigger:** Tag "pxlsmash-trial" added (via download form or CLI telemetry)
- **Sequence:** 5 emails over 14 days
- **Exit conditions:** User purchases license → tag "pxlsmash-customer" → exit sequence, enter customer onboarding
- **Segments:** CLI-only vs Cloud-interested (based on Email 3 reply)
