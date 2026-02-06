import 'dart:convert';

import '../core/http_status.dart';
import 'body.dart';
import 'headers.dart';

/// Fetch-like HTTP response model.
class Response with BodyMixin {
  Response({
    Object? body,
    int status = HttpStatus.ok,
    String? statusText,
    Headers? headers,
    this.url,
    this.redirected = false,
  })  : status = _validateStatus(status),
        statusText = statusText ?? HttpStatus.reasonPhrase(status),
        headers = headers?.clone() ?? Headers(),
        bodyData = BodyData.fromInit(body) {
    _applyDefaultBodyHeaders();
  }

  Response._internal({
    required this.status,
    required this.statusText,
    required this.headers,
    required this.bodyData,
    required this.url,
    required this.redirected,
  });

  factory Response.text(
    String body, {
    int status = HttpStatus.ok,
    String? statusText,
    Headers? headers,
    Uri? url,
    bool redirected = false,
  }) {
    return Response(
      body: body,
      status: status,
      statusText: statusText,
      headers: headers,
      url: url,
      redirected: redirected,
    );
  }

  factory Response.json(
    Object? body, {
    int status = HttpStatus.ok,
    String? statusText,
    Headers? headers,
    Uri? url,
    bool redirected = false,
  }) {
    final nextHeaders = headers?.clone() ?? Headers();
    if (!nextHeaders.has('content-type')) {
      nextHeaders.set('content-type', 'application/json; charset=utf-8');
    }

    return Response(
      body: json.encode(body),
      status: status,
      statusText: statusText,
      headers: nextHeaders,
      url: url,
      redirected: redirected,
    );
  }

  factory Response.bytes(
    List<int> body, {
    int status = HttpStatus.ok,
    String? statusText,
    Headers? headers,
    Uri? url,
    bool redirected = false,
  }) {
    return Response(
      body: body,
      status: status,
      statusText: statusText,
      headers: headers,
      url: url,
      redirected: redirected,
    );
  }

  factory Response.redirect(
    Uri location, {
    int status = HttpStatus.found,
    Headers? headers,
  }) {
    if (!const <int>{301, 302, 303, 307, 308}.contains(status)) {
      throw ArgumentError.value(
        status,
        'status',
        'Redirect response must use one of 301, 302, 303, 307, 308',
      );
    }

    final nextHeaders = headers?.clone() ?? Headers();
    nextHeaders.set('location', location.toString());

    return Response(
      status: status,
      headers: nextHeaders,
      url: location,
      redirected: true,
    );
  }

  factory Response.empty({
    int status = HttpStatus.noContent,
    String? statusText,
    Headers? headers,
    Uri? url,
    bool redirected = false,
  }) {
    return Response(
      status: status,
      statusText: statusText,
      headers: headers,
      url: url,
      redirected: redirected,
    );
  }

  final int status;
  final String statusText;
  final Headers headers;
  final Uri? url;
  final bool redirected;

  @override
  final BodyData bodyData;

  bool get ok => HttpStatus.isSuccess(status);

  @override
  String? get bodyMimeTypeHint => headers.get('content-type');

  Response clone() {
    return Response._internal(
      status: status,
      statusText: statusText,
      headers: headers.clone(),
      bodyData: bodyData.clone(),
      url: url,
      redirected: redirected,
    );
  }

  Response copyWith({
    Object? body = _sentinel,
    int? status,
    String? statusText,
    Headers? headers,
    Uri? url,
    bool? redirected,
  }) {
    final hasBody = !identical(body, _sentinel);

    return Response(
      body: hasBody ? body : bodyData.clone(),
      status: status ?? this.status,
      statusText: statusText ?? this.statusText,
      headers: headers ?? this.headers.clone(),
      url: url ?? this.url,
      redirected: redirected ?? this.redirected,
    );
  }

  static const Object _sentinel = Object();

  static int _validateStatus(int status) {
    HttpStatus.validate(status);
    return status;
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
