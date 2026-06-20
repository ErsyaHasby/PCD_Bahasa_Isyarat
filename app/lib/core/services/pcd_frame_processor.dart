import 'dart:async';
import 'dart:isolate';
import 'package:flutter/services.dart';

import '../models/inference_result.dart';
import 'pcd_pipeline.dart';

class PcdFrameProcessor {
  Isolate? _isolate;
  SendPort? _sendPort;
  Future<void>? _init;
  
  // Cache for assets
  Uint8List? _modelBytes;
  String? _labelsJson;

  Future<void> initialize(Uint8List modelBytes, String labelsJson) async {
    _modelBytes = modelBytes;
    _labelsJson = labelsJson;
    await _ensureIsolate();
  }

  Future<InferenceResult> processFrame(IsolatePayload payload) async {
    await _ensureIsolate();
    final responsePort = ReceivePort();
    _sendPort!.send([payload, responsePort.sendPort]);
    final result = await responsePort.first as InferenceResult;
    responsePort.close();
    return result;
  }

  Future<void> _ensureIsolate() {
    if (_init != null) return _init!;
    final ready = Completer<void>();
    _init = ready.future;

    final initPort = ReceivePort();
    final token = RootIsolateToken.instance!;
    final payload = InitPayload(
      sendPort: initPort.sendPort,
      token: token,
      modelBytes: _modelBytes,
      labelsJson: _labelsJson,
    );

    Isolate.spawn(_pcdIsolateEntry, payload).then((isolate) {
      _isolate = isolate;
    });

    initPort.listen((message) {
      if (message is SendPort) {
        _sendPort = message;
        ready.complete();
        initPort.close();
      }
    });

    return _init!;
  }

  void dispose() {
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
    _sendPort = null;
    _init = null;
  }
}

class InitPayload {
  final SendPort sendPort;
  final RootIsolateToken token;
  final Uint8List? modelBytes;
  final String? labelsJson;
  InitPayload({
    required this.sendPort,
    required this.token,
    this.modelBytes,
    this.labelsJson,
  });
}

Future<void> _pcdIsolateEntry(InitPayload initPayload) async {
  // 1. Initialize Flutter platform channels in the background isolate
  BackgroundIsolateBinaryMessenger.ensureInitialized(initPayload.token);

  // 2. Setup the pipeline state
  await setupPcdPipeline(initPayload.modelBytes, initPayload.labelsJson);

  // 3. Setup communication
  final port = ReceivePort();
  initPayload.sendPort.send(port.sendPort);

  port.listen((message) async {
    final payload = message[0] as IsolatePayload;
    final replyPort = message[1] as SendPort;
    final result = await runPcdPipeline(payload);
    replyPort.send(result);
  });
}
