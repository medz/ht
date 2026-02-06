import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'blob.dart';
import 'file.dart';

/// Multipart body payload generated from [FormData].
final class MultipartBody {
  MultipartBody._({
    required Stream<Uint8List> Function() streamFactory,
    required this.boundary,
    required this.contentLength,
  }) : _streamFactory = streamFactory;

  final Stream<Uint8List> Function() _streamFactory;
  final String boundary;
  final int contentLength;

  String get contentType => 'multipart/form-data; boundary=$boundary';
  Stream<Uint8List> get stream => _streamFactory();

  Future<Uint8List> bytes() async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in _streamFactory()) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }
}

/// Form-data collection compatible with fetch-style APIs.
class FormData extends IterableBase<MapEntry<String, Object>> {
  final _entries = <MapEntry<String, Object>>[];

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
    final snapshot = List<MapEntry<String, Object>>.unmodifiable(
      _entries.map((entry) => MapEntry(entry.key, entry.value)),
    );

    return MultipartBody._(
      streamFactory: () => _encodeMultipart(snapshot, safeBoundary),
      boundary: safeBoundary,
      contentLength: _calculateMultipartLength(snapshot, safeBoundary),
    );
  }

  MultipartBody encodeMultipartStream({String? boundary}) {
    return encodeMultipart(boundary: boundary);
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
        <Object>[value],
        filename,
        type: value.type,
        lastModified: value.lastModified,
      );
    }

    if (value is Blob) {
      return File(<Object>[value], filename ?? 'blob', type: value.type);
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

  static Stream<Uint8List> _encodeMultipart(
    List<MapEntry<String, Object>> entries,
    String boundary,
  ) async* {
    for (final entry in entries) {
      yield _utf8('--$boundary\r\n');

      if (entry.value is File) {
        final file = entry.value as File;
        yield _utf8(
          'Content-Disposition: form-data; '
          'name="${_escapeHeaderValue(entry.key)}"; '
          'filename="${_escapeHeaderValue(file.name)}"\r\n',
        );

        final type = file.type.isEmpty ? 'application/octet-stream' : file.type;
        yield _utf8('Content-Type: $type\r\n\r\n');
        yield* file.stream();
        yield _utf8('\r\n');
        continue;
      }

      final value = entry.value as String;
      yield _utf8(
        'Content-Disposition: form-data; '
        'name="${_escapeHeaderValue(entry.key)}"\r\n\r\n',
      );
      yield _utf8(value);
      yield _utf8('\r\n');
    }

    yield _utf8('--$boundary--\r\n');
  }

  static int _calculateMultipartLength(
    List<MapEntry<String, Object>> entries,
    String boundary,
  ) {
    var total = 0;

    for (final entry in entries) {
      total += _utf8Length('--$boundary\r\n');

      if (entry.value is File) {
        final file = entry.value as File;
        total += _utf8Length(
          'Content-Disposition: form-data; '
          'name="${_escapeHeaderValue(entry.key)}"; '
          'filename="${_escapeHeaderValue(file.name)}"\r\n',
        );

        final type = file.type.isEmpty ? 'application/octet-stream' : file.type;
        total += _utf8Length('Content-Type: $type\r\n\r\n');
        total += file.size;
        total += _utf8Length('\r\n');
        continue;
      }

      final value = entry.value as String;
      total += _utf8Length(
        'Content-Disposition: form-data; '
        'name="${_escapeHeaderValue(entry.key)}"\r\n\r\n',
      );
      total += _utf8Length(value);
      total += _utf8Length('\r\n');
    }

    total += _utf8Length('--$boundary--\r\n');
    return total;
  }

  static int _utf8Length(String value) => utf8.encode(value).length;

  static Uint8List _utf8(String value) =>
      Uint8List.fromList(utf8.encode(value));
}
