@JS()
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import '../_internal/web_fetch_utils.dart' as web_fetch;
import '../_internal/web_stream_bridge.dart';
import 'blob.dart';
import 'body.dart';
import 'form_data.native.dart';
import 'headers.js.dart' as js_headers;
import 'response.native.dart' as native;

sealed class ResponseHost<T> {
  const ResponseHost(this.value);

  final T value;
}

final class WebResponseHost extends ResponseHost<web.Response> {
  const WebResponseHost(super.value);
}

final class NativeResponseHost extends ResponseHost<native.Response> {
  const NativeResponseHost(super.value);
}

class Response implements native.Response {
  Response._(this._host);

  factory Response([Object? body, native.ResponseInit? init]) {
    final host = switch ((body, init)) {
      (final Response response, _) => response._host,
      (final web.Response response, null) => WebResponseHost(response),
      (final native.Response response, _) => NativeResponseHost(response),
      _ => NativeResponseHost(native.Response(body, init)),
    };

    return Response._(host);
  }

  factory Response.error() => Response._(WebResponseHost(web.Response.error()));

  factory Response.json(Object? data, [native.ResponseInit? init]) {
    return Response(native.Response.json(data, init));
  }

  factory Response.redirect(Uri url, [int status = 302]) {
    return Response._(
      WebResponseHost(web.Response.redirect(url.toString(), status)),
    );
  }

  final ResponseHost _host;
  js_headers.Headers? _headers;
  Body? _body;

  @override
  js_headers.Headers get headers {
    final headers = _headers;
    if (headers != null) return headers;

    return _headers = switch (_host) {
      final WebResponseHost host => js_headers.Headers(host.value.headers),
      final NativeResponseHost host => js_headers.Headers(host.value.headers),
    };
  }

  @override
  Body? get body {
    final body = _body;
    if (body != null) return body;

    return switch (_host) {
      final WebResponseHost host => switch (host.value.body) {
        final web.ReadableStream stream => _body = Body(
          dartByteStreamFromWebReadableStream(stream),
        ),
        null => null,
      },
      final NativeResponseHost host => host.value.body,
    };
  }

  @override
  bool get bodyUsed {
    return switch (_host) {
      final WebResponseHost host => host.value.bodyUsed,
      final NativeResponseHost host => host.value.bodyUsed,
    };
  }

  @override
  bool get ok {
    return switch (_host) {
      final WebResponseHost host => host.value.ok,
      final NativeResponseHost host => host.value.ok,
    };
  }

  @override
  bool get redirected {
    return switch (_host) {
      final WebResponseHost host => host.value.redirected,
      final NativeResponseHost host => host.value.redirected,
    };
  }

  @override
  int get status {
    return switch (_host) {
      final WebResponseHost host => host.value.status,
      final NativeResponseHost host => host.value.status,
    };
  }

  @override
  String get statusText {
    return switch (_host) {
      final WebResponseHost host => host.value.statusText,
      final NativeResponseHost host => host.value.statusText,
    };
  }

  @override
  native.ResponseType get type {
    return switch (_host) {
      final WebResponseHost host => _responseTypeFromValue(host.value.type),
      final NativeResponseHost host => host.value.type,
    };
  }

  @override
  String get url {
    return switch (_host) {
      final WebResponseHost host => host.value.url,
      final NativeResponseHost host => host.value.url,
    };
  }

  @override
  Future<Uint8List> arrayBuffer() => bytes();

  @override
  Future<Blob> blob() async {
    final blob = await switch (_host) {
      final WebResponseHost host => web_fetch.blobFromWebPromise(
        host.value.blob(),
        type: headers.get('content-type'),
      ),
      _ => switch (body) {
        final Body body => body.blob(),
        null => Future<Blob>.value(Blob()),
      },
    };

    final type = headers.get('content-type');
    if (type == null || type.isEmpty || blob.type == type) {
      return blob;
    }

    return Blob(<Object>[blob], type);
  }

  @override
  Future<Uint8List> bytes() {
    return switch (_host) {
      final WebResponseHost host => web_fetch.bytesFromWebPromise(
        host.value.bytes(),
      ),
      _ => switch (body) {
        final Body body => body.bytes(),
        null => Future<Uint8List>.value(Uint8List(0)),
      },
    };
  }

  @override
  Future<FormData> formData() {
    return switch (_host) {
      final WebResponseHost host => host.value
          .formData()
          .toDart
          .then(web_fetch.formDataFromWebHost),
      _ => switch (body) {
        final Body body => FormData.parse(
          body,
          contentType: headers.get('content-type'),
        ),
        null => Future<FormData>.error(
          const FormatException('Cannot decode form data from an empty body.'),
        ),
      },
    };
  }

  @override
  Future<T> json<T>() {
    return switch (body) {
      final Body body => body.json<T>(),
      null => Future<T>.error(
        const FormatException('Cannot decode JSON from an empty body.'),
      ),
    };
  }

  @override
  Future<String> text() {
    return switch (_host) {
      final WebResponseHost host => web_fetch.textFromWebPromise(
        host.value.text(),
      ),
      _ => switch (body) {
        final Body body => body.text(),
        null => Future<String>.value(''),
      },
    };
  }

  @override
  Response clone() {
    return switch (_host) {
      final WebResponseHost host => Response(host.value.clone()),
      final NativeResponseHost host => Response(host.value.clone()),
    };
  }

  static native.ResponseType _responseTypeFromValue(String value) {
    return switch (value) {
      'basic' => native.ResponseType.basic,
      'cors' => native.ResponseType.cors,
      'error' => native.ResponseType.error,
      'opaque' => native.ResponseType.opaque,
      'opaqueredirect' => native.ResponseType.opaqueRedirect,
      _ => native.ResponseType.default_,
    };
  }
}
