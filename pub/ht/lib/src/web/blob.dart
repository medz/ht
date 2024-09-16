import 'dart:convert';
import 'dart:typed_data';

/// Binary large object
abstract interface class Blob {
  /// Creates a new [Blob] from [bytes].
  const factory Blob.fromBytes(Uint8List bytes, {String type}) = _BytesBlob;

  /// The total size of the [Blob] in bytes.
  int get size;

  /// The content-type of the [Blob].
  String get type;

  /// Returns a future that fulfills with an [ByteBuffer] containing a copy of
  /// the [Blob] data.
  Future<ByteBuffer> byteBuffer();

  /// Returns a future that filfills with an [Uint8List] containing a copy of
  /// the [Blob] data.
  Future<Uint8List> bytes();

  /// Returns a promise that fulfills with the contents of the [Blob] decoded as a
  /// [utf8] string.
  Future<String> text();

  /// Returns a new `Stream` that allows the content of the [Blob] to be read.
  Stream<Uint8List> stream();

  /// Creates and returns a new [Blob] containing a subset of this [Blob] objects
  /// data. The original [Blob] is not altered.
  Blob slice(int start, [int? end]);
}

/// The octet bytes [Blob] impl.
class _BytesBlob implements Blob {
  const _BytesBlob(this.data, {this.type = 'application/octet-stream'});

  final Uint8List data;

  @override
  final String type;

  @override
  int get size => data.lengthInBytes;

  @override
  Future<ByteBuffer> byteBuffer() async => data.buffer;

  @override
  Future<Uint8List> bytes() async => data;

  @override
  Blob slice(int start, [int? end]) {
    return _BytesBlob(data.sublist(start, end));
  }

  @override
  Stream<Uint8List> stream() async* {
    yield data;
  }

  @override
  Future<String> text() async {
    return utf8.decode(data);
  }
}
