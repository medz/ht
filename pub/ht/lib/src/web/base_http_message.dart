import 'dart:convert';
import 'dart:typed_data';

import '../mime.dart';
import '../utils/errors.dart';
import '../utils/formdata_utils.dart';
import '../utils/url_search_params_utils.dart';
import 'headers.dart';
import 'blob.dart';
import 'formdata.dart';

/// Represents a base interface for HTTP messages, providing methods to access the message body in various formats.
///
/// This interface is implemented by both requests and responses, allowing for uniform access to message content.
mixin BaseHttpMessage {
  Headers get headers;

  /// The raw body of the HTTP message as a stream of bytes.
  ///
  /// This may be null if the message has no body.
  Stream<Uint8List>? get body;

  /// Indicates whether the body of the message has been read.
  ///
  /// Once true, attempting to read the body again may throw an error.
  bool get bodyUsed;

  /// Retrieves the message body as a [Blob].
  ///
  /// This is useful for handling binary data or large objects.
  Future<Blob> blob() async {
    _validateBodyNotRead();

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

  /// Retrieves the message body as a [ByteBuffer].
  ///
  /// This is useful for working with the raw byte data of the message.
  Future<ByteBuffer> byteBuffer() async {
    return (await bytes()).buffer;
  }

  /// Retrieves the message body as a [Uint8List].
  ///
  /// This provides the body as a list of unsigned 8-bit integers.
  Future<Uint8List> bytes() async {
    return (await blob()).bytes();
  }

  /// Retrieves the message body as a [String].
  ///
  /// This is useful when the body is expected to be text content.
  Future<String> text() async {
    return (await blob()).text();
  }

  /// Retrieves the message body as a JSON-decoded object.
  ///
  /// The return type is [dynamic] as JSON can represent various data structures.
  Future<dynamic> json() async {
    _validateBodyNotRead();
    if (body == null) return null;

    return jsonDecode(await text());
  }

  /// Retrieves the message body as [FormData].
  ///
  /// This is particularly useful for handling form submissions or multipart data.
  Future<FormData> formData() async {
    final contentType = switch (headers.get("content-type")) {
      String value when value.isNotEmpty => MimeType.parse(value),
      _ => null,
    };
    if (contentType?.essence == MimeType.form.essence) {
      final fromData = FormData();
      for (final (key, value) in parseURLSearchParams(await text())) {
        fromData.append(key, value);
      }

      return fromData;
    }

    final boundary = contentType?.params['boundary'];
    if (boundary != null && contentType?.essence == MimeType.formData.essence) {
      return await parseFormData(boundary, (await blob()).stream());
    }

    throw StateError('The content type is not a valid form data type.');
  }

  /// Validates that the body has not been read yet.
  void _validateBodyNotRead() {
    if (bodyUsed) {
      throw throwHttpBodyUsedError();
    }
  }
}
