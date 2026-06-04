"""
=======================================================================
EKSPERIMEN: Extract MediaPipe Landmarks dari Dataset BISINDO
=======================================================================
Tujuan: Extract 21 landmarks per tangan dari gambar dataset
Format output: CSV dengan 64 kolom (label + x0,y0,z0 ... x20,y20,z20)
Normalisasi: Relatif ke wrist, skala wrist→middle finger MCP
=======================================================================
"""

import cv2
import numpy as np
import pandas as pd
from pathlib import Path
from tqdm import tqdm
import os

# Import MediaPipe dengan cara yang kompatibel untuk versi terbaru
try:
    import mediapipe as mp

    mp_hands = mp.solutions.hands
    mp_drawing = mp.solutions.drawing_utils
except AttributeError:
    # Fallback untuk versi MediaPipe terbaru
    from mediapipe.python.solutions import hands as mp_hands_module
    from mediapipe.python.solutions import drawing_utils as mp_drawing_module

    mp_hands = mp_hands_module
    mp_drawing = mp_drawing_module

# Konfigurasi paths
DATASET_DIR = Path("app/assets/bisindo")
IMAGES_DIR = DATASET_DIR / "images" / "train"
OUTPUT_CSV = Path("experiments/feature_extraction/dataset_landmarks.csv")
MISSING_LOG = Path("experiments/feature_extraction/missing_hands_log.txt")

# Buat direktori output jika belum ada
OUTPUT_CSV.parent.mkdir(parents=True, exist_ok=True)


def extract_landmarks_from_image(image_path: str):
    """
    Extract 21 landmarks dari satu gambar menggunakan MediaPipe Hands.

    Args:
        image_path: Path ke file gambar

    Returns:
        - landmarks: numpy array (21, 3) berisi [x, y, z] normalized
        - hand_count: jumlah tangan terdeteksi (1 atau 2)
        - None jika tidak ada tangan terdeteksi
    """
    # Baca gambar
    image = cv2.imread(str(image_path))
    if image is None:
        return None, 0

    # Convert BGR ke RGB untuk MediaPipe
    image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    # Process dengan MediaPipe Hands
    with mp_hands.Hands(
        static_image_mode=True, max_num_hands=2, min_detection_confidence=0.5
    ) as hands:
        results = hands.process(image_rgb)

    # Jika tidak ada tangan terdeteksi
    if not results.multi_hand_landmarks:
        return None, 0

    # Ambil landmarks dari tangan pertama (dominant hand)
    # Untuk MVP, kita fokus pada 1 tangan dulu
    hand_landmarks = results.multi_hand_landmarks[0]

    # Extract 21 landmarks
    landmarks = []
    for landmark in hand_landmarks.landmark:
        landmarks.append([landmark.x, landmark.y, landmark.z])

    return np.array(landmarks), len(results.multi_hand_landmarks)


def normalize_landmarks(landmarks: np.ndarray):
    """
    Normalisasi landmarks sesuai PRD Section 8.2:
    - Titik acuan: wrist (landmark 0)
    - Skala: jarak wrist ke middle finger MCP (landmark 9)
    - Normalisasi: (x, y, z) relatif terhadap wrist dan dibagi skala

    Args:
        landmarks: numpy array (21, 3) berisi [x, y, z] raw dari MediaPipe

    Returns:
        normalized: numpy array (21, 3) berisi [x, y, z] ternormalisasi
    """
    # Wrist adalah landmark 0
    wrist = landmarks[0]

    # Middle finger MCP adalah landmark 9
    middle_mcp = landmarks[9]

    # Hitung skala: jarak Euclidean wrist ke middle finger MCP
    # Ini merepresentasikan ukuran tangan untuk normalisasi
    scale = np.sqrt(
        (middle_mcp[0] - wrist[0]) ** 2
        + (middle_mcp[1] - wrist[1]) ** 2
        + (middle_mcp[2] - wrist[2]) ** 2
    )

    # Avoid division by zero
    if scale == 0:
        scale = 1.0

    # Normalisasi: (landmark - wrist) / scale
    # Ini membuat posisi relatif terhadap wrist dan dinormalisasi oleh ukuran tangan
    normalized = (landmarks - wrist) / scale

    return normalized


def flatten_landmarks(landmarks: np.ndarray):
    """
    Flatten array (21, 3) menjadi vektor 63 nilai.
    Format: [x0, y0, z0, x1, y1, z1, ..., x20, y20, z20]

    Args:
        landmarks: numpy array (21, 3) ternormalisasi

    Returns:
        flattened: list 63 nilai
    """
    return landmarks.flatten().tolist()


def process_dataset():
    """
    Main function untuk process seluruh dataset.
    Loop semua folder A-Z, extract landmarks, normalisasi, dan simpan ke CSV.
    """
    # Siapkan list untuk menyimpan data
    data_rows = []
    missing_files = []

    # Loop semua folder A-Z
    label_folders = sorted([d for d in IMAGES_DIR.iterdir() if d.is_dir()])

    print(f"Menemukan {len(label_folders)} folder label")

    # Progress bar untuk outer loop (per label)
    for label_folder in tqdm(label_folders, desc="Processing labels"):
        label = label_folder.name

        # Skip jika bukan huruf A-Z
        if not label.isalpha() or len(label) != 1:
            continue

        # Cari semua gambar di folder ini
        image_files = sorted(label_folder.glob("*.jpg")) + sorted(
            label_folder.glob("*.png")
        )

        # Progress bar untuk inner loop (per gambar)
        for image_path in tqdm(image_files, desc=f"  {label}", leave=False):
            # Extract landmarks
            landmarks, hand_count = extract_landmarks_from_image(image_path)

            # Skip jika tidak ada tangan terdeteksi
            if landmarks is None:
                missing_files.append(str(image_path))
                continue

            # Normalisasi landmarks
            normalized = normalize_landmarks(landmarks)

            # Flatten ke 63 nilai
            flattened = flatten_landmarks(normalized)

            # Tambahkan label di depan
            row = [label] + flattened
            data_rows.append(row)

    # Buat DataFrame dan simpan ke CSV
    print(f"\nMenyimpan {len(data_rows)} sampel ke {OUTPUT_CSV}")

    # Buat header: label, x0, y0, z0, ..., x20, y20, z20
    header = ["label"]
    for i in range(21):
        header.extend([f"x{i}", f"y{i}", f"z{i}"])

    df = pd.DataFrame(data_rows, columns=header)
    df.to_csv(OUTPUT_CSV, index=False)

    # Log file yang gagal
    print(f"Menyimpan {len(missing_files)} file yang gagal ke {MISSING_LOG}")
    with open(MISSING_LOG, "w") as f:
        for file_path in missing_files:
            f.write(f"{file_path}\n")

    print(f"\n✓ Selesai!")
    print(f"  - Total sampel berhasil: {len(data_rows)}")
    print(f"  - Total file gagal: {len(missing_files)}")
    print(f"  - Output CSV: {OUTPUT_CSV}")
    print(f"  - Missing log: {MISSING_LOG}")

    # Tampilkan distribusi per kelas
    print("\nDistribusi sampel per kelas:")
    print(df["label"].value_counts().sort_index())


if __name__ == "__main__":
    print("╔══════════════════════════════════════════════════════════════════╗")
    print("║  Extract MediaPipe Landmarks dari Dataset BISINDO               ║")
    print("╚══════════════════════════════════════════════════════════════════╝\n")

    process_dataset()
