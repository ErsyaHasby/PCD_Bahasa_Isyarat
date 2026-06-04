import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:hand_detection/hand_detection.dart';
import '../models/hand_data.dart';

class HandLandmarkDetector {
  HandDetector? _detector;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _detector = await HandDetector.create(
        mode: HandMode.boxesAndLandmarks,
        maxDetections: 2,
      );
      _initialized = true;
      debugPrint('HandLandmarkDetector initialized');
    } catch (e) {
      debugPrint('HandLandmarkDetector init error: $e');
    }
  }

  Future<List<HandData>> processFrame(
    CameraImage image,
    CameraDescription camera,
  ) async {
    if (_detector == null) return [];

    try {
      final hands = await _detector!.detectFromCameraImage(
        image,
        rotation: _rotation(camera),
        maxDim: 640,
      );

      return hands.map((hand) => _extractHandData(hand)).toList();
    } catch (e) {
      debugPrint('HandLandmarkDetector process error: $e');
      return [];
    }
  }

  CameraFrameRotation? _rotation(CameraDescription camera) {
    if (defaultTargetPlatform == TargetPlatform.iOS) return null;
    // Android: sensorOrientation 90 = back cam, 270 = front cam
    if (camera.sensorOrientation == 90) return CameraFrameRotation.cw270;
    if (camera.sensorOrientation == 270) return CameraFrameRotation.cw90;
    return null;
  }

  HandData _extractHandData(Hand hand) {
    final count = hand.landmarks.length;
    final landmarks = List<LandmarkPoint>.generate(
      HandData.landmarkCount,
      (i) {
        if (i >= count) return LandmarkPoint.zero;
        final lm = hand.landmarks[i];
        return LandmarkPoint(
          x: lm.xNorm(hand.imageWidth),
          y: lm.yNorm(hand.imageHeight),
          z: lm.z,
        );
      },
    );
    return HandData(landmarks: landmarks, isDetected: true);
  }

  void dispose() {
    _detector?.dispose();
    _initialized = false;
  }
}
