import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart' as ort;

/// ═══════════════════════════════════════════════════════════════════
///  ONNX Classifier Service
///  Load model ONNX dan lakukan inference untuk klasifikasi gesture A-Z
/// ═══════════════════════════════════════════════════════════════════
class OnnxClassifierService {
  ort.Session? _session;
  List<String> _labels = [];
  bool _isInitialized = false;

  /// Initialize ONNX session dan load labels
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load labels dari JSON
      await _loadLabels();

      // Load ONNX model dari assets
      final modelBytes = await rootBundle.load('assets/models/gesture_model.onnx');
      
      // Buat ONNX session options
      final sessionOptions = ort.SessionOptions();
      
      // Create session
      _session = ort.Session.fromBuffer(
        modelBytes.buffer.asUint8List(),
        sessionOptions,
      );

      _isInitialized = true;
      print('✓ ONNX Classifier initialized successfully');
      print('  - Labels: ${_labels.length} classes');
      print('  - Input shape: [batch, 63]');
    } catch (e) {
      print('✗ Failed to initialize ONNX Classifier: $e');
      rethrow;
    }
  }

  /// Load labels dari JSON file
  Future<void> _loadLabels() async {
    try {
      final jsonString = await rootBundle.loadString('assets/models/labels.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _labels = jsonList.cast<String>();
      print('✓ Loaded ${_labels.length} labels: $_labels');
    } catch (e) {
      print('✗ Failed to load labels: $e');
      // Fallback ke A-Z jika gagal
      _labels = List.generate(26, (i) => String.fromCharCode(65 + i));
    }
  }

  /// Lakukan inference dengan input landmarks (63 nilai: x0,y0,z0,...,x20,y20,z20)
  /// 
  /// Args:
  ///   landmarks: List 63 float values (ternormalisasi)
  /// 
  /// Returns:
  ///   Map dengan 'label' (String) dan 'confidence' (double)
  Future<Map<String, dynamic>> predict(List<double> landmarks) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_session == null) {
      throw Exception('ONNX Session not initialized');
    }

    try {
      // Prepare input tensor (shape: [1, 63])
      final inputOrt = ort.OrtValue.createTensorWithData(
        ort.DataType.float,
        Float32List.fromList(landmarks),
        [1, 63],
      );

      // Run inference
      final inputs = {'float_input': inputOrt};
      final outputs = _session!.run(ort.RunOptions(), inputs);

      // Get output (class index)
      final outputTensor = outputs[0];
      final outputData = outputTensor.value as List<List<List<double>>>;
      
      // ONNX SVM output biasanya [1, 1] atau [1] untuk class index
      final classIndex = outputData[0][0][0].toInt();

      // Get label dari class index
      final label = _labels[classIndex];

      // Confidence: untuk SVM tanka probability, gunakan confidence fixed
      // TODO: Jika model di-training dengan probability=True, extract dari output
      final confidence = 0.85; // Placeholder confidence

      // Clean up
      inputOrt.release();
      for (final output in outputs) {
        output.release();
      }

      return {
        'label': label,
        'confidence': confidence,
        'class_index': classIndex,
      };
    } catch (e) {
      print('✗ Inference error: $e');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _session?.release();
    _session = null;
    _isInitialized = false;
  }

  /// Cek apakah service sudah di-initialize
  bool get isInitialized => _isInitialized;

  /// Get list labels
  List<String> get labels => List.unmodifiable(_labels);
}
