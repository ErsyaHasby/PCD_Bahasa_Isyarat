import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';
import 'hand_data.dart';

class InferenceResult {
  final String label;
  final double confidence;
  final HandData hand1;
  final HandData hand2;
  final int handsDetected;
  final int latencyMs;

  const InferenceResult({
    required this.label,
    required this.confidence,
    required this.hand1,
    required this.hand2,
    required this.handsDetected,
    this.latencyMs = 0,
  });

  static const InferenceResult empty = InferenceResult(
    label: '',
    confidence: 0.0,
    hand1: HandData.empty,
    hand2: HandData.empty,
    handsDetected: 0,
    latencyMs: 0,
  );

  bool get isConfident => confidence >= 0.75;
  bool get handDetected => handsDetected > 0;
  bool get bothHandsDetected => handsDetected >= 2;

  List<LandmarkPoint> get allLandmarks => [
    ...hand1.landmarks,
    ...hand2.landmarks,
  ];

  List<Offset> get landmarkOffsets =>
      allLandmarks.map((lm) => Offset(lm.x, lm.y)).toList();

  /// Get landmarks as List<Offset> untuk UI Varian
  /// Jika 1 tangan: return 21 titik dari hand1
  /// Jika 2 tangan: return 42 titik (hand1 + hand2)
  List<Offset> get landmarks {
    if (handsDetected == 0) return [];
    if (handsDetected == 1) return hand1.landmarkOffsets;
    return [...hand1.landmarkOffsets, ...hand2.landmarkOffsets];
  }
}

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
