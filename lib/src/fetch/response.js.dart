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

final class _ResponseSnapshot {
  _ResponseSnapshot({
    required this.headers,
    required this.redirected,
    required this.status,
    required this.statusText,
    required this.type,
    required this.url,
  });

  factory _ResponseSnapshot.from(
    native.Response response, [
    native.ResponseInit? init,
  ]) {
    return _ResponseSnapshot(
      headers: js_headers.Headers(init?.headers ?? response.headers),
      redirected: response.redirected,
      status: init?.status ?? response.status,
      statusText: init?.statusText ?? response.statusText,
      type: response.type,
      url: response.url,
    );
  }

  factory _ResponseSnapshot.fromWeb(
    web.Response response, [
    native.ResponseInit? init,
  ]) {
    return _ResponseSnapshot(
      headers: js_headers.Headers(init?.headers ?? response.headers),
      redirected: response.redirected,
      status: init?.status ?? response.status,
      statusText: init?.statusText ?? response.statusText,
      type: Response._responseTypeFromValue(response.type),
      url: response.url,
    );
  }

  final js_headers.Headers headers;
  final bool redirected;
  final int status;
  final String statusText;
  final native.ResponseType type;
  final String url;
}

class Response implements native.Response {
  Response._(this._host, [this._snapshot]);

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
        _ResponseSnapshot.fromWeb(response, init),
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
  final _ResponseSnapshot? _snapshot;
  js_headers.Headers? _headers;
  Body? _body;

  @override
  js_headers.Headers get headers {
    final headers = _headers;
    if (headers != null) return headers;

    final snapshotHeaders = _snapshot?.headers;
    if (snapshotHeaders != null) return _headers = snapshotHeaders;

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
    final snapshot = _snapshot;
    if (snapshot != null) {
      return snapshot.status >= 200 && snapshot.status <= 299;
    }

    return switch (_host) {
      final WebResponseHost host => host.value.ok,
      final NativeResponseHost host => host.value.ok,
    };
  }

  @override
  bool get redirected {
    final snapshot = _snapshot;
    if (snapshot != null) return snapshot.redirected;

    return switch (_host) {
      final WebResponseHost host => host.value.redirected,
      final NativeResponseHost host => host.value.redirected,
    };
  }

  @override
  int get status {
    final snapshot = _snapshot;
    if (snapshot != null) return snapshot.status;

    return switch (_host) {
      final WebResponseHost host => host.value.status,
      final NativeResponseHost host => host.value.status,
    };
  }

  @override
  String get statusText {
    final snapshot = _snapshot;
    if (snapshot != null) return snapshot.statusText;

    return switch (_host) {
      final WebResponseHost host => host.value.statusText,
      final NativeResponseHost host => host.value.statusText,
    };
  }

  @override
  native.ResponseType get type {
    final snapshot = _snapshot;
    if (snapshot != null) return snapshot.type;

    return switch (_host) {
      final WebResponseHost host => _responseTypeFromValue(host.value.type),
      final NativeResponseHost host => host.value.type,
    };
  }

  @override
  String get url {
    final snapshot = _snapshot;
    if (snapshot != null) return snapshot.url;

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
    final snapshot = _ResponseSnapshot.from(this);
    return switch (_host) {
      final WebResponseHost host => _responseFromWebResponse(
        host.value,
        null,
        snapshot,
      ),
      final NativeResponseHost host => Response._(
        NativeResponseHost(host.value.clone()),
        snapshot,
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
    final snapshot = _ResponseSnapshot.from(response, init);
    return switch (response._host) {
      final WebResponseHost host => _responseFromWebResponse(
        host.value,
        init,
        snapshot,
      ),
      NativeResponseHost() => _responseFromNativeWrappedResponse(
        response,
        init,
        snapshot,
      ),
    };
  }

  static Response _responseFromWebResponse(
    web.Response response,
    native.ResponseInit? init,
    _ResponseSnapshot snapshot,
  ) {
    if (init?.status == null && snapshot.status == 0) {
      return Response._(WebResponseHost(response.clone()), snapshot);
    }

    final targetStatus = _validateStatus(snapshot.status);
    if (!_statusAllowsBody(targetStatus) && response.body != null) {
      throw ArgumentError.value(
        response,
        'body',
        'Response status $targetStatus cannot have a body.',
      );
    }

    final source = response.clone();
    return Response._(
      WebResponseHost(
        web.Response(
          source.body,
          web.ResponseInit(
            status: targetStatus,
            statusText: snapshot.statusText,
            headers: snapshot.headers.host,
          ),
        ),
      ),
      snapshot,
    );
  }

  static Response _responseFromNativeWrappedResponse(
    Response response,
    native.ResponseInit? init,
    _ResponseSnapshot snapshot,
  ) {
    return _responseFromNativeCopySource(
      init,
      snapshot,
      cloneHost: () => response.clone()._host,
      body: () => response.body,
    );
  }

  static Response _responseFromNativeResponse(
    native.Response response,
    native.ResponseInit? init,
  ) {
    final snapshot = _ResponseSnapshot.from(response, init);
    return _responseFromNativeCopySource(
      init,
      snapshot,
      cloneHost: () => NativeResponseHost(response.clone()),
      body: () => response.body,
    );
  }

  static Response _responseFromNativeCopySource(
    native.ResponseInit? init,
    _ResponseSnapshot snapshot, {
    required ResponseHost Function() cloneHost,
    required Body? Function() body,
  }) {
    if (init?.status == null && snapshot.status == 0) {
      return Response._(cloneHost(), snapshot);
    }

    return Response._(
      NativeResponseHost(
        _nativeResponseFromCopy(
          body(),
          snapshot: snapshot,
          preserveMissingContentType: _shouldPreserveMissingContentType(
            init,
            snapshot,
          ),
        ),
      ),
      snapshot,
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

  static bool _shouldPreserveMissingContentType(
    native.ResponseInit? init,
    _ResponseSnapshot snapshot,
  ) {
    return init?.headers == null && !snapshot.headers.has('content-type');
  }

  static native.Response _nativeResponseFromCopy(
    Body? body, {
    required _ResponseSnapshot snapshot,
    required bool preserveMissingContentType,
  }) {
    final response = native.Response(
      body,
      native.ResponseInit(
        status: snapshot.status,
        statusText: snapshot.statusText,
        headers: snapshot.headers,
      ),
    );
    if (preserveMissingContentType) {
      response.headers.delete('content-type');
    }
    return response;
  }
}
