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
  ]) : super([_toBlock(parts, type)], type);

  static block.Block _toBlock(Iterable<native.BlobPart> parts, String type) {
    return block.Block(_normalizeParts(parts), type: type);
  }

  static List<Object> _normalizeParts(Iterable<native.BlobPart> parts) =>
      parts.map(_normalizePart).toList(growable: false);

  static Object _normalizePart(native.BlobPart part) {
    return switch (part) {
      final Blob blob => blob,
      final native.Blob blob => blob,
      final web.Blob blob => blob,
      _ => native.Blob([part]),
    };
  }
}
