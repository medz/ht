@JS()
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../fetch/blob.dart';
import '../fetch/file.dart';
import '../fetch/form_data.native.dart';
import 'web_utils.dart' as web_utils;

Future<Uint8List> bytesFromWebPromise(JSPromise<JSUint8Array> promise) {
  return promise.toDart.then((value) => value.toDart);
}

Future<String> textFromWebPromise(JSPromise<JSString> promise) {
  return promise.toDart.then((value) => value.toDart);
}

Future<Blob> blobFromWebPromise(
  JSPromise<web.Blob> promise, {
  String? type,
}) async {
  final hostBlob = await promise.toDart;
  return Blob(<Object>[hostBlob], type ?? hostBlob.type);
}

FormData formDataFromWebHost(web.FormData host) {
  final formData = FormData();
  final iterator = web_utils.FormData.fromHost(host).entries();

  while (true) {
    final result = iterator.next();
    if (result.done) break;
    final value = result.value;
    if (value == null || value.isUndefinedOrNull) {
      continue;
    }

    final [name, entry] = (value as JSArray<JSAny?>).toDart;
    final key = (name as JSString).toDart;
    if (entry == null || entry.isUndefinedOrNull) {
      continue;
    }

    if (entry.typeofEquals('string')) {
      formData.append(key, Multipart.text((entry as JSString).toDart));
      continue;
    }

    if (entry case final web.File file) {
      formData.append(
        key,
        Multipart.blob(File(<Object>[file], file.name, type: file.type)),
      );
      continue;
    }

    if (entry case final web.Blob blob) {
      formData.append(key, Multipart.blob(Blob(<Object>[blob], blob.type)));
    }
  }

  return formData;
}
