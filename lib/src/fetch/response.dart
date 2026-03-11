import 'dart:convert';

import '../core/http_status.dart';
import 'body.dart';
import 'headers.dart';

/// Initialization options for [Response], aligned with Fetch `ResponseInit`.
final class ResponseInit {
  ResponseInit({this.status, this.statusText, Headers? headers})
    : headers = headers?.clone();

  final int? status;
  final String? statusText;
  final Headers? headers;

  ResponseInit copyWith({int? status, String? statusText, Headers? headers}) {
    return ResponseInit(
      status: status ?? this.status,
      statusText: statusText ?? this.statusText,
      headers: headers ?? this.headers?.clone(),
    );
  }
}

/// Fetch-like HTTP response model.
class Response with BodyMixin {
  Response([Object? body, ResponseInit? init])
    : this._create(body, init, url: null, redirected: false);

  Response._create(
    Object? body,
    ResponseInit? init, {
    required this.url,
    required this.redirected,
  }) : status = _validateStatus(init?.status ?? HttpStatus.ok),
       statusText =
           init?.statusText ??
           HttpStatus.reasonPhrase(init?.status ?? HttpStatus.ok),
       headers = init?.headers?.clone() ?? Headers(),
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

  factory Response.text(String body, [ResponseInit? init]) {
    return Response(body, init);
  }

  factory Response.json(Object? body, [ResponseInit? init]) {
    final nextHeaders = init?.headers?.clone() ?? Headers();
    if (!nextHeaders.has('content-type')) {
      nextHeaders.set('content-type', 'application/json; charset=utf-8');
    }

    return Response(
      json.encode(body),
      (init ?? ResponseInit()).copyWith(headers: nextHeaders),
    );
  }

  factory Response.bytes(List<int> body, [ResponseInit? init]) {
    return Response(body, init);
  }

  factory Response.redirect(Uri location, [int status = HttpStatus.found]) {
    if (!const <int>{301, 302, 303, 307, 308}.contains(status)) {
      throw ArgumentError.value(
        status,
        'status',
        'Redirect response must use one of 301, 302, 303, 307, 308',
      );
    }

    final nextHeaders = Headers()..set('location', location.toString());

    return Response._create(
      null,
      ResponseInit(status: status, headers: nextHeaders),
      url: location,
      redirected: true,
    );
  }

  factory Response.empty([ResponseInit? init]) {
    return Response(
      null,
      ResponseInit(
        status: init?.status ?? HttpStatus.noContent,
        statusText: init?.statusText,
        headers: init?.headers,
      ),
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

    return Response._create(
      hasBody ? body : bodyData.clone(),
      ResponseInit(
        status: status ?? this.status,
        statusText: statusText ?? this.statusText,
        headers: headers ?? this.headers.clone(),
      ),
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
