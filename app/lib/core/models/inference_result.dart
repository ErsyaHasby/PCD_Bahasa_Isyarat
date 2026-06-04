import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';

/// Hasil output dari Background Isolate setelah PCD + Inference
class InferenceResult {
  final String label; // Label gestur (contoh: "Halo", "A", "Terima Kasih")
  final double confidence; // Skor kepercayaan 0.0 - 1.0
  final List<Offset>
  landmarks; // 21 koordinat tangan (sudah dinormalisasi 0.0-1.0)
  final int handsDetected; // Jumlah tangan terdeteksi (0, 1, atau 2)
  final int latencyMs; // E2E Latency

  const InferenceResult({
    required this.label,
    required this.confidence,
    required this.landmarks,
    required this.handsDetected,
    required this.latencyMs,
  });

  static const InferenceResult empty = InferenceResult(
    label: '',
    confidence: 0.0,
    landmarks: [],
    handsDetected: 0,
    latencyMs: 0,
  );

  bool get isConfident => confidence >= 0.75;
  bool get handDetected => handsDetected > 0;
  bool get bothHandsDetected => handsDetected >= 2;
}

/// Data yang dikirim ke Background Isolate
class IsolatePayload {
  final Uint8List bytes;
  final int width;
  final int height;
  final bool isFrontCamera;

  const IsolatePayload({
    required this.bytes,
    required this.width,
    required this.height,
    required this.isFrontCamera,
  });
}
