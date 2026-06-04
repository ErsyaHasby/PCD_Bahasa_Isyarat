"""
Data Collector — A-Z Gesture Dataset.

Mengumpulkan data gesture A-Z (1 tangan & 2 tangan) via webcam,
mengekstrak fitur, dan menyimpan ke CSV/NPY.

Cocok untuk training scikit-learn (Brata).

Usage:
    python data_collector.py --label A --output data/
    python data_collector.py --label A --two-hand --output data/
    python data_collector.py --list  # lihat daftar label tersimpan
"""

import argparse
import csv
import os
import sys
import time
from pathlib import Path

import cv2
import mediapipe as mp
import numpy as np

from feature_extractor import extract_all

# MediaPipe setup
mp_hands = mp.solutions.hands
mp_draw = mp.solutions.drawing_utils
mp_draw_styles = mp.solutions.drawing_styles

COLLECTING = False
SAMPLE_COUNT = 0


def _normalize_landmarks(hand_landmarks, w, h):
    """Konversi MediaPipe landmarks ke list of (x, y, z) relatif."""
    return [(lm.x * w, lm.y * h, lm.z) for lm in hand_landmarks.landmark]


def main():
    parser = argparse.ArgumentParser(description='Koleksi data gesture A-Z')
    parser.add_argument('--label', type=str, help='Label gesture (A-Z)')
    parser.add_argument('--two-hand', action='store_true',
                        help='Gesture membutuhkan 2 tangan')
    parser.add_argument('--output', type=str, default='data',
                        help='Folder output')
    parser.add_argument('--samples', type=int, default=50,
                        help='Jumlah sampel per label')
    parser.add_argument('--list', action='store_true',
                        help='Lihat daftar label yang sudah ada')
    args = parser.parse_args()

    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)

    csv_path = output_dir / 'dataset.csv'

    if args.list:
        if csv_path.exists():
            with open(csv_path, 'r') as f:
                reader = csv.reader(f)
                labels = sorted(set(row[0] for i, row in enumerate(reader)
                                    if i > 0 or row[0] != 'label'))
                print(f'Label terkumpul ({len(labels)}): {", ".join(labels)}')
        else:
            print('Belum ada dataset.')
        return

    if not args.label:
        print('Error: --label wajib diisi (A-Z)')
        sys.exit(1)

    label = args.label.upper()
    target = args.samples
    csv_exists = csv_path.exists()

    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print('Error: Tidak bisa buka webcam')
        sys.exit(1)

    with mp_hands.Hands(
        static_image_mode=False,
        max_num_hands=2,
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5,
    ) as hands:
        global COLLECTING, SAMPLE_COUNT
        COLLECTING = False
        SAMPLE_COUNT = 0
        frame_count = 0

        print(f'\n=== Koleksi data untuk label "{label}" ===')
        print(f'Target: {target} sampel')
        print(f'Mode: {"2 tangan" if args.two_hand else "1 tangan"}')
        print('Tekan [SPACE] untuk mulai/kumpulkan')
        print('Tekan [R] untuk reset sampel label ini')
        print('Tekan [ESC] untuk keluar\n')

        while True:
            success, frame = cap.read()
            if not success:
                break

            frame = cv2.flip(frame, 1)
            h, w, _ = frame.shape
            rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
            result = hands.process(rgb)

            # Info overlay
            info_y = 30
            cv2.putText(frame, f'Label: {label}  Mode: {"2H" if args.two_hand else "1H"}',
                        (10, info_y), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (200, 200, 200), 1)
            cv2.putText(frame, f'Sampel: {SAMPLE_COUNT}/{target}',
                        (10, info_y + 25), cv2.FONT_HERSHEY_SIMPLEX, 0.6,
                        (0, 255, 0) if COLLECTING else (100, 100, 100), 1)
            cv2.putText(frame, f'{"MENGUMPULKAN..." if COLLECTING else "TEKAN SPACE"}',
                        (10, info_y + 50), cv2.FONT_HERSHEY_SIMPLEX, 0.5,
                        (0, 255, 255) if COLLECTING else (150, 150, 150), 1)

            # Draw landmarks
            detected_hands = []
            if result.multi_hand_landmarks:
                for hl in result.multi_hand_landmarks:
                    mp_draw.draw_landmarks(
                        frame, hl, mp_hands.HAND_CONNECTIONS,
                        mp_draw_styles.get_default_hand_landmarks_style(),
                        mp_draw_styles.get_default_hand_connections_style())
                    detected_hands.append(hl)

            # Collect sample when SPACE is held
            if COLLECTING and SAMPLE_COUNT < target and len(detected_hands) > 0:
                frame_count += 1
                if frame_count % 5 == 0:  # every 5 frames = ~10 Hz
                    raw_hands = [
                        _normalize_landmarks(hl, w, h)
                        for hl in detected_hands[:2]
                    ]
                    features = extract_all(raw_hands)

                    # Simpan ke CSV
                    row = [label, args.two_hand, features['hand_count']]
                    row.extend(features['combined'].tolist())
                    with open(csv_path, 'a', newline='') as f:
                        writer = csv.writer(f)
                        if not csv_exists:
                            header = ['label', 'two_hand', 'hand_count']
                            header.extend([f'f{i}' for i in range(
                                len(features['combined']))])
                            writer.writerow(header)
                            csv_exists = True
                        writer.writerow(row)

                    SAMPLE_COUNT += 1
                    print(f'  Sample {SAMPLE_COUNT}/{target} collected', end='\r')

            # Check completion
            if SAMPLE_COUNT >= target:
                cv2.putText(frame, 'SELESAI!', (w//2-80, h//2),
                            cv2.FONT_HERSHEY_SIMPLEX, 1.5, (0, 255, 0), 3)
                COLLECTING = False

            cv2.imshow('Data Collector - BISINDO', frame)
            key = cv2.waitKey(1) & 0xFF

            if key == 27:  # ESC
                break
            elif key == 32:  # SPACE
                if SAMPLE_COUNT >= target:
                    print(f'\nSudah mencapai target {target}. Tekan ESC.')
                else:
                    COLLECTING = not COLLECTING
                    frame_count = 0
                    status = 'MULAI' if COLLECTING else 'STOP'
                    print(f'\n{status} koleksi untuk label {label}')
            elif key == ord('r') or key == ord('R'):
                # Hapus sampel label ini dari CSV
                if csv_path.exists():
                    rows = []
                    with open(csv_path, 'r') as f:
                        reader = csv.reader(f)
                        header = next(reader)
                        rows.append(header)
                        kept = 0
                        for row in reader:
                            if row[0] != label:
                                rows.append(row)
                                kept += 1
                    with open(csv_path, 'w', newline='') as f:
                        writer = csv.writer(f)
                        writer.writerows(rows)
                    SAMPLE_COUNT = 0
                    print(f'\nReset sampel label {label}. Tersimpan {kept} baris.')

    cap.release()
    cv2.destroyAllWindows()

    # Buat NPY juga untuk training
    if csv_path.exists():
        print(f'\nDataset tersimpan di: {csv_path}')
        print(f'Total sampel terkumpul untuk {label}: {SAMPLE_COUNT}')

        # Convert CSV ke NPY untuk training
        import pandas as pd
        df = pd.read_csv(csv_path)
        X = df.filter(like='f').values.astype(np.float32)
        y = df['label'].values
        np.save(output_dir / 'X.npy', X)
        np.save(output_dir / 'y.npy', y)
        print(f'X.npy: {X.shape}')
        print(f'y.npy: {y.shape}')
        print(f'Label: {np.unique(y)}')


if __name__ == '__main__':
    main()
