#!/bin/sh
# pxlsmash installer — download and install the latest release
# Usage: curl -fsSL https://pxlsmash.dev/install.sh | sh
#
# Environment variables:
#   PXLSRUSH_VERSION — specific version to install (default: latest)
#   PXLSRUSH_PREFIX  — install prefix (default: /usr/local)

set -e

REPO="pxlsmash/pxlsmash"
PREFIX="${PXLSRUSH_PREFIX:-/usr/local}"
BIN_DIR="$PREFIX/bin"
MAN_DIR="$PREFIX/share/man/man1"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RESET='\033[0m'

info()  { printf "${CYAN}%s${RESET}\n" "$1"; }
ok()    { printf "${GREEN}✓${RESET} %s\n" "$1"; }
fail()  { printf "${RED}✗ %s${RESET}\n" "$1"; exit 1; }

# Check macOS
if [ "$(uname -s)" != "Darwin" ]; then
  fail "pxlsmash requires macOS. Linux/Windows are not supported."
fi

# Check macOS version (13+)
MACOS_VERSION=$(sw_vers -productVersion | cut -d. -f1)
if [ "$MACOS_VERSION" -lt 13 ] 2>/dev/null; then
  fail "pxlsmash requires macOS 13 (Ventura) or later. You have $(sw_vers -productVersion)."
fi

echo ""
info "═══════════════════════════════════════"
info "  pxlsmash installer"
info "═══════════════════════════════════════"
echo ""

# Determine version
if [ -n "${PXLSRUSH_VERSION:-}" ]; then
  VERSION="$PXLSRUSH_VERSION"
  info "Installing pxlsmash v${VERSION}..."
else
  info "Fetching latest version..."
  VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/')
  if [ -z "$VERSION" ]; then
    fail "Could not determine latest version. Set PXLSRUSH_VERSION manually."
  fi
  info "Latest version: v${VERSION}"
fi
echo ""

# Determine architecture
ARCH=$(uname -m)
ARCHIVE_NAME="pxlsmash-${VERSION}-macos-universal"

# Download
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/v${VERSION}/${ARCHIVE_NAME}.tar.gz"
TMPDIR=$(mktemp -d)
trap "rm -rf '$TMPDIR'" EXIT

info "Downloading ${ARCHIVE_NAME}.tar.gz..."
if ! curl -fSL --progress-bar "$DOWNLOAD_URL" -o "$TMPDIR/pxlsmash.tar.gz"; then
  fail "Download failed. Check https://github.com/${REPO}/releases for available versions."
fi
ok "Downloaded"

# Verify checksum
CHECKSUM_URL="https://github.com/${REPO}/releases/download/v${VERSION}/${ARCHIVE_NAME}.tar.gz.sha256"
if curl -fsSL "$CHECKSUM_URL" -o "$TMPDIR/checksum.sha256" 2>/dev/null; then
  cd "$TMPDIR"
  EXPECTED=$(cat checksum.sha256 | awk '{print $1}')
  ACTUAL=$(shasum -a 256 pxlsmash.tar.gz | awk '{print $1}')
  if [ "$EXPECTED" = "$ACTUAL" ]; then
    ok "Checksum verified"
  else
    fail "Checksum mismatch! Expected: $EXPECTED, Got: $ACTUAL"
  fi
  cd - > /dev/null
else
  echo "  ⚠ Checksum not available, skipping verification"
fi

# Extract
info "Extracting..."
tar -xzf "$TMPDIR/pxlsmash.tar.gz" -C "$TMPDIR"
ok "Extracted"

# Install
echo ""
info "Installing to ${BIN_DIR}/pxlsmash..."

if [ -w "$BIN_DIR" ]; then
  cp "$TMPDIR/pxlsmash" "$BIN_DIR/pxlsmash"
  chmod +x "$BIN_DIR/pxlsmash"
else
  sudo mkdir -p "$BIN_DIR"
  sudo cp "$TMPDIR/pxlsmash" "$BIN_DIR/pxlsmash"
  sudo chmod +x "$BIN_DIR/pxlsmash"
fi
ok "Binary installed"

# Man page
if [ -f "$TMPDIR/pxlsmash.1" ]; then
  if [ -w "$MAN_DIR" ] 2>/dev/null; then
    mkdir -p "$MAN_DIR"
    cp "$TMPDIR/pxlsmash.1" "$MAN_DIR/pxlsmash.1"
  else
    sudo mkdir -p "$MAN_DIR"
    sudo cp "$TMPDIR/pxlsmash.1" "$MAN_DIR/pxlsmash.1"
  fi
  ok "Man page installed"
fi

# Verify
echo ""
if command -v pxlsmash > /dev/null 2>&1; then
  INSTALLED_VERSION=$(pxlsmash --version 2>&1 || echo "unknown")
  ok "pxlsmash ${INSTALLED_VERSION} installed successfully!"
else
  if [ -f "$BIN_DIR/pxlsmash" ]; then
    ok "Installed to $BIN_DIR/pxlsmash"
    echo ""
    echo "  ⚠ $BIN_DIR is not in your PATH. Add it:"
    echo "    export PATH=\"$BIN_DIR:\$PATH\""
  else
    fail "Installation failed"
  fi
fi

echo ""
info "═══════════════════════════════════════"
info "  Quick start"
info "═══════════════════════════════════════"
echo ""
echo "  # Optimize a single image"
echo "  pxlsmash photo.png"
echo ""
echo "  # Batch optimize a directory"
echo "  pxlsmash ./images/ --recursive"
echo ""
echo "  # Convert to WebP"
echo "  pxlsmash ./assets/ --format webp --quality 85"
echo ""
echo "  # Full documentation"
echo "  https://pxlsmash.dev/docs"
echo ""
echo "  # 14-day free trial included — no license key needed to start."
echo ""
