#!/bin/bash
# pxlsmash Cloud API — cURL examples

API_KEY="your-api-key"
BASE_URL="https://api.pxlsmash.dev/v1"

# Optimize a single image
echo "=== Optimize single image ==="
curl -X POST "$BASE_URL/optimize" \
  -H "X-API-Key: $API_KEY" \
  -F "file=@photo.jpg" \
  -F "quality=85" \
  -o optimized.jpg -v

# Convert PNG to WebP
echo "=== Convert PNG → WebP ==="
curl -X POST "$BASE_URL/optimize" \
  -H "X-API-Key: $API_KEY" \
  -F "file=@image.png" \
  -F "format=webp" \
  -F "quality=80" \
  -o image.webp

# Resize and optimize
echo "=== Resize + optimize ==="
curl -X POST "$BASE_URL/optimize" \
  -H "X-API-Key: $API_KEY" \
  -F "file=@photo.jpg" \
  -F "resize=800x600" \
  -F "format=webp" \
  -o thumbnail.webp

# Smart quality (auto-detect optimal)
echo "=== Smart quality ==="
curl -X POST "$BASE_URL/optimize" \
  -H "X-API-Key: $API_KEY" \
  -F "file=@photo.jpg" \
  -F "smart_quality=true" \
  -F "keep_metadata=true" \
  -o smart.jpg

# Batch optimize
echo "=== Batch optimize ==="
JOB_ID=$(curl -s -X POST "$BASE_URL/batch" \
  -H "X-API-Key: $API_KEY" \
  -F "files=@img1.jpg" \
  -F "files=@img2.png" \
  -F "files=@img3.webp" \
  -F "quality=80" | jq -r '.id')

echo "Job ID: $JOB_ID"

# Poll for completion
while true; do
  STATUS=$(curl -s "$BASE_URL/batch/$JOB_ID" \
    -H "X-API-Key: $API_KEY" | jq -r '.status')
  echo "Status: $STATUS"
  [ "$STATUS" = "completed" ] && break
  sleep 2
done

# Download results
curl "$BASE_URL/batch/$JOB_ID/download" \
  -H "X-API-Key: $API_KEY" \
  -o results.zip

# Check usage
echo "=== Usage ==="
curl -s "$BASE_URL/usage?period=month" \
  -H "X-API-Key: $API_KEY" | jq .

# Health check (no auth required)
echo "=== Health ==="
curl -s "$BASE_URL/health" | jq .
