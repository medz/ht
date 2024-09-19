import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../utils/clonable_stream.dart';

/// Binary large object
abstract interface class Blob {
  /// Creates a new [Blob] from [bytes].
  const factory Blob.bytes(Uint8List bytes, {String? type}) = _BytesBlob;

  /// Creates a new [Blob] from [stream].
  factory Blob.stream(Stream<Uint8List> stream,
      {String? type, required int size}) = _StreamBlob;

  /// Creates a new [Blob] from [String].
  factory Blob.text(String str, {String? type}) {
    return Blob.bytes(utf8.encode(str), type: type ?? 'text/plain');
  }

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
  Blob slice(int start, [int? end, String? contentType]);
}

/// The octet bytes [Blob] impl.
class _BytesBlob implements Blob {
  const _BytesBlob(this.data, {String? type})
      : type = type ?? 'application/octet-stream';

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
  Blob slice(int start, [int? end, String? contentType]) {
    return _BytesBlob(data.sublist(start, end), type: contentType ?? type);
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

// Stream wraped [Blob] impl.
class _StreamBlob implements Blob {
  _StreamBlob(
    Stream<Uint8List> stream, {
    required this.size,
    String? type,
  })  : upstream = ClonableStream(stream),
        type = type ?? 'application/octet-stream';

  final ClonableStream<Uint8List> upstream;

  @override
  final String type;

  @override
  final int size;

  @override
  Future<ByteBuffer> byteBuffer() async => (await bytes()).buffer;

  @override
  Future<Uint8List> bytes() async {
    final bytes = Uint8List(size);
    await for (final chunk in stream()) {
      bytes.addAll(chunk);
    }

    return bytes;
  }

  @override
  Stream<Uint8List> stream() => upstream.clone();

  @override
  Future<String> text() {
    return utf8.decodeStream(stream());
  }

  @override
  Blob slice(int start, [int? end, String? contentType]) {
    return _StreamBlob(
      stream().slice(size, start, end),
      size: (end ?? size) - start,
      type: contentType ?? type,
    );
  }
}

extension on Stream<Uint8List> {
  Stream<Uint8List> slice(int size, int start, [int? end]) async* {
    int offset = 0;
    int effectiveEnd = end ?? size;

    await for (final chunk in this) {
      if (offset >= effectiveEnd) break;

      int chunkLength = chunk.lengthInBytes;
      int startOffset = max(0, start - offset);
      int endOffset = min(offset + chunkLength, effectiveEnd) - offset;

      yield chunk.sublist(startOffset, endOffset);
      offset += chunkLength;
    }
  }
}
