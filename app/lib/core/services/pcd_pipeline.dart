import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';
import '../models/inference_result.dart';

/// Pipeline PCD + MediaPipe + Feature Extraction
///
/// Alur: CameraImage - HandDetector - Normalisasi - Smoothing - Fitur - Classifier
///
/// Implementasi runtime ada di:
///   - HandLandmarkDetector (MediaPipe via hand_landmarker)
///   - HandFeatureExtractor (normalisasi, smoothing, fitur)
///   - HandClassifier (inference placeholder, diganti Brata)
///
/// NOTE: PCD Pipeline via isolate digantikan oleh HandLandmarkDetector (Alex)
/// Fallback implementation (Ersya) disimpan di bawah untuk TFLite backup

/// Entry point untuk background isolate — saat ini tidak dipakai
/// karena ML Kit berjalan di native thread sendiri.
/// Ke depan bisa dipakai untuk TFLite fallback.
Future<<InferenceResult> runPcdPipeline(IsolatePayload payload) async {
  throw UnimplementedError(
    'PCD Pipeline via isolate digantikan oleh HandLandmarkDetector.\n'
    'Lihat camera_screen.dart untuk pipeline real-time.\n'
    'Fallback TFLite implementation ada di bawah (commented).',
  );
}

// ═══════════════════════════════════════════════════════════════════
//  FALLBACK: PCD Pipeline (Ersya) - Untuk TFLite backup
//  Uncomment jika MediaPipe tidak tersedia atau untuk benchmark
// ═══════════════════════════════════════════════════════════════════
/*
/// ═══════════════════════════════════════════════════════════════════
///  PCD Pipeline — Berjalan di Background Isolate
///  Alur: YUV/BGRA → RGB → Center Crop → Resize → Normalisasi → Done
///  Input size: 224x224 (disinkronisasi dengan MediaPipe optimal)
/// ═══════════════════════════════════════════════════════════════════

Future<<InferenceResult> runPcdPipelineFallback(IsolatePayload payload) async {
  // ── Step 1: Decode raw bytes jadi pixel array ──────────────────────
  final preprocessed = _preprocessFromPlanes(payload);

  // ── Step 2: TFLite Inference ───────────────────────────────────────
  // CATATAN: Implementasi nyata memerlukan tflite_flutter & model .tflite
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

// ... (rest of Ersya's implementation: _fillFromYuv420, _fillFromBgra8888, etc)
*/

/// Preprocessing frame — tidak dipakai langsung.
/// Disimpan sebagai referensi untuk TFLite fallback.
Float32List preprocessFrame(Uint8List rawBytes, int width, int height) {
  const modelSize = 224;
  final result = Float32List(modelSize * modelSize * 3);
  for (int i = 0; i < result.length; i++) {
    result[i] = (rawBytes[i % rawBytes.length] & 0xFF) / 255.0;
  }
  return result;
}

/// Mirror koordinat untuk kamera depan
List<<Offset> mirrorLandmarks(
  List<<Offset> landmarks, {
  required bool isFrontCamera,
}) {
  if (!isFrontCamera) return landmarks;
  return landmarks.map((pt) => Offset(1.0 - pt.dx, pt.dy)).toList();
}