import 'dart:convert';
import 'dart:typed_data';

import 'package:block/block.dart' as block;

/// Binary large object.
class Blob implements block.Block {
  Blob([Iterable<Object> parts = const <Object>[], String type = ''])
    : this._fromPrepared(_prepareParts(parts), _normalizeType(type));

  Blob.bytes(List<int> bytes, {String type = ''})
    : this._fromInline(Uint8List.fromList(bytes), _normalizeType(type));

  Blob.text(
    String text, {
    String type = 'text/plain;charset=utf-8',
    Encoding encoding = utf8,
  }) : this._fromInline(
         Uint8List.fromList(encoding.encode(text)),
         _normalizeType(type),
       );

  Blob._fromPrepared(
    ({List<Object> parts, Uint8List? inlineBytes}) prepared,
    String normalizedType,
  ) : _blockParts = prepared.parts,
      _inlineBytes = prepared.inlineBytes,
      type = normalizedType;

  Blob._fromInline(Uint8List inlineBytes, String normalizedType)
    : _blockParts = <Object>[inlineBytes],
      _inlineBytes = inlineBytes,
      type = normalizedType;

  Blob._fromBlock(
    block.Block block, {
    required this.type,
    Uint8List? inlineBytes,
  }) : _block = block,
       _blockParts = null,
       _inlineBytes = inlineBytes;

  block.Block? _block;
  final List<Object>? _blockParts;
  final Uint8List? _inlineBytes;

  /// MIME type hint.
  @override
  final String type;

  @override
  int get size => _inlineBytes?.length ?? _toBlock().size;

  /// Returns a copy of underlying bytes.
  Future<Uint8List> bytes() async {
    final inline = _inlineBytes;
    if (inline != null) {
      return Uint8List.fromList(inline);
    }

    return Uint8List.fromList(await _toBlock().arrayBuffer());
  }

  @override
  Future<Uint8List> arrayBuffer() => bytes();

  @override
  Future<String> text([Encoding encoding = utf8]) async {
    final inline = _inlineBytes;
    if (inline != null) {
      return encoding.decode(inline);
    }

    if (identical(encoding, utf8)) {
      return _toBlock().text();
    }

    return encoding.decode(await bytes());
  }

  @override
  Stream<Uint8List> stream({int chunkSize = 16 * 1024}) {
    if (chunkSize <= 0) {
      throw ArgumentError.value(chunkSize, 'chunkSize', 'Must be > 0');
    }

    final inline = _inlineBytes;
    if (inline != null) {
      return _streamInline(inline, chunkSize);
    }

    return _toBlock().stream(chunkSize: chunkSize);
  }

  @override
  Blob slice(int start, [int? end, String? contentType]) {
    final normalizedType = _normalizeType(contentType ?? '');

    final inline = _inlineBytes;
    if (inline != null) {
      final bounds = _normalizeSliceBounds(inline.length, start, end);
      return Blob._fromInline(
        Uint8List.sublistView(inline, bounds.start, bounds.end),
        normalizedType,
      );
    }

    return Blob._fromBlock(
      _toBlock().slice(start, end, normalizedType),
      type: normalizedType,
    );
  }

  block.Block _toBlock() {
    final existing = _block;
    if (existing != null) {
      return existing;
    }

    final created = block.Block(_blockParts ?? const <Object>[], type: type);
    _block = created;
    return created;
  }

  static ({List<Object> parts, Uint8List? inlineBytes}) _prepareParts(
    Iterable<Object> parts,
  ) {
    final normalized = <Object>[];
    final inlineBuilder = BytesBuilder(copy: false);
    var canInline = true;

    for (final part in parts) {
      normalized.add(_normalizePart(part));

      if (!canInline) {
        continue;
      }

      final bytes = _partInlineBytes(part);
      if (bytes == null) {
        canInline = false;
        continue;
      }

      inlineBuilder.add(bytes);
    }

    return (
      parts: List<Object>.unmodifiable(normalized),
      inlineBytes: canInline ? inlineBuilder.takeBytes() : null,
    );
  }

  static Object _normalizePart(Object part) {
    if (part is Blob) {
      return part;
    }

    if (part is block.Block) {
      return part;
    }

    if (part is ByteBuffer) {
      return ByteData.sublistView(part.asUint8List());
    }

    if (part is Uint8List) {
      return part;
    }

    if (part is List<int>) {
      return Uint8List.fromList(part);
    }

    if (part is String) {
      return part;
    }

    throw ArgumentError.value(
      part,
      'parts',
      'Unsupported blob part type: ${part.runtimeType}',
    );
  }

  static Uint8List? _partInlineBytes(Object part) {
    if (part is Blob) {
      return part._inlineBytes;
    }

    if (part is block.Block) {
      return null;
    }

    if (part is ByteBuffer) {
      return part.asUint8List();
    }

    if (part is Uint8List) {
      return part;
    }

    if (part is List<int>) {
      return Uint8List.fromList(part);
    }

    if (part is String) {
      return Uint8List.fromList(utf8.encode(part));
    }

    return null;
  }

  static Stream<Uint8List> _streamInline(
    Uint8List bytes,
    int chunkSize,
  ) async* {
    var offset = 0;
    while (offset < bytes.length) {
      final nextOffset = (offset + chunkSize).clamp(0, bytes.length);
      yield Uint8List.sublistView(bytes, offset, nextOffset);
      offset = nextOffset;
    }
  }

  static ({int start, int end}) _normalizeSliceBounds(
    int size,
    int start,
    int? end,
  ) {
    var normalizedStart = start;
    var normalizedEnd = end ?? size;

    if (normalizedStart < 0) {
      normalizedStart = size + normalizedStart;
    }

    if (normalizedEnd < 0) {
      normalizedEnd = size + normalizedEnd;
    }

    normalizedStart = normalizedStart.clamp(0, size);
    normalizedEnd = normalizedEnd.clamp(0, size);

    if (normalizedEnd < normalizedStart) {
      normalizedEnd = normalizedStart;
    }

    return (start: normalizedStart, end: normalizedEnd);
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
