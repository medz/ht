import 'dart:convert';

import 'body.dart';
import 'blob.dart';
import 'form_data.dart';
import 'headers.dart';
import 'url_search_params.dart';

/// Initialization options for [Request], aligned with Fetch `RequestInit`.
class RequestInit {
  RequestInit({this.method, this.headers, this.body});

  final String? method;
  final HeadersInit? headers;
  final Object? body;
}

/// Fetch-like HTTP request model.
class Request {
  Request(Uri url, [RequestInit? init])
    : this._create(
        url: url,
        method: init?.method ?? 'GET',
        headers: _headersFromInit(init?.headers),
        bodyData: Body(init?.body),
      );

  Request._create({
    required this.url,
    required String method,
    required this.headers,
    required this.bodyData,
  }) : method = _normalizeMethod(method) {
    _validateMethodAndBody();
    _applyDefaultBodyHeaders();
  }

  Request._internal({
    required this.url,
    required this.method,
    required this.headers,
    required this.bodyData,
  });

  factory Request.text(Uri url, String body, [RequestInit? init]) {
    return Request(url, _coerceInit(init, body: body));
  }

  factory Request.json(Uri url, Object? body, [RequestInit? init]) {
    final nextInit = _coerceInit(init, body: json.encode(body));
    final nextHeaders = _headersFromInit(nextInit.headers);
    if (!nextHeaders.has('content-type')) {
      nextHeaders.set('content-type', 'application/json; charset=utf-8');
    }

    return Request._create(
      url: url,
      method: nextInit.method ?? 'POST',
      headers: nextHeaders,
      bodyData: BodyData.fromInit(nextInit.body),
    );
  }

  factory Request.bytes(Uri url, List<int> body, [RequestInit? init]) {
    return Request(url, _coerceInit(init, body: body));
  }

  factory Request.stream(Uri url, Stream<List<int>> body, [RequestInit? init]) {
    return Request(url, _coerceInit(init, body: body));
  }

  factory Request.searchParams(
    Uri url,
    URLSearchParams body, [
    RequestInit? init,
  ]) {
    return Request(url, _coerceInit(init, body: body));
  }

  factory Request.formData(Uri url, FormData body, [RequestInit? init]) {
    return Request(url, _coerceInit(init, body: body));
  }

  /// Target URL.
  final Uri url;

  /// HTTP method in upper-case wire format.
  final String method;

  /// Mutable request headers.
  final Headers headers;

  final Body bodyData;

  Stream<Uint8List>? get body => bodyData.hasBody ? bodyData.stream : null;
  bool get bodyUsed => bodyData.bodyUsed;
  Future<Uint8List> bytes() => bodyData.bytes();
  Future<String> text([Encoding encoding = utf8]) => bodyData.text(encoding);
  Future<T> json<T>() => bodyData.json<T>();
  Future<Blob> blob() async {
    final blob = await bodyData.blob();
    final type = headers.get('content-type');
    if (type == null || type.isEmpty || blob.type == type) {
      return blob;
    }

    return Blob(<Object>[blob], type);
  }

  Request clone() {
    return Request._internal(
      url: url,
      method: method,
      headers: Headers(headers.entries()),
      bodyData: bodyData.clone(),
    );
  }

  static RequestInit _coerceInit(RequestInit? init, {required Object? body}) {
    return RequestInit(
      method: init?.method ?? 'POST',
      headers: init?.headers,
      body: body,
    );
  }

  static Headers _headersFromInit(HeadersInit? init) {
    return switch (init) {
      final Headers headers => headers,
      _ => Headers(init),
    };
  }

  static String _normalizeMethod(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized.isEmpty) {
      throw ArgumentError.value(
        value,
        'method',
        'Request method cannot be empty',
      );
    }

    return normalized;
  }

  static bool _methodAllowsBody(String method) {
    return method != 'GET' && method != 'HEAD' && method != 'TRACE';
  }

  void _validateMethodAndBody() {
    if (!_methodAllowsBody(method) && bodyData.hasBody) {
      throw ArgumentError('HTTP $method requests cannot include a body.');
    }
  }

  void _applyDefaultBodyHeaders() {
    if (!bodyData.hasBody) return;

    final inferredType = bodyData.defaultContentType;
    if (inferredType != null && !headers.has('content-type')) {
      headers.set('content-type', inferredType);
    }

    final inferredLength = bodyData.defaultContentLength;
    if (inferredLength != null && !headers.has('content-length')) {
      headers.set('content-length', inferredLength.toString());
    }
  }
}
