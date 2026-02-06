#!/bin/bash
# demo.sh — Record a terminal demo of imgcrush for marketing
# Usage: ./scripts/demo.sh
# Requires: imgcrush built and in PATH, sample images

set -e

DEMO_DIR="/tmp/imgcrush-demo"
OUT_DIR="/tmp/imgcrush-demo-out"

echo "🎬 imgcrush demo — setting up..."

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
echo "  imgcrush — Metal GPU Image Optimizer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "▶ Demo 1: Batch optimize directory"
echo "$ imgcrush $DEMO_DIR/ --verbose"
imgcrush "$DEMO_DIR/" --verbose
echo ""

echo "▶ Demo 2: Convert PNG → WebP"
echo "$ imgcrush $DEMO_DIR/photo_1.png --format webp --output $OUT_DIR/"
imgcrush "$DEMO_DIR/photo_1.png" --format webp --output "$OUT_DIR/"
echo ""

echo "▶ Demo 3: JSON output for CI/CD"
echo "$ imgcrush $DEMO_DIR/ --json"
imgcrush "$DEMO_DIR/" --json
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Demo complete!"
echo "  📦 https://imgcrush.dev"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

rm -rf "$DEMO_DIR" "$OUT_DIR"
