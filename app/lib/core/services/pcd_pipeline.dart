import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';
import '../models/inference_result.dart';

/// ═══════════════════════════════════════════════════════════════════
///  PCD Pipeline — Berjalan di Background Isolate
///  Alur: YUV/BGRA → RGB → Center Crop → Resize → Normalisasi → Done
/// ═══════════════════════════════════════════════════════════════════

/// Entry point untuk compute() — dipanggil dari CameraNotifier
Future<InferenceResult> runPcdPipeline(IsolatePayload payload) async {
  // ── Step 1: Decode raw bytes jadi pixel array ──────────────────────
  final preprocessed = _preprocessFromPlanes(payload);

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
  );
}

/// Step 1 - 4: Pre-processing pipeline
/// Color Conversion → Center Crop → Resize → Normalisasi
Float32List _preprocessFromPlanes(IsolatePayload payload) {
  final width = payload.width;
  final height = payload.height;

  // Langkah 2: Center Crop (jaga aspek rasio)
  final cropSize = width < height ? width : height;
  final startX = (width - cropSize) ~/ 2;
  final startY = (height - cropSize) ~/ 2;

  // Langkah 3: Resize ke input model
  // Ukuran 224x224 dipilih berdasarkan:
  // - TASK_BREAKDOWN.md line 67: target 224x224
  // - MediaPipe Hands optimal: 256x256 (dokumentasi resmi)
  // - Kompromi akurasi vs latency (target preprocessing < 50 ms)
  const modelSize = 224;

  // Langkah 4: Normalisasi [0,255] → [0.0, 1.0] Float32
  final result = Float32List(modelSize * modelSize * 3);

  if (payload.formatGroup == 'yuv420') {
    if (payload.planes.length < 3) return result;
    _fillFromYuv420(
      yPlane: payload.planes[0],
      uPlane: payload.planes[1],
      vPlane: payload.planes[2],
      cropX: startX,
      cropY: startY,
      cropSize: cropSize,
      modelSize: modelSize,
      output: result,
    );
  } else if (payload.formatGroup == 'bgra8888') {
    if (payload.planes.isEmpty) return result;
    _fillFromBgra8888(
      plane: payload.planes[0],
      cropX: startX,
      cropY: startY,
      cropSize: cropSize,
      modelSize: modelSize,
      output: result,
    );
  }

  return result;
}

void _fillFromYuv420({
  required PlaneData yPlane,
  required PlaneData uPlane,
  required PlaneData vPlane,
  required int cropX,
  required int cropY,
  required int cropSize,
  required int modelSize,
  required Float32List output,
}) {
  final yBytes = yPlane.bytes;
  final uBytes = uPlane.bytes;
  final vBytes = vPlane.bytes;

  final yRowStride = yPlane.bytesPerRow;
  final uRowStride = uPlane.bytesPerRow;
  final vRowStride = vPlane.bytesPerRow;
  final uPixelStride = uPlane.bytesPerPixel;
  final vPixelStride = vPlane.bytesPerPixel;

  for (int y = 0; y < modelSize; y++) {
    final srcY = cropY + (y * cropSize ~/ modelSize);
    final yRow = srcY * yRowStride;
    final uRow = (srcY >> 1) * uRowStride;
    final vRow = (srcY >> 1) * vRowStride;

    for (int x = 0; x < modelSize; x++) {
      final srcX = cropX + (x * cropSize ~/ modelSize);
      final yIndex = yRow + srcX;
      final uvX = srcX >> 1;
      final uIndex = uRow + uvX * uPixelStride;
      final vIndex = vRow + uvX * vPixelStride;

      final yVal = yBytes[yIndex];
      final uVal = uBytes[uIndex];
      final vVal = vBytes[vIndex];

      final yf = yVal.toDouble();
      final uf = uVal - 128.0;
      final vf = vVal - 128.0;

      var r = yf + 1.402 * vf;
      var g = yf - 0.344136 * uf - 0.714136 * vf;
      var b = yf + 1.772 * uf;

      if (r < 0) r = 0;
      if (g < 0) g = 0;
      if (b < 0) b = 0;
      if (r > 255) r = 255;
      if (g > 255) g = 255;
      if (b > 255) b = 255;

      final outIndex = (y * modelSize + x) * 3;
      output[outIndex] = r / 255.0;
      output[outIndex + 1] = g / 255.0;
      output[outIndex + 2] = b / 255.0;
    }
  }
}

void _fillFromBgra8888({
  required PlaneData plane,
  required int cropX,
  required int cropY,
  required int cropSize,
  required int modelSize,
  required Float32List output,
}) {
  final bytes = plane.bytes;
  final rowStride = plane.bytesPerRow;

  for (int y = 0; y < modelSize; y++) {
    final srcY = cropY + (y * cropSize ~/ modelSize);
    final row = srcY * rowStride;
    for (int x = 0; x < modelSize; x++) {
      final srcX = cropX + (x * cropSize ~/ modelSize);
      final index = row + srcX * 4;
      final b = bytes[index];
      final g = bytes[index + 1];
      final r = bytes[index + 2];

      final outIndex = (y * modelSize + x) * 3;
      output[outIndex] = r / 255.0;
      output[outIndex + 1] = g / 255.0;
      output[outIndex + 2] = b / 255.0;
    }
  }
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
