import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import 'package:camera/camera.dart';

import '../../core/models/inference_result.dart';
import '../../core/models/hand_data.dart';
import '../../core/services/hand_landmark_detector.dart';
import '../../core/services/hand_classifier.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/journal_repository.dart';
import '../../core/services/pcd_frame_processor.dart';
import '../../core/services/tts_service.dart';
import 'hand_overlay_painter.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  // ── Services ───────────────────────────────────────────────────────
  final _tts = TtsService();
  final _repo = JournalRepository();
  final _pcdProcessor = PcdFrameProcessor();

  // ── State ──────────────────────────────────────────────────────────
  InferenceResult _result = InferenceResult.empty;
  String _phraseBuffer = ''; // The full sentence being built
  String _detectingLabel = ''; // The current letter being hovered
  int _detectingStartMs = 0; // When the current hover started
  String _lastRegisteredLabel = ''; // To prevent registering the same letter repeatedly
  
  CameraController? _cameraCtrl;
  List<CameraDescription> _cameras = [];
  bool _isCameraReady = false;
  bool _isFrontCamera = true;
  bool _isTtsEnabled = true;
  bool _isProcessing = false;
  String? _lastSpokenText;

  // ── Hand Detection State ───────────────────────────────────────────
  bool _bothHandsDetected = false;
  bool _handReadyNotified = false;
  int _lastHandsCount = 0;

  // ── Asset Cache untuk Isolate ──────────────────────────────────────
  Uint8List? _modelBytes;
  String? _labelsJson;

  // ── Animations ─────────────────────────────────────────────────────
  late AnimationController _textCtrl;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;

  // ── Camera stream control ─────────────────────────────────────────
  bool _isStreaming = false;
  int _sensorOrientation = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _tts.initialize();
    _preloadAssets();
    _initRealCamera();
  }

  Future<void> _preloadAssets() async {
    try {
      final bytes = await rootBundle.load('assets/models/gesture_model.onnx');
      _modelBytes = bytes.buffer.asUint8List();
      _labelsJson = await rootBundle.loadString('assets/models/labels.json');
      
      // Initialize persistent background isolate
      await _pcdProcessor.initialize(_modelBytes!, _labelsJson!);
    } catch (e) {
      debugPrint('Failed to preload ONNX assets: $e');
    }
  }

  Future<void> _initRealCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _setCamera(
          _isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back,
        );
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _setCamera(CameraLensDirection dir) async {
    if (_cameras.isEmpty) return;

    CameraDescription? target;
    try {
      target = _cameras.firstWhere((c) => c.lensDirection == dir);
    } catch (_) {
      target = _cameras.first;
    }

    final oldCtrl = _cameraCtrl;
    _cameraCtrl = CameraController(
      target,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _cameraCtrl!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraReady = true;
        _sensorOrientation = target?.sensorOrientation ?? 0;
      });
      await _startImageStream();
    } catch (e) {
      debugPrint('Camera set error: $e');
    }

    if (oldCtrl != null) {
      try {
        if (oldCtrl.value.isStreamingImages) {
          await oldCtrl.stopImageStream();
        }
      } catch (_) {}
      await oldCtrl.dispose();
    }
  }

  void _setupAnimations() {
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));
    _textFade = CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
  }

  List<PlaneData> _buildPlaneData(List<Plane> planes) {
    return planes.map((p) => PlaneData(
      bytes: p.bytes,
      bytesPerRow: p.bytesPerRow,
      bytesPerPixel: p.bytesPerPixel,
    )).toList();
  }

  Future<void> _startImageStream() async {
    if (_cameraCtrl == null || _isStreaming) return;
    try {
      await _cameraCtrl!.startImageStream(_onCameraImage);
      _isStreaming = true;
    } catch (e) {
      debugPrint('Camera stream error: $e');
    }
  }

  void _onCameraImage(CameraImage image) {
    _processFrame(image);
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessing || !mounted) return;
    _isProcessing = true;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    try {
      final payload = IsolatePayload(
        planes: _buildPlaneData(image.planes),
        width: image.width,
        height: image.height,
        formatGroup: image.format.group.name,
        isFrontCamera: _isFrontCamera,
        sensorOrientation: _sensorOrientation,
      );

      // Run MediaPipe & ONNX entirely in the persistent background isolate!
      final result = await _pcdProcessor.processFrame(payload);

      if (!mounted) return;

      setState(() => _result = result);
      _checkHandsDetection(result);
      if (_bothHandsDetected) {
        _maybeUpdateTranslation(result);
      }
    } catch (e) {
      debugPrint('PCD process error: $e');
    } finally {
      if (mounted) _isProcessing = false;
    }
  }

  // _processFrameIsolate dihilangkan karena menggunakan PcdFrameProcessor

  void _checkHandsDetection(InferenceResult result) {
    final handsCount = result.handsDetected;

    // Deteksi perubahan status
    if (handsCount >= 1 && !_bothHandsDetected) {
      setState(() => _bothHandsDetected = true);
      _handReadyNotified = false; // Reset flag
      // Trigger notifikasi
      _notifyHandsReady();
    } else if (handsCount < 1 && _bothHandsDetected) {
      setState(() {
        _bothHandsDetected = false;
        _detectingLabel = ''; // Reset detecting state
        _lastRegisteredLabel = ''; // Reset cooldown so they can re-register later
      });
      _handReadyNotified = false;
    }

    _lastHandsCount = handsCount;
  }

  void _notifyHandsReady() {
    if (_handReadyNotified) return;
    _handReadyNotified = true;

    // Suara notifikasi
    if (_isTtsEnabled) {
      _tts.speak('Tangan terdeteksi. Siap meragakan isyarat.');
      Vibration.vibrate(duration: 150, amplitude: 255);
    }
  }

  void _maybeUpdateTranslation(InferenceResult result) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Jika hasil tidak valid, reset state pendeteksian
    if (result.label.isEmpty || !result.isConfident) {
      if (_detectingLabel.isNotEmpty) {
        setState(() {
          _detectingLabel = '';
          _lastRegisteredLabel = '';
        });
      }
      return;
    }

    final currentLabel = result.label;

    // Jika label berubah dari yang sedang dideteksi
    if (currentLabel != _detectingLabel) {
      setState(() {
        _detectingLabel = currentLabel;
        _detectingStartMs = nowMs;
      });
      return;
    }

    // Jika label sama dengan yang sedang dideteksi dan belum masuk cooldown (belum terdaftar)
    if (currentLabel != _lastRegisteredLabel) {
      final holdDuration = nowMs - _detectingStartMs;

      // Render progress bar secara halus dengan memanggil setState
      setState(() {});

      // Jika sudah ditahan selama 2 detik
      if (holdDuration >= 2000) {
        _registerLetter(currentLabel);
      }
    }
  }

  void _registerLetter(String letter) {
    setState(() {
      _phraseBuffer += letter;
      _lastRegisteredLabel = letter;
      _detectingLabel = ''; // Reset visual progress bar
    });
    
    _textCtrl.forward(from: 0);

    if (_isTtsEnabled) {
      _tts.speak(letter);
    }
    Vibration.vibrate(duration: 80, amplitude: 128);
  }

  void _saveSession() {
    if (_phraseBuffer.isEmpty) return;
    
    if (_isTtsEnabled) {
      _tts.speak(_phraseBuffer);
    }

    // Simpan ke jurnal (Hive)
    _repo.saveEntry(
      translatedText: _phraseBuffer,
      confidenceScore: 1.0, // Assumed confident since user verified it
      gestureLabel: 'Session',
    );

    setState(() {
      _phraseBuffer = '';
      _detectingLabel = '';
      _lastRegisteredLabel = '';
    });
  }

  void _addSpace() {
    setState(() {
      _phraseBuffer += ' ';
      _lastRegisteredLabel = ''; // reset cooldown
    });
  }

  void _backspace() {
    if (_phraseBuffer.isNotEmpty) {
      setState(() {
        _phraseBuffer = _phraseBuffer.substring(0, _phraseBuffer.length - 1);
        _lastRegisteredLabel = ''; // reset cooldown
      });
    }
  }

  void _toggleCamera() {
    setState(() => _isFrontCamera = !_isFrontCamera);
    _setCamera(
      _isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back,
    );
    HapticFeedback.lightImpact();
  }

  void _toggleTts() {
    setState(() => _isTtsEnabled = !_isTtsEnabled);
    if (!_isTtsEnabled) _tts.stop();
    HapticFeedback.lightImpact();
  }

  @override
  void dispose() {
    try {
      if (_cameraCtrl?.value.isStreamingImages ?? false) {
        _cameraCtrl?.stopImageStream();
      }
    } catch (_) {}
    _cameraCtrl?.dispose();
    _textCtrl.dispose();
    _tts.dispose();
    _pcdProcessor.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Camera preview ──────────────────────────────────────────
          if (_cameraCtrl != null && _cameraCtrl!.value.isInitialized)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraCtrl!.value.previewSize?.height ?? 1,
                  height: _cameraCtrl!.value.previewSize?.width ?? 1,
                  child: CameraPreview(_cameraCtrl!),
                ),
              ),
            )
          else
            _buildCameraBackground(),

          // ── Hand skeleton overlay ───────────────────────────────────
          if (_isCameraReady)
            CustomPaint(
              painter: HandOverlayPainter(
                result: _result,
                previewSize: Size(
                  _cameraCtrl!.value.previewSize!.width.toDouble(),
                  _cameraCtrl!.value.previewSize!.height.toDouble(),
                ),
                screenSize: MediaQuery.of(context).size,
                isFrontCamera: _isFrontCamera,
                sensorOrientation: _sensorOrientation,
              ),
            ),

          // ── Hand detection status & Top buttons ───────────────────────
          if (_isCameraReady)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: SafeArea(
                child: Row(
                  children: [
                    _CircleButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => context.go('/'),
                    ),
                    const Spacer(),
                    if (!_bothHandsDetected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Deteksi: ${_lastHandsCount} tangan',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textHint,
                          ),
                        ),
                      ),
                    if (_bothHandsDetected)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '⏱ ${_result.latencyMs} ms',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _result.latencyMs < 300
                                ? AppTheme.success
                                : AppTheme.warning,
                          ),
                        ),
                      ),
                    const Spacer(),
                    _CircleButton(
                      icon: _isTtsEnabled
                          ? Icons.volume_up_rounded
                          : Icons.volume_off_rounded,
                      color: _isTtsEnabled ? AppTheme.secondary : null,
                      onTap: _toggleTts,
                    ),
                    const SizedBox(width: 8),
                    _CircleButton(
                      icon: Icons.flip_camera_android_rounded,
                      onTap: _toggleCamera,
                    ),
                  ],
                ),
              ),
            ),

          // ── Translation panel (bottom) ──────────────────────────────
          if (_bothHandsDetected || _phraseBuffer.isNotEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildTranslationPanel(),
            ),

          // ── Hand detection awaiting ─────────────────────────────────
          if (!_bothHandsDetected && _phraseBuffer.isEmpty && _isCameraReady)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Letakkan tangan di depan kamera',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Loading overlay ───────────────────────────────────────────
          if (!_isCameraReady) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // ── Camera Background (simulasi, ganti dengan CameraPreview) ────────
  Widget _buildCameraBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D0D18), Color(0xFF1A1025), Color(0xFF0D0D18)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.06,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 8,
              childAspectRatio: 1,
            ),
            itemCount: 120,
            itemBuilder: (_, i) => Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primary, width: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Top App Bar ──────────────────────────────────────────────────────
  // REMOVED: Simplified UI

  // ── Guide Overlay ────────────────────────────────────────────────────
  // REMOVED: Simplified UI

  // ── Translation Panel ─────────────────────────────────────────────────
  Widget _buildTranslationPanel() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final isDetecting = _detectingLabel.isNotEmpty && _detectingLabel != _lastRegisteredLabel;
    final holdProgress = isDetecting 
        ? ((nowMs - _detectingStartMs) / 2000.0).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surface.withOpacity(0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _phraseBuffer.isNotEmpty || isDetecting
                  ? AppTheme.primary.withOpacity(0.4)
                  : AppTheme.divider,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teks Sesi Utuh
              _phraseBuffer.isEmpty
                  ? Text(
                      'Mulai ragakan isyarat...',
                      style: TextStyle(
                        fontSize: 18,
                        color: AppTheme.textHint,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Text(
                      _phraseBuffer,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
              
              const SizedBox(height: 16),

              // Indikator Hold & Kontrol UI
              Row(
                children: [
                  // Progress indicator untuk mendeteksi
                  if (isDetecting) ...[
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        value: holdProgress,
                        color: AppTheme.primary,
                        backgroundColor: AppTheme.divider,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Menahan "$_detectingLabel"...',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else if (_phraseBuffer.isNotEmpty) ...[
                    // Tampilkan indikator idle jika sedang tidak ada gestur
                    Text(
                      'Sesi aktif. Lanjutkan...',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textHint,
                      ),
                    ),
                  ],

                  const Spacer(),

                  // Tombol UI
                  if (_phraseBuffer.isNotEmpty) ...[
                    IconButton(
                      icon: const Icon(Icons.backspace_rounded, size: 20),
                      color: AppTheme.textSecondary,
                      onPressed: _backspace,
                      tooltip: 'Hapus',
                    ),
                    IconButton(
                      icon: const Icon(Icons.space_bar_rounded, size: 20),
                      color: AppTheme.textSecondary,
                      onPressed: _addSpace,
                      tooltip: 'Spasi',
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save_rounded, size: 16),
                      label: const Text('Simpan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: _saveSession,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Loading Overlay ───────────────────────────────────────────────────
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 16),
            Text(
              'Menginisialisasi kamera...',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Reusable Widgets
// ═══════════════════════════════════════════════════════════════════════

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;
  const _CircleButton({required this.icon, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.divider),
        ),
        child: Icon(icon, size: 18, color: color ?? AppTheme.textPrimary),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
//  Additional Widgets (Confidence Bar, etc)
// ═══════════════════════════════════════════════════════════════════════

class _ConfidenceBar extends StatelessWidget {
  final double confidence;
  const _ConfidenceBar({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final color = confidence >= 0.85
        ? AppTheme.success
        : confidence >= 0.70
        ? AppTheme.warning
        : AppTheme.error;
    return Row(
      children: [
        Text(
          'Akurasi ',
          style: TextStyle(fontSize: 11, color: AppTheme.textHint),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: confidence,
              backgroundColor: AppTheme.divider,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 5,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '${(confidence * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _GuideOverlayPainter extends CustomPainter {
  final double pulse;
  final bool handDetected;

  _GuideOverlayPainter({required this.pulse, required this.handDetected});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (handDetected ? AppTheme.success : Colors.white).withOpacity(
        0.7,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final glow = Paint()
      ..color = (handDetected ? AppTheme.success : AppTheme.primary)
          .withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final faceRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.28),
        width: size.width * 0.55,
        height: size.height * 0.26,
      ),
      const Radius.circular(28),
    );

    final handRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.68),
        width: size.width * 0.72,
        height: size.height * 0.30,
      ),
      const Radius.circular(28),
    );

    canvas.drawRRect(faceRect, glow);
    canvas.drawRRect(handRect, glow);
    canvas.drawRRect(faceRect, paint);
    canvas.drawRRect(handRect, paint);

    _drawLabel(canvas, size, 'Wajah', faceRect, pulse);
    _drawLabel(canvas, size, 'Tangan', handRect, pulse);
  }

  void _drawLabel(
    Canvas canvas,
    Size size,
    String text,
    RRect rect,
    double pulse,
  ) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final offset = Offset(rect.left + 16, rect.top - 22 - (pulse - 1) * 6);

    final bg = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(offset.dx - 6, offset.dy - 2, tp.width + 12, tp.height + 6),
      const Radius.circular(12),
    );

    canvas.drawRRect(bgRect, bg);
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _GuideOverlayPainter oldDelegate) {
    return oldDelegate.pulse != pulse ||
        oldDelegate.handDetected != handDetected;
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomGradient extends StatelessWidget {
  const _BottomGradient();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withOpacity(0.85)],
        ),
      ),
    );
  }
}
