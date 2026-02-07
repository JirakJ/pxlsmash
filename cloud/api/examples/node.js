// optipix Cloud API — Node.js SDK example
// npm install node-fetch form-data

const fs = require("fs");
const FormData = require("form-data");

const API_KEY = process.env.OPTXRUSH_API_KEY || "your-api-key";
const BASE_URL = "https://api.optipix.dev/v1";

async function optimizeImage(filePath, options = {}) {
  const form = new FormData();
  form.append("file", fs.createReadStream(filePath));

  if (options.format) form.append("format", options.format);
  if (options.quality) form.append("quality", String(options.quality));
  if (options.resize) form.append("resize", options.resize);
  if (options.smartQuality) form.append("smart_quality", "true");
  if (options.keepMetadata) form.append("keep_metadata", "true");

  const res = await fetch(`${BASE_URL}/optimize`, {
    method: "POST",
    headers: { "X-API-Key": API_KEY },
    body: form,
  });

  if (!res.ok) {
    const err = await res.json();
    throw new Error(`optipix API error: ${err.message}`);
  }

  const stats = {
    originalSize: parseInt(res.headers.get("X-Original-Size")),
    optimizedSize: parseInt(res.headers.get("X-Optimized-Size")),
    savingsPercent: parseFloat(res.headers.get("X-Savings-Percent")),
    processingTimeMs: parseFloat(res.headers.get("X-Processing-Time-Ms")),
  };

  return { buffer: Buffer.from(await res.arrayBuffer()), stats };
}

async function batchOptimize(filePaths, options = {}) {
  const form = new FormData();
  for (const fp of filePaths) {
    form.append("files", fs.createReadStream(fp));
  }
  if (options.format) form.append("format", options.format);
  if (options.quality) form.append("quality", String(options.quality));

  const res = await fetch(`${BASE_URL}/batch`, {
    method: "POST",
    headers: { "X-API-Key": API_KEY },
    body: form,
  });

  if (!res.ok) throw new Error(`Batch failed: ${(await res.json()).message}`);
  return await res.json();
}

async function pollBatchJob(jobId) {
  while (true) {
    const res = await fetch(`${BASE_URL}/batch/${jobId}`, {
      headers: { "X-API-Key": API_KEY },
    });
    const job = await res.json();
    console.log(`Job ${jobId}: ${job.status} (${job.completed}/${job.total})`);

    if (job.status === "completed" || job.status === "failed") return job;
    await new Promise((r) => setTimeout(r, 2000));
  }
}

async function getUsage(period = "month") {
  const res = await fetch(`${BASE_URL}/usage?period=${period}`, {
    headers: { "X-API-Key": API_KEY },
  });
  return await res.json();
}

// --- Example usage ---

async function main() {
  // Single image optimization
  const { buffer, stats } = await optimizeImage("photo.jpg", {
    format: "webp",
    quality: 85,
  });
  fs.writeFileSync("photo.webp", buffer);
  console.log(`Saved ${stats.savingsPercent}% (${stats.processingTimeMs}ms)`);

  // Smart quality
  const smart = await optimizeImage("photo.jpg", { smartQuality: true });
  fs.writeFileSync("smart.jpg", smart.buffer);

  // Batch
  const job = await batchOptimize(["img1.jpg", "img2.png", "img3.webp"], {
    quality: 80,
  });
  const result = await pollBatchJob(job.id);
  console.log("Batch results:", result.results);

  // Usage
  const usage = await getUsage();
  console.log("This month:", usage.images_processed, "images processed");
}

main().catch(console.error);
