"""imgcrush Cloud API — Python SDK example.

pip install requests
"""

import os
import time
import requests

API_KEY = os.environ.get("IMGCRUSH_API_KEY", "your-api-key")
BASE_URL = "https://api.imgcrush.dev/v1"

HEADERS = {"X-API-Key": API_KEY}


def optimize_image(
    file_path: str,
    *,
    format: str | None = None,
    quality: int | None = None,
    resize: str | None = None,
    smart_quality: bool = False,
    keep_metadata: bool = False,
) -> tuple[bytes, dict]:
    """Optimize a single image. Returns (data, stats)."""
    with open(file_path, "rb") as f:
        files = {"file": (os.path.basename(file_path), f)}
        data = {}
        if format:
            data["format"] = format
        if quality:
            data["quality"] = str(quality)
        if resize:
            data["resize"] = resize
        if smart_quality:
            data["smart_quality"] = "true"
        if keep_metadata:
            data["keep_metadata"] = "true"

        resp = requests.post(
            f"{BASE_URL}/optimize", headers=HEADERS, files=files, data=data
        )

    resp.raise_for_status()

    stats = {
        "original_size": int(resp.headers.get("X-Original-Size", 0)),
        "optimized_size": int(resp.headers.get("X-Optimized-Size", 0)),
        "savings_percent": float(resp.headers.get("X-Savings-Percent", 0)),
        "processing_time_ms": float(resp.headers.get("X-Processing-Time-Ms", 0)),
    }
    return resp.content, stats


def batch_optimize(
    file_paths: list[str],
    *,
    format: str | None = None,
    quality: int | None = None,
) -> dict:
    """Submit a batch optimization job."""
    files = [("files", (os.path.basename(fp), open(fp, "rb"))) for fp in file_paths]
    data = {}
    if format:
        data["format"] = format
    if quality:
        data["quality"] = str(quality)

    resp = requests.post(f"{BASE_URL}/batch", headers=HEADERS, files=files, data=data)
    for _, f in files:
        f[1].close()

    resp.raise_for_status()
    return resp.json()


def poll_batch_job(job_id: str, interval: float = 2.0) -> dict:
    """Poll a batch job until completion."""
    while True:
        resp = requests.get(f"{BASE_URL}/batch/{job_id}", headers=HEADERS)
        resp.raise_for_status()
        job = resp.json()
        print(f"Job {job_id}: {job['status']} ({job.get('completed', 0)}/{job['total']})")

        if job["status"] in ("completed", "failed"):
            return job
        time.sleep(interval)


def download_batch_results(job_id: str, output_path: str = "results.zip") -> str:
    """Download batch results as ZIP."""
    resp = requests.get(f"{BASE_URL}/batch/{job_id}/download", headers=HEADERS)
    resp.raise_for_status()
    with open(output_path, "wb") as f:
        f.write(resp.content)
    return output_path


def get_usage(period: str = "month") -> dict:
    """Get API usage statistics."""
    resp = requests.get(f"{BASE_URL}/usage", headers=HEADERS, params={"period": period})
    resp.raise_for_status()
    return resp.json()


# --- Example usage ---

if __name__ == "__main__":
    # Single image
    data, stats = optimize_image("photo.jpg", format="webp", quality=85)
    with open("photo.webp", "wb") as f:
        f.write(data)
    print(f"Saved {stats['savings_percent']}% in {stats['processing_time_ms']}ms")

    # Smart quality
    data, stats = optimize_image("photo.jpg", smart_quality=True, keep_metadata=True)
    with open("smart.jpg", "wb") as f:
        f.write(data)
    print(f"Smart quality: {stats['savings_percent']}% savings")

    # Batch
    job = batch_optimize(["img1.jpg", "img2.png"], quality=80)
    result = poll_batch_job(job["id"])
    if result["status"] == "completed":
        download_batch_results(job["id"])
        print("Downloaded results.zip")

    # Usage
    usage = get_usage()
    print(f"This month: {usage['images_processed']} images, {usage['bytes_saved']} bytes saved")
