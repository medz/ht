@JS()
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

Stream<Uint8List> dartByteStreamFromWebReadableStream(
  web.ReadableStream stream,
) async* {
  final reader = stream.getReader() as web.ReadableStreamDefaultReader;

  try {
    while (true) {
      final result = await reader.read().toDart;
      if (result.done) {
        break;
      }

      final value = result.value;
      if (value == null || value.isUndefinedOrNull) {
        continue;
      }

      final bytes = (value as JSUint8Array).toDart;
      if (bytes.isEmpty) {
        continue;
      }

      yield bytes;
    }
  } finally {
    reader.releaseLock();
  }
}
