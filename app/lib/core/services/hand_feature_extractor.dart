import 'dart:math';
import '../models/hand_data.dart';
import '../models/feature_set.dart';

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

  List<double> extractGeometric(List<List<LandmarkPoint>> hands) {
    final features = <double>[];

    for (int h = 0; h < 2; h++) {
      features.addAll(_fingerDistances(hands[h]));
      features.addAll(_fingerAngles(hands[h]));
      features.addAll(_fingerRatios(hands[h]));
    }

    return features;
  }

  List<double> _fingerDistances(List<LandmarkPoint> lm) {
    final fingertipIndices = [4, 8, 12, 16, 20];
    // wrist (0) to each fingertip
    final distances = fingertipIndices.map((i) => _dist(lm[0], lm[i]));
    // thumb tip to index tip (pinch distance)
    final pinchDist = _dist(lm[4], lm[8]);
    // palm width: index MCP to pinky MCP
    final palmWidth = _dist(lm[5], lm[17]);
    return [...distances, pinchDist, palmWidth];
  }

  List<double> _fingerAngles(List<LandmarkPoint> lm) {
    final angles = <double>[];
    // Finger curl angle (MCP-PIP-DIP angle) for index, middle, ring, pinky
    final fingerJoints = [
      [5, 6, 7],
      [9, 10, 11],
      [13, 14, 15],
      [17, 18, 19],
    ];
    for (final joint in fingerJoints) {
      angles.add(_angle(lm[joint[0]], lm[joint[1]], lm[joint[2]]));
    }
    // Spread angle between adjacent fingers at MCP
    final mcpIndices = [5, 9, 13, 17];
    for (int i = 0; i < mcpIndices.length - 1; i++) {
      angles.add(_angle(lm[0], lm[mcpIndices[i]], lm[mcpIndices[i + 1]]));
    }
    return angles;
  }

  List<double> _fingerRatios(List<LandmarkPoint> lm) {
    final fingerLengths = [
      _dist(lm[5], lm[8]),  // index
      _dist(lm[9], lm[12]), // middle
      _dist(lm[13], lm[16]), // ring
      _dist(lm[17], lm[20]), // pinky
    ];
    final middleLen = fingerLengths[1];
    if (middleLen < 1e-6) return [0, 0, 0, 0];
    // Ratios relative to middle finger
    return [
      fingerLengths[0] / middleLen, // index/middle
      fingerLengths[2] / middleLen, // ring/middle
      fingerLengths[3] / middleLen, // pinky/middle
      _dist(lm[1], lm[5]) / middleLen, // thumb base to index base
    ];
  }

  FeatureSet extractAll(
    List<List<LandmarkPoint>> hands, {
    bool useZ = true,
  }) {
    final handCount = hands[0].any((lm) => lm != LandmarkPoint.zero) ? 1 : 0;
    final hasSecond =
        handCount > 0 && hands[1].any((lm) => lm != LandmarkPoint.zero);

    return FeatureSet(
      landmarkVector: flatten(hands, useZ: useZ),
      geometricFeatures: extractGeometric(hands),
      handCount: hasSecond ? 2 : handCount,
      useZ: useZ,
    );
  }

  double _dist(LandmarkPoint a, LandmarkPoint b) {
    return sqrt(
      (a.x - b.x) * (a.x - b.x) +
          (a.y - b.y) * (a.y - b.y) +
          (a.z - b.z) * (a.z - b.z),
    );
  }

  double _angle(LandmarkPoint a, LandmarkPoint b, LandmarkPoint c) {
    final v1 = (a.x - b.x, a.y - b.y, a.z - b.z);
    final v2 = (c.x - b.x, c.y - b.y, c.z - b.z);
    final dot = v1.$1 * v2.$1 + v1.$2 * v2.$2 + v1.$3 * v2.$3;
    final m1 = sqrt(v1.$1 * v1.$1 + v1.$2 * v1.$2 + v1.$3 * v1.$3);
    final m2 = sqrt(v2.$1 * v2.$1 + v2.$2 * v2.$2 + v2.$3 * v2.$3);
    if (m1 < 1e-6 || m2 < 1e-6) return 0;
    return acos((dot / (m1 * m2)).clamp(-1.0, 1.0));
  }

  void reset() {
    _buffer = [[], []];
  }
}
