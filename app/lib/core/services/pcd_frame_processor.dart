import 'dart:async';
import 'dart:isolate';

import '../models/inference_result.dart';
import 'pcd_pipeline.dart';

class PcdFrameProcessor {
  Isolate? _isolate;
  SendPort? _sendPort;
  Future<void>? _init;

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
    Isolate.spawn(_pcdIsolateEntry, initPort.sendPort).then((isolate) {
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

void _pcdIsolateEntry(SendPort mainPort) {
  final port = ReceivePort();
  mainPort.send(port.sendPort);

  port.listen((message) async {
    final payload = message[0] as IsolatePayload;
    final replyPort = message[1] as SendPort;
    final result = await runPcdPipeline(payload);
    replyPort.send(result);
  });
}
