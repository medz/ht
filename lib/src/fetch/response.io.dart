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
  Response._(this._host);

  factory Response([Object? body, native.ResponseInit? init]) {
    final host = switch ((body, init)) {
      (final Response response, _) => response._host,
      (final io.HttpClientResponse response, null) => HttpClientResponseHost(
        response,
      ),
      (final native.Response response, _) => NativeResponseHost(response),
      _ => NativeResponseHost(native.Response(body, init)),
    };

    return Response._(host);
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
    return switch (_host) {
      final HttpClientResponseHost host => HttpStatus.isSuccess(
        host.value.statusCode,
      ),
      final NativeResponseHost host => host.value.ok,
    };
  }

  @override
  bool get redirected {
    return switch (_host) {
      final HttpClientResponseHost host => host.value.redirects.isNotEmpty,
      final NativeResponseHost host => host.value.redirected,
    };
  }

  @override
  int get status {
    return switch (_host) {
      final HttpClientResponseHost host => host.value.statusCode,
      final NativeResponseHost host => host.value.status,
    };
  }

  @override
  String get statusText {
    return switch (_host) {
      final HttpClientResponseHost host => host.value.reasonPhrase,
      final NativeResponseHost host => host.value.statusText,
    };
  }

  @override
  native.ResponseType get type {
    return switch (_host) {
      final HttpClientResponseHost _ => native.ResponseType.default_,
      final NativeResponseHost host => host.value.type,
    };
  }

  @override
  String get url {
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
    final body = this.body;
    return Response(
      native.Response(
        body?.clone(),
        native.ResponseInit(
          status: status,
          statusText: statusText,
          headers: io_headers.Headers(headers),
        ),
      ),
    );
  }
}
