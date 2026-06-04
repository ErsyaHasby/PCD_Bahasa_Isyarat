import '../models/inference_result.dart';
import '../models/hand_data.dart';

class HandClassifier {
  static const List<String> _labels = [
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
    'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
    'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  int _labelIndex = 0;
  int _lastSwitchMs = 0;

  InferenceResult classify({
    required HandData hand1,
    required HandData hand2,
    required int handsDetected,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;

    if (handsDetected == 0) {
      return InferenceResult.empty;
    }

    if (now - _lastSwitchMs > 2000) {
      _labelIndex = (_labelIndex + 1) % _labels.length;
      _lastSwitchMs = now;
    }

    final confidence = 0.85 + (now % 12) / 100;

    return InferenceResult(
      label: _labels[_labelIndex],
      confidence: confidence,
      hand1: hand1,
      hand2: hand2,
      handsDetected: handsDetected,
    );
  }
}
