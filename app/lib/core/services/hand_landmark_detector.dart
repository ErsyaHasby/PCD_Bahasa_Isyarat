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
        minHandDetectionConfidence: 0.5,
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
    CameraDescription camera, {
    bool isFrontCamera = false,
  }) async {
    if (_plugin == null || _isDetecting) return [];
    _isDetecting = true;

    try {
      // Validate image dimensions
      if (image.width == 0 || image.height == 0) {
        debugPrint(
          'Warning: Invalid image dimensions: ${image.width}x${image.height}',
        );
        return [];
      }

      final hands = _plugin!.detect(image, 0);

      // Debug: log sensor orientation & hand count
      debugPrint(
        'HandDetect: sensorOrientation=${camera.sensorOrientation} hands=${hands.length} isFrontCamera=$isFrontCamera',
      );

      // Pass sensorOrientation so extraction can account for image rotation
      return hands
          .map(
            (hand) => _extractHandData(
              hand,
              image.width,
              image.height,
              camera.sensorOrientation,
              isFrontCamera: isFrontCamera,
            ),
          )
          .toList();
    } catch (e, stack) {
      debugPrint('HandLandmarkDetector process error: $e\n$stack');
      return [];
    } finally {
      _isDetecting = false;
    }
  }

  HandData _extractHandData(
    Hand hand,
    int imageWidth,
    int imageHeight,
    int sensorOrientation, {
    bool isFrontCamera = false,
  }) {
    try {
      // MediaPipe outputs landmarks in the ORIGINAL (unrotated) image coordinate
      // space. The hand_landmarker plugin passes sensorOrientation as
      // setRotationDegrees for internal processing, but the returned x,y are
      // still in sensor-native coordinates (e.g. 720×480 landscape).
      // We must rotate them to display (portrait) space here.
      if (hand.landmarks.isNotEmpty) {
        final raw0 = hand.landmarks[0];
        debugPrint(
          'RawMediaPipe: first=(${raw0.x.toStringAsFixed(2)}, ${raw0.y.toStringAsFixed(2)}) dims=${imageWidth}x$imageHeight rot=$sensorOrientation',
        );
      }

      final landmarks = hand.landmarks.map((lm) {
        double dx, dy;

        // Rotate from sensor orientation to display orientation.
        // sensorOrientation is the counter-clockwise rotation needed.
        switch (sensorOrientation) {
          case 0:
            dx = lm.x;
            dy = lm.y;
          case 90:
            // Swapped with 270 to fix 180-degree inversion
            dx = 1.0 - lm.y;
            dy = lm.x;
          case 180:
            dx = 1.0 - lm.x;
            dy = 1.0 - lm.y;
          case 270:
            // Swapped with 90 to fix 180-degree inversion
            dx = lm.y;
            dy = 1.0 - lm.x;
          default:
            dx = lm.x;
            dy = lm.y;
        }

        // Mirror for front camera
        if (isFrontCamera) {
          dx = 1.0 - dx;
        }

        return LandmarkPoint(x: dx, y: dy, z: lm.z);
      }).toList();

      // Validate landmark count (should be 21 for MediaPipe Hands)
      if (landmarks.isEmpty) {
        debugPrint('Warning: Empty landmarks detected');
        return HandData.empty;
      }

      if (landmarks.length != HandData.landmarkCount) {
        debugPrint(
          'Warning: Expected ${HandData.landmarkCount} landmarks, got ${landmarks.length}',
        );
        // Pad or truncate to 21 landmarks
        final padded = List<LandmarkPoint>.filled(
          HandData.landmarkCount,
          LandmarkPoint.zero,
        );
        for (
          int i = 0;
          i < landmarks.length && i < HandData.landmarkCount;
          i++
        ) {
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
