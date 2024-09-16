import 'dart:typed_data';

import 'blob.dart';

abstract interface class File implements Blob {
  factory File.fromBytes(Uint8List bytes, String name,
          {String? type, int? lastModified}) =>
      _FileImpl(Blob.fromBytes(bytes, type: type), name, lastModified ?? 0);

  factory File.fromStream(Stream<Uint8List> stream, String name,
          {String? type, int? lastModified, required int size}) =>
      _FileImpl(Blob.fromStream(stream, size: size, type: type), name,
          lastModified ?? 0);

  /// Name of the file referenced by the File object.
  String get name;

  /// The last modified date of the file as the number of milliseconds
  /// since the Unix epoch (January 1, 1970 at midnight). Files without
  /// a known last modified date return the current date.
  int get lastModified;
}

/// File impl.
class _FileImpl implements File {
  const _FileImpl(this.blob, this.name, this.lastModified);

  final Blob blob;

  @override
  final int lastModified;

  @override
  final String name;

  @override
  int get size => blob.size;

  @override
  String get type => blob.type;

  @override
  Future<ByteBuffer> byteBuffer() => blob.byteBuffer();

  @override
  Future<Uint8List> bytes() => blob.bytes();

  @override
  Stream<Uint8List> stream() => blob.stream();

  @override
  Future<String> text() => blob.text();

  @override
  Blob slice(int start, [int? end, String? contentType]) =>
      blob.slice(start, end, contentType);
}
