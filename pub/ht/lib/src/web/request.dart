import 'dart:convert' as convert;
import 'dart:typed_data';

import '../method.dart';
import '../mime.dart';
import '../utils/clonable_stream.dart';
import '../utils/serialize_url_search_params.dart';
import '../utils/stateful_stream.dart';
import 'base_http_message.dart';
import 'blob.dart';
import 'formdata.dart';
import 'headers.dart';
import 'url_search_params.dart';

/// Represents an HTTP request, including URL, method, headers, and body.
///
/// This class provides various factory constructors to create requests with different
/// body types (e.g., bytes, text, JSON, blob) and methods to access and manipulate
/// the request data.
///
/// Key features:
/// - Supports multiple body types: stream, bytes, text, JSON, blob, and URL search params.
/// - Provides methods to access the body in different formats (blob, bytes, text, JSON).
/// - Allows cloning of the request for reuse.
/// - Implements lazy loading of the body to improve performance.
///
/// Example:
/// ```dart
/// final request = Request(
///   Uri.parse('https://api.example.com/data'),
///   method: 'POST',
///   headers: Headers({'Content-Type': 'application/json'}),
///   body: Stream.value(utf8.encode('{"key": "value"}')),
/// );
///
/// final jsonBody = await request.json();
/// ```
///
/// Note: The body can only be read once unless the request is cloned.
abstract interface class Request implements BaseHttpMessage {
  /// Creates a new [Request] instance.
  ///
  /// Parameters:
  /// - [url]: The target URI for the request.
  /// - [method]: The HTTP method (e.g., GET, POST). Defaults to GET if not specified.
  /// - [headers]: The HTTP headers. If null, an empty [Headers] object is used.
  /// - [body]: The request body as a [Stream] of [Uint8List]. If null, the request has no body.
  ///
  /// The [body] stream, if provided, is wrapped in a [StatefulStream] for internal management.
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

  /// Creates a [Request] from a [ByteBuffer].
  ///
  /// Useful for sending binary data as the request body.
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

  /// Creates a [Request] from a [Uint8List].
  ///
  /// Convenient for sending raw byte data as the request body.
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

  /// Creates a [Request] from [URLSearchParams].
  ///
  /// Useful for sending form data in the request body.
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
        type: MimeType.form.toString(),
      ),
    );
  }

  /// Creates a [Request] from a [Blob].
  ///
  /// Useful when you have data encapsulated in a [Blob] to send as the request body.
  factory Request.blob(Uri url,
      {String? method, Headers? headers, required Blob body}) {
    return _BlobRequestImpl(
      url,
      body: body,
      method: method ?? Method.get.toString(),
      headers: headers,
    );
  }

  /// Creates a [Request] with a text body.
  ///
  /// Convenient for sending plain text or string data as the request body.
  factory Request.text(Uri url,
      {String? method, Headers? headers, required String body}) {
    return _BlobRequestImpl(
      url,
      method: method ?? Method.get.toString(),
      headers: headers,
      body: Blob.text(body, type: headers?.get('content-type')),
    );
  }

  /// Creates a [Request] with a JSON body.
  ///
  /// Automatically serializes the provided object to JSON and sets the appropriate content type.
  factory Request.json(Uri url,
      {String? method, Headers? headers, required dynamic body}) {
    return _BlobRequestImpl(
      url,
      method: method ?? Method.get.toString(),
      headers: headers,
      body: Blob.text(
        convert.json.encode(body),
        type: MimeType.json.toString(),
      ),
    );
  }

  /// The request URL.
  Uri get url;

  /// The request method.
  String get method;

  /// The request headers.
  Headers get headers;

  /// Indicates whether the body has been read.
  @override
  bool get bodyUsed;

  /// Retrieves the request body as a [Blob].
  ///
  /// Throws a [StateError] if the body has already been read.
  @override
  Future<Blob> blob();

  /// Retrieves the request body as a [ByteBuffer].
  @override
  Future<ByteBuffer> byteBuffer();

  /// Retrieves the request body as a [Uint8List].
  @override
  Future<Uint8List> bytes();

  /// Retrieves the request body as [FormData].
  @override
  Future<FormData> formData();

  /// Retrieves the request body as a [String].
  @override
  Future<String> text();

  /// Retrieves the request body as a JSON object.
  ///
  /// Returns null if the body is empty.
  @override
  Future<dynamic> json();

  /// Creates a clone of this request.
  ///
  /// Throws a [StateError] if the body has already been read.
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
