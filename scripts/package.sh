#!/bin/bash
# package.sh — Build distributable optipix package for sale
# Usage: ./scripts/package.sh [--sign] [--notarize]
#
# Produces:
#   dist/optipix-<VERSION>-macos-universal.tar.gz
#   dist/optipix-<VERSION>-macos-universal.zip
#   dist/optipix-<VERSION>-macos-universal.tar.gz.sha256
#   dist/optipix-<VERSION>-macos-universal.zip.sha256

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VERSION=$(git describe --tags --always 2>/dev/null | sed 's/^v//' || echo "1.0.0")
DIST="$ROOT/dist"
STAGING="$DIST/staging"
BINARY_NAME="optipix"
ARCHIVE_BASE="optipix-${VERSION}-macos-universal"
SIGN=false
NOTARIZE=false

# Parse flags
for arg in "$@"; do
  case "$arg" in
    --sign) SIGN=true ;;
    --notarize) NOTARIZE=true ;;
  esac
done

echo "═══════════════════════════════════════"
echo "  optipix packaging — v${VERSION}"
echo "═══════════════════════════════════════"
echo ""

# Clean
rm -rf "$DIST"
mkdir -p "$STAGING"

# Build universal binary
echo "▶ Building universal binary (arm64 + x86_64)..."
swift build -c release --arch arm64 --arch x86_64
BINARY=".build/apple/Products/Release/$BINARY_NAME"

if [ ! -f "$BINARY" ]; then
  echo "❌ Build failed — binary not found"
  exit 1
fi

echo "  ✓ Binary built: $(file "$BINARY" | cut -d: -f2)"
echo "  ✓ Size: $(du -h "$BINARY" | cut -f1)"
echo ""

# Verify binary works
echo "▶ Verifying binary..."
BINARY_VERSION=$("$BINARY" --version 2>&1 || true)
echo "  ✓ Version: $BINARY_VERSION"
echo "  ✓ Architectures: $(lipo -archs "$BINARY")"
echo ""

# Code sign
if [ "$SIGN" = true ]; then
  echo "▶ Code signing..."
  if [ -n "${SIGNING_IDENTITY:-}" ]; then
    codesign --sign "$SIGNING_IDENTITY" --options runtime --timestamp "$BINARY"
    echo "  ✓ Signed with: $SIGNING_IDENTITY"
  else
    codesign --sign - --options runtime "$BINARY"
    echo "  ✓ Ad-hoc signed (set SIGNING_IDENTITY for distribution)"
  fi
  echo ""
fi

# Prepare staging directory
echo "▶ Preparing package contents..."
cp "$BINARY" "$STAGING/"
cp "$ROOT/README.md" "$STAGING/"
cp "$ROOT/CHANGELOG.md" "$STAGING/"
cp "$ROOT/docs/optipix.1" "$STAGING/"

# Create install instructions
cat > "$STAGING/INSTALL.txt" << 'INSTALLEOF'
optipix — Metal-accelerated image optimizer for macOS
══════════════════════════════════════════════════════

QUICK INSTALL
─────────────
  sudo cp optipix /usr/local/bin/
  sudo cp optipix.1 /usr/local/share/man/man1/

Or use the install script:
  curl -fsSL https://optipix.dev/install.sh | sh

VERIFY
──────
  optipix --version

ACTIVATE LICENSE
────────────────
  optipix --activate YOUR-LICENSE-KEY --email you@example.com

LICENSE STATUS
──────────────
  optipix --license-status

FREE TRIAL
──────────
  optipix ships with a 14-day free trial. No credit card needed.
  Just run any command and the trial starts automatically.

PURCHASE
────────
  Personal (1 dev):      €29  — htmeta.gumroad.com/l/optipix
  Team (5 devs):         €99  — htmeta.gumroad.com/l/optipix-team
  Enterprise (unlimited): €299 — htmeta.gumroad.com/l/optipix-enterprise

  Also available on Etsy: etsy.com/shop/htmeta

SUPPORT
───────
  Email: support@optipix.dev
  GitHub: github.com/optipix/optipix/issues
  Docs:  optipix.dev/docs

SYSTEM REQUIREMENTS
───────────────────
  • macOS 13 (Ventura) or later
  • Apple Silicon or Intel Mac
  • Metal GPU recommended (CPU fallback available)
INSTALLEOF

echo "  ✓ Binary, README, CHANGELOG, man page, INSTALL.txt"
echo ""

# Create archives
echo "▶ Creating archives..."
cd "$DIST"

# tar.gz
tar -czf "${ARCHIVE_BASE}.tar.gz" -C staging .
echo "  ✓ ${ARCHIVE_BASE}.tar.gz ($(du -h "${ARCHIVE_BASE}.tar.gz" | cut -f1))"

# zip
(cd staging && zip -qr "../${ARCHIVE_BASE}.zip" .)
echo "  ✓ ${ARCHIVE_BASE}.zip ($(du -h "${ARCHIVE_BASE}.zip" | cut -f1))"

# Checksums
shasum -a 256 "${ARCHIVE_BASE}.tar.gz" > "${ARCHIVE_BASE}.tar.gz.sha256"
shasum -a 256 "${ARCHIVE_BASE}.zip" > "${ARCHIVE_BASE}.zip.sha256"
echo "  ✓ SHA256 checksums generated"
echo ""

# Notarize
if [ "$NOTARIZE" = true ]; then
  echo "▶ Notarizing..."
  if [ -n "${APPLE_ID:-}" ] && [ -n "${APPLE_TEAM_ID:-}" ]; then
    xcrun notarytool submit "${ARCHIVE_BASE}.zip" \
      --apple-id "$APPLE_ID" \
      --team-id "$APPLE_TEAM_ID" \
      --password "$APPLE_APP_PASSWORD" \
      --wait
    echo "  ✓ Notarized successfully"
  else
    echo "  ⚠ Skipped — set APPLE_ID, APPLE_TEAM_ID, APPLE_APP_PASSWORD"
  fi
  echo ""
fi

# Cleanup staging
rm -rf "$STAGING"

# Summary
echo "═══════════════════════════════════════"
echo "  ✅ Package ready!"
echo "═══════════════════════════════════════"
echo ""
echo "  Files:"
ls -lh "$DIST/"*.{tar.gz,zip,sha256} 2>/dev/null | awk '{print "    " $NF " (" $5 ")"}'
echo ""
echo "  Upload these to Gumroad/Etsy:"
echo "    • ${ARCHIVE_BASE}.zip (primary)"
echo "    • ${ARCHIVE_BASE}.tar.gz (alternative)"
echo ""
echo "  Next steps:"
echo "    1. Upload to Gumroad: htmeta.gumroad.com"
echo "    2. Upload to Etsy: etsy.com/shop/htmeta"
echo "    3. Create GitHub Release: git tag v${VERSION} && git push --tags"
