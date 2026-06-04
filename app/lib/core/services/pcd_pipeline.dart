import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';
import '../models/inference_result.dart';

/// ═══════════════════════════════════════════════════════════════════
///  PCD Pipeline — Berjalan di Background Isolate
///  Alur: YUV/BGRA → RGB → Center Crop → Resize → Normalisasi → Done
/// ═══════════════════════════════════════════════════════════════════

/// Entry point untuk compute() — dipanggil dari CameraNotifier
Future<InferenceResult> runPcdPipeline(IsolatePayload payload) async {
  final startTime = DateTime.now().millisecondsSinceEpoch;
  // ── Step 1: Decode raw bytes jadi pixel array ──────────────────────
  // (Dalam implementasi nyata, ini menerima CameraImage planes dari Flutter)
  // Di sini kita simulasikan dengan mock inference untuk demo UI
  final preprocessed = _preprocess(
    payload.bytes,
    payload.width,
    payload.height,
  );

  // ── Step 2: TFLite Inference ───────────────────────────────────────
  // CATATAN: Implementasi nyata memerlukan tflite_flutter & model .tflite
  // final interpreter = Interpreter.fromAsset('assets/models/gesture.tflite');
  // interpreter.run(preprocessed, outputBuffer);
  final result = await _mockInference(preprocessed);

  // ── Step 3: Coordinate Mapping ─────────────────────────────────────
  final mappedLandmarks = _mapCoordinates(
    result.landmarks,
    isFrontCamera: payload.isFrontCamera,
  );

  return InferenceResult(
    label: result.label,
    confidence: result.confidence,
    landmarks: mappedLandmarks,
    handsDetected: result.handsDetected,
    latencyMs: DateTime.now().millisecondsSinceEpoch - startTime,
  );
}

/// Step 1 - 4: Pre-processing pipeline
/// Color Conversion → Center Crop → Resize → Normalisasi
Float32List _preprocess(Uint8List rawBytes, int width, int height) {
  // Langkah 1: Color Conversion
  // Dalam produksi: YUV420 (Android) / BGRA8888 (iOS) → RGB
  // Contoh konversi YUV → RGB:
  //   R = Y + 1.402 * (V - 128)
  //   G = Y - 0.344 * (U - 128) - 0.714 * (V - 128)
  //   B = Y + 1.772 * (U - 128)

  // Langkah 2: Center Crop (jaga aspek rasio)
  final cropSize = width < height ? width : height;
  // ignore: unused_local_variable
  final startX = (width - cropSize) ~/ 2;
  // ignore: unused_local_variable
  final startY = (height - cropSize) ~/ 2;

  // Langkah 3: Resize ke 224x224 (input size model)
  const modelSize = 224;

  // Langkah 4: Normalisasi [0,255] → [0.0, 1.0] Float32
  final result = Float32List(modelSize * modelSize * 3);
  for (int i = 0; i < result.length; i++) {
    // pixel_value / 255.0
    result[i] = (rawBytes[i % rawBytes.length] & 0xFF) / 255.0;
  }

  return result;

  // Supres unused variable warnings
  // ignore: unused_local_variable
  // (startX, startY, cropSize digunakan dalam implementasi nyata)
}

/// Mock inference — diganti dengan TFLite nyata saat model tersedia
Future<InferenceResult> _mockInference(Float32List _) async {
  // Simulasi 21 landmark tangan dalam koordinat relatif (0.0 - 1.0)
  // Posisi simulasi telapak tangan dan jari-jari
  final landmarks = _generateMockLandmarks();

  // Pilih label secara sekuensial untuk demo
  final labels = ['Halo', 'Terima Kasih', 'Maaf', 'Tolong', 'Ya', 'Tidak'];
  final now = DateTime.now().millisecondsSinceEpoch;
  final label = labels[(now ~/ 3000) % labels.length];

  return InferenceResult(
    label: label,
    confidence: 0.85 + (now % 15) / 100,
    landmarks: landmarks,
    handsDetected: 2, // Deteksi 2 tangan untuk demo
    latencyMs: 0,
  );
}

/// Hasilkan 21 landmark tangan simulasi (posisi relatif 0.0-1.0)
List<Offset> _generateMockLandmarks() {
  // 21 titik sesuai MediaPipe Hand Landmark model:
  // 0: Pergelangan tangan
  // 1-4: Jempol (CMC → tip)
  // 5-8: Telunjuk
  // 9-12: Tengah
  // 13-16: Manis
  // 17-20: Kelingking
  const cx = 0.5, cy = 0.55;
  return [
    const Offset(cx, cy + 0.15), // 0 - wrist
    const Offset(cx - 0.08, cy + 0.10), // 1 - thumb CMC
    const Offset(cx - 0.13, cy + 0.06), // 2 - thumb MCP
    const Offset(cx - 0.17, cy + 0.01), // 3 - thumb IP
    const Offset(cx - 0.20, cy - 0.03), // 4 - thumb tip
    const Offset(cx - 0.08, cy + 0.05), // 5 - index MCP
    const Offset(cx - 0.08, cy - 0.03), // 6 - index PIP
    const Offset(cx - 0.08, cy - 0.10), // 7 - index DIP
    const Offset(cx - 0.08, cy - 0.17), // 8 - index tip
    const Offset(cx, cy + 0.03), // 9 - middle MCP
    const Offset(cx, cy - 0.05), // 10 - middle PIP
    const Offset(cx, cy - 0.12), // 11 - middle DIP
    const Offset(cx, cy - 0.20), // 12 - middle tip
    const Offset(cx + 0.08, cy + 0.04), // 13 - ring MCP
    const Offset(cx + 0.08, cy - 0.03), // 14 - ring PIP
    const Offset(cx + 0.08, cy - 0.10), // 15 - ring DIP
    const Offset(cx + 0.08, cy - 0.16), // 16 - ring tip
    const Offset(cx + 0.16, cy + 0.07), // 17 - pinky MCP
    const Offset(cx + 0.16, cy + 0.01), // 18 - pinky PIP
    const Offset(cx + 0.16, cy - 0.05), // 19 - pinky DIP
    const Offset(cx + 0.16, cy - 0.10), // 20 - pinky tip
  ];
}

/// Step 5: Pemetaan koordinat + Mirroring untuk kamera depan
/// Formula: x_screen = x_relative * canvas_width
/// Mirroring: x_mirrored = 1.0 - x_relative
List<Offset> _mapCoordinates(
  List<Offset> landmarks, {
  required bool isFrontCamera,
}) {
  return landmarks.map((pt) {
    final x = isFrontCamera ? 1.0 - pt.dx : pt.dx;
    return Offset(x, pt.dy);
  }).toList();
}
