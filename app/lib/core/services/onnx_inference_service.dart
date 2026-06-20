import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import '../models/hand_data.dart';

class OnnxInferenceService {
  OrtSession? _session;
  OrtSessionOptions? _sessionOptions;
  List<String> _labels = [];
  String? _inputName;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Load model from assets
      final modelBytes = await rootBundle.load('assets/models/gesture_model.onnx');
      final modelData = modelBytes.buffer.asUint8List();

      // Load labels
      final labelsJson = await rootBundle.loadString('assets/models/labels.json');
      _labels = (await _parseLabels(labelsJson));

      // Create ONNX session options
      _sessionOptions = OrtSessionOptions();

      // Create ONNX session
      _session = OrtSession.fromBuffer(modelData, _sessionOptions!);

      // Get input/output names from model metadata
      final inputNames = _session!.inputNames;
      final outputNames = _session!.outputNames;
      print('ONNX: Input names: $inputNames');
      print('ONNX: Output names: $outputNames');

      // Store the first input name
      if (inputNames.isNotEmpty) {
        _inputName = inputNames.first;
        print('ONNX: Using input name: $_inputName');
      }

      _initialized = true;
      print('ONNX Inference Service initialized with ${_labels.length} labels');
    } catch (e) {
      print('ONNX Inference Service init error: $e');
      // Fallback to placeholder if ONNX fails
      _initialized = false;
    }
  }

  Future<List<String>> _parseLabels(String json) async {
    // Simple JSON parser for labels array
    final cleanJson = json.trim();
    if (cleanJson.startsWith('[') && cleanJson.endsWith(']')) {
      final content = cleanJson.substring(1, cleanJson.length - 1);
      final items = content.split(',').map((e) => e.trim().replaceAll('"', '').replaceAll("'", '')).toList();
      return items;
    }
    return [];
  }

  Map<String, dynamic> classify(HandData hand1, HandData hand2) {
    if (!_initialized || _session == null) {
      print('ONNX: Not initialized');
      return {'label': '', 'confidence': 0.0};
    }

    try {
      // Convert HandData to input tensor
      // Based on svm_params.json: 63 features (21 landmarks x 3 for 1 hand)
      final input = _prepareInputTensor(hand1);
      print('ONNX: Input tensor prepared, length=${input.length}');

      // Create input tensor
      final inputOrt = OrtValueTensor.createTensorWithDataList(
        Float32List.fromList(input),
        [1, 63],
      );

      // Run inference
      final inputs = {_inputName ?? 'input': inputOrt};
      final outputs = _session!.run(OrtRunOptions(), inputs);
      print('ONNX: Inference completed, outputs=${outputs.length}');

      // Get output
      final outputOrt = outputs[0];
      if (outputOrt == null) {
        inputOrt.release();
        print('ONNX: Output is null');
        return {'label': '', 'confidence': 0.0};
      }
      final outputDynamic = outputOrt.value as List<dynamic>;
      final outputList = outputDynamic.map((e) => (e as num).toDouble()).toList();
      print('ONNX: Output list length=${outputList.length}');

      // Get predicted label and confidence
      final maxIndex = _argMax(outputList);
      final confidence = outputList[maxIndex];
      final label = maxIndex < _labels.length ? _labels[maxIndex] : '';
      print('ONNX: Predicted label=$label, confidence=$confidence');

      // Clean up
      inputOrt.release();
      for (final output in outputs) {
        output?.release();
      }

      return {'label': label, 'confidence': confidence};
    } catch (e) {
      print('ONNX inference error: $e');
      return {'label': '', 'confidence': 0.0};
    }
  }

  List<double> _prepareInputTensor(HandData hand) {
    // Flatten 21 landmarks x 3 (x, y, z) = 63 features
    final features = <double>[];
    for (final landmark in hand.landmarks) {
      features.add(landmark.x);
      features.add(landmark.y);
      features.add(landmark.z);
    }
    return features;
  }

  int _argMax(List<double> list) {
    if (list.isEmpty) return 0;
    int maxIndex = 0;
    double maxValue = list[0];
    for (int i = 1; i < list.length; i++) {
      if (list[i] > maxValue) {
        maxValue = list[i];
        maxIndex = i;
      }
    }
    return maxIndex;
  }

  void dispose() {
    _sessionOptions?.release();
    _session?.release();
    _session = null;
    _sessionOptions = null;
    _initialized = false;
  }
}
