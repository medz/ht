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
  Response._(
    this._host, {
    js_headers.Headers? headers,
    bool? redirected,
    int? status,
    String? statusText,
    native.ResponseType? type,
    String? url,
  }) : _headers = headers,
       _redirected = redirected,
       _status = status,
       _statusText = statusText,
       _type = type,
       _url = url;

  factory Response([Object? body, native.ResponseInit? init]) {
    return switch ((body, init)) {
      (final Response response, null) => response.clone(),
      (final Response response, _) => _responseFromWrappedResponse(
        response,
        init,
      ),
      (final web.Response response, null) => Response._(
        WebResponseHost(response),
      ),
      (final web.Response response, _) => _responseFromWebResponse(
        response,
        init,
      ),
      (final native.Response response, null) => Response._(
        NativeResponseHost(response.clone()),
      ),
      (final native.Response response, _) => _responseFromNativeResponse(
        response,
        init,
      ),
      _ => Response._(NativeResponseHost(native.Response(body, init))),
    };
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
  final bool? _redirected;
  final int? _status;
  final String? _statusText;
  final native.ResponseType? _type;
  final String? _url;

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
    final status = _status;
    if (status != null) return status >= 200 && status <= 299;

    return switch (_host) {
      final WebResponseHost host => host.value.ok,
      final NativeResponseHost host => host.value.ok,
    };
  }

  @override
  bool get redirected {
    final redirected = _redirected;
    if (redirected != null) return redirected;

    return switch (_host) {
      final WebResponseHost host => host.value.redirected,
      final NativeResponseHost host => host.value.redirected,
    };
  }

  @override
  int get status {
    final status = _status;
    if (status != null) return status;

    return switch (_host) {
      final WebResponseHost host => host.value.status,
      final NativeResponseHost host => host.value.status,
    };
  }

  @override
  String get statusText {
    final statusText = _statusText;
    if (statusText != null) return statusText;

    return switch (_host) {
      final WebResponseHost host => host.value.statusText,
      final NativeResponseHost host => host.value.statusText,
    };
  }

  @override
  native.ResponseType get type {
    final type = _type;
    if (type != null) return type;

    return switch (_host) {
      final WebResponseHost host => _responseTypeFromValue(host.value.type),
      final NativeResponseHost host => host.value.type,
    };
  }

  @override
  String get url {
    final url = _url;
    if (url != null) return url;

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
      final WebResponseHost host => host.value.formData().toDart.then(
        web_fetch.formDataFromWebHost,
      ),
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
      final WebResponseHost host => Response._(
        WebResponseHost(host.value.clone()),
        headers: js_headers.Headers(headers),
        redirected: redirected,
        status: status,
        statusText: statusText,
        type: type,
        url: url,
      ),
      final NativeResponseHost host => Response._(
        NativeResponseHost(host.value.clone()),
        headers: js_headers.Headers(headers),
        redirected: redirected,
        status: status,
        statusText: statusText,
        type: type,
        url: url,
      ),
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

  static Response _responseFromWrappedResponse(
    Response response,
    native.ResponseInit? init,
  ) {
    return switch (response._host) {
      final WebResponseHost host => _responseFromWebResponse(
        host.value,
        init,
        sourceHeaders: js_headers.Headers(response.headers),
        redirected: response.redirected,
        status: response.status,
        statusText: response.statusText,
        type: response.type,
        url: response.url,
      ),
      NativeResponseHost() => _responseFromNativeWrappedResponse(
        response,
        init,
      ),
    };
  }

  static Response _responseFromWebResponse(
    web.Response response,
    native.ResponseInit? init, {
    Object? sourceHeaders,
    bool? redirected,
    int? status,
    String? statusText,
    native.ResponseType? type,
    String? url,
  }) {
    final targetStatus = _validateStatus(
      init?.status ?? status ?? response.status,
    );
    if (!_statusAllowsBody(targetStatus) && response.body != null) {
      throw ArgumentError.value(
        response,
        'body',
        'Response status $targetStatus cannot have a body.',
      );
    }

    return Response._(
      WebResponseHost(response.clone()),
      headers: js_headers.Headers(
        init?.headers ?? sourceHeaders ?? response.headers,
      ),
      redirected: redirected,
      status: targetStatus,
      statusText: init?.statusText ?? statusText ?? response.statusText,
      type: type,
      url: url,
    );
  }

  static Response _responseFromNativeWrappedResponse(
    Response response,
    native.ResponseInit? init,
  ) {
    return Response._(
      NativeResponseHost(
        _nativeResponseFromNativeWrappedResponse(response, init),
      ),
      redirected: response.redirected,
      type: response.type,
      url: response.url,
    );
  }

  static Response _responseFromNativeResponse(
    native.Response response,
    native.ResponseInit? init,
  ) {
    return Response._(
      NativeResponseHost(_nativeResponseFromNativeResponse(response, init)),
      redirected: response.redirected,
      type: response.type,
      url: response.url,
    );
  }

  static int _validateStatus(int status) {
    if (status < 200 || status > 599) {
      throw RangeError.range(status, 200, 599, 'status');
    }
    return status;
  }

  static bool _statusAllowsBody(int status) {
    return !const <int>{204, 205, 304}.contains(status);
  }

  static native.Response _nativeResponseFromNativeWrappedResponse(
    Response response,
    native.ResponseInit? init,
  ) {
    final sourceHeaders = js_headers.Headers(response.headers);
    return _nativeResponseFromCopy(
      response.body,
      status: init?.status ?? response.status,
      statusText: init?.statusText ?? response.statusText,
      headers: init?.headers ?? sourceHeaders,
      preserveMissingContentType:
          init?.headers == null && !sourceHeaders.has('content-type'),
    );
  }

  static native.Response _nativeResponseFromNativeResponse(
    native.Response response,
    native.ResponseInit? init,
  ) {
    final sourceHeaders = js_headers.Headers(response.headers);
    return _nativeResponseFromCopy(
      response.body,
      status: init?.status ?? response.status,
      statusText: init?.statusText ?? response.statusText,
      headers: init?.headers ?? sourceHeaders,
      preserveMissingContentType:
          init?.headers == null && !sourceHeaders.has('content-type'),
    );
  }

  static native.Response _nativeResponseFromCopy(
    Body? body, {
    required int status,
    required String statusText,
    required Object? headers,
    required bool preserveMissingContentType,
  }) {
    final response = native.Response(
      body,
      native.ResponseInit(
        status: status,
        statusText: statusText,
        headers: headers,
      ),
    );
    if (preserveMissingContentType) {
      response.headers.delete('content-type');
    }
    return response;
  }
}
