import 'package:flutter/material.dart';
import '../../core/models/inference_result.dart';
import '../../core/theme/app_theme.dart';

/// CustomPainter yang menggambar skeleton 21 landmark tangan di atas preview kamera
class HandOverlayPainter extends CustomPainter {
  final InferenceResult result;
  final Size previewSize;

  HandOverlayPainter({required this.result, required this.previewSize});

  // Koneksi tulang tangan sesuai MediaPipe topology
  static const List<List<int>> _connections = [
    [0, 1], [1, 2], [2, 3], [3, 4],        // Jempol
    [0, 5], [5, 6], [6, 7], [7, 8],        // Telunjuk
    [0, 9], [9, 10], [10, 11], [11, 12],   // Tengah
    [0, 13], [13, 14], [14, 15], [15, 16], // Manis
    [0, 17], [17, 18], [18, 19], [19, 20], // Kelingking
    [5, 9], [9, 13], [13, 17],             // Telapak horizontal
  ];

  // Warna per jari
  static const List<Color> _fingerColors = [
    Color(0xFFFF6B6B), // Jempol — merah coral
    Color(0xFF7B61FF), // Telunjuk — violet
    Color(0xFF00D4FF), // Tengah — cyan
    Color(0xFF22D3A5), // Manis — emerald
    Color(0xFFFFB347), // Kelingking — amber
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (!result.handDetected || result.landmarks.isEmpty) return;

    // Konversi koordinat relatif → koordinat canvas
    final pts = result.landmarks.map((lm) {
      return Offset(lm.dx * size.width, lm.dy * size.height);
    }).whereType<Offset>().toList();

    // ── Gambar koneksi (tulang) ─────────────────────────────────────
    for (final conn in _connections) {
      final a = conn[0], b = conn[1];
      if (a >= pts.length || b >= pts.length) continue;

      final color = _connectionColor(a, b);
      final bonePaint = Paint()
        ..color = color.withOpacity(0.75)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Glow effect di bawah garis
      final glowPaint = Paint()
        ..color = color.withOpacity(0.25)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawLine(pts[a], pts[b], glowPaint);
      canvas.drawLine(pts[a], pts[b], bonePaint);
    }

    // ── Gambar titik landmark ───────────────────────────────────────
    for (int i = 0; i < pts.length; i++) {
      final color = _landmarkColor(i);
      final isKeyPoint = i == 0 || i % 4 == 0; // Wrist & ujung jari

      // Outer glow
      canvas.drawCircle(pts[i], isKeyPoint ? 9 : 6,
        Paint()
          ..color = color.withOpacity(0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Ring
      canvas.drawCircle(pts[i], isKeyPoint ? 6 : 4,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Inner fill
      canvas.drawCircle(pts[i], isKeyPoint ? 4 : 2.5,
        Paint()..color = Colors.white.withOpacity(0.9),
      );
    }

    // ── Label angka di atas landmark (debugging) ────────────────────
    // (disabled by default, aktifkan untuk debugging koordinat)
    // for (int i = 0; i < pts.length; i++) {
    //   final tp = TextPainter(
    //     text: TextSpan(text: '$i',
    //       style: const TextStyle(color: Colors.yellow, fontSize: 9)),
    //     textDirection: TextDirection.ltr,
    //   )..layout();
    //   tp.paint(canvas, pts[i].translate(-4, -14));
    // }
  }

  /// Tentukan warna berdasarkan indeks koneksi → jari mana
  Color _connectionColor(int a, int b) {
    if (_isThumb(a) || _isThumb(b)) return _fingerColors[0];
    if (_isIndex(a) || _isIndex(b)) return _fingerColors[1];
    if (_isMiddle(a) || _isMiddle(b)) return _fingerColors[2];
    if (_isRing(a) || _isRing(b)) return _fingerColors[3];
    if (_isPinky(a) || _isPinky(b)) return _fingerColors[4];
    return AppTheme.textSecondary;
  }

  Color _landmarkColor(int i) {
    if (_isThumb(i))  return _fingerColors[0];
    if (_isIndex(i))  return _fingerColors[1];
    if (_isMiddle(i)) return _fingerColors[2];
    if (_isRing(i))   return _fingerColors[3];
    if (_isPinky(i))  return _fingerColors[4];
    return Colors.white70;
  }

  bool _isThumb(int i)  => i >= 1  && i <= 4;
  bool _isIndex(int i)  => i >= 5  && i <= 8;
  bool _isMiddle(int i) => i >= 9  && i <= 12;
  bool _isRing(int i)   => i >= 13 && i <= 16;
  bool _isPinky(int i)  => i >= 17 && i <= 20;

  @override
  bool shouldRepaint(HandOverlayPainter old) =>
      old.result != result || old.previewSize != previewSize;
}
