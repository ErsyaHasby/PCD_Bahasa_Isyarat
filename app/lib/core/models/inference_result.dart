import 'dart:typed_data' show Uint8List;
import 'dart:ui' show Offset;

/// Hasil output dari Background Isolate setelah PCD + Inference
class InferenceResult {
  final String label; // Label gestur (contoh: "Halo", "A", "Terima Kasih")
  final double confidence; // Skor kepercayaan 0.0 - 1.0
  final List<Offset>
  landmarks; // 21 koordinat tangan (sudah dinormalisasi 0.0-1.0)
  final int handsDetected; // Jumlah tangan terdeteksi (0, 1, atau 2)

  const InferenceResult({
    required this.label,
    required this.confidence,
    required this.landmarks,
    required this.handsDetected,
  });

  static const InferenceResult empty = InferenceResult(
    label: '',
    confidence: 0.0,
    landmarks: [],
    handsDetected: 0,
  );

  bool get isConfident => confidence >= 0.75;
  bool get handDetected => handsDetected > 0;
  bool get bothHandsDetected => handsDetected >= 2;
}

/// Data yang dikirim ke Background Isolate
class IsolatePayload {
  final List<PlaneData> planes;
  final int width;
  final int height;
  final String formatGroup;
  final bool isFrontCamera;

  const IsolatePayload({
    required this.planes,
    required this.width,
    required this.height,
    required this.formatGroup,
    required this.isFrontCamera,
  });
}

/// Plane metadata + bytes untuk CameraImage (aman dikirim ke isolate)
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
