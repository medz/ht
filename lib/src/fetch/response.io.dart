import 'dart:io' as io;
import 'dart:typed_data';

import '../core/http_status.dart';
import 'blob.dart';
import 'body.dart';
import 'form_data.native.dart';
import 'headers.io.dart' as io_headers;
import 'response.native.dart' as native;

sealed class ResponseHost<T> {
  const ResponseHost(this.value);

  final T value;
}

final class HttpClientResponseHost extends ResponseHost<io.HttpClientResponse> {
  const HttpClientResponseHost(super.value);
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
      headers: io_headers.Headers(init?.headers ?? response.headers),
      redirected: response.redirected,
      status: init?.status ?? response.status,
      statusText: init?.statusText ?? response.statusText,
      type: response.type,
      url: response.url,
    );
  }

  final io_headers.Headers headers;
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
      (final io.HttpClientResponse response, null) => Response._(
        HttpClientResponseHost(response),
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

  factory Response.error() => Response(native.Response.error());

  factory Response.json(Object? data, [native.ResponseInit? init]) {
    return Response(native.Response.json(data, init));
  }

  factory Response.redirect(Uri url, [int status = io.HttpStatus.found]) {
    return Response(native.Response.redirect(url, status));
  }

  final ResponseHost _host;
  final _ResponseSnapshot? _snapshot;
  io_headers.Headers? _headers;
  Body? _body;

  @override
  io_headers.Headers get headers {
    final headers = _headers;
    if (headers != null) return headers;

    final snapshotHeaders = _snapshot?.headers;
    if (snapshotHeaders != null) return _headers = snapshotHeaders;

    return _headers = switch (_host) {
      final HttpClientResponseHost host => io_headers.Headers(
        host.value.headers,
      ),
      final NativeResponseHost host => io_headers.Headers(host.value.headers),
    };
  }

  @override
  Body? get body {
    final body = _body;
    if (body != null) return body;

    return switch (_host) {
      final HttpClientResponseHost host => _body = Body(host.value),
      final NativeResponseHost host => host.value.body,
    };
  }

  @override
  bool get bodyUsed => body?.bodyUsed ?? false;

  @override
  bool get ok {
    final snapshot = _snapshot;
    if (snapshot != null) return HttpStatus.isSuccess(snapshot.status);

    return switch (_host) {
      final HttpClientResponseHost host => HttpStatus.isSuccess(
        host.value.statusCode,
      ),
      final NativeResponseHost host => host.value.ok,
    };
  }

  @override
  bool get redirected {
    final snapshot = _snapshot;
    if (snapshot != null) return snapshot.redirected;

    return switch (_host) {
      final HttpClientResponseHost host => host.value.redirects.isNotEmpty,
      final NativeResponseHost host => host.value.redirected,
    };
  }

  @override
  int get status {
    final snapshot = _snapshot;
    if (snapshot != null) return snapshot.status;

    return switch (_host) {
      final HttpClientResponseHost host => host.value.statusCode,
      final NativeResponseHost host => host.value.status,
    };
  }

  @override
  String get statusText {
    final snapshot = _snapshot;
    if (snapshot != null) return snapshot.statusText;

    return switch (_host) {
      final HttpClientResponseHost host => host.value.reasonPhrase,
      final NativeResponseHost host => host.value.statusText,
    };
  }

  @override
  native.ResponseType get type {
    final snapshot = _snapshot;
    if (snapshot != null) return snapshot.type;

    return switch (_host) {
      final HttpClientResponseHost _ => native.ResponseType.default_,
      final NativeResponseHost host => host.value.type,
    };
  }

  @override
  String get url {
    final snapshot = _snapshot;
    if (snapshot != null) return snapshot.url;

    return switch (_host) {
      final HttpClientResponseHost _ => '',
      final NativeResponseHost host => host.value.url,
    };
  }

  @override
  Future<Uint8List> arrayBuffer() => bytes();

  @override
  Future<Blob> blob() async {
    final blob = switch (body) {
      final Body body => await body.blob(),
      null => Blob(),
    };

    final type = headers.get('content-type');
    if (type == null || type.isEmpty || blob.type == type) {
      return blob;
    }

    return Blob(<Object>[blob], type);
  }

  @override
  Future<Uint8List> bytes() {
    return switch (body) {
      final Body body => body.bytes(),
      null => Future<Uint8List>.value(Uint8List(0)),
    };
  }

  @override
  Future<FormData> formData() {
    return switch (body) {
      final Body body => FormData.parse(
        body,
        contentType: headers.get('content-type'),
      ),
      null => Future<FormData>.error(
        const FormatException('Cannot decode form data from an empty body.'),
      ),
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
    return switch (body) {
      final Body body => body.text(),
      null => Future<String>.value(''),
    };
  }

  @override
  Response clone() {
    final snapshot = _ResponseSnapshot.from(this);
    return switch (_host) {
      final NativeResponseHost host => Response._(
        NativeResponseHost(host.value.clone()),
        snapshot,
      ),
      final HttpClientResponseHost _ => Response._(
        NativeResponseHost(
          native.Response(
            _bodyForNativeCopy(),
            native.ResponseInit(
              status: status,
              statusText: statusText,
              headers: io_headers.Headers(headers),
            ),
          ),
        ),
        snapshot,
      ),
    };
  }

  static bool _statusAllowsBody(int status) {
    return !const <int>{
      HttpStatus.noContent,
      HttpStatus.resetContent,
      HttpStatus.notModified,
    }.contains(status);
  }

  static Response _responseFromWrappedResponse(
    Response response,
    native.ResponseInit? init,
  ) {
    return _responseFromNativeCopySource(
      response,
      init,
      cloneHost: () => response.clone()._host,
      body: response._bodyForNativeCopy,
    );
  }

  static Response _responseFromNativeResponse(
    native.Response response,
    native.ResponseInit? init,
  ) {
    return _responseFromNativeCopySource(
      response,
      init,
      cloneHost: () => NativeResponseHost(response.clone()),
      body: () => response.body,
    );
  }

  static Response _responseFromNativeCopySource(
    native.Response response,
    native.ResponseInit? init, {
    required ResponseHost Function() cloneHost,
    required Body? Function() body,
  }) {
    final snapshot = _ResponseSnapshot.from(response, init);
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

  Body? _bodyForNativeCopy() {
    if (!_statusAllowsBody(status)) {
      return null;
    }

    return body;
  }
}
