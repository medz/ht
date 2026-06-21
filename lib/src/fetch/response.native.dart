import 'dart:convert';
import 'dart:typed_data';

import '../core/http_status.dart';
import 'blob.dart';
import 'body.dart';
import 'form_data.native.dart';
import 'headers.dart';

enum ResponseType {
  basic('basic'),
  cors('cors'),
  default_('default'),
  error('error'),
  opaque('opaque'),
  opaqueRedirect('opaqueredirect');

  const ResponseType(this.value);

  final String value;
}

class ResponseInit {
  const ResponseInit({this.status, this.statusText, this.headers});

  final int? status;
  final String? statusText;
  final HeadersInit? headers;
}

class Response {
  factory Response([BodyInit? body, ResponseInit? init]) {
    final status = _validateStatus(init?.status ?? HttpStatus.ok);
    return Response._internal(
      body: _bodyFromInit(body, status),
      headers: _headersFromInit(init?.headers),
      ok: HttpStatus.isSuccess(status),
      redirected: false,
      status: status,
      statusText: init?.statusText ?? '',
      type: ResponseType.default_,
      url: '',
    );
  }

  Response._internal({
    required this.body,
    required this.headers,
    required this.ok,
    required this.redirected,
    required this.status,
    required this.statusText,
    required this.type,
    required this.url,
  });

  factory Response.error() {
    return Response._internal(
      body: null,
      headers: Headers(),
      ok: false,
      redirected: false,
      status: 0,
      statusText: '',
      type: ResponseType.error,
      url: '',
    );
  }

  factory Response.json(Object? data, [ResponseInit? init]) {
    final headers = _headersFromInit(init?.headers);
    if (!headers.has('content-type')) {
      headers.set('content-type', 'application/json; charset=utf-8');
    }

    return Response(
      jsonEncode(data),
      ResponseInit(
        status: init?.status,
        statusText: init?.statusText,
        headers: headers,
      ),
    );
  }

  factory Response.redirect(Uri url, [int status = HttpStatus.found]) {
    if (!const <int>{301, 302, 303, 307, 308}.contains(status)) {
      throw ArgumentError.value(
        status,
        'status',
        'Redirect response must use one of 301, 302, 303, 307, 308',
      );
    }

    return Response(
      null,
      ResponseInit(
        status: status,
        headers: Headers()..set('location', url.toString()),
      ),
    );
  }

  final Body? body;
  final Headers headers;
  final bool ok;
  final bool redirected;
  final int status;
  final String statusText;
  final ResponseType type;
  final String url;

  bool get bodyUsed => body?.bodyUsed ?? false;

  Future<Uint8List> arrayBuffer() => bytes();

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

  Future<Uint8List> bytes() {
    return switch (body) {
      final Body body => body.bytes(),
      null => Future<Uint8List>.value(Uint8List(0)),
    };
  }

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

  Future<T> json<T>() {
    return switch (body) {
      final Body body => body.json<T>(),
      null => Future<T>.error(
        const FormatException('Cannot decode JSON from an empty body.'),
      ),
    };
  }

  Future<String> text() {
    return switch (body) {
      final Body body => body.text(),
      null => Future<String>.value(''),
    };
  }

  Response clone() {
    return Response._internal(
      body: body?.clone(),
      headers: Headers(headers),
      ok: ok,
      redirected: redirected,
      status: status,
      statusText: statusText,
      type: type,
      url: url,
    );
  }

  static Body? _bodyFromInit(BodyInit? init, int status) {
    return switch (init) {
      null => null,
      _ when _isNullBodyStatus(status) => throw ArgumentError.value(
        init,
        'body',
        'Response status $status cannot have a body.',
      ),
      _ => Body(init),
    };
  }

  static Headers _headersFromInit(HeadersInit? init) {
    return switch (init) {
      null => Headers(),
      _ => Headers(init),
    };
  }

  static int _validateStatus(int status) {
    if (status < 200 || status > 599) {
      throw RangeError.range(status, 200, 599, 'status');
    }
    return status;
  }

  static bool _isNullBodyStatus(int status) {
    return const <int>{
      HttpStatus.noContent,
      HttpStatus.resetContent,
      HttpStatus.notModified,
    }.contains(status);
  }
}
