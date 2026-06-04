import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import '../models/hand_data.dart';

class HandLandmarkDetector {
  HandLandmarkerPlugin? _plugin;
  bool _initialized = false;
  bool _isDetecting = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      _plugin = HandLandmarkerPlugin.create(
        numHands: 2,
        minHandDetectionConfidence: 0.7,
        delegate: HandLandmarkerDelegate.cpu,
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
    if (_plugin == null || _isDetecting) return [];
    _isDetecting = true;

    try {
      // Validate image dimensions
      if (image.width == 0 || image.height == 0) {
        debugPrint('Warning: Invalid image dimensions: ${image.width}x${image.height}');
        return [];
      }

      final hands = _plugin!.detect(image, camera.sensorOrientation);

      // Debug: log sensor orientation & hand count
      debugPrint('HandDetect: sensorOrientation=${camera.sensorOrientation} hands=${hands.length}');

      return hands.map(_extractHandData).toList();
    } catch (e, stack) {
      debugPrint('HandLandmarkDetector process error: $e\n$stack');
      return [];
    } finally {
      _isDetecting = false;
    }
  }

  HandData _extractHandData(Hand hand) {
    try {
      final landmarks = hand.landmarks.map((lm) => LandmarkPoint(
        x: lm.x,
        y: lm.y,
        z: lm.z,
      )).toList();

      // Validate landmark count (should be 21 for MediaPipe Hands)
      if (landmarks.isEmpty) {
        debugPrint('Warning: Empty landmarks detected');
        return HandData.empty;
      }

      if (landmarks.length != HandData.landmarkCount) {
        debugPrint('Warning: Expected ${HandData.landmarkCount} landmarks, got ${landmarks.length}');
        // Pad or truncate to 21 landmarks
        final padded = List<LandmarkPoint>.filled(
          HandData.landmarkCount,
          LandmarkPoint.zero,
        );
        for (int i = 0; i < landmarks.length && i < HandData.landmarkCount; i++) {
          padded[i] = landmarks[i];
        }
        return HandData(landmarks: padded, isDetected: true);
      }

      return HandData(landmarks: landmarks, isDetected: true);
    } catch (e) {
      debugPrint('Error extracting hand data: $e');
      return HandData.empty;
    }
  }

  void dispose() {
    _plugin?.dispose();
    _initialized = false;
  }
}
