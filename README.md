<div align="center">

# 🤟 IsyaratAI

### Sistem Intelijen Visual Penerjemah Bahasa Isyarat BISINDO Real-Time

[![Flutter](https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![MediaPipe](https://img.shields.io/badge/MediaPipe-Hands-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://mediapipe.dev)
[![ONNX](https://img.shields.io/badge/ONNX-Runtime-7B68EE?style=for-the-badge&logo=onnx&logoColor=white)](https://onnxruntime.ai)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)](https://python.org)

---

Aplikasi mobile berbasis **AI** yang menerjemahkan gestur **Bahasa Isyarat Indonesia (BISINDO)** alfabet **A–Z** menjadi teks secara *real-time* menggunakan kamera perangkat. Dibangun dengan arsitektur *on-device inference* untuk performa rendah latensi tanpa memerlukan koneksi internet.

**Kelompok 2 — Pengolahan Citra Digital 2025/2026**
**Politeknik Negeri Bandung (POLBAN)**

</div>

---

## 📸 Tangkapan Layar

> *Tangkapan layar akan segera ditambahkan.*

<!--
Uncomment dan ganti path gambar setelah screenshot tersedia:

<div align="center">
  <img src="docs/screenshots/home.png" width="200" alt="Home Screen"/>
  <img src="docs/screenshots/camera.png" width="200" alt="Camera AI"/>
  <img src="docs/screenshots/detection.png" width="200" alt="Detection"/>
  <img src="docs/screenshots/history.png" width="200" alt="History"/>
</div>
-->

---

## ✨ Fitur Utama (Key Features)

### 🎯 Deteksi Bahasa Isyarat Real-Time
- Deteksi gestur tangan statis **alfabet A–Z BISINDO** secara langsung melalui kamera.
- Mendukung deteksi **satu tangan** (huruf C, E, I, J, L, O, R, U, V, Z) maupun **dua tangan** (huruf A, B, D, F, G, H, K, M, N, P, Q, S, T, W, X, Y).
- Target latensi inferensi **< 200–300ms** per frame.

### 🦴 Skeleton Tracking (Hand Landmark Visualization)
- Menampilkan **overlay kerangka tangan (skeleton)** 21 titik landmark secara real-time di atas preview kamera.
- Visualisasi titik sendi dan garis penghubung antar jari dengan warna dinamis.

### ✍️ Session-Based Translation (Merangkai Kata/Kalimat)
- Fitur **Hold-to-Register (2 detik)**: Huruf hanya terdaftar jika gestur ditahan secara konstan selama 2 detik, memfilter gestur transisi yang tidak disengaja.
- Circular Progress Indicator sebagai umpan balik visual saat menahan gestur.
- Tombol **Spasi**, **Backspace**, dan **Simpan** untuk merangkai dan mengedit kalimat langsung di layar kamera.
- Panel translasi bersifat **persisten** — tetap tampil meskipun tangan keluar dari frame kamera.

### 🔊 Text-to-Speech (TTS)
- Integrasi **Google Text-to-Speech** untuk membacakan huruf yang terdeteksi secara otomatis (jika diaktifkan).
- Tombol **Putar Suara** di halaman Detail Riwayat untuk membacakan ulang kalimat yang tersimpan.
- Toggle speaker on/off langsung dari layar kamera.

### 📒 Riwayat & Jurnal Terjemahan
- Penyimpanan sesi terjemahan ke **database lokal (Hive)** berbasis sesi (*session-based*), bukan per huruf.
- Halaman **History** dengan fitur pencarian dan filter.
- Halaman **Detail Terjemahan** lengkap dengan informasi waktu, tanggal, dan opsi putar suara.
- Dialog **konfirmasi hapus** untuk mencegah penghapusan tidak sengaja.
- Statistik **Hari Ini** dan **Total Jurnal** di beranda yang terupdate secara reaktif (*real-time*).

### 📷 Manajemen Kamera
- Dukungan kamera **depan** dan **belakang** dengan transisi mulus tanpa crash.
- *Lifecycle management* yang aman: stop stream → dispose → re-initialize → restart stream.
- Indikator loading selama proses perpindahan kamera.

---

## 🛠️ Tech Stack

| Layer | Teknologi | Keterangan |
|---|---|---|
| **Mobile Framework** | Flutter 3.10+ / Dart 3.x | UI cross-platform, dijalankan di Android |
| **Hand Detection** | MediaPipe Hands (via `hand_landmarker`) | Deteksi 21 titik landmark tangan secara real-time |
| **ML Inference** | ONNX Runtime (`onnxruntime`) | Inferensi model klasifikasi gestur on-device |
| **Model Training** | Python (scikit-learn, SVM) | Pelatihan model classifier menggunakan Support Vector Machine |
| **Feature Extraction** | MediaPipe + Custom Pipeline | Ekstraksi 126 fitur landmark (21 titik × 3 koordinat × 2 tangan) |
| **Model Export** | `skl2onnx` | Konversi model scikit-learn (.pkl) ke format ONNX |
| **Local Database** | Hive | Penyimpanan jurnal riwayat terjemahan secara lokal |
| **State Management** | Riverpod | Manajemen state aplikasi Flutter |
| **Text-to-Speech** | `flutter_tts` + Google TTS Engine | Konversi teks hasil terjemahan menjadi suara |
| **Navigation** | GoRouter | Deklaratif routing untuk navigasi antar halaman |

---

## 🏗️ Arsitektur Sistem

```
┌─────────────────────────────────────────────────────────────────┐
│                        📱 Flutter App                           │
│                                                                 │
│  ┌──────────┐    ┌──────────────┐    ┌───────────────────────┐  │
│  │  Camera   │───▶│  MediaPipe   │───▶│  Feature Extraction   │  │
│  │  Stream   │    │  Hand        │    │  (126 Landmark        │  │
│  │  (30fps)  │    │  Landmarker  │    │   Features per frame) │  │
│  └──────────┘    └──────────────┘    └───────────┬───────────┘  │
│                                                   │              │
│                                      ┌────────────▼────────────┐│
│                                      │   ONNX Runtime          ││
│                                      │   (SVM Classifier)      ││
│                                      │   Gesture → Label A-Z   ││
│                                      └────────────┬────────────┘│
│                                                   │              │
│                    ┌──────────────────────────────┼─────────┐   │
│                    │           UI Layer            │         │   │
│                    │                               ▼         │   │
│                    │  ┌─────────┐ ┌───────┐ ┌──────────┐    │   │
│                    │  │Skeleton │ │ Label │ │Hold-to-  │    │   │
│                    │  │Overlay  │ │Display│ │Register  │    │   │
│                    │  └─────────┘ └───────┘ └──────────┘    │   │
│                    │                                         │   │
│                    │  ┌─────────────────────────────────┐    │   │
│                    │  │  Session Panel                  │    │   │
│                    │  │  [Phrase Buffer] [⌫] [⎵] [💾]  │    │   │
│                    │  └─────────────────────────────────┘    │   │
│                    └─────────────────────────────────────────┘   │
│                                                                  │
│  ┌───────────────┐    ┌───────────────┐                         │
│  │  Hive DB      │    │  Google TTS   │                         │
│  │  (History)    │    │  (Speech)     │                         │
│  └───────────────┘    └───────────────┘                         │
└──────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────┐
│                    🧪 Training Pipeline (Python)                 │
│                                                                  │
│  Dataset Gambar ──▶ MediaPipe Extraction ──▶ CSV Landmarks       │
│                         (extract_mediapipe_landmarks.py)         │
│                                                                  │
│  CSV Landmarks ──▶ Train SVM/RF/KNN ──▶ best_model_svm.pkl      │
│                      (train_classifier.py)                       │
│                                                                  │
│  .pkl Model ──▶ skl2onnx ──▶ gesture_model.onnx                 │
│                   (export_model.py)                               │
└──────────────────────────────────────────────────────────────────┘
```

---

## 📋 Prasyarat (Prerequisites)

Sebelum memulai, pastikan Anda sudah menginstal:

| Prasyarat | Versi Minimum | Keterangan |
|---|---|---|
| **Flutter SDK** | 3.10.8+ | [Panduan instalasi Flutter](https://docs.flutter.dev/get-started/install) |
| **Dart SDK** | 3.x | Terinstal otomatis bersama Flutter |
| **Android Studio / Android SDK** | API 24+ (Android 7.0) | Untuk build dan emulator |
| **Perangkat Android Fisik** | Android 7.0+ | **Direkomendasikan** — kamera & TTS tidak berfungsi optimal di emulator |
| **Python** | 3.10+ | Hanya diperlukan untuk melatih ulang model (opsional) |
| **Git** | Terbaru | Untuk clone repositori |

### Prasyarat Opsional (Untuk Re-Training Model)
```
pip install mediapipe scikit-learn pandas numpy matplotlib seaborn joblib skl2onnx
```

---

## 🚀 Instalasi & Cara Menjalankan (Getting Started)

### 1. Clone Repositori

```bash
git clone https://github.com/ErsyaHasby/PCD_Bahasa_Isyarat.git
cd PCD_Bahasa_Isyarat
```

### 2. Install Dependencies Flutter

```bash
cd app
flutter pub get
```

### 3. Hubungkan Perangkat Android

Hubungkan HP Android Anda ke komputer via USB, lalu pastikan perangkat terdeteksi:

```bash
flutter devices
```

### 4. Jalankan Aplikasi

```bash
flutter run
```

> **Catatan:**
> - Untuk performa terbaik, gunakan **perangkat Android fisik**.
> - Pastikan **izin kamera** diberikan saat diminta.
> - Untuk fitur **Text-to-Speech**, pastikan mesin **Google TTS** terinstal dan paket **Bahasa Indonesia** sudah diunduh di pengaturan HP Anda (Settings → Text-to-Speech → Install voice data).

### 5. (Opsional) Persiapan Dataset & Re-Training Model

Jika ingin melatih ulang model, Anda perlu menyiapkan datasetnya terlebih dahulu:

1. **Download Dataset**: Unduh dataset BISINDO dari [Kaggle - Indonesian Sign Language (BISINDO)](https://www.kaggle.com/datasets/agungmrf/indonesian-sign-language-bisindo).
2. **Ekstrak Dataset**: Ekstrak file dataset yang sudah diunduh ke dalam folder `app/assets`. 

> **Catatan:** Folder dataset ini sudah otomatis diabaikan (di-ignore) oleh `.gitignore` sehingga tidak akan membebani repository saat Anda melakukan *push* ke GitHub.

Setelah dataset siap di `app/assets`, Anda bisa melatih ulang model dengan perintah berikut:

```bash
# Dari root direktori proyek
# 1. Ekstraksi landmark dari gambar dataset
python experiments/feature_extraction/extract_mediapipe_landmarks.py

# 2. Latih classifier (SVM, Random Forest, KNN)
python experiments/feature_extraction/train_classifier.py

# 3. Export model terbaik ke format ONNX
python experiments/feature_extraction/export_model.py
```

---

## 📁 Struktur Folder (Project Structure)

```
PCD_Bahasa_Isyarat/
├── app/                                 # 📱 Aplikasi Flutter
│   ├── android/                         # Konfigurasi native Android
│   ├── assets/
│   │   ├── models/
│   │   │   ├── gesture_model.onnx       # Model ONNX (SVM classifier)
│   │   │   ├── labels.json              # Label huruf A-Z
│   │   │   └── svm_params.json          # Parameter normalisasi model
│   │   └── images/                      # Aset gambar aplikasi
│   ├── lib/
│   │   ├── core/
│   │   │   ├── models/                  # Data models (HandData, FeatureSet, dll.)
│   │   │   ├── router/                  # Konfigurasi GoRouter
│   │   │   ├── services/
│   │   │   │   ├── hand_classifier.dart           # Orchestrator deteksi → klasifikasi
│   │   │   │   ├── hand_feature_extractor.dart    # Ekstraksi 126 fitur landmark
│   │   │   │   ├── hand_landmark_detector.dart    # Wrapper MediaPipe Hand Landmarker
│   │   │   │   ├── onnx_classifier_service.dart   # Klasifikasi gestur via ONNX
│   │   │   │   ├── onnx_inference_service.dart     # Low-level ONNX Runtime bridge
│   │   │   │   ├── pcd_frame_processor.dart       # Prosesor frame kamera
│   │   │   │   ├── pcd_pipeline.dart              # Pipeline PCD (preprocessing)
│   │   │   │   └── tts_service.dart               # Layanan Text-to-Speech
│   │   │   └── theme/                   # AppTheme (warna, tipografi, gradien)
│   │   ├── data/
│   │   │   └── local/
│   │   │       ├── journal_repository.dart   # CRUD operasi jurnal (Hive)
│   │   │       └── models/                   # TranslationEntry model
│   │   ├── features/
│   │   │   ├── camera/                  # 📷 Layar kamera AI & deteksi
│   │   │   ├── history/                 # 📒 Riwayat terjemahan
│   │   │   ├── home/                    # 🏠 Beranda & statistik
│   │   │   ├── onboarding/              # 👋 Layar onboarding
│   │   │   └── splash/                  # ⚡ Splash screen
│   │   └── main.dart                    # Entry point aplikasi
│   └── pubspec.yaml                     # Dependencies Flutter
│
├── experiments/                          # 🧪 Pipeline Training & Eksperimen
│   ├── feature_extraction/
│   │   ├── extract_mediapipe_landmarks.py   # Ekstraksi landmark dari gambar
│   │   ├── train_classifier.py              # Training SVM/RF/KNN
│   │   ├── export_model.py                  # Konversi .pkl → .onnx
│   │   ├── dataset_landmarks.csv            # Dataset hasil ekstraksi
│   │   └── models/
│   │       ├── best_model_svm.pkl           # Model SVM terbaik (.pkl)
│   │       ├── label_encoder.pkl            # Label encoder
│   │       └── confusion_matrix_svm.png     # Visualisasi confusion matrix
│   ├── benchmark/                       # Benchmark performa
│   ├── mediapipe/                       # Eksperimen MediaPipe
│   └── preprocessing/                   # Eksperimen preprocessing
│
├── PRD.md                               # Product Requirements Document
├── PROPOSAL.md                          # Proposal proyek
├── TASK_BREAKDOWN.md                    # Pembagian tugas tim
├── GIT_WORKFLOW.md                      # Panduan workflow Git
└── README.md                            # 📖 Anda sedang membaca ini
```

---

## 👥 Anggota Tim / Kontributor

<div align="center">

| No | Nama | Peran |
|:---:|---|---|
| 1 | **Ersya Hasby Satria (072)** | Camera + Pre-Processing (PCD) + Performance Optimization |
| 2 | **Alexandrio Vega Bonito (067)** | MediaPipe Integration + Feature Extraction |
| 3 | **Muhammad Brata Hadinata (082)** | Machine Learning Training (Sklearn) + Model Export + Inference + Integrasi Keseluruhan & Problem Solving |
| 4 | **Varian Abidarma Syuhada (091)** | UI/UX + History/Local DB + Hasil Integrasi |

</div>


---

<div align="center">

**Kelompok 2 — Pengolahan Citra Digital (PCD) 2025/2026**

**Politeknik Negeri Bandung (POLBAN)**

Teknik Informatika

---

<sub>Dibuat dengan ❤️ menggunakan Flutter, MediaPipe, dan ONNX Runtime</sub>

</div>
