import 'dart:convert';
import 'dart:typed_data';

import 'package:block/block.dart' as block;

/// Binary large object.
class Blob implements block.Block {
  Blob([Iterable<Object> parts = const <Object>[], String type = ''])
    : this._fromNormalized(_normalizeParts(parts), _normalizeType(type));

  Blob.bytes(List<int> bytes, {String type = ''})
    : this._fromNormalized(<Object>[
        Uint8List.fromList(bytes),
      ], _normalizeType(type));

  Blob.text(
    String text, {
    String type = 'text/plain;charset=utf-8',
    Encoding encoding = utf8,
  }) : this._fromNormalized(<Object>[
         Uint8List.fromList(encoding.encode(text)),
       ], _normalizeType(type));

  Blob._fromNormalized(List<Object> parts, String normalizedType)
    : this._fromBlock(
        block.Block(parts, type: normalizedType),
        type: normalizedType,
      );

  Blob._fromBlock(this._inner, {required this.type});

  final block.Block _inner;

  /// MIME type hint.
  @override
  final String type;

  @override
  int get size => _inner.size;

  /// Returns a copy of underlying bytes.
  Future<Uint8List> bytes() async {
    return Uint8List.fromList(await _inner.arrayBuffer());
  }

  @override
  Future<Uint8List> arrayBuffer() => bytes();

  @override
  Future<String> text([Encoding encoding = utf8]) async {
    if (identical(encoding, utf8)) {
      return _inner.text();
    }

    return encoding.decode(await bytes());
  }

  @override
  Stream<Uint8List> stream({int chunkSize = 16 * 1024}) {
    if (chunkSize <= 0) {
      throw ArgumentError.value(chunkSize, 'chunkSize', 'Must be > 0');
    }

    return _inner.stream(chunkSize: chunkSize);
  }

  @override
  Blob slice(int start, [int? end, String? contentType]) {
    final normalizedType = _normalizeType(contentType ?? '');
    return Blob._fromBlock(
      _inner.slice(start, end, normalizedType),
      type: normalizedType,
    );
  }

  static List<Object> _normalizeParts(Iterable<Object> parts) {
    return List<Object>.unmodifiable(parts.map(_normalizePart));
  }

  static Object _normalizePart(Object part) {
    return switch (part) {
      final Blob blob => blob._inner,
      final block.Block blockPart => blockPart,
      final ByteBuffer buffer => ByteData.sublistView(buffer.asUint8List()),
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

  static String _normalizeType(String input) {
    final normalized = input.trim().toLowerCase();
    if (normalized.isEmpty) {
      return '';
    }

    if (normalized.contains('\r') || normalized.contains('\n')) {
      throw ArgumentError.value(input, 'type', 'Invalid blob type');
    }

    return normalized;
  }
}
