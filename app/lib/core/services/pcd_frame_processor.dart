import 'package:flutter/foundation.dart';

import '../models/inference_result.dart';
import 'pcd_pipeline.dart';

class PcdFrameProcessor {
  const PcdFrameProcessor();

  Future<InferenceResult> processFrame(IsolatePayload payload) {
    return compute(runPcdPipeline, payload);
  }
}
