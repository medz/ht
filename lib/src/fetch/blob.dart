import 'dart:convert';
import 'dart:typed_data';

/// Binary large object.
class Blob {
  Blob([Iterable<Object> parts = const <Object>[], String type = ''])
    : _bytes = _concatenate(parts),
      type = _normalizeType(type);

  Blob.bytes(List<int> bytes, {String type = ''})
    : _bytes = Uint8List.fromList(bytes),
      type = _normalizeType(type);

  Blob.text(
    String text, {
    String type = 'text/plain;charset=utf-8',
    Encoding encoding = utf8,
  }) : _bytes = Uint8List.fromList(encoding.encode(text)),
       type = _normalizeType(type);

  final Uint8List _bytes;

  /// MIME type hint.
  final String type;

  int get size => _bytes.length;

  /// Returns a copy of underlying bytes.
  Future<Uint8List> bytes() async => copyBytes();

  /// Synchronous copy helper for internal body assembly.
  Uint8List copyBytes() => Uint8List.fromList(_bytes);

  Future<String> text([Encoding encoding = utf8]) async {
    return encoding.decode(_bytes);
  }

  Stream<Uint8List> stream({int chunkSize = 16 * 1024}) async* {
    if (chunkSize <= 0) {
      throw ArgumentError.value(chunkSize, 'chunkSize', 'Must be > 0');
    }

    var offset = 0;
    while (offset < _bytes.length) {
      final nextOffset = (offset + chunkSize).clamp(0, _bytes.length);
      yield Uint8List.sublistView(_bytes, offset, nextOffset);
      offset = nextOffset;
    }
  }

  Blob slice([int start = 0, int? end, String contentType = '']) {
    final safeStart = start.clamp(0, _bytes.length);
    final safeEnd = (end ?? _bytes.length).clamp(safeStart, _bytes.length);
    return Blob.bytes(
      Uint8List.sublistView(_bytes, safeStart, safeEnd),
      type: contentType,
    );
  }

  static Uint8List _concatenate(Iterable<Object> parts) {
    final builder = BytesBuilder(copy: false);

    for (final part in parts) {
      if (part is Blob) {
        builder.add(part._bytes);
        continue;
      }

      if (part is ByteBuffer) {
        builder.add(part.asUint8List());
        continue;
      }

      if (part is Uint8List) {
        builder.add(part);
        continue;
      }

      if (part is List<int>) {
        builder.add(part);
        continue;
      }

      if (part is String) {
        builder.add(utf8.encode(part));
        continue;
      }

      throw ArgumentError.value(
        part,
        'parts',
        'Unsupported blob part type: ${part.runtimeType}',
      );
    }

    return builder.takeBytes();
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
