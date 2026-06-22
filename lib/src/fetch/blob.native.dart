import 'dart:typed_data';

import 'package:block/block.dart' as block;

/// Constructor parts accepted by native [Blob].
///
/// Supported part types:
/// - [String]
/// - [Uint8List]
/// - [ByteBuffer]
/// - [ByteData]
/// - [Blob]
/// - [block.Block]
///
/// Platform-specific extensions:
/// - `web.Blob`
/// - `web.File`
/// - `dart:io File`
///
/// These platform-specific part types are added by other implementations.
typedef BlobPart = Object;

/// Native detached binary large object.
class Blob implements block.Block {
  Blob([Iterable<BlobPart> parts = const <BlobPart>[], String type = ''])
    : this._fromNormalized(_normalizeParts(parts), normalizeBlobType(type));

  Blob._fromNormalized(List<Object> parts, String normalizedType)
    : this._fromBlock(
        block.Block(parts, type: normalizedType),
        type: normalizedType,
      );

  Blob._fromBlock(this._host, {required this.type});

  final block.Block _host;

  @override
  final String type;

  @override
  int get size => _host.size;

  Future<Uint8List> bytes() => _host.arrayBuffer();

  @override
  Future<Uint8List> arrayBuffer() => _host.arrayBuffer();

  @override
  Future<String> text() => _host.text();

  @override
  Stream<Uint8List> stream({int chunkSize = 16 * 1024}) {
    if (chunkSize <= 0) {
      throw ArgumentError.value(chunkSize, 'chunkSize', 'Must be > 0');
    }

    return _host.stream(chunkSize: chunkSize);
  }

  @override
  Blob slice(int start, [int? end, String? contentType]) {
    final normalizedContentType = normalizeBlobType(contentType ?? '');
    return Blob._fromBlock(
      _host.slice(start, end, normalizedContentType),
      type: normalizedContentType,
    );
  }

  static List<Object> _normalizeParts(Iterable<BlobPart> parts) =>
      parts.map(_normalizePart).toList(growable: false);

  static Object _normalizePart(BlobPart part) {
    return switch (part) {
      final Blob blob => blob._host,
      final block.Block blockPart => blockPart,
      final ByteBuffer buffer => ByteData.sublistView(buffer.asUint8List()),
      final ByteData data => ByteData.sublistView(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      ),
      final Uint8List bytes => Uint8List.fromList(bytes),
      final List<int> bytes => Uint8List.fromList(bytes),
      final String text => text,
      _ => throw ArgumentError.value(
        part,
        'parts',
        'Unsupported blob part type: ${part.runtimeType}',
      ),
    };
  }
}

/// Normalizes Blob/File MIME type inputs using the File API rules.
String normalizeBlobType(String type) {
  StringBuffer? buffer;

  for (var index = 0; index < type.length; index += 1) {
    final unit = type.codeUnitAt(index);
    if (unit < 0x20 || unit > 0x7E) {
      return '';
    }

    if (unit >= 0x41 && unit <= 0x5A) {
      buffer ??= StringBuffer(type.substring(0, index));
      buffer.writeCharCode(unit + 0x20);
    } else {
      buffer?.writeCharCode(unit);
    }
  }

  return buffer?.toString() ?? type;
}
