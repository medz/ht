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

class Response implements native.Response {
  Response._(
    this._host, {
    io_headers.Headers? headers,
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
  io_headers.Headers? _headers;
  Body? _body;
  final bool? _redirected;
  final int? _status;
  final String? _statusText;
  final native.ResponseType? _type;
  final String? _url;

  @override
  io_headers.Headers get headers {
    final headers = _headers;
    if (headers != null) return headers;

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
    final status = _status;
    if (status != null) return HttpStatus.isSuccess(status);

    return switch (_host) {
      final HttpClientResponseHost host => HttpStatus.isSuccess(
        host.value.statusCode,
      ),
      final NativeResponseHost host => host.value.ok,
    };
  }

  @override
  bool get redirected {
    final redirected = _redirected;
    if (redirected != null) return redirected;

    return switch (_host) {
      final HttpClientResponseHost host => host.value.redirects.isNotEmpty,
      final NativeResponseHost host => host.value.redirected,
    };
  }

  @override
  int get status {
    final status = _status;
    if (status != null) return status;

    return switch (_host) {
      final HttpClientResponseHost host => host.value.statusCode,
      final NativeResponseHost host => host.value.status,
    };
  }

  @override
  String get statusText {
    final statusText = _statusText;
    if (statusText != null) return statusText;

    return switch (_host) {
      final HttpClientResponseHost host => host.value.reasonPhrase,
      final NativeResponseHost host => host.value.statusText,
    };
  }

  @override
  native.ResponseType get type {
    final type = _type;
    if (type != null) return type;

    return switch (_host) {
      final HttpClientResponseHost _ => native.ResponseType.default_,
      final NativeResponseHost host => host.value.type,
    };
  }

  @override
  String get url {
    final url = _url;
    if (url != null) return url;

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
    return switch (_host) {
      final NativeResponseHost host => Response._(
        NativeResponseHost(host.value.clone()),
        headers: io_headers.Headers(headers),
        redirected: redirected,
        status: status,
        statusText: statusText,
        type: type,
        url: url,
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
        redirected: redirected,
        type: type,
        url: url,
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
    if (init?.status == null && response.status == 0) {
      final clone = response.clone();
      return Response._(
        clone._host,
        headers: io_headers.Headers(init?.headers ?? response.headers),
        redirected: response.redirected,
        status: response.status,
        statusText: init?.statusText ?? response.statusText,
        type: response.type,
        url: response.url,
      );
    }

    return Response._(
      NativeResponseHost(_nativeResponseFromWrappedResponse(response, init)),
      redirected: response.redirected,
      type: response.type,
      url: response.url,
    );
  }

  static Response _responseFromNativeResponse(
    native.Response response,
    native.ResponseInit? init,
  ) {
    if (init?.status == null && response.status == 0) {
      return Response._(
        NativeResponseHost(response.clone()),
        headers: io_headers.Headers(init?.headers ?? response.headers),
        redirected: response.redirected,
        status: response.status,
        statusText: init?.statusText ?? response.statusText,
        type: response.type,
        url: response.url,
      );
    }

    return Response._(
      NativeResponseHost(_nativeResponseFromNativeResponse(response, init)),
      redirected: response.redirected,
      type: response.type,
      url: response.url,
    );
  }

  static native.Response _nativeResponseFromWrappedResponse(
    Response response,
    native.ResponseInit? init,
  ) {
    final sourceHeaders = io_headers.Headers(response.headers);
    return _nativeResponseFromCopy(
      response._bodyForNativeCopy(),
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
    final sourceHeaders = io_headers.Headers(response.headers);
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

  Body? _bodyForNativeCopy() {
    if (!_statusAllowsBody(status)) {
      return null;
    }

    return body;
  }
}
