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
import sys
import importlib.util

# Load feature_extractor.py directly by path to avoid collision with official 'mediapipe' package
feat_ext_path = Path(__file__).parent.parent / "mediapipe" / "feature_extractor.py"
spec = importlib.util.spec_from_file_location("feature_extractor", feat_ext_path)
feature_extractor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(feature_extractor)
extract_all = feature_extractor.extract_all

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

    # Extract up to 2 hands
    hands_list = []
    for hand_landmarks in results.multi_hand_landmarks[:2]:
        landmarks = []
        for landmark in hand_landmarks.landmark:
            landmarks.append([landmark.x, landmark.y, landmark.z])
        hands_list.append(landmarks)

    return hands_list, len(results.multi_hand_landmarks)


    pass


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
            # Extract landmarks (Original Image)
            hands, hand_count = extract_landmarks_from_image(image_path)

            if hands is not None and len(hands) > 0:
                features = extract_all(hands, use_z=True)
                flattened = features['landmark_vector'].tolist()
                data_rows.append([label] + flattened)
            else:
                missing_files.append(str(image_path))

            # DATA AUGMENTATION: Extract landmarks (Mirrored Image)
            # Ini sangat penting untuk mengatasi kamera depan yang memantulkan gambar (Mirroring)
            image = cv2.imread(str(image_path))
            if image is not None:
                image_flipped = cv2.flip(image, 1)
                
                # Convert BGR ke RGB untuk MediaPipe
                image_rgb = cv2.cvtColor(image_flipped, cv2.COLOR_BGR2RGB)
                with mp_hands.Hands(static_image_mode=True, max_num_hands=2, min_detection_confidence=0.5) as hands_processor:
                    results = hands_processor.process(image_rgb)
                    
                if results.multi_hand_landmarks:
                    hands_list = []
                    for hand_landmarks in results.multi_hand_landmarks[:2]:
                        landmarks = []
                        for landmark in hand_landmarks.landmark:
                            landmarks.append([landmark.x, landmark.y, landmark.z])
                        hands_list.append(landmarks)
                    
                    features_flipped = extract_all(hands_list, use_z=True)
                    flattened_flipped = features_flipped['landmark_vector'].tolist()
                    # Simpan data yang di-flip sebagai label yang sama
                    data_rows.append([label] + flattened_flipped)

    # Buat DataFrame dan simpan ke CSV
    print(f"\nMenyimpan {len(data_rows)} sampel ke {OUTPUT_CSV}")

    # Buat header: label, x0, y0, z0, ..., x41, y41, z41
    header = ["label"]
    for i in range(42):
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
