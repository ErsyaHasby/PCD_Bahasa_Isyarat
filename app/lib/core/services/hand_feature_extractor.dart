import 'dart:math';
import '../models/hand_data.dart';

class HandFeatureExtractor {
  final int smoothWindow;
  late List<List<List<LandmarkPoint>>> _buffer;

  HandFeatureExtractor({this.smoothWindow = 3}) {
    _buffer = [[], []];
  }

  List<List<LandmarkPoint>> normalize(List<HandData> hands) {
    final result = <List<LandmarkPoint>>[];

    for (int h = 0; h < 2; h++) {
      if (h < hands.length && hands[h].isDetected) {
        result.add(_normalizeHand(hands[h].landmarks));
      } else {
        result.add(List<LandmarkPoint>.filled(
          HandData.landmarkCount,
          LandmarkPoint.zero,
        ));
      }
    }

    return result;
  }

  List<LandmarkPoint> _normalizeHand(List<LandmarkPoint> raw) {
    if (raw.isEmpty || raw.length < HandData.landmarkCount) {
      return List<LandmarkPoint>.filled(
        HandData.landmarkCount,
        LandmarkPoint.zero,
      );
    }

    final wrist = raw[0];
    final mcp = raw[9];

    final scale = sqrt(
      (mcp.x - wrist.x) * (mcp.x - wrist.x) +
          (mcp.y - wrist.y) * (mcp.y - wrist.y) +
          (mcp.z - wrist.z) * (mcp.z - wrist.z),
    );

    if (scale < 1e-6) {
      return raw.map((_) => LandmarkPoint.zero).toList();
    }

    return raw.map((lm) {
      return LandmarkPoint(
        x: (lm.x - wrist.x) / scale,
        y: (lm.y - wrist.y) / scale,
        z: (lm.z - wrist.z) / scale,
      );
    }).toList();
  }

  List<List<LandmarkPoint>> smooth(List<List<LandmarkPoint>> hands) {
    final result = <List<LandmarkPoint>>[];

    for (int h = 0; h < 2; h++) {
      _buffer[h].add(hands[h]);

      while (_buffer[h].length > smoothWindow) {
        _buffer[h].removeAt(0);
      }

      result.add(_averageLandmarks(_buffer[h]));
    }

    return result;
  }

  List<LandmarkPoint> _averageLandmarks(List<List<LandmarkPoint>> frames) {
    if (frames.isEmpty) {
      return List<LandmarkPoint>.filled(
        HandData.landmarkCount,
        LandmarkPoint.zero,
      );
    }

    if (frames.length == 1) return frames[0];

    final count = frames.length;
    return List<LandmarkPoint>.generate(HandData.landmarkCount, (i) {
      double sumX = 0, sumY = 0, sumZ = 0;
      for (final frame in frames) {
        if (i < frame.length) {
          sumX += frame[i].x;
          sumY += frame[i].y;
          sumZ += frame[i].z;
        }
      }
      return LandmarkPoint(
        x: sumX / count,
        y: sumY / count,
        z: sumZ / count,
      );
    });
  }

  List<double> flatten(List<List<LandmarkPoint>> hands, {bool useZ = true}) {
    final features = <double>[];

    for (int h = 0; h < 2; h++) {
      for (final lm in hands[h]) {
        features.add(lm.x);
        features.add(lm.y);
        if (useZ) features.add(lm.z);
      }
    }

    return features;
  }

  void reset() {
    _buffer = [[], []];
  }
}
