import 'dart:typed_data';

import 'blob.dart';
import 'formdata.dart';

abstract interface class BaseHttpMessage {
  Stream<Uint8List>? get body;
  bool get bodyUsed;

  Future<ByteBuffer> byteBuffer();
  Future<Uint8List> bytes();
  Future<String> text();
  Future json();
  Future<FormData> formData();
  Future<Blob> blob();
}
