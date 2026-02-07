/**
 * optipix Cloud API — Cloudflare Workers
 *
 * Endpoints:
 *   POST /optimize     — Upload and optimize an image
 *   GET  /status/:id   — Check processing status
 *   GET  /download/:id — Download processed image
 *   GET  /usage        — Get API key usage stats
 */

export interface Env {
  IMAGES: R2Bucket;
  API_KEYS: KVNamespace;
  ENVIRONMENT: string;
}

interface ApiKeyData {
  email: string;
  tier: "starter" | "pro" | "scale";
  monthlyLimit: number;
  usedThisMonth: number;
  createdAt: string;
}

interface OptimizeRequest {
  quality?: number;
  format?: "png" | "jpeg" | "webp";
  width?: number;
  height?: number;
}

interface ProcessingResult {
  id: string;
  status: "processing" | "completed" | "error";
  originalSize?: number;
  optimizedSize?: number;
  savings?: string;
  format?: string;
  downloadUrl?: string;
  error?: string;
}

// CORS headers for dashboard
const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    // Handle CORS preflight
    if (request.method === "OPTIONS") {
      return new Response(null, { headers: corsHeaders });
    }

    const url = new URL(request.url);
    const path = url.pathname;

    try {
      // API key authentication (except health check)
      if (path !== "/" && path !== "/health") {
        const authResult = await authenticateRequest(request, env);
        if (!authResult.ok) {
          return jsonResponse({ error: authResult.error }, 401);
        }
      }

      // Route handling
      if (path === "/" || path === "/health") {
        return jsonResponse({
          service: "optipix Cloud API",
          version: "1.0.0",
          status: "ok",
        });
      }

      if (path === "/optimize" && request.method === "POST") {
        return handleOptimize(request, env);
      }

      if (path.startsWith("/status/") && request.method === "GET") {
        const id = path.replace("/status/", "");
        return handleStatus(id, env);
      }

      if (path.startsWith("/download/") && request.method === "GET") {
        const id = path.replace("/download/", "");
        return handleDownload(id, env);
      }

      if (path === "/usage" && request.method === "GET") {
        const apiKey = extractApiKey(request);
        return handleUsage(apiKey!, env);
      }

      return jsonResponse({ error: "Not found" }, 404);
    } catch (err) {
      const message = err instanceof Error ? err.message : "Internal error";
      return jsonResponse({ error: message }, 500);
    }
  },
};

// --- Authentication ---

async function authenticateRequest(
  request: Request,
  env: Env
): Promise<{ ok: boolean; error?: string }> {
  const apiKey = extractApiKey(request);
  if (!apiKey) {
    return { ok: false, error: "Missing Authorization header (Bearer token)" };
  }

  const keyData = await env.API_KEYS.get(apiKey, "json");
  if (!keyData) {
    return { ok: false, error: "Invalid API key" };
  }

  const data = keyData as ApiKeyData;
  if (data.usedThisMonth >= data.monthlyLimit) {
    return {
      ok: false,
      error: `Monthly limit reached (${data.monthlyLimit} images). Upgrade at https://optipix.dev/pricing`,
    };
  }

  return { ok: true };
}

function extractApiKey(request: Request): string | null {
  const auth = request.headers.get("Authorization");
  if (!auth?.startsWith("Bearer ")) return null;
  return auth.slice(7);
}

// --- Handlers ---

async function handleOptimize(
  request: Request,
  env: Env
): Promise<Response> {
  const contentType = request.headers.get("Content-Type") || "";

  if (!contentType.includes("multipart/form-data")) {
    return jsonResponse(
      { error: "Content-Type must be multipart/form-data" },
      400
    );
  }

  const formData = await request.formData();
  const file = formData.get("image") as File | null;

  if (!file) {
    return jsonResponse({ error: "Missing 'image' field" }, 400);
  }

  // Validate file size (max 50MB)
  if (file.size > 50 * 1024 * 1024) {
    return jsonResponse({ error: "File too large (max 50MB)" }, 400);
  }

  // Parse options
  const options: OptimizeRequest = {
    quality: parseIntParam(formData.get("quality") as string, 1, 100),
    format: parseFormatParam(formData.get("format") as string),
    width: parseIntParam(formData.get("width") as string, 1, 10000),
    height: parseIntParam(formData.get("height") as string, 1, 10000),
  };

  // Generate processing ID
  const id = crypto.randomUUID();

  // Store original image in R2
  const imageData = await file.arrayBuffer();
  await env.IMAGES.put(`originals/${id}`, imageData, {
    httpMetadata: { contentType: file.type },
    customMetadata: {
      originalName: file.name,
      options: JSON.stringify(options),
    },
  });

  // In production: enqueue for processing via Cloudflare Queue
  // For now: process inline (suitable for small images)
  // TODO: Implement actual image processing (requires sharp/wasm or external service)

  // Store processing status
  const result: ProcessingResult = {
    id,
    status: "processing",
    originalSize: file.size,
  };

  await env.IMAGES.put(`status/${id}`, JSON.stringify(result));

  // Increment usage counter
  const apiKey = extractApiKey(request)!;
  await incrementUsage(apiKey, env);

  return jsonResponse(
    {
      id,
      status: "processing",
      statusUrl: `/status/${id}`,
      originalSize: file.size,
    },
    202
  );
}

async function handleStatus(id: string, env: Env): Promise<Response> {
  const obj = await env.IMAGES.get(`status/${id}`);
  if (!obj) {
    return jsonResponse({ error: "Not found" }, 404);
  }

  const result = (await obj.json()) as ProcessingResult;
  return jsonResponse(result);
}

async function handleDownload(id: string, env: Env): Promise<Response> {
  const obj = await env.IMAGES.get(`optimized/${id}`);
  if (!obj) {
    return jsonResponse({ error: "Not found or still processing" }, 404);
  }

  const headers = new Headers();
  headers.set(
    "Content-Type",
    obj.httpMetadata?.contentType || "application/octet-stream"
  );
  headers.set(
    "Content-Disposition",
    `attachment; filename="optimized-${id}"`
  );
  Object.entries(corsHeaders).forEach(([k, v]) => headers.set(k, v));

  return new Response(obj.body, { headers });
}

async function handleUsage(apiKey: string, env: Env): Promise<Response> {
  const keyData = (await env.API_KEYS.get(apiKey, "json")) as ApiKeyData | null;
  if (!keyData) {
    return jsonResponse({ error: "Invalid API key" }, 401);
  }

  return jsonResponse({
    tier: keyData.tier,
    monthlyLimit: keyData.monthlyLimit,
    usedThisMonth: keyData.usedThisMonth,
    remaining: keyData.monthlyLimit - keyData.usedThisMonth,
  });
}

// --- Helpers ---

async function incrementUsage(apiKey: string, env: Env): Promise<void> {
  const keyData = (await env.API_KEYS.get(apiKey, "json")) as ApiKeyData | null;
  if (keyData) {
    keyData.usedThisMonth += 1;
    await env.API_KEYS.put(apiKey, JSON.stringify(keyData));
  }
}

function parseIntParam(
  value: string | null,
  min: number,
  max: number
): number | undefined {
  if (!value) return undefined;
  const n = parseInt(value, 10);
  if (isNaN(n) || n < min || n > max) return undefined;
  return n;
}

function parseFormatParam(
  value: string | null
): "png" | "jpeg" | "webp" | undefined {
  if (!value) return undefined;
  const v = value.toLowerCase();
  if (v === "png" || v === "jpeg" || v === "jpg" || v === "webp") {
    return v === "jpg" ? "jpeg" : (v as "png" | "jpeg" | "webp");
  }
  return undefined;
}

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders,
    },
  });
}
