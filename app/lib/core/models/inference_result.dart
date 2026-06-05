import 'dart:typed_data' show Uint8List;
import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';
import 'hand_data.dart';

/// Hasil output dari Background Isolate setelah PCD + Inference
/// Menggunakan HandData (Alex) untuk MediaPipe integration
/// Backward compatibility dengan List<<Offset> (Ersya) untuk fallback
class InferenceResult {
  final String label;
  final double confidence;
  final HandData hand1;
  final HandData hand2;
  final int handsDetected;

  const InferenceResult({
    required this.label,
    required this.confidence,
    required this.hand1,
    required this.hand2,
    required this.handsDetected,
  });

  static const InferenceResult empty = InferenceResult(
    label: '',
    confidence: 0.0,
    hand1: HandData.empty,
    hand2: HandData.empty,
    handsDetected: 0,
  );

  bool get isConfident => confidence >= 0.75;
  bool get handDetected => handsDetected > 0;
  bool get bothHandsDetected => handsDetected >= 2;

  List<LandmarkPoint> get allLandmarks =>
      [...hand1.landmarks, ...hand2.landmarks];

  List<<Offset> get landmarkOffsets =>
      allLandmarks.map((lm) => Offset(lm.x, lm.y)).toList();
}

/// Data yang dikirim ke Background Isolate (Alex's version untuk MediaPipe)
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

/// Plane metadata + bytes untuk CameraImage (Ersya's version untuk PCD fallback)
/// Disimpan sebagai reference untuk TFLite fallback jika MediaPipe tidak tersedia
class PlaneData {
  final Uint8List bytes;
  final int bytesPerRow;
  final int bytesPerPixel;
  final int width;
  final int height;

  const PlaneData({
    required this.bytes,
    required this.bytesPerRow,
    required this.bytesPerPixel,
    required this.width,
    required this.height,
  });
}