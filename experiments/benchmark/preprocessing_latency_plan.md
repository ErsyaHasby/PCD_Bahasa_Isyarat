# Benchmark Plan: Preprocessing Latency (PCD Pipeline)

## Konteks
- **Tujuan**: Validasi bahwa preprocessing PCD pipeline memenuhi target latency < 50 ms
- **Ukuran input**: 224x224 (sudah disinkronisasi dengan MediaPipe)
- **Arsitektur**: Camera → PCD (YUV/BGRA → RGB → Center Crop → Resize → Normalisasi) → MediaPipe

## Target Performa (PRD)
- **Preprocessing latency**: < 50 ms (Ersya)
- **Preprocess + MediaPipe**: <= 120 ms (total)
- **End-to-end latency**: < 300 ms
- **FPS minimal**: 20 FPS

## Metrik yang Diukur

### 1. Preprocessing Latency (PCD Pipeline)
- Waktu eksekusi `_preprocessFromPlanes()` di isolate
- Breakdown per step:
  - Color conversion (YUV→RGB / BGRA→RGB)
  - Center crop
  - Resize (224x224)
  - Normalisasi [0,255] → [0.0, 1.0]

### 2. Memory Usage
- Heap allocation per frame
- Peak memory usage
- Memory leak detection

### 3. FPS Stability
- Rata-rata FPS
- FPS minimum
- Jitter (standard deviation)

## Setup Benchmark

### Device Test
- **Mid-range device**: Samsung Galaxy S21 / Xiaomi 12 (sesuai Qualcomm AI Hub)
- **Resolusi kamera**: 640x480, 1280x720
- **Format**: YUV420 (Android), BGRA8888 (iOS)

### Implementasi Benchmark

```dart
// Di camera_screen.dart atau file benchmark terpisah
final sw = Stopwatch()..start();
final preprocessed = _preprocessFromPlanes(payload);
sw.stop();
final preprocessMs = sw.elapsedMilliseconds;

// Log ke file atau console
print('Preprocessing: ${preprocessMs}ms (target < 50ms)');
```

### Skenario Test

1. **Baseline Test**
   - 100 frame consecutive
   - Ukuran input: 640x480 → 224x224
   - Format: YUV420

2. **Stress Test**
   - 1000 frame consecutive
   - Cek memory leak
   - Monitor FPS stability

3. **Format Comparison**
   - YUV420 vs BGRA8888
   - Bandingkan latency

4. **Resolution Impact**
   - 640x480 → 224x224
   - 1280x720 → 224x224
   - Bandingkan latency

## Kriteria Sukses

- ✅ Rata-rata preprocessing latency < 50 ms
- ✅ 95th percentile latency < 60 ms
- ✅ FPS >= 20 stabil
- ✅ Tidak ada memory leak setelah 1000 frame
- ✅ Variasi latency (std dev) < 10 ms

## Output yang Diharapkan

1. **Laporan Benchmark**
   - Tabel latency per step
   - Grafik FPS over time
   - Memory usage profile

2. **Rekomendasi Optimasi** (jika perlu)
   - Jika latency > 50 ms: pertimbangkan 192x192
   - Jika latency << 50 ms: bisa naik ke 256x256

3. **Konfirmasi untuk Alex**
   - Ukuran 224x224 stabil untuk MediaPipe
   - Siap untuk integrasi

## Timeline

- **Hari 1**: Implementasi benchmark code
- **Hari 2**: Jalankan baseline test
- **Hari 3**: Analisis hasil dan optimasi (jika perlu)
- **Hari 4**: Final test dan laporan

## Catatan

- Benchmark harus dijalankan di device nyata, bukan emulator
- Gunakan mode release build untuk hasil akurat
- Matikan debug logging saat benchmark
- Pastikan device dalam kondisi normal (tidak overheating)
