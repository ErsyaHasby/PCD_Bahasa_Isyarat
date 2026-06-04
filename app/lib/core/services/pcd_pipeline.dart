import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';
import '../models/inference_result.dart';

/// Pipeline PCD + MediaPipe + Feature Extraction
///
/// Alur: CameraImage - HandDetector - Normalisasi - Smoothing - Fitur - Classifier
///
/// Implementasi runtime ada di:
///   - HandLandmarkDetector (MediaPipe via hand_detection)
///   - HandFeatureExtractor (normalisasi, smoothing, fitur)
///   - HandClassifier (inference placeholder, diganti Brata)

/// Entry point untuk background isolate — saat ini tidak dipakai
/// karena ML Kit berjalan di native thread sendiri.
/// Ke depan bisa dipakai untuk TFLite fallback.
Future<InferenceResult> runPcdPipeline(IsolatePayload payload) async {
  throw UnimplementedError(
    'PCD Pipeline via isolate digantikan oleh HandLandmarkDetector.\n'
    'Lihat camera_screen.dart untuk pipeline real-time.',
  );
}

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
List<Offset> mirrorLandmarks(
  List<Offset> landmarks, {
  required bool isFrontCamera,
}) {
  if (!isFrontCamera) return landmarks;
  return landmarks.map((pt) => Offset(1.0 - pt.dx, pt.dy)).toList();
}
