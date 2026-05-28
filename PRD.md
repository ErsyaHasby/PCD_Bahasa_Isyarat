# PRD - Aplikasi Penerjemah Bahasa Isyarat (BISINDO)

Tanggal: 28 Mei 2026
Versi: 1.0
Status: Draft untuk internal tim

## 1. Deskripsi Aplikasi

Aplikasi mobile penerjemah bahasa isyarat (BISINDO) berbasis kamera real-time.
Sistem mendeteksi gesture tangan statis (alfabet A-Z) menggunakan MediaPipe Hands, mengekstrak fitur landmark, lalu mengklasifikasikan gesture dengan model scikit-learn. Hasil ditampilkan sebagai teks dengan target latensi < 200-300 ms, disertai confidence score dan riwayat terjemahan.

## 2. Tujuan Produk

- Menjembatani komunikasi antara pengguna BISINDO dan masyarakat umum.
- Memberikan penerjemahan gesture statis A-Z secara real-time di perangkat mobile.
- Menyediakan riwayat terjemahan sebagai jurnal pengguna.

## 3. Target Pengguna

- Teman Tuli pengguna BISINDO.
- Masyarakat umum yang tidak memahami BISINDO.
- Pengajar atau pelajar BISINDO.

## 4. Ruang Lingkup (Scope)

### 4.1 In-Scope (MVP)

- Deteksi gesture statis A-Z (termasuk yang membutuhkan dua tangan).
- Output teks real-time dengan latency < 200-300 ms.
- Confidence meter sederhana.
- History/jurnal terjemahan lokal (Hive).
- UI sederhana: Home, Camera, History.

### 4.2 Out-of-Scope (Tahap Lanjut)

- Gesture dinamis (kata atau kalimat).
- Sinkronisasi cloud (MongoDB).
- Multibahasa atau translasi kalimat panjang.
- Model end-to-end deep learning di device.

### 4.3 Larangan Keras di MVP

- Gesture dinamis atau kata/kalimat (sementara).
- Sinkronisasi cloud atau auth (sementara).
- Export data (PDF/CSV) dan sharing.
- Fitur multi-bahasa atau terjemahan kalimat.

## 5. Flow Aplikasi

1. Splash/Onboarding
2. Home
3. Camera
4. Deteksi gesture real-time
5. Output teks + confidence
6. Simpan ke History
7. History list dan detail

## 6. MVP Definition

- Pengguna bisa membuka Camera screen.
- Gesture statis A-Z terdeteksi dan muncul teks dalam < 200-300 ms.
- Riwayat terjemahan tersimpan lokal dan bisa dilihat di History.

## 6.1 Batasan Teknis MVP

- Hanya gesture statis A-Z (1 frame sebagai input utama).
- Output real-time dengan latensi end-to-end < 200-300 ms.
- Tidak ada mode kalimat, mode dinamis, atau cloud (sementara).

## 7. Teknologi dan Tools

### 7.1 Mobile

- Flutter 3.x
- Dart 3.x
- go_router
- flutter_riverpod
- camera
- hive, hive_flutter
- flutter_tts (opsional di MVP)

### 7.2 AI / ML

- MediaPipe Hands (21 landmarks)
- scikit-learn (SVM/RandomForest/KNN)

### 7.3 Eksperimen

- Python + OpenCV + MediaPipe
- NumPy, Matplotlib

## 8. Standar Format Fitur (Wajib Konsisten)

### 8.1 Landmark

- Sumber: MediaPipe Hands (21 landmark per tangan).
- Urutan landmark: sesuai indeks resmi MediaPipe.
- Input: maksimal 2 tangan (dominant + non-dominant).

### 8.2 Normalisasi

- Titik acuan per tangan: wrist (landmark 0).
- Skala per tangan: jarak wrist ke middle finger MCP (landmark 9).
- Normalisasi: (x, y, z) relatif terhadap wrist tangan masing-masing dan dibagi skala.

### 8.3 Format Fitur

- Dua tangan digabung: 42 titik total.
- Flatten menjadi vektor 126 nilai: [x0, y0, z0, ... x41, y41, z41].
- Jika z tidak stabil di device, fallback ke 84 nilai (x, y).
- Jika hanya 1 tangan terdeteksi, isi tangan kedua dengan nol dan beri flag `hand_count=1` untuk classifier.
- Semua tim wajib menggunakan format yang sama untuk training dan inference.

### 8.4 Smoothing

- Moving average 3 frame per tangan untuk stabilitas.
- Output prediksi tetap berbasis single frame terakhir (bukan sequence).

## 9. Arsitektur Singkat

- Camera stream -> Preprocess (PCD) -> MediaPipe Hands -> Feature Extraction -> scikit-learn classifier -> UI output.
- Background isolate untuk pipeline berat agar UI tetap responsif.

## 10. Standarisasi Vibe Coding

### 9.1 Prinsip

- Fokus ke hasil nyata, bukan asumsi.
- Semua fitur diukur (latency, FPS, akurasi).
- Data-driven: setiap klaim akurasi harus ada metrik.

### 9.2 Aturan Coding

- Hindari mock ketika fitur inti harus real.
- Modular: PCD, MediaPipe, classifier, UI terpisah jelas.
- Konsistensi format fitur: satu standar untuk training dan inference.

### 9.3 Konvensi Commit

- feat: fitur baru
- fix: perbaikan bug
- refactor: perombakan kode
- docs: dokumentasi

### 10.1 Guardrails untuk AI Coding

- Dilarang menambah fitur di luar MVP.
- Jika detail tidak jelas, AI wajib bertanya dulu.
- Selalu pakai format fitur dan pipeline yang sudah ditetapkan.
- Setiap perubahan harus update dokumentasi jika relevan.

### 10.2 Prompt Header untuk Copilot (Wajib Tempel di Awal Request)

Gunakan header ini saat meminta bantuan AI agar output konsisten:

```
KONTEKS: Aplikasi penerjemah BISINDO (MVP). Fokus A-Z statis, two-hand supported.
LARANGAN: Jangan buat fitur di luar MVP (dinamis (sementara), cloud (sementara), export, multi-bahasa).
PERFORMA: Latency end-to-end <= 300 ms, FPS >= 20.
FORMAT FITUR: 2 tangan, 42 titik, flatten 126 (x,y,z) atau 84 (x,y) jika z tidak stabil.
NORMALISASI: Per tangan, relatif ke wrist, skala wrist ke middle finger MCP.
HAND COUNT: Jika 1 tangan, isi tangan kedua nol dan set hand_count=1.
GAYA KODE: Modular, tidak ada mock untuk fitur inti, update doc jika relevan.
```

## 11. Branching Strategy

- main: hanya untuk release stabil
- develop: integrasi harian
- feature/camera-pcd (Ersya)
- feature/mediapipe-features (Alex)
- feature/sklearn-model (Brata)
- feature/ui-history (Varian)

## 12. Pembagian Tugas (Ringkas)

- Ersya: camera + PCD + latency
- Alex: MediaPipe + feature extraction
- Brata: training sklearn + model export + inference
- Varian: UI + history + integrasi hasil

## 13. Target Performa dan Kualitas

### 13.1 Performa

- Latency end-to-end: <= 300 ms.
- Preprocess + MediaPipe: <= 120 ms.
- Classifier: <= 20 ms.
- UI update: <= 30 ms.
- FPS minimal: 20 FPS.

### 13.2 Akurasi

- Akurasi A-Z minimal 80% pada data uji.
- Setiap kelas minimal 50 sampel, target 200 sampel.
- Dataset wajib mencakup gesture dua tangan.

## 14. Standar Dataset dan Training

- Dataset: gesture A-Z statis (1 tangan dan 2 tangan), variasi lighting dan jarak.
- Split data: 70% train, 15% validasi, 15% test.
- Simpan fitur dan label dalam CSV/NPY dengan metadata versi.
- Evaluasi wajib: confusion matrix + per-class accuracy.

### 14.1 Checklist Two-Hand BISINDO (Wajib di Dataset)

- Tandai huruf yang membutuhkan dua tangan saat kurasi dataset.
- Setiap huruf two-hand minimal 50 sampel (target 200 sampel).
- Jika daftar huruf two-hand belum final, gunakan checklist operasional sementara dan revisi setelah validasi lapangan.

### 14.2 Flag `hand_count` (Wajib di Inference)

- `hand_count=2` jika dua tangan terdeteksi lengkap.
- `hand_count=1` jika hanya satu tangan terdeteksi.
- Jika gesture two-hand tapi `hand_count=1`, tampilkan pesan: "Gesture tidak lengkap".

## 15. Device Scope

- Platform: Android saja.
- Minimum SDK: 24.
- Target device: mid-range (RAM 4-6 GB, chipset kelas menengah).

## 16. Konvensi Repo dan Integrasi

- Tiap orang hanya menyentuh area modulnya kecuali ada koordinasi.
- Format fitur tidak boleh diubah sepihak.
- Merge ke develop hanya jika: build lulus, tidak ada crash, dan latency diuji.
- Semua PR harus menyertakan ringkasan perubahan dan hasil uji.

- Latency output < 200-300 ms di device mid-range.
- Akurasi huruf A-Z >= 80% pada data uji.
- UI stabil tanpa crash selama 5 menit stream.

## 17. Kriteria Sukses MVP

- Latency output < 200-300 ms di device mid-range.
- Akurasi huruf A-Z >= 80% pada data uji.
- UI stabil tanpa crash selama 5 menit stream.

## 18. Risiko dan Mitigasi

- Landmark tidak stabil -> smoothing dan pencahayaan minimum.
- Dataset kurang -> tambah data per kelas.
- Latency tinggi -> optimasi isolate dan preprocessing.

## 19. Next Step

- Siapkan dataset A-Z.
- Implementasi pipeline end-to-end.
- Uji latency dan akurasi.
