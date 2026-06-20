import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';
import '../models/inference_result.dart';
import '../models/hand_data.dart';

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

  // Convert List<Offset> to HandData for InferenceResult
  final hand1 = HandData(
    landmarks: mappedLandmarks
        .take(21)
        .map((pt) => LandmarkPoint(x: pt.dx, y: pt.dy, z: 0.0))
        .toList(),
    isDetected: true,
  );
  final hand2 = HandData(
    landmarks: mappedLandmarks
        .skip(21)
        .take(21)
        .map((pt) => LandmarkPoint(x: pt.dx, y: pt.dy, z: 0.0))
        .toList(),
    isDetected: true,
  );

  return InferenceResult(
    label: result.label,
    confidence: result.confidence,
    hand1: hand1,
    hand2: hand2,
    handsDetected: result.handsDetected,
    latencyMs: DateTime.now().millisecondsSinceEpoch - startTime,
  );
}

/// Step 1 - 4: Pre-processing pipeline
/// Color Conversion → Center Crop → Resize → Normalisasi
Float32List _preprocess(Uint8List rawBytes, int width, int height) {
  const modelSize = 224;
  final result = Float32List(modelSize * modelSize * 3);
  for (int i = 0; i < result.length; i++) {
    result[i] = (rawBytes[i % rawBytes.length] & 0xFF) / 255.0;
  }
  return result;
}

/// Mock inference — diganti dengan TFLite nyata saat model tersedia
Future<_MockResult> _mockInference(Float32List _) async {
  // Simulasi 21 landmark tangan dalam koordinat relatif (0.0 - 1.0)
  // Posisi simulasi telapak tangan dan jari-jari
  final landmarks = _generateMockLandmarks();

  // Pilih label secara sekuensial untuk demo
  final labels = ['Halo', 'Terima Kasih', 'Maaf', 'Tolong', 'Ya', 'Tidak'];
  final now = DateTime.now().millisecondsSinceEpoch;
  final label = labels[(now ~/ 3000) % labels.length];

  return _MockResult(
    label: label,
    confidence: 0.85 + (now % 15) / 100,
    landmarks: landmarks,
    handsDetected: 2, // Deteksi 2 tangan untuk demo
  );
}

class _MockResult {
  final String label;
  final double confidence;
  final List<Offset> landmarks;
  final int handsDetected;

  _MockResult({
    required this.label,
    required this.confidence,
    required this.landmarks,
    required this.handsDetected,
  });
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
