# 🤟 Sistem Intelijen Visual Penerjemah Bahasa Isyarat Real-Time

<div align="center">

![Banner](docs/assets/banner.png)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![TFLite](https://img.shields.io/badge/TFLite-Inference-FF6F00?style=for-the-badge&logo=tensorflow)](https://www.tensorflow.org/lite)
[![MediaPipe](https://img.shields.io/badge/MediaPipe-Hand%20Tracking-4285F4?style=for-the-badge&logo=google)](https://mediapipe.dev)
[![MongoDB](https://img.shields.io/badge/MongoDB-Cloud%20Sync-47A248?style=for-the-badge&logo=mongodb)](https://www.mongodb.com)

**Tugas Besar — Pengolahan Citra Digital**  
Program Studi D3 Teknik Informatika | Politeknik Negeri Bandung  
Tahun Akademik 2025/2026

</div>

---

## 👥 Tim Pengembang — Kelompok 2

| No | Nama | NIM |
|:--:|------|:---:|
| 1 | Alexandrio Vega Bonito | 241511067 |
| 2 | Ersya Hasby Satria | 241511072 |
| 3 | Muhammad Brata Hadinata | 241511082 |
| 4 | Varian Abidarma Syuhada | 241511081 |

---

## 📋 Daftar Isi

- [Latar Belakang & Masalah](#-latar-belakang--masalah)
- [Solusi yang Diusulkan](#-solusi-yang-diusulkan)
- [Inheritance dari Proyek Sebelumnya](#-inheritance-dari-proyek-sebelumnya)
- [Pipeline PCD & ML](#-pipeline-pcd--ml)
- [Arsitektur Sistem](#-arsitektur-sistem)
- [Struktur Proyek](#-struktur-proyek)
- [Cara Menjalankan](#-cara-menjalankan)

---

## 🧩 Bagian 1: Ideation & Problem-Solution Fit

### 🌐 Domain & Masalah

| Aspek | Detail |
|-------|--------|
| **Domain** | Aksesibilitas / Komunikasi Sosial |
| **Target Pengguna** | Teman Tuli (pengguna Bahasa Isyarat Indonesia / BISINDO) & masyarakat umum |
| **Masalah Utama** | Keterbatasan komunikasi dua arah antara pengguna bahasa isyarat dengan masyarakat yang tidak memahami isyarat |

### 😤 Problem Statement

> Teman Tuli menghadapi kesulitan komunikasi yang signifikan dalam interaksi sehari-hari karena tidak semua orang memahami bahasa isyarat. Mencari penerjemah manusia secara spontan hampir mustahil dilakukan, sehingga menghambat kemandirian dan inklusi sosial mereka.

### ✅ Solusi yang Diusulkan

Membangun aplikasi mobile berbasis Flutter yang memanfaatkan kamera perangkat untuk:
1. **Mendeteksi** gestur tangan secara real-time menggunakan model AI (MediaPipe / TFLite)
2. **Menerjemahkan** isyarat menjadi teks dan suara yang dapat dipahami masyarakat umum
3. **Mencatat** riwayat terjemahan dalam "Buku Jurnal Terjemahan" yang tersinkronisasi ke cloud

---

## ♻️ Inheritance dari Proyek Sebelumnya (Proyek 4)

Sistem ini mewarisi dan mentransformasi komponen dari proyek Logbook sebelumnya:

```
Proyek 4 (Logbook App)          Proyek 5 (Sign Language Translator)
─────────────────────────────────────────────────────────────────────
Hive (database lokal)      →    Menyimpan cache terjemahan & setting
MongoDB (cloud sync)       →    Sinkronisasi riwayat terjemahan
Modul Logbook              →    "Buku Jurnal Terjemahan" (History Log)
                                  └─ Frasa yang diterjemahkan + timestamp
```

Setiap entri jurnal terjemahan akan menyimpan:
- Teks hasil terjemahan
- Waktu kejadian (timestamp)
- Skor kepercayaan (confidence score) dari model AI
- Thumbnail frame gestur (opsional)

---

## 🔬 Bagian 2: Deep Dive PCD & ML Pipeline

### 🎨 Target Sensorik

| Sensor | Data | Keterangan |
|--------|------|------------|
| Kamera Depan | Frame video real-time | Menangkap gestur tangan pengguna |
| Hand Landmarks | 21 titik per tangan | Ujung jari, ruas jari, telapak tangan, pergelangan |
| Pose Estimation | Titik lengan atas | Konteks posisi tangan relatif terhadap tubuh |

---

### ⚙️ Alur Pre-Processing PCD (Sebelum Inference)

```
┌──────────────────────────────────────────────────────────────┐
│                     ALUR PCD PIPELINE                        │
└──────────────────────────────────────────────────────────────┘

  📷 Frame Kamera (YUV420 / BGRA8888)
          │
          ▼
  ┌───────────────────┐
  │  1. COLOR CONVERSION  │  YUV/BGRA → RGB
  │                   │  (Model AI dilatih dengan RGB)
  └────────┬──────────┘
           │
           ▼
  ┌───────────────────┐
  │  2. CENTER CROP   │  16:9 (HP) → 1:1 (Square)
  │                   │  Contoh: 1080×1920 → crop tengah 1080×1080
  │                   │  ⚠️ WAJIB sebelum resize agar tidak distorted
  └────────┬──────────┘
           │
           ▼
  ┌───────────────────┐
  │  3. RESIZE        │  1080×1080 → 224×224
  │                   │  (Sesuai input size model TFLite)
  └────────┬──────────┘
           │
           ▼
  ┌───────────────────┐
  │  4. NORMALISASI   │  pixel_value / 255.0
  │                   │  [0, 255] uint8 → [0.0, 1.0] Float32
  └────────┬──────────┘
           │
           ▼
  ┌───────────────────┐
  │  5. INFERENCE     │  TFLite interpreter.run()
  │                   │  Output: koordinat landmarks + label isyarat
  └────────┬──────────┘
           │
           ▼
  ┌───────────────────┐
  │  6. COORD MAPPING │  Koordinat model (224px) → Layar HP (relatif)
  │                   │  Normalisasi → Perkalian dimensi layar
  └───────────────────┘
```

> **Mengapa tidak Grayscale?**  
> Informasi warna kulit tangan sangat membantu model membedakan tangan dari latar belakang. Konversi ke Grayscale akan menurunkan akurasi deteksi secara signifikan.

---

### 🧵 Pemetaan Isolate (Thread Management)

Flutter berjalan secara single-thread. Pemrosesan AI yang berat **harus dipisah** ke background isolate agar UI tetap responsif (target: 60 FPS).

```
┌─────────────────────────────────────────────────────────────────┐
│                     THREAD ARCHITECTURE                         │
├────────────────────────┬────────────────────────────────────────┤
│   MAIN ISOLATE (UI)    │     BACKGROUND ISOLATE (Worker)        │
│   ─────────────────    │     ──────────────────────────         │
│                        │                                        │
│  • CameraController    │  • Terima CameraImage object           │
│    (stream frames)     │  • PCD: RGB Conversion                 │
│  • Tampilkan UI        │  • PCD: Center Crop                    │
│    (tombol, teks)      │  • PCD: Resize → 224×224               │
│  • CustomPainter       │  • PCD: Normalisasi → Float32List      │
│    (skeleton overlay)  │  • TFLite inference                    │
│  • TTS / Text-to-      │  • Mapping output tensor               │
│    Speech output       │  • Kirim hasil (teks + koordinat)      │
│  • Haptic feedback     │    ke Main Isolate via SendPort         │
│                        │                                        │
│  compute() ◄───────────────────────────── hasil ringkas         │
└────────────────────────┴────────────────────────────────────────┘
```

---

### 📐 Pemetaan Koordinat (Model Space → Screen Space)

Model AI menghasilkan koordinat dalam ruang 224×224 px. Koordinat ini harus dipetakan ke dimensi layar aktual HP.

#### Formula Konversi:

```dart
// Step 1: Normalisasi output model menjadi nilai relatif (0.0 - 1.0)
double xRelative = landmarkX / modelInputWidth;   // contoh: 112 / 224 = 0.5
double yRelative = landmarkY / modelInputHeight;

// Step 2: Kalikan dengan dimensi canvas layar
double xScreen = xRelative * canvasWidth;
double yScreen = yRelative * canvasHeight;

// Step 3: Mirroring untuk kamera depan (balik sumbu X)
double xScreenMirrored = canvasWidth - xScreen;
```

#### Mengapa Mirroring Diperlukan?

```
Tanpa mirroring:          Dengan mirroring:
  ✋ (isyarat "A")          ✋ (terlihat natural)
  Overlay malah terbalik    Overlay sesuai posisi tangan
  seperti di cermin         di layar
```

---

## 🏗️ Arsitektur Sistem

```
┌─────────────────────────────────────────────────────────────┐
│                    FLUTTER APPLICATION                      │
│                                                             │
│  ┌──────────────┐   ┌─────────────────┐   ┌─────────────┐ │
│  │ Camera Layer │   │  AI/ML Layer    │   │  UI Layer   │ │
│  │              │   │                 │   │             │ │
│  │ CameraPlugin │──▶│ Background      │──▶│ CustomPaint │ │
│  │ YUV/BGRA     │   │ Isolate         │   │ (Skeleton)  │ │
│  │ frame stream │   │ ┌─────────────┐ │   │             │ │
│  └──────────────┘   │ │ PCD Pipeline│ │   │ TTS Output  │ │
│                     │ │ TFLite Model│ │   │ Haptic Fbck │ │
│  ┌──────────────┐   │ └─────────────┘ │   └─────────────┘ │
│  │  Data Layer  │   └─────────────────┘                   │
│  │              │                                          │
│  │ Hive (local) │◀──────── Terjemahan berhasil            │
│  │ MongoDB      │          disimpan ke jurnal              │
│  │ (cloud sync) │                                          │
│  └──────────────┘                                          │
└─────────────────────────────────────────────────────────────┘
```

---

## 📁 Struktur Proyek

```
PCD_TUBES_COBA/
├── 📄 README.md                    ← Dokumentasi ini
├── 📄 PROPOSAL.md                  ← Proposal lengkap proyek
│
├── 📂 docs/                        ← Dokumentasi & aset
│   ├── assets/
│   │   └── banner.png
│   ├── diagrams/                   ← Diagram arsitektur & pipeline
│   └── laporan/                    ← Draft laporan akhir
│
├── 📂 research/                    ← Riset & referensi
│   ├── dataset_notes.md            ← Catatan dataset BISINDO
│   ├── model_comparison.md         ← Perbandingan model AI
│   └── references/                 ← Paper & artikel referensi
│
├── 📂 experiments/                 ← Eksperimen & prototipe Python
│   ├── preprocessing/
│   │   ├── color_conversion.py     ← Uji konversi YUV→RGB
│   │   ├── center_crop.py          ← Uji center crop
│   │   └── normalization.py        ← Uji normalisasi piksel
│   ├── landmark_detection/
│   │   ├── mediapipe_test.py       ← Uji MediaPipe hand tracking
│   │   └── coordinate_mapping.py  ← Uji pemetaan koordinat
│   └── model_inference/
│       └── tflite_benchmark.py     ← Benchmark kecepatan inference
│
└── 📂 app/                         ← Source code Flutter (akan datang)
    ├── lib/
    │   ├── core/
    │   │   ├── isolates/           ← Background isolate logic
    │   │   └── preprocessing/      ← PCD pipeline
    │   ├── features/
    │   │   ├── camera/             ← Kamera & stream
    │   │   ├── inference/          ← TFLite inference
    │   │   ├── overlay/            ← CustomPainter skeleton
    │   │   ├── tts/                ← Text-to-Speech
    │   │   └── history/            ← Jurnal Terjemahan
    │   └── data/
    │       ├── local/              ← Hive database
    │       └── remote/             ← MongoDB sync
    └── assets/
        └── models/                 ← File model .tflite
```

---

## 🚀 Cara Menjalankan (Development)

### Prasyarat

```bash
# Flutter SDK (versi 3.x)
flutter --version

# Python (untuk eksperimen preprocessing)
python --version  # 3.9+

# Dependencies Python
pip install mediapipe opencv-python numpy matplotlib tensorflow
```

### Menjalankan Eksperimen Python

```bash
cd experiments/preprocessing
python color_conversion.py
python center_crop.py

cd ../landmark_detection
python mediapipe_test.py
```

### Menjalankan Aplikasi Flutter

```bash
cd app
flutter pub get
flutter run
```

---

## 📚 Referensi Teknologi

| Teknologi | Kegunaan | Link |
|-----------|----------|------|
| MediaPipe Hands | Deteksi 21 landmark tangan | [mediapipe.dev](https://mediapipe.dev) |
| TensorFlow Lite | Inference model di mobile | [tensorflow.org/lite](https://www.tensorflow.org/lite) |
| Flutter | Framework aplikasi mobile | [flutter.dev](https://flutter.dev) |
| Hive | Database lokal Flutter | [pub.dev/packages/hive](https://pub.dev/packages/hive) |
| MongoDB Atlas | Cloud database sync | [mongodb.com](https://www.mongodb.com) |
| BISINDO | Bahasa Isyarat Indonesia | Referensi dataset isyarat |

---

<div align="center">

**Kelompok 2 — PCD 2025/2026**  
Politeknik Negeri Bandung

*"Menjembatani komunikasi, satu isyarat dalam satu waktu."*

</div>
