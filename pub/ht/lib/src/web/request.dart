import 'dart:convert' as convert;
import 'dart:typed_data';

import '../method.dart';
import '../utils/clonable_stream.dart';
import '../utils/serialize_url_search_params.dart';
import '../utils/stateful_stream.dart';
import 'base_http_message.dart';
import 'blob.dart';
import 'formdata.dart';
import 'headers.dart';
import 'url_search_params.dart';

/// A web API like request object suitable for Dart.
abstract interface class Request implements BaseHttpMessage {
  /// Creates a new [Request].
  factory Request(
    Uri url, {
    String? method,
    Headers? headers,
    Stream<Uint8List>? body,
  }) {
    return _Request(
      url,
      method: method ?? Method.get.toString(),
      headers: headers,
      body: body != null ? StatefulStream(body) : null,
    );
  }

  /// Creates a new [Request] from [ByteBuffer].
  factory Request.byteBuffer(
    Uri url, {
    String? method,
    Headers? headers,
    required ByteBuffer body,
  }) {
    return Request.bytes(
      url,
      method: method,
      headers: headers,
      body: body.asUint8List(),
    );
  }

  /// Creates a new [Request] from [bytes].
  factory Request.bytes(
    Uri url, {
    String? method,
    Headers? headers,
    required Uint8List body,
  }) {
    return _BlobRequestImpl(
      url,
      method: method ?? Method.get.toString(),
      headers: headers,
      body: Blob.bytes(body, type: headers?.get('content-type')),
    );
  }

  /// Creates a new [Request] from [URLSearchParams].
  factory Request.searchParams(
    Uri url, {
    String? method,
    Headers? headers,
    required URLSearchParams body,
  }) {
    return _BlobRequestImpl(
      url,
      method: method ?? Method.get.toString(),
      headers: headers,
      body: Blob.text(
        serializeURLSearchParams(body),
        type: 'application/x-www-form-urlencoded',
      ),
    );
  }

  /// Creates a new [Request] from [Blob].
  factory Request.blob(Uri url,
      {String? method, Headers? headers, required Blob body}) {
    return _BlobRequestImpl(
      url,
      body: body,
      method: method ?? Method.get.toString(),
      headers: headers,
    );
  }

  /// Creates a new [Request] from [String]
  factory Request.text(Uri url,
      {String? method, Headers? headers, required String body}) {
    return _BlobRequestImpl(
      url,
      method: method ?? Method.get.toString(),
      headers: headers,
      body: Blob.text(body),
    );
  }

  /// Request URL.
  Uri get url;

  /// Request method.
  String get method;

  /// Request headers.
  Headers get headers;

  /// Clone a new request.
  Request clone();
}

/// Request impl.
class _Request implements Request {
  _Request(
    this.url, {
    this.method = 'get',
    Headers? headers,
    this.body,
  }) : headers = headers ?? Headers();

  @override
  final String method;

  @override
  final Uri url;

  @override
  final Headers headers;

  @override
  StatefulStream<Uint8List>? body;

  @override
  bool get bodyUsed => body?.isListened ?? false;

  @override
  Future<Blob> blob() async {
    if (bodyUsed) {
      throw _createRequestBodyUsedError();
    }

    final contentLength = headers.get('content-length');
    final size = switch (contentLength?.trim()) {
      String(isEmpty: true) || null => null,
      String value => int.tryParse(value),
    };

    if (body != null && size != null && size > 0) {
      return Blob.stream(body!, size: size, type: headers.get('content-type'));
    }

    return Blob.bytes(Uint8List(0), type: headers.get('content-type'));
  }

  @override
  Future<ByteBuffer> byteBuffer() {
    return blob().then((blob) => blob.byteBuffer());
  }

  @override
  Future<Uint8List> bytes() {
    return blob().then((blob) => blob.bytes());
  }

  @override
  Future<FormData> formData() {
    // TODO: implement formData
    throw UnimplementedError();
  }

  @override
  Future<String> text() {
    return blob().then((blob) => blob.text());
  }

  @override
  Future json() async {
    if (body != null) {
      return convert.json.decode(await text());
    }

    return null;
  }

  @override
  Request clone() {
    if (bodyUsed) {
      throw _createRequestBodyUsedError();
    } else if (body == null) {
      return _Request(url, method: method, headers: headers);
    }

    final stream = ClonableStream(body!);
    body = StatefulStream(stream);

    return _Request(
      url,
      method: method,
      headers: headers,
      body: StatefulStream(stream.clone()),
    );
  }
}

class _BlobRequestImpl extends _Request {
  _BlobRequestImpl(
    super.url, {
    super.method,
    super.headers,
    required Blob body,
  }) : inner = body {
    headers.set('content-type', body.type);
    headers.set('content-length', body.size.toString());
  }

  final Blob inner;
  StatefulStream<Uint8List>? _stream;

  @override
  StatefulStream<Uint8List> get body =>
      _stream ??= StatefulStream(inner.stream());

  @override
  Future<Blob> blob() async {
    body.isListened = true;

    return Blob.stream(
      body,
      size: inner.size,
      type: headers.get('content-type'),
    );
  }

  @override
  Request clone() {
    if (bodyUsed) {
      throw _createRequestBodyUsedError();
    }

    return _BlobRequestImpl(url, method: method, headers: headers, body: inner);
  }
}

Error _createRequestBodyUsedError() {
  return StateError('The request body used.');
}
