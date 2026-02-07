#!/bin/bash
# demo.sh — Record a terminal demo of pxlsmash for marketing
# Usage: ./scripts/demo.sh
# Requires: pxlsmash built and in PATH, sample images

set -e

DEMO_DIR="/tmp/pxlsmash-demo"
OUT_DIR="/tmp/pxlsmash-demo-out"

echo "🎬 pxlsmash demo — setting up..."

mkdir -p "$DEMO_DIR" "$OUT_DIR"

# Create test images via sips
COUNT=0
for f in /System/Library/Desktop\ Pictures/*.heic; do
    [ -f "$f" ] || continue
    COUNT=$((COUNT + 1))
    [ $COUNT -gt 5 ] && break
    sips -s format png "$f" --resampleWidth 2048 --out "$DEMO_DIR/photo_${COUNT}.png" 2>/dev/null || true
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  pxlsmash — Metal GPU Image Optimizer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "▶ Demo 1: Batch optimize directory"
echo "$ pxlsmash $DEMO_DIR/ --verbose"
pxlsmash "$DEMO_DIR/" --verbose
echo ""

echo "▶ Demo 2: Convert PNG → WebP"
echo "$ pxlsmash $DEMO_DIR/photo_1.png --format webp --output $OUT_DIR/"
pxlsmash "$DEMO_DIR/photo_1.png" --format webp --output "$OUT_DIR/"
echo ""

echo "▶ Demo 3: JSON output for CI/CD"
echo "$ pxlsmash $DEMO_DIR/ --json"
pxlsmash "$DEMO_DIR/" --json
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Demo complete!"
echo "  📦 https://pxlsmash.dev"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

rm -rf "$DEMO_DIR" "$OUT_DIR"
