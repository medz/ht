import 'dart:io' as io;

import 'package:block/block.dart' as block;

import 'blob.native.dart' as native;

/// IO-backed [Blob] implementation.
///
/// This extends the native detached baseline by accepting `dart:io File`
/// parts during construction.
class Blob extends native.Blob implements block.Block {
  Blob([
    Iterable<native.BlobPart> parts = const <native.BlobPart>[],
    String type = '',
  ]) : super(_normalizeParts(parts), type);

  static List<Object> _normalizeParts(Iterable<native.BlobPart> parts) =>
      parts.map(_normalizePart).toList(growable: false);

  static Object _normalizePart(native.BlobPart part) {
    return switch (part) {
      final Blob blob => blob,
      final native.Blob blob => blob,
      final io.File file => block.Block(<Object>[file]),
      _ => native.Blob([part]),
    };
  }
}
