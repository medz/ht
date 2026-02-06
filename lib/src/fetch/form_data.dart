import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'blob.dart';
import 'file.dart';

/// Multipart body payload generated from [FormData].
final class MultipartBody {
  MultipartBody(this.bytes, this.boundary);

  final Uint8List bytes;
  final String boundary;

  String get contentType => 'multipart/form-data; boundary=$boundary';
  int get contentLength => bytes.length;
}

/// Form-data collection compatible with fetch-style APIs.
class FormData extends IterableBase<MapEntry<String, Object>> {
  final List<MapEntry<String, Object>> _entries = <MapEntry<String, Object>>[];

  void append(String name, Object value, {String? filename}) {
    _entries.add(MapEntry(name, _normalizeValue(value, filename: filename)));
  }

  void set(String name, Object value, {String? filename}) {
    delete(name);
    append(name, value, filename: filename);
  }

  void delete(String name) {
    _entries.removeWhere((entry) => entry.key == name);
  }

  Object? get(String name) {
    for (final entry in _entries) {
      if (entry.key == name) {
        return entry.value;
      }
    }

    return null;
  }

  List<Object> getAll(String name) {
    return List<Object>.unmodifiable(
      _entries.where((entry) => entry.key == name).map((entry) => entry.value),
    );
  }

  bool has(String name) => _entries.any((entry) => entry.key == name);

  FormData clone() {
    final next = FormData();
    for (final entry in _entries) {
      next.append(entry.key, entry.value);
    }
    return next;
  }

  MultipartBody encodeMultipart({String? boundary}) {
    final safeBoundary = boundary ?? _generateBoundary();
    final builder = BytesBuilder(copy: false);

    for (final entry in _entries) {
      builder.add(_utf8('--$safeBoundary\r\n'));

      if (entry.value is File) {
        final file = entry.value as File;
        builder.add(
          _utf8(
            'Content-Disposition: form-data; '
            'name="${_escapeHeaderValue(entry.key)}"; '
            'filename="${_escapeHeaderValue(file.name)}"\r\n',
          ),
        );

        final type = file.type.isEmpty ? 'application/octet-stream' : file.type;
        builder.add(_utf8('Content-Type: $type\r\n\r\n'));
        builder.add(file.copyBytes());
        builder.add(_utf8('\r\n'));
        continue;
      }

      final value = entry.value as String;
      builder.add(
        _utf8(
          'Content-Disposition: form-data; '
          'name="${_escapeHeaderValue(entry.key)}"\r\n\r\n',
        ),
      );
      builder.add(_utf8(value));
      builder.add(_utf8('\r\n'));
    }

    builder.add(_utf8('--$safeBoundary--\r\n'));

    return MultipartBody(builder.takeBytes(), safeBoundary);
  }

  @override
  Iterator<MapEntry<String, Object>> get iterator =>
      List<MapEntry<String, Object>>.unmodifiable(_entries).iterator;

  static Object _normalizeValue(Object value, {String? filename}) {
    if (value is File) {
      if (filename == null) {
        return value;
      }

      return File(
        <Object>[value.copyBytes()],
        filename,
        type: value.type,
        lastModified: value.lastModified,
      );
    }

    if (value is Blob) {
      return File(
        <Object>[value.copyBytes()],
        filename ?? 'blob',
        type: value.type,
      );
    }

    if (value is String) {
      return value;
    }

    return value.toString();
  }

  static String _escapeHeaderValue(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\r', '\\r')
        .replaceAll('\n', '\\n');
  }

  static String _generateBoundary() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure();
    final suffix = List<String>.generate(
      24,
      (_) => alphabet[random.nextInt(alphabet.length)],
      growable: false,
    ).join();
    return '----ht-$suffix';
  }

  static Uint8List _utf8(String value) =>
      Uint8List.fromList(utf8.encode(value));
}
