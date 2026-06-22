import 'dart:ui' show Offset;

class LandmarkPoint {
  final double x;
  final double y;
  final double z;

  const LandmarkPoint({required this.x, required this.y, required this.z});

  Offset get toOffset => Offset(x, y);

  Map<String, double> toMap() => {'x': x, 'y': y, 'z': z};

  static const LandmarkPoint zero = LandmarkPoint(x: 0, y: 0, z: 0);
}

class HandData {
  final List<LandmarkPoint> landmarks;
  final bool isDetected;

  static const int landmarkCount = 21;

  const HandData({required this.landmarks, required this.isDetected});

  static const HandData empty = HandData(landmarks: [], isDetected: false);

  static final HandData zero = HandData(
    landmarks: List<LandmarkPoint>.filled(21, LandmarkPoint.zero),
    isDetected: false,
  );

  int get count => isDetected ? 1 : 0;

  /// Get landmarks as List<Offset> untuk UI Varian
  List<Offset> get landmarkOffsets =>
      landmarks.map((lm) => lm.toOffset).toList();
}
