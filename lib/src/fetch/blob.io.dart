import 'dart:convert';
import 'dart:io' as io;
import 'dart:math';
import 'dart:typed_data';

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
      // Downstream shim until block exposes a reusable public file-backed
      // primitive: https://github.com/medz/block/issues/10
      final io.File file => _FileBlock(file),
      _ => native.Blob([part]),
    };
  }
}

/// Temporary downstream file-backed block until `block` exposes reusable
/// io-backed file primitives. Once https://github.com/medz/block/issues/10 is
/// available, this wrapper should be replaced with the upstream implementation.
final class _FileBlock implements block.Block {
  _FileBlock(this._file, {int start = 0, int? length, this.type = ''})
    : _start = start,
      _length = length ?? _file.lengthSync();

  final io.File _file;
  final int _start;
  final int _length;

  @override
  final String type;

  @override
  int get size => _length;

  @override
  _FileBlock slice(int start, [int? end, String? contentType]) {
    final bounds = _normalizeSliceBounds(_length, start, end);
    return _FileBlock(
      _file,
      start: _start + bounds.start,
      length: bounds.length,
      type: contentType ?? '',
    );
  }

  @override
  Future<Uint8List> arrayBuffer() => _readRange(0, _length);

  @override
  Future<String> text() async => utf8.decode(await arrayBuffer());

  @override
  Stream<Uint8List> stream({
    int chunkSize = block.Block.defaultStreamChunkSize,
  }) async* {
    _validateChunkSize(chunkSize);
    if (_length == 0) {
      return;
    }

    final reader = await _file.open(mode: io.FileMode.read);
    var remaining = _length;

    try {
      await reader.setPosition(_start);

      while (remaining > 0) {
        final toRead = min(chunkSize, remaining);
        final chunk = await reader.read(toRead);
        if (chunk.isEmpty) {
          throw StateError(
            'Unexpected end of file while streaming ${_file.path}.',
          );
        }

        yield chunk;
        remaining -= chunk.length;
      }
    } finally {
      try {
        await reader.close();
      } catch (_) {
        // best-effort cleanup.
      }
    }
  }

  Future<Uint8List> _readRange(int offset, int length) async {
    _validateRange(_length, offset, length);
    if (length == 0) {
      return Uint8List(0);
    }

    final reader = await _file.open(mode: io.FileMode.read);
    try {
      await reader.setPosition(_start + offset);
      final bytes = await reader.read(length);
      if (bytes.length != length) {
        throw StateError(
          'Unexpected end of file while reading $length bytes from ${_file.path}.',
        );
      }
      return bytes;
    } finally {
      try {
        await reader.close();
      } catch (_) {
        // best-effort cleanup.
      }
    }
  }

  static ({int start, int length}) _normalizeSliceBounds(
    int size,
    int start,
    int? end,
  ) {
    final normalizedStart = start < 0
        ? (size + start).clamp(0, size)
        : start.clamp(0, size);
    final normalizedEnd = end == null
        ? size
        : end < 0
        ? (size + end).clamp(0, size)
        : end.clamp(0, size);
    final clampedEnd = normalizedEnd < normalizedStart
        ? normalizedStart
        : normalizedEnd;
    return (start: normalizedStart, length: clampedEnd - normalizedStart);
  }

  static void _validateChunkSize(int chunkSize) {
    if (chunkSize <= 0) {
      throw ArgumentError.value(chunkSize, 'chunkSize', 'Must be > 0');
    }
  }

  static void _validateRange(int size, int offset, int length) {
    if (offset < 0 || offset > size) {
      throw RangeError.range(offset, 0, size, 'offset');
    }

    if (length < 0 || offset + length > size) {
      throw RangeError.range(length, 0, size - offset, 'length');
    }
  }
}
