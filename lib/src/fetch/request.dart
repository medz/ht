import 'dart:convert';

import 'body.dart';
import 'form_data.dart';
import 'headers.dart';
import 'url_search_params.dart';

/// Fetch-like HTTP request model.
class Request with BodyMixin {
  Request(this.url, {String method = 'GET', Headers? headers, Object? body})
    : method = _normalizeMethod(method),
      headers = headers?.clone() ?? Headers(),
      bodyData = BodyData.fromInit(body) {
    _validateMethodAndBody();
    _applyDefaultBodyHeaders();
  }

  Request._internal({
    required this.url,
    required this.method,
    required this.headers,
    required this.bodyData,
  });

  factory Request.text(
    Uri url, {
    String method = 'POST',
    Headers? headers,
    required String body,
  }) {
    return Request(url, method: method, headers: headers, body: body);
  }

  factory Request.json(
    Uri url, {
    String method = 'POST',
    Headers? headers,
    required Object? body,
  }) {
    final nextHeaders = headers?.clone() ?? Headers();
    if (!nextHeaders.has('content-type')) {
      nextHeaders.set('content-type', 'application/json; charset=utf-8');
    }

    return Request(
      url,
      method: method,
      headers: nextHeaders,
      body: json.encode(body),
    );
  }

  factory Request.bytes(
    Uri url, {
    String method = 'POST',
    Headers? headers,
    required List<int> body,
  }) {
    return Request(url, method: method, headers: headers, body: body);
  }

  factory Request.stream(
    Uri url, {
    String method = 'POST',
    Headers? headers,
    required Stream<List<int>> body,
  }) {
    return Request(url, method: method, headers: headers, body: body);
  }

  factory Request.searchParams(
    Uri url, {
    String method = 'POST',
    Headers? headers,
    required URLSearchParams body,
  }) {
    return Request(url, method: method, headers: headers, body: body);
  }

  factory Request.formData(
    Uri url, {
    String method = 'POST',
    Headers? headers,
    required FormData body,
  }) {
    return Request(url, method: method, headers: headers, body: body);
  }

  /// Target URL.
  final Uri url;

  /// HTTP method in upper-case wire format.
  final String method;

  /// Mutable request headers.
  final Headers headers;

  @override
  final BodyData bodyData;

  @override
  String? get bodyMimeTypeHint => headers.get('content-type');

  Request clone() {
    return Request._internal(
      url: url,
      method: method,
      headers: headers.clone(),
      bodyData: bodyData.clone(),
    );
  }

  Request copyWith({
    Uri? url,
    String? method,
    Headers? headers,
    Object? body = _sentinel,
  }) {
    final hasBody = !identical(body, _sentinel);
    return Request(
      url ?? this.url,
      method: method ?? this.method,
      headers: headers ?? this.headers.clone(),
      body: hasBody ? body : bodyData.clone(),
    );
  }

  static const Object _sentinel = Object();

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
    if (!bodyData.hasBody) {
      return;
    }

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
