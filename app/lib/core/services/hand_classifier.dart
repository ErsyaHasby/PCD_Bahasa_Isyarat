import '../models/inference_result.dart';
import '../models/hand_data.dart';
import 'onnx_inference_service.dart';

class HandClassifier {
  final OnnxInferenceService _onnxService = OnnxInferenceService();
  bool _useOnnx = true;

  Future<void> initialize() async {
    await _onnxService.initialize();
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
        return InferenceResult(
          label: result['label'].toString(),
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
