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
  Response([BodyInit? body, ResponseInit? init])
    : body = _bodyFromInit(body),
      headers = _headersFromInit(init?.headers),
      status = _validateStatus(init?.status ?? HttpStatus.ok),
      statusText = init?.statusText ?? '',
      ok = HttpStatus.isSuccess(init?.status ?? HttpStatus.ok),
      redirected = false,
      type = ResponseType.default_,
      url = '';

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
    return Response(
      body?.clone(),
      ResponseInit(
        status: status,
        statusText: statusText,
        headers: Headers(headers),
      ),
    );
  }

  static Body? _bodyFromInit(BodyInit? init) {
    return switch (init) {
      null => null,
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
    HttpStatus.validate(status);
    return status;
  }
}
