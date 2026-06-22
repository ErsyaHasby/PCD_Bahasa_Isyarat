import 'dart:ui' show Offset;
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import '../models/inference_result.dart';
import '../models/hand_data.dart';
import 'hand_landmark_detector.dart';
import 'hand_classifier.dart';

/// ═══════════════════════════════════════════════════════════════════
///  PCD Pipeline — Berjalan di Background Isolate
///  Alur: CameraImage Planes → MediaPipe (JNI) → ONNX → Result
/// ═══════════════════════════════════════════════════════════════════

// Global state within the isolate
HandLandmarkDetector? _detector;
HandClassifier? _classifier;

Future<void> setupPcdPipeline(Uint8List? modelBytes, String? labelsJson) async {
  if (_detector != null) return;

  _detector = HandLandmarkDetector();
  await _detector!.initialize(); // uses CPU delegate by default

  _classifier = HandClassifier();
  await _classifier!.initialize(modelBytes: modelBytes, labelsJson: labelsJson);
}

/// Entry point untuk PcdFrameProcessor
Future<InferenceResult> runPcdPipeline(IsolatePayload payload) async {
  if (_detector == null || _classifier == null) {
    return InferenceResult.empty;
  }

  // 1. Reconstruct CameraImage from planes
  final mockImage = _MockCameraImage(
    width: payload.width,
    height: payload.height,
    formatGroup: payload.formatGroup,
    planes: payload.planes,
  );

  final mockCameraDesc = CameraDescription(
    name: 'mock',
    lensDirection: payload.isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back,
    sensorOrientation: payload.sensorOrientation,
  );

  // 2. Run MediaPipe Detection (JNI call, runs synchronously but inside this isolate)
  final hands = await _detector!.processFrame(
    mockImage,
    mockCameraDesc,
    isFrontCamera: payload.isFrontCamera,
  );

  if (hands.isEmpty) {
    return InferenceResult.empty;
  }

  // 3. Run ONNX Classification
  final hand1 = hands.isNotEmpty ? hands[0] : HandData.empty;
  final hand2 = hands.length > 1 ? hands[1] : HandData.empty;

  return _classifier!.classify(
    hand1: hand1,
    hand2: hand2,

    handsDetected: hands.length,
    latencyMs: 0,
  );
}

// ── Mock Classes for MediaPipe ───────────────────────────────────────

class _MockCameraImage implements CameraImage {
  @override
  final int width;
  @override
  final int height;
  @override
  final ImageFormat format;
  @override
  final List<Plane> planes;
  @override
  final double? lensAperture;
  @override
  final int? sensorExposureTime;
  @override
  final double? sensorSensitivity;

  _MockCameraImage({
    required this.width,
    required this.height,
    required String formatGroup,
    required List<PlaneData> planes,
  })  : format = _MockImageFormat(_parseFormatGroup(formatGroup), 0),
        planes = planes.map((p) => _MockPlane(p)).toList(),
        lensAperture = null,
        sensorExposureTime = null,
        sensorSensitivity = null;

  static ImageFormatGroup _parseFormatGroup(String name) {
    switch (name) {
      case 'yuv420': return ImageFormatGroup.yuv420;
      case 'bgra8888': return ImageFormatGroup.bgra8888;
      case 'nv21': return ImageFormatGroup.nv21;
      case 'jpeg': return ImageFormatGroup.jpeg;
      default: return ImageFormatGroup.unknown;
    }
  }
}

class _MockImageFormat implements ImageFormat {
  @override
  final ImageFormatGroup group;
  @override
  final int raw;

  _MockImageFormat(this.group, this.raw);
}

class _MockPlane implements Plane {
  @override
  final Uint8List bytes;
  @override
  final int bytesPerRow;
  @override
  final int? bytesPerPixel;
  @override
  final int? width;
  @override
  final int? height;

  _MockPlane(PlaneData data)
      : bytes = data.bytes,
        bytesPerRow = data.bytesPerRow,
        bytesPerPixel = data.bytesPerPixel,
        width = null,
        height = null;
}
