"""
=======================================================================
EKSPERIMEN 1: Color Conversion — YUV / BGRA → RGB
=======================================================================
Kelompok 2 — PCD Tugas Besar 2025/2026
Topik: Sistem Intelijen Visual Penerjemah Bahasa Isyarat Real-Time

Tujuan:
    Membuktikan pentingnya konversi warna yang benar sebelum inferensi
    model AI. Membandingkan YUV→RGB, BGRA→RGB, dan Grayscale.

Pipeline:
    Frame Kamera (YUV/BGRA) → [COLOR CONVERSION] → RGB → Center Crop → ...
=======================================================================
"""

import cv2
import numpy as np
import matplotlib.pyplot as plt
import os, sys

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "output", "color_conversion")
os.makedirs(OUTPUT_DIR, exist_ok=True)
SAMPLE_IMAGE_PATH = os.path.join(os.path.dirname(__file__), "sample_hand.jpg")


# ── Utilitas ────────────────────────────────────────────────────────────

def load_or_create_sample(path: str) -> np.ndarray:
    if os.path.exists(path):
        img = cv2.imread(path)
        print(f"[✓] Gambar dimuat: {path}")
        return img
    print("[!] Membuat gambar synthetic...")
    return _make_synthetic(path)


def _make_synthetic(save_path: str, w=640, h=480) -> np.ndarray:
    frame = np.zeros((h, w, 3), dtype=np.uint8)
    for y in range(h):
        v = int(30 + (y / h) * 80)
        frame[y, :] = [v, v, v]
    skin = (120, 170, 210)
    cx, cy, r = w // 2, h // 2, 90
    cv2.ellipse(frame, (cx, cy), (r, int(r * 1.3)), 0, 0, 360, skin, -1)
    for fx, fy in [(cx-60, cy-r-10), (cx-20, cy-r-25), (cx+20, cy-r-30), (cx+55, cy-r-20)]:
        cv2.ellipse(frame, (fx, fy), (18, 50), 0, 0, 360, skin, -1)
    noise = np.random.randint(-15, 15, frame.shape, dtype=np.int16)
    frame = np.clip(frame.astype(np.int16) + noise, 0, 255).astype(np.uint8)
    cv2.imwrite(save_path, frame)
    print(f"[✓] Synthetic disimpan: {save_path}")
    return frame


# ── Konversi ────────────────────────────────────────────────────────────

def bgr_to_rgb(bgr): return cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)

def yuv_to_rgb(bgr):
    """Simulasi: BGR → YUV (kamera Android) → RGB (Background Isolate Flutter)."""
    yuv = cv2.cvtColor(bgr, cv2.COLOR_BGR2YUV)
    return cv2.cvtColor(yuv, cv2.COLOR_YUV2RGB)

def bgra_to_rgb(bgr):
    """Simulasi: BGR → BGRA (kamera iOS) → RGB (Background Isolate Flutter)."""
    bgra = cv2.cvtColor(bgr, cv2.COLOR_BGR2BGRA)
    return cv2.cvtColor(bgra, cv2.COLOR_BGRA2RGB)

def to_gray_rgb(bgr):
    """Grayscale (TIDAK direkomendasikan — kehilangan info warna kulit)."""
    gray = cv2.cvtColor(bgr, cv2.COLOR_BGR2GRAY)
    return cv2.cvtColor(gray, cv2.COLOR_GRAY2RGB)


# ── Metrik ──────────────────────────────────────────────────────────────

def psnr(ref: np.ndarray, img: np.ndarray) -> float:
    mse = np.mean((ref.astype(float) - img.astype(float)) ** 2)
    return round(20 * np.log10(255.0 / np.sqrt(mse)), 2) if mse else float('inf')


# ── Visualisasi ─────────────────────────────────────────────────────────

def plot_comparison(images: dict, ref: np.ndarray):
    n = len(images)
    fig, axes = plt.subplots(1, n, figsize=(5 * n, 4))
    fig.suptitle("Perbandingan Format Konversi Warna — Kelompok 2", fontsize=12, fontweight='bold')
    for ax, (label, img) in zip(axes, images.items()):
        ax.imshow(img)
        score = psnr(ref, img)
        ax.set_title(label, fontsize=9, fontweight='bold')
        ax.set_xlabel(f"PSNR vs Original: {score} dB", fontsize=8)
        ax.axis('off')
    plt.tight_layout()
    out = os.path.join(OUTPUT_DIR, "color_comparison.png")
    plt.savefig(out, dpi=150, bbox_inches='tight')
    print(f"  [✓] Disimpan: {out}")
    plt.show()


def plot_histograms(images: dict):
    n = len(images)
    fig, axes = plt.subplots(n, 3, figsize=(12, 3 * n))
    fig.suptitle("Histogram Distribusi Warna — Kelompok 2", fontsize=12, fontweight='bold')
    for row, (label, img) in enumerate(images.items()):
        for col, (color, ch) in enumerate(zip(['red', 'green', 'blue'], ['R', 'G', 'B'])):
            ax = axes[row][col]
            hist = cv2.calcHist([img], [col], None, [256], [0, 256])
            ax.plot(hist, color=color, linewidth=1.2)
            ax.fill_between(range(256), hist.flatten(), alpha=0.3, color=color)
            ax.set_title(f"{label} — Ch.{ch}", fontsize=8)
            ax.set_xlim([0, 256])
            ax.grid(True, alpha=0.3)
    plt.tight_layout()
    out = os.path.join(OUTPUT_DIR, "histograms.png")
    plt.savefig(out, dpi=150, bbox_inches='tight')
    print(f"  [✓] Disimpan: {out}")
    plt.show()


# ── Main ────────────────────────────────────────────────────────────────

def main():
    print("╔══════════════════════════════════════════════╗")
    print("║  PCD Tubes Kel.2 — Eksperimen Color Conv.   ║")
    print("╚══════════════════════════════════════════════╝\n")

    path = sys.argv[1] if len(sys.argv) > 1 else SAMPLE_IMAGE_PATH
    bgr  = load_or_create_sample(path)
    ref  = bgr_to_rgb(bgr)

    images = {
        "Original (BGR→RGB)":     ref,
        "YUV420→RGB (Android)":   yuv_to_rgb(bgr),
        "BGRA8888→RGB (iOS)":     bgra_to_rgb(bgr),
        "Grayscale ❌":            to_gray_rgb(bgr),
    }

    print(f"\n{'Format':<26} {'Mean R':>8} {'Mean G':>8} {'Mean B':>8} {'PSNR':>10}")
    print("-" * 65)
    for label, img in images.items():
        mr, mg, mb = np.mean(img[:,:,0]), np.mean(img[:,:,1]), np.mean(img[:,:,2])
        p = psnr(ref, img)
        print(f"{label:<26} {mr:>8.2f} {mg:>8.2f} {mb:>8.2f} {str(p)+' dB':>10}")

    plot_comparison(images, ref)
    plot_histograms(images)

    print("\n[SELESAI] Konklusi: Gunakan RGB (bukan Grayscale).")
    print("          Info warna kulit tangan penting untuk akurasi deteksi.")

if __name__ == "__main__":
    main()
