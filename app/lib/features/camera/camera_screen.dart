import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:vibration/vibration.dart';
import 'package:camera/camera.dart';

import '../../core/models/inference_result.dart';
import '../../core/models/hand_data.dart';
import '../../core/services/hand_landmark_detector.dart';
import '../../core/services/hand_classifier.dart';
import '../../core/services/hand_feature_extractor.dart';
import '../../core/services/tts_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/local/journal_repository.dart';
import 'hand_overlay_painter.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  final _tts = TtsService();
  final _repo = JournalRepository();
  final _detector = HandLandmarkDetector();
  final _classifier = HandClassifier();
  final _extractor = HandFeatureExtractor();

  InferenceResult _result = InferenceResult.empty;
  String _translatedText = '';
  CameraController? _cameraCtrl;
  List<CameraDescription> _cameras = [];
  bool _isCameraReady = false;
  bool _isFrontCamera = true;
  bool _isTtsEnabled = true;
  bool _isProcessing = false;
  String? _lastSpokenText;

  bool _bothHandsDetected = false;
  bool _handReadyNotified = false;
  int _lastHandsCount = 0;

  late AnimationController _textCtrl;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;

  bool _isStreaming = false;
  int _lastFrameMs = 0;
  int _lastLabelMs = 0;
  String _stableLabel = '';
  static const int _frameIntervalMs = 250;

  final List<List<LandmarkPoint>> _rawBuffer = [[], []];
  int _sensorOrientation = 0;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _tts.initialize();
    _detector.initialize();
    _initRealCamera();
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
    _detector.dispose();
    super.dispose();
  }

  Future<void> _initRealCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _setCamera(
          _isFrontCamera
              ? CameraLensDirection.front
              : CameraLensDirection.back,
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
      _sensorOrientation = target.sensorOrientation;
      debugPrint('Camera initialized successfully');
      debugPrint('Camera previewSize: ${_cameraCtrl!.value.previewSize}');
      debugPrint('Camera sensorOrientation: ${target.sensorOrientation}');
      debugPrint('Camera isInitialized: ${_cameraCtrl!.value.isInitialized}');
      debugPrint('Screen size: ${MediaQuery.of(context).size}');
      setState(() => _isCameraReady = true);
      await _startImageStream();
    } catch (e) {
      debugPrint('Camera set error: $e');
      setState(() => _isCameraReady = false);
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
    _textFade =
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut);
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
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastFrameMs < _frameIntervalMs) return;
    _lastFrameMs = nowMs;
    _processFrame(image);
  }

  Future<void> _processFrame(CameraImage image) async {
    if (_isProcessing || !mounted) return;
    _isProcessing = true;

    try {
      final camera = _cameras.firstWhere(
        (c) =>
            c.lensDirection ==
            (_isFrontCamera
                ? CameraLensDirection.front
                : CameraLensDirection.back),
        orElse: () => _cameras.first,
      );

      final handDataList = await _detector.processFrame(image, camera);

      int handsDetected = handDataList.length;

      if (!mounted) {
        _isProcessing = false;
        return;
      }

      // --- Feature pipeline (wrist-relative) for classifier ---
      final normalized = _extractor.normalize(handDataList);
      final smoothed = _extractor.smooth(normalized);

      // --- Display pipeline (raw 0-1 image coords) for skeleton overlay ---
      final rawSmoothed = _smoothRawLandmarks(handDataList);

      // Mirror horizontally for front camera (camera preview is mirrored)
      if (_isFrontCamera) {
        for (int h = 0; h < rawSmoothed.length; h++) {
          rawSmoothed[h] = rawSmoothed[h].map((lm) => LandmarkPoint(
            x: 1.0 - lm.x,
            y: lm.y,
            z: lm.z,
          )).toList();
        }
      }

      final hand1 = handDataList.isNotEmpty
          ? HandData(
              landmarks: rawSmoothed[0],
              isDetected: handDataList[0].isDetected)
          : HandData.empty;
      final hand2 = handDataList.length >= 2
          ? HandData(
              landmarks: rawSmoothed[1],
              isDetected: handDataList[1].isDetected)
          : HandData.empty;

      final featureSet = _extractor.extractAll(smoothed);
      handsDetected = featureSet.handCount;

      final result = _classifier.classify(
        hand1: hand1,
        hand2: hand2,
        handsDetected: handsDetected,
      );

      setState(() => _result = result);
      _checkHandsDetection(result);

      if (_bothHandsDetected) {
        _maybeUpdateTranslation(result);
      }
    } catch (e) {
      debugPrint('Process frame error: $e');
    }

    _isProcessing = false;
  }

  List<List<LandmarkPoint>> _smoothRawLandmarks(List<HandData> hands) {
    // EMA alpha: higher = more responsive (less smoothing)
    // 0.8 means 80% new + 20% previous — reduces jitter without noticeable lag
    const double alpha = 0.8;
    final result = <List<LandmarkPoint>>[];

    for (int h = 0; h < 2; h++) {
      if (h < hands.length && hands[h].isDetected) {
        final raw = hands[h].landmarks;

        if (_rawBuffer[h].isEmpty) {
          // First detection — initialise EMA with raw frame
          _rawBuffer[h] = raw.map((lm) => LandmarkPoint(
            x: lm.x, y: lm.y, z: lm.z,
          )).toList();
        } else {
          // EMA update: blend current raw into stored EMA
          for (int i = 0; i < HandData.landmarkCount && i < raw.length; i++) {
            final prev = _rawBuffer[h][i];
            final cur = raw[i];
            _rawBuffer[h][i] = LandmarkPoint(
              x: alpha * cur.x + (1 - alpha) * prev.x,
              y: alpha * cur.y + (1 - alpha) * prev.y,
              z: alpha * cur.z + (1 - alpha) * prev.z,
            );
          }
        }

        // Use EMA value for display
        result.add(List<LandmarkPoint>.from(_rawBuffer[h]));
      } else {
        // Hand lost — clear buffer
        _rawBuffer[h].clear();
        result.add(List<LandmarkPoint>.filled(
          HandData.landmarkCount,
          LandmarkPoint.zero,
        ));
      }
    }

    return result;
  }

  void _checkHandsDetection(InferenceResult result) {
    final handsCount = result.handsDetected;

    if (handsCount >= 2 && !_bothHandsDetected) {
      setState(() => _bothHandsDetected = true);
      _handReadyNotified = false;
      _notifyHandsReady();
    } else if (handsCount < 2 && _bothHandsDetected) {
      setState(() {
        _bothHandsDetected = false;
        _translatedText = '';
      });
      _handReadyNotified = false;
    }

    _lastHandsCount = handsCount;
  }

  void _notifyHandsReady() {
    if (_handReadyNotified) return;
    _handReadyNotified = true;

    if (_isTtsEnabled) {
      _tts.speak('Tangan terdeteksi. Siap meragakan isyarat.');
      Vibration.vibrate(duration: 150, amplitude: 255);
    }
  }

  void _maybeUpdateTranslation(InferenceResult result) {
    if (!result.isConfident) return;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final isNewLabel = result.label != _stableLabel;
    final isHoldExpired = nowMs - _lastLabelMs > 1200;

    if (isNewLabel || isHoldExpired) {
      _stableLabel = result.label;
      _lastLabelMs = nowMs;
      if (result.label != _translatedText) {
        _updateTranslation(result.label, result.confidence);
      }
    }
  }

  void _updateTranslation(String text, double confidence) {
    setState(() => _translatedText = text);
    _textCtrl.forward(from: 0);

    if (_isTtsEnabled && text != _lastSpokenText) {
      _tts.speak(text);
      _lastSpokenText = text;
    }

    Vibration.vibrate(duration: 80, amplitude: 128);

    _repo.saveEntry(
      translatedText: text,
      confidenceScore: confidence,
      gestureLabel: _result.label,
    );
  }

  void _toggleCamera() {
    setState(() => _isFrontCamera = !_isFrontCamera);
    _setCamera(
      _isFrontCamera
          ? CameraLensDirection.front
          : CameraLensDirection.back,
    );
    HapticFeedback.lightImpact();
  }

  void _toggleTts() {
    setState(() => _isTtsEnabled = !_isTtsEnabled);
    if (!_isTtsEnabled) _tts.stop();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_cameraCtrl != null && _cameraCtrl!.value.isInitialized)
            Positioned.fill(
              child: CameraPreview(_cameraCtrl!),
            )
          else
            _buildCameraBackground(),

          if (_isCameraReady)
            CustomPaint(
              painter: HandOverlayPainter(
                result: _result,
                previewSize: _cameraCtrl!.value.previewSize ?? MediaQuery.of(context).size,
                screenSize: MediaQuery.of(context).size,
                isFrontCamera: _isFrontCamera,
                sensorOrientation: _sensorOrientation,
              ),
            ),

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
                          'Deteksi: $_lastHandsCount tangan',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textHint,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

          if (_isCameraReady)
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: Row(
                  children: [
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

          if (_bothHandsDetected)
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildTranslationPanel(),
            ),

          if (!_bothHandsDetected && _isCameraReady)
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
                        'Letakkan 2 tangan di depan kamera',
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

          if (!_isCameraReady) _buildLoadingOverlay(),
        ],
      ),
    );
  }

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

  Widget _buildTranslationPanel() {
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
              color: _translatedText.isNotEmpty
                  ? AppTheme.primary.withOpacity(0.4)
                  : AppTheme.divider,
              width: 2,
            ),
          ),
          child: _translatedText.isEmpty
              ? Text(
                  'Mulai ragakan isyarat...',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppTheme.textHint,
                    fontStyle: FontStyle.italic,
                  ),
                )
              : SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Text(
                      _translatedText,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

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
