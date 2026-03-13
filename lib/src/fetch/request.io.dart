import 'dart:io' as io;
import 'dart:typed_data';

import '../core/http_method.dart';
import 'body.dart';
import 'blob.dart';
import 'form_data.native.dart';
import 'headers.io.dart' as io_headers;
import 'request.native.dart' as native;

sealed class RequestHost<T> {
  const RequestHost(this.value);

  final T value;
}

final class HttpRequestHost extends RequestHost<io.HttpRequest> {
  const HttpRequestHost(super.value);
}

final class NativeRequestHost extends RequestHost<native.Request> {
  const NativeRequestHost(super.value);
}

class Request implements native.Request {
  Request._(this._host);

  factory Request(Object? input, [native.RequestInit? init]) {
    return Request._(switch ((input, init)) {
      (final io.HttpRequest request, null) => HttpRequestHost(request),
      _ => NativeRequestHost(_toNativeRequest(input, init)),
    });
  }

  final RequestHost _host;
  io_headers.Headers? _headers;
  Body? _body;

  @override
  io_headers.Headers get headers {
    final headers = _headers;
    if (headers != null) return headers;

    return _headers = switch (_host) {
      final HttpRequestHost host => io_headers.Headers(host.value.headers),
      final NativeRequestHost host => io_headers.Headers(host.value.headers),
    };
  }

  @override
  Body? get body {
    final body = _body;
    if (body != null) return body;

    return switch (_host) {
      final HttpRequestHost host => _body = Body(host.value),
      final NativeRequestHost host => host.value.body,
    };
  }

  @override
  bool get bodyUsed => body?.bodyUsed ?? false;

  @override
  native.RequestCache get cache {
    return switch (_host) {
      final HttpRequestHost _ => native.RequestCache.default_,
      final NativeRequestHost host => host.value.cache,
    };
  }

  @override
  native.RequestCredentials get credentials {
    return switch (_host) {
      final HttpRequestHost _ => native.RequestCredentials.sameOrigin,
      final NativeRequestHost host => host.value.credentials,
    };
  }

  @override
  String get destination {
    return switch (_host) {
      final HttpRequestHost _ => '',
      final NativeRequestHost host => host.value.destination,
    };
  }

  @override
  native.RequestDuplex get duplex {
    return switch (_host) {
      final HttpRequestHost _ => native.RequestDuplex.half,
      final NativeRequestHost host => host.value.duplex,
    };
  }

  @override
  String get integrity {
    return switch (_host) {
      final HttpRequestHost _ => '',
      final NativeRequestHost host => host.value.integrity,
    };
  }

  @override
  bool get isHistoryNavigation {
    return switch (_host) {
      final HttpRequestHost _ => false,
      final NativeRequestHost host => host.value.isHistoryNavigation,
    };
  }

  @override
  bool get keepalive {
    return switch (_host) {
      final HttpRequestHost host => host.value.persistentConnection,
      final NativeRequestHost host => host.value.keepalive,
    };
  }

  @override
  HttpMethod get method {
    return switch (_host) {
      final HttpRequestHost host => HttpMethod.parse(host.value.method),
      final NativeRequestHost host => host.value.method,
    };
  }

  @override
  native.RequestMode get mode {
    return switch (_host) {
      final HttpRequestHost _ => native.RequestMode.cors,
      final NativeRequestHost host => host.value.mode,
    };
  }

  @override
  native.RequestRedirect get redirect {
    return switch (_host) {
      final HttpRequestHost _ => native.RequestRedirect.follow,
      final NativeRequestHost host => host.value.redirect,
    };
  }

  @override
  String get referrer {
    return switch (_host) {
      final HttpRequestHost _ => 'about:client',
      final NativeRequestHost host => host.value.referrer,
    };
  }

  @override
  native.RequestReferrerPolicy? get referrerPolicy {
    return switch (_host) {
      final HttpRequestHost _ => null,
      final NativeRequestHost host => host.value.referrerPolicy,
    };
  }

  @override
  String get url {
    return switch (_host) {
      final HttpRequestHost host => host.value.requestedUri.toString(),
      final NativeRequestHost host => host.value.url,
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
  Request clone() {
    final body = this.body;
    return Request(
      native.Request(
        url,
        native.RequestInit(
          method: method,
          headers: io_headers.Headers(headers),
          body: body?.clone(),
          referrer: referrer,
          referrerPolicy: referrerPolicy,
          mode: mode,
          credentials: credentials,
          cache: cache,
          redirect: redirect,
          integrity: integrity,
          keepalive: keepalive,
          duplex: duplex,
        ),
      ),
    );
  }

  static native.Request _toNativeRequest(
    Object? input,
    native.RequestInit? init,
  ) {
    return switch (input) {
      final Request request => native.Request(request.clone(), init),
      final native.Request request => native.Request(request, init),
      final String value => native.Request(value, init),
      final Uri value => native.Request(value, init),
      _ => throw ArgumentError.value(
        input,
        'input',
        'Unsupported request input: ${input.runtimeType}',
      ),
    };
  }
}
