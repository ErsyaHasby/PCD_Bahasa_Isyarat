import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import '../models/hand_data.dart';
import 'hand_feature_extractor.dart';

class OnnxInferenceService {
  OrtSession? _session;
  OrtSessionOptions? _sessionOptions;
  List<String> _labels = [];
  String? _inputName;
  bool _initialized = false;
  final HandFeatureExtractor _featureExtractor = HandFeatureExtractor();

  Future<void> initialize({Uint8List? modelBytes, String? labelsJson}) async {
    if (_initialized) return;

    try {
      // Use provided bytes or load from assets
      Uint8List modelData;
      if (modelBytes != null) {
        modelData = modelBytes;
      } else {
        final bytes = await rootBundle.load('assets/models/gesture_model.onnx');
        modelData = bytes.buffer.asUint8List();
      }

      // Load labels
      if (labelsJson != null) {
        _labels = await _parseLabels(labelsJson);
      } else {
        final json = await rootBundle.loadString('assets/models/labels.json');
        _labels = await _parseLabels(json);
      }

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
      // Based on PRD: 126 features (21 landmarks x 3 for 2 hands)
      final input = _prepareInputTensor(hand1, hand2);
      print('ONNX: Input tensor prepared, length=${input.length}');
      print('ONNX: First 5 input values: ${input.take(5).map((e) => e.toStringAsFixed(2)).join(', ')}');
      print('ONNX: Last 5 input values: ${input.skip(input.length - 5).map((e) => e.toStringAsFixed(2)).join(', ')}');

      // Create input tensor
      final inputOrt = OrtValueTensor.createTensorWithDataList(
        Float32List.fromList(input),
        [1, 126],
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
      print('ONNX: All output values: ${outputList.map((e) => e.toStringAsFixed(2)).join(', ')}');

      // Check if output is label index (single value) or probabilities (26 values)
      String label;
      double confidence;

      if (outputList.length == 1) {
        // Output is label index
        final labelIndex = outputList[0].toInt();
        label = labelIndex < _labels.length ? _labels[labelIndex] : '';
        confidence = 1.0; // Default confidence for index-based output
        print('ONNX: Output is label index=$labelIndex, label=$label');
      } else if (outputList.length == 26) {
        // Output is probabilities
        final maxIndex = _argMax(outputList);
        confidence = outputList[maxIndex];
        label = maxIndex < _labels.length ? _labels[maxIndex] : '';
        print('ONNX: Output is probabilities, maxIndex=$maxIndex, label=$label, confidence=$confidence');
      } else {
        // Unknown format
        label = '';
        confidence = 0.0;
        print('ONNX: Unknown output format, length=${outputList.length}');
      }

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

  List<double> _prepareInputTensor(HandData hand1, HandData hand2) {
    // 1. Normalize hands using HandFeatureExtractor
    final normalizedHands = _featureExtractor.normalize([hand1, hand2]);
    // 2. Flatten to 126 features (2 hands x 21 landmarks x 3)
    return _featureExtractor.flatten(normalizedHands, useZ: true);
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
