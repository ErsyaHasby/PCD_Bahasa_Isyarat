import 'package:flutter/material.dart';
import '../../core/models/inference_result.dart';
import '../../core/models/hand_data.dart';
import '../../core/theme/app_theme.dart';

class HandOverlayPainter extends CustomPainter {
  final InferenceResult result;
  final Size previewSize;
  final Size screenSize;
  final bool isFrontCamera;
  final int sensorOrientation;

  HandOverlayPainter({
    required this.result,
    required this.previewSize,
    required this.screenSize,
    this.isFrontCamera = true,
    this.sensorOrientation = 0,
  });

  static const List<List<int>> _connections = [
    [0, 1],
    [1, 2],
    [2, 3],
    [3, 4],
    [0, 5],
    [5, 6],
    [6, 7],
    [7, 8],
    [0, 9],
    [9, 10],
    [10, 11],
    [11, 12],
    [0, 13],
    [13, 14],
    [14, 15],
    [15, 16],
    [0, 17],
    [17, 18],
    [18, 19],
    [19, 20],
    [5, 9],
    [9, 13],
    [13, 17],
  ];

  static const List<Color> _fingerColors = [
    Color(0xFFFF6B6B),
    Color(0xFF7B61FF),
    Color(0xFF00D4FF),
    Color(0xFF22D3A5),
    Color(0xFFFFB347),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (!result.handDetected) return;

    // CameraPreview rotates the image based on sensorOrientation, so the
    // effective display aspect ratio may be swapped relative to previewSize.
    final isRotated = (sensorOrientation % 180 == 90);
    final dispW = isRotated ? previewSize.height : previewSize.width;
    final dispH = isRotated ? previewSize.width : previewSize.height;
    final cameraAspect = dispW / dispH;
    final screenAspect = screenSize.width / screenSize.height;

    // Calculate actual displayed camera preview size (with aspect ratio preservation)
    Size displayedSize;
    Offset offset;

    if (screenAspect > cameraAspect) {
      // Screen is wider than camera - height constrained, letterboxing on left/right
      displayedSize = Size(size.height * cameraAspect, size.height);
      offset = Offset((size.width - displayedSize.width) / 2, 0);
    } else {
      // Screen is taller than camera - width constrained, letterboxing on top/bottom
      displayedSize = Size(size.width, size.width / cameraAspect);
      offset = Offset(0, (size.height - displayedSize.height) / 2);
    }

    debugPrint(
      'OverlayPainter: screenSize=$screenSize, previewSize=$previewSize sensorOrientation=$sensorOrientation',
    );
    debugPrint(
      'cameraAspect=$cameraAspect displayedSize=$displayedSize, offset=$offset',
    );

    if (result.hand1.isDetected) {
      debugPrint(
        'Hand1 landmarks: ${result.hand1.landmarks.map((lm) => '(${lm.x.toStringAsFixed(2)}, ${lm.y.toStringAsFixed(2)})').take(5).join(', ')}...',
      );
      _drawHand(canvas, displayedSize, offset, result.hand1.landmarks, 0);
    }
    if (result.hand2.isDetected) {
      _drawHand(canvas, displayedSize, offset, result.hand2.landmarks, 1);
    }
  }

  void _drawHand(
    Canvas canvas,
    Size size,
    Offset offset,
    List<LandmarkPoint> landmarks,
    int handIndex,
  ) {
    final pts = landmarks.map((lm) {
      final x = lm.x;
      final y = lm.y;

      // Scale to displayed size and apply offset
      return Offset(x * size.width + offset.dx, y * size.height + offset.dy);
    }).toList();

    for (final conn in _connections) {
      final a = conn[0], b = conn[1];
      if (a >= pts.length || b >= pts.length) continue;

      final color = _connectionColor(a, b).withOpacity(0.75);
      final bonePaint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final glowPaint = Paint()
        ..color = color.withOpacity(0.25)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawLine(pts[a], pts[b], glowPaint);
      canvas.drawLine(pts[a], pts[b], bonePaint);
    }

    for (int i = 0; i < pts.length; i++) {
      final color = _landmarkColor(i);
      final isKeyPoint = i == 0 || i % 4 == 0;

      canvas.drawCircle(
        pts[i],
        isKeyPoint ? 9 : 6,
        Paint()
          ..color = color.withOpacity(0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      canvas.drawCircle(
        pts[i],
        isKeyPoint ? 6 : 4,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      canvas.drawCircle(
        pts[i],
        isKeyPoint ? 4 : 2.5,
        Paint()..color = Colors.white.withOpacity(0.9),
      );
    }
  }

  Color _connectionColor(int a, int b) {
    if (_isThumb(a) || _isThumb(b)) return _fingerColors[0];
    if (_isIndex(a) || _isIndex(b)) return _fingerColors[1];
    if (_isMiddle(a) || _isMiddle(b)) return _fingerColors[2];
    if (_isRing(a) || _isRing(b)) return _fingerColors[3];
    if (_isPinky(a) || _isPinky(b)) return _fingerColors[4];
    return AppTheme.textSecondary;
  }

  Color _landmarkColor(int i) {
    if (_isThumb(i)) return _fingerColors[0];
    if (_isIndex(i)) return _fingerColors[1];
    if (_isMiddle(i)) return _fingerColors[2];
    if (_isRing(i)) return _fingerColors[3];
    if (_isPinky(i)) return _fingerColors[4];
    return Colors.white70;
  }

  bool _isThumb(int i) => i >= 1 && i <= 4;
  bool _isIndex(int i) => i >= 5 && i <= 8;
  bool _isMiddle(int i) => i >= 9 && i <= 12;
  bool _isRing(int i) => i >= 13 && i <= 16;
  bool _isPinky(int i) => i >= 17 && i <= 20;

  @override
  bool shouldRepaint(HandOverlayPainter old) =>
      old.result != result ||
      old.previewSize != previewSize ||
      old.screenSize != screenSize ||
      old.isFrontCamera != isFrontCamera ||
      old.sensorOrientation != sensorOrientation;
}
