import 'dart:convert';
import 'dart:typed_data';

import 'blob.dart';
import 'body.dart';
import 'file.dart';
import 'url_search_params.dart';

sealed class MultipartBody {
  const MultipartBody();

  const factory MultipartBody.text(String value) = TextMultipartBody;
  factory MultipartBody.blob(Blob value, [String? filename]) =>
      BlobMultipartBody(value, filename);
}

final class TextMultipartBody extends MultipartBody {
  const TextMultipartBody(this.value);

  final String value;
}

final class BlobMultipartBody extends File implements MultipartBody {
  BlobMultipartBody(Blob value, [String? filename])
    : filename = switch (value) {
        final File file => filename ?? file.name,
        _ => filename ?? 'blob',
      },
      super(
        <BlobPart>[value],
        switch (value) {
          final File file => filename ?? file.name,
          _ => filename ?? 'blob',
        },
        type: value.type,
      );

  final String filename;
}

class FormData with Iterable<MapEntry<String, MultipartBody>> {
  static Future<FormData> parse(Body body, {String? contentType}) async {
    final essence = _contentTypeEssence(contentType);
    return switch (essence) {
      'application/x-www-form-urlencoded' => _parseUrlEncoded(body),
      'multipart/form-data' => _parseMultipart(body, contentType: contentType),
      '' => throw UnsupportedError('Unsupported form content type: (missing)'),
      _ => throw UnsupportedError(
        'Unsupported form content type: ${contentType ?? '(missing)'}',
      ),
    };
  }

  final _entries = <MapEntry<String, MultipartBody>>[];

  @override
  Iterator<MapEntry<String, MultipartBody>> get iterator => _entries.iterator;

  Iterable<MapEntry<String, MultipartBody>> entries() => this;

  Iterable<String> keys() sync* {
    for (final MapEntry(:key) in _entries) {
      yield key;
    }
  }

  Iterable<MultipartBody> values() sync* {
    for (final MapEntry(:value) in _entries) {
      yield value;
    }
  }

  MultipartBody? get(String name) {
    for (final entry in _entries) {
      if (entry.key == name) {
        return entry.value;
      }
    }

    return null;
  }

  List<MultipartBody> getAll(String name) {
    return List<MultipartBody>.unmodifiable(
      _entries.where((entry) => entry.key == name).map((entry) => entry.value),
    );
  }

  bool has(String name) => _entries.any((entry) => entry.key == name);

  void append(String name, MultipartBody value) {
    _entries.add(MapEntry<String, MultipartBody>(name, value));
  }

  void delete(String name) {
    _entries.removeWhere((entry) => entry.key == name);
  }

  void set(String name, MultipartBody value) {
    delete(name);
    append(name, value);
  }

  static Future<FormData> _parseUrlEncoded(Body body) async {
    final params = URLSearchParams(await body.text());
    final formData = FormData();
    for (final MapEntry(:key, :value) in params.entries()) {
      formData.append(key, MultipartBody.text(value));
    }
    return formData;
  }

  static Future<FormData> _parseMultipart(
    Body body, {
    required String? contentType,
  }) async {
    final boundary = _boundaryFromContentType(contentType);
    if (boundary == null || boundary.isEmpty) {
      throw const FormatException(
        'Missing multipart boundary in content-type.',
      );
    }

    final bytes = await body.bytes();
    final boundaryMarker = utf8.encode('--$boundary');
    final boundaryPrefix = utf8.encode('\r\n--$boundary');
    final headerSeparator = utf8.encode('\r\n\r\n');
    final formData = FormData();

    var offset = _indexOf(bytes, boundaryMarker);
    if (offset == -1) {
      throw const FormatException('Multipart body does not contain boundary.');
    }

    while (offset != -1) {
      offset += boundaryMarker.length;

      if (_matches(bytes, offset, utf8.encode('--'))) {
        break;
      }

      if (!_matches(bytes, offset, utf8.encode('\r\n'))) {
        throw const FormatException('Invalid multipart boundary separator.');
      }
      offset += 2;

      final headerEnd = _indexOf(bytes, headerSeparator, offset);
      if (headerEnd == -1) {
        throw const FormatException('Invalid multipart part headers.');
      }

      final headers = _parsePartHeaders(bytes.sublist(offset, headerEnd));
      final contentStart = headerEnd + headerSeparator.length;
      final nextBoundary = _indexOf(bytes, boundaryPrefix, contentStart);
      if (nextBoundary == -1) {
        throw const FormatException(
          'Multipart part is missing a closing boundary.',
        );
      }

      final contentBytes = Uint8List.sublistView(
        bytes,
        contentStart,
        nextBoundary,
      );
      formData.append(
        _fieldNameFromPartHeaders(headers),
        _partBodyFromHeaders(headers, contentBytes),
      );

      offset = nextBoundary + 2;
    }

    return formData;
  }

  static String _contentTypeEssence(String? contentType) {
    if (contentType == null) return '';

    final separator = contentType.indexOf(';');
    final essence = separator == -1
        ? contentType
        : contentType.substring(0, separator);
    return essence.trim().toLowerCase();
  }

  static String? _boundaryFromContentType(String? contentType) {
    if (contentType == null) return null;

    final segments = contentType.split(';');
    for (final rawSegment in segments.skip(1)) {
      final segment = rawSegment.trim();
      if (!segment.toLowerCase().startsWith('boundary=')) {
        continue;
      }

      final value = segment.substring('boundary='.length).trim();
      if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
        return value.substring(1, value.length - 1);
      }
      return value;
    }

    return null;
  }

  static Map<String, String> _parsePartHeaders(Uint8List bytes) {
    final text = latin1.decode(bytes);
    final headers = <String, String>{};

    for (final line in text.split('\r\n')) {
      final separator = line.indexOf(':');
      if (separator <= 0) {
        continue;
      }

      final name = line.substring(0, separator).trim().toLowerCase();
      final value = line.substring(separator + 1).trim();
      headers[name] = value;
    }

    return headers;
  }

  static String _fieldNameFromPartHeaders(Map<String, String> headers) {
    final disposition = headers['content-disposition'];
    if (disposition == null) {
      throw const FormatException(
        'Multipart part is missing content-disposition.',
      );
    }

    final parameters = _parseHeaderParameters(disposition);
    final name = parameters['name'];
    if (name == null || name.isEmpty) {
      throw const FormatException(
        'Multipart part is missing content-disposition name.',
      );
    }

    return name;
  }

  static MultipartBody _partBodyFromHeaders(
    Map<String, String> headers,
    Uint8List bytes,
  ) {
    final disposition = headers['content-disposition'];
    if (disposition == null) {
      throw const FormatException(
        'Multipart part is missing content-disposition.',
      );
    }

    final parameters = _parseHeaderParameters(disposition);
    final filename = parameters['filename'];
    if (filename != null) {
      return MultipartBody.blob(
        Blob(<BlobPart>[bytes], headers['content-type'] ?? ''),
        filename,
      );
    }

    return MultipartBody.text(utf8.decode(bytes));
  }

  static Map<String, String> _parseHeaderParameters(String value) {
    final parameters = <String, String>{};
    for (final segment in value.split(';').skip(1)) {
      final separator = segment.indexOf('=');
      if (separator == -1) {
        continue;
      }

      final name = segment.substring(0, separator).trim().toLowerCase();
      var parameterValue = segment.substring(separator + 1).trim();
      if (parameterValue.length >= 2 &&
          parameterValue.startsWith('"') &&
          parameterValue.endsWith('"')) {
        parameterValue = parameterValue.substring(1, parameterValue.length - 1);
      }

      parameters[name] = _unescapeHeaderValue(parameterValue);
    }

    return parameters;
  }

  static String _unescapeHeaderValue(String value) {
    return value
        .replaceAll(r'\\', '\\')
        .replaceAll(r'\"', '"')
        .replaceAll(r'\r', '\r')
        .replaceAll(r'\n', '\n');
  }

  static int _indexOf(List<int> haystack, List<int> needle, [int start = 0]) {
    if (needle.isEmpty) {
      return start <= haystack.length ? start : -1;
    }

    for (var i = start; i <= haystack.length - needle.length; i++) {
      if (_matches(haystack, i, needle)) {
        return i;
      }
    }

    return -1;
  }

  static bool _matches(List<int> haystack, int start, List<int> needle) {
    if (start < 0 || start + needle.length > haystack.length) {
      return false;
    }

    for (var i = 0; i < needle.length; i++) {
      if (haystack[start + i] != needle[i]) {
        return false;
      }
    }

    return true;
  }
}
