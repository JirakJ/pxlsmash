#!/bin/sh
# imgcrush installer — download and install the latest release
# Usage: curl -fsSL https://imgcrush.dev/install.sh | sh
#
# Environment variables:
#   IMGCRUSH_VERSION — specific version to install (default: latest)
#   IMGCRUSH_PREFIX  — install prefix (default: /usr/local)

set -e

REPO="imgcrush/imgcrush"
PREFIX="${IMGCRUSH_PREFIX:-/usr/local}"
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
  fail "imgcrush requires macOS. Linux/Windows are not supported."
fi

# Check macOS version (13+)
MACOS_VERSION=$(sw_vers -productVersion | cut -d. -f1)
if [ "$MACOS_VERSION" -lt 13 ] 2>/dev/null; then
  fail "imgcrush requires macOS 13 (Ventura) or later. You have $(sw_vers -productVersion)."
fi

echo ""
info "═══════════════════════════════════════"
info "  imgcrush installer"
info "═══════════════════════════════════════"
echo ""

# Determine version
if [ -n "${IMGCRUSH_VERSION:-}" ]; then
  VERSION="$IMGCRUSH_VERSION"
  info "Installing imgcrush v${VERSION}..."
else
  info "Fetching latest version..."
  VERSION=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | sed 's/.*"v\(.*\)".*/\1/')
  if [ -z "$VERSION" ]; then
    fail "Could not determine latest version. Set IMGCRUSH_VERSION manually."
  fi
  info "Latest version: v${VERSION}"
fi
echo ""

# Determine architecture
ARCH=$(uname -m)
ARCHIVE_NAME="imgcrush-${VERSION}-macos-universal"

# Download
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/v${VERSION}/${ARCHIVE_NAME}.tar.gz"
TMPDIR=$(mktemp -d)
trap "rm -rf '$TMPDIR'" EXIT

info "Downloading ${ARCHIVE_NAME}.tar.gz..."
if ! curl -fSL --progress-bar "$DOWNLOAD_URL" -o "$TMPDIR/imgcrush.tar.gz"; then
  fail "Download failed. Check https://github.com/${REPO}/releases for available versions."
fi
ok "Downloaded"

# Verify checksum
CHECKSUM_URL="https://github.com/${REPO}/releases/download/v${VERSION}/${ARCHIVE_NAME}.tar.gz.sha256"
if curl -fsSL "$CHECKSUM_URL" -o "$TMPDIR/checksum.sha256" 2>/dev/null; then
  cd "$TMPDIR"
  EXPECTED=$(cat checksum.sha256 | awk '{print $1}')
  ACTUAL=$(shasum -a 256 imgcrush.tar.gz | awk '{print $1}')
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
tar -xzf "$TMPDIR/imgcrush.tar.gz" -C "$TMPDIR"
ok "Extracted"

# Install
echo ""
info "Installing to ${BIN_DIR}/imgcrush..."

if [ -w "$BIN_DIR" ]; then
  cp "$TMPDIR/imgcrush" "$BIN_DIR/imgcrush"
  chmod +x "$BIN_DIR/imgcrush"
else
  sudo mkdir -p "$BIN_DIR"
  sudo cp "$TMPDIR/imgcrush" "$BIN_DIR/imgcrush"
  sudo chmod +x "$BIN_DIR/imgcrush"
fi
ok "Binary installed"

# Man page
if [ -f "$TMPDIR/imgcrush.1" ]; then
  if [ -w "$MAN_DIR" ] 2>/dev/null; then
    mkdir -p "$MAN_DIR"
    cp "$TMPDIR/imgcrush.1" "$MAN_DIR/imgcrush.1"
  else
    sudo mkdir -p "$MAN_DIR"
    sudo cp "$TMPDIR/imgcrush.1" "$MAN_DIR/imgcrush.1"
  fi
  ok "Man page installed"
fi

# Verify
echo ""
if command -v imgcrush > /dev/null 2>&1; then
  INSTALLED_VERSION=$(imgcrush --version 2>&1 || echo "unknown")
  ok "imgcrush ${INSTALLED_VERSION} installed successfully!"
else
  if [ -f "$BIN_DIR/imgcrush" ]; then
    ok "Installed to $BIN_DIR/imgcrush"
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
echo "  imgcrush photo.png"
echo ""
echo "  # Batch optimize a directory"
echo "  imgcrush ./images/ --recursive"
echo ""
echo "  # Convert to WebP"
echo "  imgcrush ./assets/ --format webp --quality 85"
echo ""
echo "  # Full documentation"
echo "  https://imgcrush.dev/docs"
echo ""
echo "  # 14-day free trial included — no license key needed to start."
echo ""
