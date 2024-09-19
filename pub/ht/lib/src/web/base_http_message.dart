import 'dart:typed_data';

import 'blob.dart';
import 'formdata.dart';

/// Represents a base interface for HTTP messages, providing methods to access the message body in various formats.
///
/// This interface is implemented by both requests and responses, allowing for uniform access to message content.
abstract interface class BaseHttpMessage {
  /// The raw body of the HTTP message as a stream of bytes.
  ///
  /// This may be null if the message has no body.
  Stream<Uint8List>? get body;

  /// Indicates whether the body of the message has been read.
  ///
  /// Once true, attempting to read the body again may throw an error.
  bool get bodyUsed;

  /// Retrieves the message body as a [ByteBuffer].
  ///
  /// This is useful for working with the raw byte data of the message.
  Future<ByteBuffer> byteBuffer();

  /// Retrieves the message body as a [Uint8List].
  ///
  /// This provides the body as a list of unsigned 8-bit integers.
  Future<Uint8List> bytes();

  /// Retrieves the message body as a [String].
  ///
  /// This is useful when the body is expected to be text content.
  Future<String> text();

  /// Retrieves the message body as a JSON-decoded object.
  ///
  /// The return type is [dynamic] as JSON can represent various data structures.
  Future<dynamic> json();

  /// Retrieves the message body as [FormData].
  ///
  /// This is particularly useful for handling form submissions or multipart data.
  Future<FormData> formData();

  /// Retrieves the message body as a [Blob].
  ///
  /// This is useful for handling binary data or large objects.
  Future<Blob> blob();
}
