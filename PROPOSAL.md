# PROPOSAL TUGAS BESAR
## Sistem Intelijen Visual Penerjemah Bahasa Isyarat Real-Time

---

**Mata Kuliah** : Pengolahan Citra Digital  
**Program Studi** : D3 Teknik Informatika  
**Institusi** : Politeknik Negeri Bandung  
**Semester** : 4 (Empat) — Tahun Akademik 2025/2026  
**Kelompok** : 2

---

## A. Identitas Tim

| No | Nama Lengkap | NIM |
|:--:|:-------------|:---:|
| 1 | Alexandrio Vega Bonito | 241511067 |
| 2 | Ersya Hasby Satria | 241511072 |
| 3 | Muhammad Brata Hadinata | 241511082 |
| 4 | Varian Abidarma Syuhada | 241511081 |

---

## B. Judul Proyek

**"Sistem Intelijen Visual Penerjemah Bahasa Isyarat Real-Time"**

---

## C. Latar Belakang

Indonesia memiliki lebih dari 2,5 juta penyandang tunarungu (Kemensos, 2023). Mereka berkomunikasi menggunakan Bahasa Isyarat Indonesia (BISINDO), sebuah sistem komunikasi visual yang kompleks namun hanya dipahami oleh sebagian kecil masyarakat umum.

Kesenjangan komunikasi ini menimbulkan hambatan nyata dalam kehidupan sehari-hari: ketika berbelanja, mengurus administrasi, mencari pertolongan darurat, atau sekadar bersosialisasi. Penerjemah manusia tidak selalu tersedia, dan tidak praktis untuk setiap situasi spontan.

Perkembangan pesat teknologi Computer Vision dan Machine Learning membuka peluang untuk menjembatani kesenjangan ini melalui perangkat yang sudah dimiliki hampir semua orang: **smartphone**.

---

## D. Rumusan Masalah

1. Bagaimana cara mendeteksi dan mengekstrak fitur gestur tangan dari aliran video kamera secara real-time pada perangkat mobile?
2. Bagaimana pipeline Pengolahan Citra Digital (PCD) yang optimal untuk mempersiapkan frame kamera sebelum proses inferensi model AI?
3. Bagaimana mengelola keterbatasan komputasi perangkat mobile agar sistem dapat berjalan dengan latensi rendah tanpa mengorbankan akurasi?
4. Bagaimana menyajikan hasil terjemahan secara intuitif dan aksesibel bagi pengguna?

---

## E. Tujuan

1. Membangun aplikasi mobile yang mampu mendeteksi gestur bahasa isyarat melalui kamera secara real-time.
2. Mengimplementasikan pipeline PCD yang lengkap: konversi warna, center crop, resize, dan normalisasi.
3. Mengintegrasikan model AI (MediaPipe + TFLite) untuk klasifikasi gestur isyarat.
4. Menyediakan umpan balik multimodal: visual (overlay skeleton), audio (TTS), dan haptik (getaran).
5. Mencatat riwayat terjemahan dalam "Buku Jurnal Terjemahan" yang tersinkronisasi ke cloud.

---

## F. Manfaat

| Penerima Manfaat | Manfaat |
|-----------------|---------|
| Teman Tuli | Kemandirian komunikasi tanpa bergantung penerjemah manusia |
| Masyarakat Umum | Dapat berinteraksi dengan pengguna isyarat tanpa pengetahuan sebelumnya |
| Dunia Pendidikan | Alat bantu pembelajaran bahasa isyarat bagi masyarakat |
| Riset PCD & AI | Kontribusi pada pengembangan sistem computer vision aksesibel |

---

## G. Batasan Masalah

1. Fokus pada gestur statis dan semi-dinamis BISINDO (alfabet dan kata dasar).
2. Input berupa satu tangan dominan dalam frame kamera.
3. Lingkungan dengan pencahayaan cukup (tidak terlalu gelap/redup).
4. Platform target: Android (dengan dukungan iOS sebagai pengembangan lanjutan).

---

## H. Metodologi

### H.1 Studi Literatur & Dataset
- Pengumpulan dataset BISINDO (alfabet A-Z dan kata dasar)
- Studi paper terkait Hand Gesture Recognition berbasis Deep Learning
- Analisis perbandingan model: MediaPipe vs. custom TFLite

### H.2 Perancangan Pipeline PCD
Merancang dan menguji setiap tahap preprocessing secara terpisah:

```
Frame Kamera → Color Conversion → Center Crop → Resize → Normalisasi → Inference
```

### H.3 Pengembangan Eksperimen (Python)
Validasi pipeline menggunakan Python + OpenCV + MediaPipe sebelum diimplementasikan ke Flutter:
- Uji konversi warna (YUV/BGRA → RGB)
- Uji center crop dengan berbagai aspek rasio
- Uji normalisasi dan validasi nilai Float32
- Benchmark kecepatan inferensi

### H.4 Pengembangan Aplikasi (Flutter)
Implementasi sistem lengkap menggunakan Flutter dengan arsitektur isolate terpisah:
- Main Isolate: UI, kamera, overlay, TTS
- Background Isolate: PCD, inference, mapping koordinat

### H.5 Pengujian & Evaluasi
- Akurasi deteksi gestur (confusion matrix)
- Latensi end-to-end (frame masuk → terjemahan tampil)
- Performa UI (frame rate, freeze detection)

---

## I. Rencana Pengerjaan (Timeline)

| Minggu | Kegiatan | PIC |
|:------:|----------|-----|
| 1-2 | Studi literatur, pengumpulan dataset, setup environment | Semua |
| 3 | Eksperimen pipeline PCD (Python) | Ersya, Brata |
| 4 | Eksperimen MediaPipe & koordinat mapping | Vega, Varian |
| 5-6 | Pengembangan core Flutter (kamera, isolate, PCD) | Semua |
| 7 | Integrasi TFLite inference ke Flutter | Ersya, Vegan |
| 8 | UI/UX: overlay, TTS, haptic feedback | Varian, Brata |
| 9 | Integrasi Hive & MongoDB (History Log) | Ersya |
| 10 | Pengujian menyeluruh & debugging | Semua |
| 11 | Penyusunan laporan & persiapan demo | Semua |
| 12 | Presentasi & Demo Final | Semua |

---

## J. Inheritance dari Proyek 4 (Logbook App)

Komponen yang diwarisi dan ditransformasi:

| Komponen Asal | Transformasi | Komponen Baru |
|---------------|-------------|---------------|
| Hive local database | Ubah skema entri | Penyimpanan cache terjemahan & preferensi |
| MongoDB cloud sync | Ubah koleksi data | Sinkronisasi riwayat jurnal terjemahan |
| Modul Logbook (CRUD) | Ubah domain data | "Buku Jurnal Terjemahan" (History Log) |
| Autentikasi user | Dipertahankan | Login untuk sinkronisasi cloud personal |

### Skema Entri Jurnal Terjemahan (Hive)

```dart
@HiveType(typeId: 1)
class TranslationEntry extends HiveObject {
  @HiveField(0) String id;
  @HiveField(1) String translatedText;    // Hasil terjemahan
  @HiveField(2) DateTime timestamp;       // Waktu kejadian
  @HiveField(3) double confidenceScore;   // Skor kepercayaan AI (0.0-1.0)
  @HiveField(4) String? gestureLabel;     // Label gestur yang dideteksi
  @HiveField(5) bool isSyncedToCloud;     // Status sinkronisasi MongoDB
}
```

---

## K. Stack Teknologi

### Mobile Application
| Layer | Teknologi | Versi |
|-------|-----------|-------|
| Framework | Flutter | 3.x |
| Language | Dart | 3.x |
| State Management | Riverpod / BLoC | Latest |
| Local DB | Hive | 2.x |
| Cloud DB | MongoDB Atlas | Latest |

### AI / ML
| Komponen | Teknologi | Keterangan |
|----------|-----------|------------|
| Hand Detection | MediaPipe Hands | 21 landmarks per tangan |
| Gesture Classification | TensorFlow Lite | Model kustom / pre-trained |
| TTS | Flutter TTS / Google TTS | Output suara terjemahan |

### Eksperimen & Riset
| Kebutuhan | Teknologi |
|-----------|-----------|
| Image Processing | OpenCV-Python |
| Landmark Detection | MediaPipe Python |
| Visualisasi | Matplotlib |
| ML Framework | TensorFlow / PyTorch |
| Data Analysis | NumPy, Pandas |

---

## L. Referensi

1. Lugaresi, C., et al. (2019). *MediaPipe: A Framework for Building Perception Pipelines*. Google Research.
2. Koller, O., et al. (2020). *Quantitative Survey of the State of the Art in Sign Language Recognition*. arXiv.
3. TensorFlow Team. (2023). *TensorFlow Lite Guide: Running Models on Mobile Devices*. tensorflow.org/lite.
4. Kementerian Sosial RI. (2023). *Data Penyandang Disabilitas Indonesia*.
5. Flutter Team. (2024). *Flutter Isolates and Concurrency*. docs.flutter.dev.

---

*Proposal ini merupakan dokumen hidup yang akan diperbarui seiring perkembangan proyek.*

**Bandung, Mei 2026**
