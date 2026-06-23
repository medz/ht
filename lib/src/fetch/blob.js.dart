import 'dart:typed_data';

import 'package:block/block.dart' as block;
import 'package:web/web.dart' as web;

import 'blob.native.dart' as native;

/// Web-backed [Blob] implementation.
///
/// This extends the native detached baseline by accepting native `web.Blob`
/// and `web.File` parts during construction.
class Blob extends native.Blob implements block.Block {
  Blob([
    Iterable<native.BlobPart> parts = const <native.BlobPart>[],
    String type = '',
  ]) : this._fromNormalized(parts, native.normalizeBlobType(type));

  Blob._fromNormalized(Iterable<native.BlobPart> parts, String normalizedType)
    : super([_toBlock(parts, normalizedType)], normalizedType);

  static block.Block _toBlock(Iterable<native.BlobPart> parts, String type) {
    return block.Block(_normalizeParts(parts), type: type);
  }

  static List<Object> _normalizeParts(Iterable<native.BlobPart> parts) =>
      parts.map(_normalizePart).toList(growable: false);

  static Object _normalizePart(native.BlobPart part) {
    return switch (part) {
      final ByteBuffer buffer => Uint8List.fromList(buffer.asUint8List()),
      final ByteData data => Uint8List.fromList(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      ),
      final Uint8List bytes => Uint8List.fromList(bytes),
      final List<int> bytes => Uint8List.fromList(bytes),
      final String text => text,
      final Blob blob => native.blobBacking(blob),
      final native.Blob blob => native.blobBacking(blob),
      final web.Blob blob => blob,
      _ => native.blobBacking(native.Blob([part])),
    };
  }
}
