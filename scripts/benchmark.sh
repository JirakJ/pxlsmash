#!/bin/bash
# imgcrush benchmark suite
# Generates test images and measures optimization performance.
# Usage: ./scripts/benchmark.sh [iterations]

set -euo pipefail

ITERATIONS=${1:-3}
BENCH_DIR="/tmp/imgcrush_bench_$$"
RESULTS_FILE="$BENCH_DIR/results.txt"
IMGCRUSH="$(cd "$(dirname "$0")/.." && pwd)/.build/release/imgcrush"

# Colors
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RESET='\033[0m'

cleanup() { rm -rf "$BENCH_DIR"; }
trap cleanup EXIT

echo -e "${CYAN}═══════════════════════════════════════${RESET}"
echo -e "${CYAN}  imgcrush Benchmark Suite${RESET}"
echo -e "${CYAN}═══════════════════════════════════════${RESET}"
echo ""

# Build release binary
echo -e "${YELLOW}Building release binary...${RESET}"
cd "$(dirname "$0")/.."
swift build -c release --quiet 2>/dev/null || swift build -c release
echo ""

# Check binary exists
if [ ! -f "$IMGCRUSH" ]; then
    echo "Error: Release binary not found at $IMGCRUSH"
    exit 1
fi

mkdir -p "$BENCH_DIR/input" "$BENCH_DIR/output"

# Generate test images using sips (macOS built-in)
echo -e "${YELLOW}Generating test images...${RESET}"

generate_png() {
    local size=$1 name=$2
    # Create a solid color PNG using Python (available on macOS)
    python3 -c "
import struct, zlib, os
w, h = $size, $size
raw = b''
for y in range(h):
    raw += b'\\x00'  # filter byte
    for x in range(w):
        r = int(255 * x / w)
        g = int(255 * y / h)
        b = 128
        a = 255
        raw += struct.pack('BBBB', r, g, b, a)
def chunk(ctype, data):
    c = ctype + data
    return struct.pack('>I', len(data)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)
with open('$BENCH_DIR/input/$name', 'wb') as f:
    f.write(b'\\x89PNG\\r\\n\\x1a\\n')
    f.write(chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)))
    f.write(chunk(b'IDAT', zlib.compress(raw)))
    f.write(chunk(b'IEND', b''))
"
}

# Small PNG (256x256)
for i in $(seq 1 10); do
    generate_png 256 "small_${i}.png"
done

# Medium PNG (1024x1024) 
for i in $(seq 1 5); do
    generate_png 1024 "medium_${i}.png"
done

# Large PNG (2048x2048)
for i in $(seq 1 3); do
    generate_png 2048 "large_${i}.png"
done

# Create JPEGs from PNGs using sips
for f in "$BENCH_DIR/input/"*.png; do
    base=$(basename "$f" .png)
    sips -s format jpeg -s formatOptions 90 "$f" --out "$BENCH_DIR/input/${base}.jpg" 2>/dev/null
done

TOTAL_INPUT=$(du -sh "$BENCH_DIR/input" | cut -f1)
INPUT_COUNT=$(ls "$BENCH_DIR/input" | wc -l | tr -d ' ')
echo "Generated $INPUT_COUNT test images ($TOTAL_INPUT)"
echo ""

# Run benchmarks
echo -e "${CYAN}Running benchmarks ($ITERATIONS iterations each)...${RESET}"
echo ""

bench() {
    local label=$1 args=$2
    local total_ms=0
    
    for i in $(seq 1 "$ITERATIONS"); do
        rm -rf "$BENCH_DIR/output/"*
        local start=$(python3 -c "import time; print(int(time.time()*1000))")
        eval "$IMGCRUSH $args" > /dev/null 2>&1 || true
        local end=$(python3 -c "import time; print(int(time.time()*1000))")
        local ms=$((end - start))
        total_ms=$((total_ms + ms))
    done
    
    local avg_ms=$((total_ms / ITERATIONS))
    printf "  %-40s %6dms (avg of %d runs)\n" "$label" "$avg_ms" "$ITERATIONS"
    echo "$label,$avg_ms" >> "$RESULTS_FILE"
}

echo "PNG optimization:"
bench "Single small PNG (256×256)" "'$BENCH_DIR/input/small_1.png' --output '$BENCH_DIR/output/'"
bench "10 small PNGs (256×256)" "'$BENCH_DIR/input/' --output '$BENCH_DIR/output/'"
bench "5 medium PNGs (1024×1024)" "'$BENCH_DIR/input/' --output '$BENCH_DIR/output/'"
echo ""

echo "JPEG optimization:"
bench "Single small JPEG (256×256)" "'$BENCH_DIR/input/small_1.jpg' --output '$BENCH_DIR/output/' --quality 85"
bench "Batch JPEG --quality 85" "'$BENCH_DIR/input/' --output '$BENCH_DIR/output/' --quality 85 --format jpeg"
echo ""

echo "Format conversion:"
bench "PNG → WebP" "'$BENCH_DIR/input/small_1.png' --output '$BENCH_DIR/output/' --format webp"
bench "PNG → JPEG" "'$BENCH_DIR/input/small_1.png' --output '$BENCH_DIR/output/' --format jpeg --quality 85"
bench "Batch PNG → WebP" "'$BENCH_DIR/input/' --output '$BENCH_DIR/output/' --format webp --quality 80"
echo ""

echo "Resize:"
bench "Resize 2048→512" "'$BENCH_DIR/input/large_1.png' --output '$BENCH_DIR/output/' --resize 512x512"
bench "Batch resize 1024→256" "'$BENCH_DIR/input/' --output '$BENCH_DIR/output/' --resize 256x256"
echo ""

echo "Smart quality:"
bench "Smart quality (JPEG)" "'$BENCH_DIR/input/small_1.jpg' --output '$BENCH_DIR/output/' --smart-quality --format jpeg"
echo ""

echo "Dry run:"
bench "Dry run batch" "'$BENCH_DIR/input/' --dry-run"
echo ""

echo -e "${GREEN}═══════════════════════════════════════${RESET}"
echo -e "${GREEN}  Benchmark complete${RESET}"
echo -e "${GREEN}═══════════════════════════════════════${RESET}"
echo ""
echo "Results saved to: $RESULTS_FILE"
