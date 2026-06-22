import 'dart:typed_data';
import '../models/inference_result.dart';
import '../models/hand_data.dart';
import 'onnx_inference_service.dart';

class HandClassifier {
  final OnnxInferenceService _onnxService = OnnxInferenceService();
  bool _useOnnx = true;

  // Daftar huruf BISINDO yang wajib menggunakan 2 tangan.
  final Set<String> _twoHandedLetters = {
    'A', 'B', 'D', 'F', 'G', 'H', 'K', 'M', 'N', 'P', 'Q', 'S', 'T', 'W', 'X', 'Y'
  };

  Future<void> initialize({Uint8List? modelBytes, String? labelsJson}) async {
    await _onnxService.initialize(modelBytes: modelBytes, labelsJson: labelsJson);
  }

  InferenceResult classify({
    required HandData hand1,
    required HandData hand2,
    required int handsDetected,
    int latencyMs = 0,
  }) {
    if (handsDetected == 0) {
      return InferenceResult.empty;
    }

    // Try ONNX inference first
    if (_useOnnx) {
      final result = _onnxService.classify(hand1, hand2);
      if (result['label'] != null && result['label'].toString().isNotEmpty) {
        final label = result['label'].toString();
        
        // Thresholding: Blokir jika huruf butuh 2 tangan tapi kamera cuma lihat 1
        if (handsDetected < 2 && _twoHandedLetters.contains(label.toUpperCase())) {
          return InferenceResult(
            label: '',
            confidence: 0.0,
            hand1: hand1,
            hand2: hand2,
            handsDetected: handsDetected,
            latencyMs: latencyMs,
          );
        }

        return InferenceResult(
          label: label,
          confidence: (result['confidence'] as num).toDouble(),
          hand1: hand1,
          hand2: hand2,
          handsDetected: handsDetected,
          latencyMs: latencyMs,
        );
      }
    }

    // Fallback to placeholder if ONNX fails
    return InferenceResult(
      label: 'Unknown',
      confidence: 0.0,
      hand1: hand1,
      hand2: hand2,
      handsDetected: handsDetected,
      latencyMs: latencyMs,
    );
  }

  void dispose() {
    _onnxService.dispose();
  }
}
