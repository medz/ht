import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:block/block.dart' as block;
import 'package:http_parser/http_parser.dart' as http_parser;

import 'blob.dart';
import 'body.dart';
import 'file.dart';
import 'headers.dart';
import 'url_search_params.dart';

sealed class Multipart {
  const Multipart();

  const factory Multipart.text(String value) = TextMultipart;
  factory Multipart.blob(Blob value, [String? filename]) =>
      BlobMultipart(value, filename);
}

final class TextMultipart extends Multipart {
  const TextMultipart(this.value);

  final String value;
}

final class BlobMultipart extends File implements Multipart {
  BlobMultipart(Blob value, [String? filename])
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
        lastModified: switch (value) {
          final File file => file.lastModified,
          _ => null,
        },
      );

  final String filename;
}

final class EncodedFormData {
  EncodedFormData._({
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

  void applyTo(Headers headers) {
    headers
      ..set('content-type', contentType)
      ..set('content-length', contentLength.toString());
  }
}

class FormData with Iterable<MapEntry<String, Multipart>> {
  static const _crlf = <int>[0x0d, 0x0a];
  static const _dashDash = <int>[0x2d, 0x2d];
  static final _boundaryRandom = Random();
  static var _boundaryCounter = 0;

  static Future<FormData> parse(Body body, {String? contentType}) async {
    final mediaType = _parseContentType(contentType);
    return switch (mediaType?.mimeType ?? '') {
      'application/x-www-form-urlencoded' => _parseUrlEncoded(body),
      'multipart/form-data' => _parseMultipart(body, mediaType: mediaType!),
      '' => throw UnsupportedError('Unsupported form content type: (missing)'),
      _ => throw UnsupportedError(
        'Unsupported form content type: ${contentType ?? '(missing)'}',
      ),
    };
  }

  final _entries = <MapEntry<String, Multipart>>[];

  @override
  Iterator<MapEntry<String, Multipart>> get iterator => _entries.iterator;

  Iterable<MapEntry<String, Multipart>> entries() => this;

  Iterable<String> keys() sync* {
    for (final MapEntry(:key) in _entries) {
      yield key;
    }
  }

  Iterable<Multipart> values() sync* {
    for (final MapEntry(:value) in _entries) {
      yield value;
    }
  }

  Multipart? get(String name) {
    for (final entry in _entries) {
      if (entry.key == name) {
        return entry.value;
      }
    }

    return null;
  }

  List<Multipart> getAll(String name) {
    return List<Multipart>.unmodifiable(
      _entries.where((entry) => entry.key == name).map((entry) => entry.value),
    );
  }

  bool has(String name) => _entries.any((entry) => entry.key == name);

  void append(String name, Multipart value) {
    _entries.add(MapEntry<String, Multipart>(name, value));
  }

  void delete(String name) {
    _entries.removeWhere((entry) => entry.key == name);
  }

  void set(String name, Multipart value) {
    final firstIndex = _entries.indexWhere((entry) => entry.key == name);
    if (firstIndex == -1) {
      append(name, value);
      return;
    }

    _entries[firstIndex] = MapEntry<String, Multipart>(name, value);
    for (var index = _entries.length - 1; index > firstIndex; index--) {
      if (_entries[index].key == name) {
        _entries.removeAt(index);
      }
    }
  }

  EncodedFormData encodeMultipart({String? boundary}) {
    final safeBoundary = boundary ?? _generateBoundary();
    final snapshot = _entries
        .map((entry) => MapEntry<String, Multipart>(entry.key, entry.value))
        .toList(growable: false);

    return EncodedFormData._(
      streamFactory: () => _encodeMultipart(snapshot, safeBoundary),
      boundary: safeBoundary,
      contentLength: _calculateMultipartLength(snapshot, safeBoundary),
    );
  }

  static Future<FormData> _parseUrlEncoded(Body body) async {
    final params = URLSearchParams(await body.text());
    final formData = FormData();
    for (final MapEntry(:key, :value) in params.entries()) {
      formData.append(key, Multipart.text(value));
    }
    return formData;
  }

  static Future<FormData> _parseMultipart(
    Body body, {
    required http_parser.MediaType mediaType,
  }) async {
    final boundary = _boundaryFromContentType(mediaType);
    if (boundary == null || boundary.isEmpty) {
      throw const FormatException(
        'Missing multipart boundary in content-type.',
      );
    }

    return _MultipartStreamParser(body, boundary).parse();
  }

  static http_parser.MediaType? _parseContentType(String? contentType) {
    if (contentType == null) return null;
    _parseParameterizedHeaderValue(contentType, 'content-type');
    return http_parser.MediaType.parse(contentType);
  }

  static String? _boundaryFromContentType(http_parser.MediaType mediaType) {
    return mediaType.parameters['boundary'];
  }

  static Map<String, String> _parsePartHeaders(Uint8List bytes) {
    final text = _decodeHeaderBytes(bytes);
    final headers = <String, String>{};
    if (text.isEmpty) return headers;

    for (final line in text.split('\r\n')) {
      final separator = line.indexOf(':');
      if (separator <= 0) {
        throw FormatException('Invalid multipart part header: $line');
      }

      final name = line.substring(0, separator).trim().toLowerCase();
      if (!_isHttpToken(name)) {
        throw FormatException('Invalid multipart part header name: $name');
      }
      if (headers.containsKey(name)) {
        throw FormatException('Duplicate multipart part header: $name');
      }

      final value = line.substring(separator + 1).trim();
      headers[name] = value;
    }

    return headers;
  }

  static _ContentDisposition _contentDispositionFromPartHeaders(
    Map<String, String> headers,
  ) {
    final disposition = headers['content-disposition'];
    if (disposition == null) {
      throw const FormatException(
        'Multipart part is missing content-disposition.',
      );
    }

    final parsed = _parseParameterizedHeaderValue(
      disposition,
      'content-disposition',
    );
    if (parsed.value.toLowerCase() != 'form-data') {
      throw const FormatException(
        'Multipart part content-disposition must be form-data.',
      );
    }

    final parameters = parsed.parameters;
    final name = parameters['name'];
    if (name == null || name.isEmpty) {
      throw const FormatException(
        'Multipart part is missing content-disposition name.',
      );
    }

    return _ContentDisposition(name, _filenameFromDisposition(parameters));
  }

  static Multipart _partBodyFromHeaders(
    Map<String, String> headers,
    _ContentDisposition disposition,
    List<Uint8List> chunks,
  ) {
    final contentType = _partContentType(headers);
    final filename = disposition.filename;
    if (filename != null) {
      final type = contentType?.raw ?? '';
      return Multipart.blob(
        Blob(<BlobPart>[block.Block(chunks, type: type)], type),
        filename,
      );
    }

    final builder = BytesBuilder(copy: false);
    for (final chunk in chunks) {
      builder.add(chunk);
    }

    return Multipart.text(
      _decodeTextPart(builder.takeBytes(), contentType?.mediaType),
    );
  }

  static _PartContentType? _partContentType(Map<String, String> headers) {
    final raw = headers['content-type'];
    if (raw == null || raw.isEmpty) return null;

    _parseParameterizedHeaderValue(raw, 'part content-type');
    return _PartContentType(raw, http_parser.MediaType.parse(raw));
  }

  static String? _filenameFromDisposition(Map<String, String> parameters) {
    final filenameStar = parameters['filename*'];
    if (filenameStar != null) {
      // RFC 7578 tells senders not to use filename*, but deployed clients do.
      // Accept it for interop and prefer it over the plain fallback filename.
      return _decodeExtendedParameterValue(filenameStar, 'filename*');
    }

    return parameters['filename'];
  }

  static String _decodeTextPart(
    Uint8List bytes,
    http_parser.MediaType? mediaType,
  ) {
    final charset = mediaType?.parameters['charset'];
    return _encodingForCharset(charset).decode(bytes);
  }

  static Encoding _encodingForCharset(String? charset) {
    if (charset == null || charset.isEmpty) return utf8;

    final normalized = charset.toLowerCase();
    return switch (normalized) {
      'utf-8' || 'utf8' => utf8,
      'iso-8859-1' || 'latin1' || 'latin-1' => latin1,
      'us-ascii' || 'ascii' => ascii,
      _ =>
        Encoding.getByName(normalized) ??
            (throw FormatException('Unsupported multipart charset: $charset')),
    };
  }

  static _ParsedHeaderValue _parseParameterizedHeaderValue(
    String value,
    String context,
  ) {
    final segments = _splitHeaderParameters(value, context);
    final primaryValue = segments.first.trim();
    if (primaryValue.isEmpty) {
      throw FormatException('Invalid $context header value.');
    }

    final parameters = <String, String>{};
    for (final segment in segments.skip(1)) {
      final separator = segment.indexOf('=');
      if (separator == -1) {
        throw FormatException('Invalid $context parameter: $segment');
      }

      final name = segment.substring(0, separator).trim().toLowerCase();
      if (!_isHttpToken(name)) {
        throw FormatException('Invalid $context parameter name: $name');
      }
      if (parameters.containsKey(name)) {
        throw FormatException('Duplicate $context parameter: $name');
      }

      final parameterValue = segment.substring(separator + 1).trim();
      parameters[name] = _parseHeaderParameterValue(parameterValue, context);
    }

    return _ParsedHeaderValue(primaryValue, parameters);
  }

  static List<String> _splitHeaderParameters(String value, String context) {
    final segments = <String>[];
    final buffer = StringBuffer();
    var quoted = false;
    var escaped = false;

    for (final rune in value.runes) {
      final char = String.fromCharCode(rune);

      if (escaped) {
        buffer.write(char);
        escaped = false;
        continue;
      }

      if (quoted && char == r'\') {
        buffer.write(char);
        escaped = true;
        continue;
      }

      if (char == '"') {
        buffer.write(char);
        quoted = !quoted;
        continue;
      }

      if (char == ';' && !quoted) {
        segments.add(buffer.toString());
        buffer.clear();
        continue;
      }

      buffer.write(char);
    }

    segments.add(buffer.toString());
    if (quoted || escaped) {
      throw FormatException('Invalid quoted $context parameter.');
    }
    return segments;
  }

  static String _parseHeaderParameterValue(String value, String context) {
    if (value.isEmpty) {
      throw FormatException('Invalid empty $context parameter value.');
    }

    if (value.startsWith('"')) {
      return _parseQuotedHeaderValue(value, context);
    }

    if (!_isHttpToken(value)) {
      throw FormatException('Invalid $context parameter value: $value');
    }
    return value;
  }

  static String _parseQuotedHeaderValue(String value, String context) {
    if (value.length < 2 || !value.endsWith('"')) {
      throw FormatException('Invalid quoted $context parameter.');
    }

    final buffer = StringBuffer();
    for (var index = 1; index < value.length - 1; index++) {
      final code = value.codeUnitAt(index);
      if (code == 0x5c) {
        index++;
        if (index >= value.length - 1) {
          throw FormatException('Invalid quoted $context parameter.');
        }
        final escaped = value.codeUnitAt(index);
        if (escaped == 0x22 || escaped == 0x5c) {
          buffer.writeCharCode(escaped);
        } else {
          buffer
            ..writeCharCode(code)
            ..writeCharCode(escaped);
        }
        continue;
      }

      if (code == 0x22 || code < 0x20 || code == 0x7f) {
        throw FormatException('Invalid quoted $context parameter.');
      }
      buffer.writeCharCode(code);
    }

    return buffer.toString();
  }

  static String _decodeExtendedParameterValue(String value, String context) {
    final firstQuote = value.indexOf("'");
    final secondQuote = firstQuote == -1
        ? -1
        : value.indexOf("'", firstQuote + 1);
    if (firstQuote <= 0 || secondQuote == -1) {
      throw FormatException('Invalid extended $context parameter.');
    }

    final charset = value.substring(0, firstQuote);
    final encodedValue = value.substring(secondQuote + 1);
    final bytes = <int>[];

    for (var index = 0; index < encodedValue.length; index++) {
      final code = encodedValue.codeUnitAt(index);
      if (code == 0x25) {
        if (index + 2 >= encodedValue.length) {
          throw FormatException('Invalid percent-encoded $context parameter.');
        }

        final byte = _hexByte(
          encodedValue.codeUnitAt(index + 1),
          encodedValue.codeUnitAt(index + 2),
        );
        if (byte == null) {
          throw FormatException('Invalid percent-encoded $context parameter.');
        }

        bytes.add(byte);
        index += 2;
        continue;
      }

      if (code > 0x7f) {
        throw FormatException('Invalid extended $context parameter.');
      }
      bytes.add(code);
    }

    return _encodingForCharset(charset).decode(bytes);
  }

  static int? _hexByte(int high, int low) {
    final highValue = _hexValue(high);
    final lowValue = _hexValue(low);
    if (highValue == null || lowValue == null) return null;
    return highValue * 16 + lowValue;
  }

  static int? _hexValue(int code) {
    if (code >= 0x30 && code <= 0x39) return code - 0x30;
    if (code >= 0x41 && code <= 0x46) return code - 0x41 + 10;
    if (code >= 0x61 && code <= 0x66) return code - 0x61 + 10;
    return null;
  }

  static String _decodeHeaderBytes(Uint8List bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }

  static bool _isHttpToken(String value) {
    if (value.isEmpty) return false;
    for (var index = 0; index < value.length; index++) {
      if (!_isHttpTokenCodeUnit(value.codeUnitAt(index))) {
        return false;
      }
    }
    return true;
  }

  static bool _isHttpTokenCodeUnit(int code) {
    if (code <= 0x20 || code >= 0x7f) return false;
    return switch (code) {
      0x28 || // (
      0x29 || // )
      0x3c || // <
      0x3e || // >
      0x40 || // @
      0x2c || // ,
      0x3b || // ;
      0x3a || // :
      0x22 || // "
      0x5c || // \
      0x2f || // /
      0x5b || // [
      0x5d || // ]
      0x3f || // ?
      0x3d || // =
      0x7b || // {
      0x7d => // }
      false,
      _ => true,
    };
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

  static String _escapeHeaderValue(String value) {
    return value
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\r', '\\r')
        .replaceAll('\n', '\\n');
  }

  static String _generateBoundary() {
    const alphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final suffix = StringBuffer()
      ..write(DateTime.now().microsecondsSinceEpoch.toRadixString(36))
      ..write((_boundaryCounter++).toRadixString(36));

    for (var index = 0; index < 16; index++) {
      suffix.write(alphabet[_boundaryRandom.nextInt(alphabet.length)]);
    }

    return '----ht-$suffix';
  }

  static Stream<Uint8List> _encodeMultipart(
    List<MapEntry<String, Multipart>> entries,
    String boundary,
  ) async* {
    for (final entry in entries) {
      yield _utf8('--$boundary\r\n');

      switch (entry.value) {
        case final BlobMultipart blob:
          yield _utf8(
            'Content-Disposition: form-data; '
            'name="${_escapeHeaderValue(entry.key)}"; '
            'filename="${_escapeHeaderValue(blob.filename)}"\r\n',
          );

          final type = blob.type.isEmpty
              ? 'application/octet-stream'
              : blob.type;
          yield _utf8('Content-Type: $type\r\n\r\n');
          yield* blob.stream();
          yield _utf8('\r\n');
        case final TextMultipart text:
          yield _utf8(
            'Content-Disposition: form-data; '
            'name="${_escapeHeaderValue(entry.key)}"\r\n\r\n',
          );
          yield _utf8(text.value);
          yield _utf8('\r\n');
      }
    }

    yield _utf8('--$boundary--\r\n');
  }

  static int _calculateMultipartLength(
    List<MapEntry<String, Multipart>> entries,
    String boundary,
  ) {
    var total = 0;

    for (final entry in entries) {
      total += _utf8Length('--$boundary\r\n');

      switch (entry.value) {
        case final BlobMultipart blob:
          total += _utf8Length(
            'Content-Disposition: form-data; '
            'name="${_escapeHeaderValue(entry.key)}"; '
            'filename="${_escapeHeaderValue(blob.filename)}"\r\n',
          );

          final type = blob.type.isEmpty
              ? 'application/octet-stream'
              : blob.type;
          total += _utf8Length('Content-Type: $type\r\n\r\n');
          total += blob.size;
          total += _utf8Length('\r\n');
        case final TextMultipart text:
          total += _utf8Length(
            'Content-Disposition: form-data; '
            'name="${_escapeHeaderValue(entry.key)}"\r\n\r\n',
          );
          total += _utf8Length(text.value);
          total += _utf8Length('\r\n');
      }
    }

    total += _utf8Length('--$boundary--\r\n');
    return total;
  }

  static int _utf8Length(String value) => utf8.encode(value).length;

  static Uint8List _utf8(String value) =>
      Uint8List.fromList(utf8.encode(value));
}

enum _MultipartParseState { firstBoundary, headers, content, closed }

enum _BoundaryLineEnd { valid, needMore, invalid }

final class _MultipartStreamParser {
  _MultipartStreamParser(this._body, String boundary)
    : _boundaryMarker = utf8.encode('--$boundary'),
      _prefixedBoundaryMarker = <int>[
        ...FormData._crlf,
        ...utf8.encode('--$boundary'),
      ],
      _headerSeparator = utf8.encode('\r\n\r\n');

  final Body _body;
  final List<int> _boundaryMarker;
  final List<int> _prefixedBoundaryMarker;
  final List<int> _headerSeparator;
  final _buffer = <int>[];
  final _formData = FormData();

  var _state = _MultipartParseState.firstBoundary;
  Map<String, String>? _partHeaders;
  _ContentDisposition? _partDisposition;
  List<Uint8List>? _partChunks;
  var _streamDone = false;

  Future<FormData> parse() async {
    await for (final chunk in _body) {
      if (_state == _MultipartParseState.closed) {
        continue;
      }

      _append(chunk);
      _drain();
    }

    _streamDone = true;
    _finish();
    return _formData;
  }

  void _append(Uint8List chunk) {
    if (chunk.isEmpty) return;
    _buffer.addAll(chunk);
  }

  void _drain() {
    var advanced = true;
    while (advanced && _state != _MultipartParseState.closed) {
      advanced = _advance();
    }

    if (_state == _MultipartParseState.closed) {
      _buffer.clear();
    }
  }

  bool _advance() {
    return switch (_state) {
      _MultipartParseState.firstBoundary => _advanceFirstBoundary(),
      _MultipartParseState.headers => _advanceHeaders(),
      _MultipartParseState.content => _advanceContent(),
      _MultipartParseState.closed => false,
    };
  }

  bool _advanceFirstBoundary() {
    final match = _findFirstBoundary();
    if (match == null) return false;

    _consumeBoundary(match);
    return true;
  }

  bool _advanceHeaders() {
    final headerEnd = FormData._indexOf(_buffer, _headerSeparator);
    if (headerEnd == -1) return false;

    final headers = FormData._parsePartHeaders(
      Uint8List.fromList(_buffer.sublist(0, headerEnd)),
    );

    _partHeaders = headers;
    _partDisposition = FormData._contentDispositionFromPartHeaders(headers);
    _partChunks = <Uint8List>[];
    _consume(headerEnd + _headerSeparator.length);
    _state = _MultipartParseState.content;
    return true;
  }

  bool _advanceContent() {
    // Only a line that is followed by CRLF or "--" is a real delimiter.
    // Boundary-like bytes inside file payloads must remain part of the body.
    final match = _findNextBoundary();
    if (match == null) {
      _flushSafeContentPrefix();
      return false;
    }

    _addContentChunk(0, match.lineStart);
    final headers = _partHeaders!;
    final disposition = _partDisposition!;
    _formData.append(
      disposition.name,
      FormData._partBodyFromHeaders(headers, disposition, _partChunks!),
    );

    _partHeaders = null;
    _partDisposition = null;
    _partChunks = null;
    _consumeBoundary(match);
    return true;
  }

  void _finish() {
    _drain();
    switch (_state) {
      case _MultipartParseState.closed:
        return;
      case _MultipartParseState.firstBoundary:
        throw const FormatException(
          'Multipart body does not contain boundary.',
        );
      case _MultipartParseState.headers:
        throw const FormatException('Invalid multipart part headers.');
      case _MultipartParseState.content:
        throw const FormatException(
          'Multipart part is missing a closing boundary.',
        );
    }
  }

  _BoundaryMatch? _findFirstBoundary() {
    if (_buffer.isEmpty) return null;

    if (_couldMatchAt(0, _boundaryMarker)) {
      final probe = _probeBoundaryAt(0, 0);
      if (probe.needMore) return null;
      if (probe.match case final match?) return match;
      throw const FormatException('Invalid multipart boundary separator.');
    }

    final match = _findNextBoundary();
    if (match != null) return match;
    _discardSafePreamblePrefix();
    return null;
  }

  _BoundaryMatch? _findNextBoundary() {
    var offset = 0;

    while (offset != -1) {
      final lineStart = FormData._indexOf(
        _buffer,
        _prefixedBoundaryMarker,
        offset,
      );
      if (lineStart == -1) return null;

      final probe = _probeBoundaryAt(
        lineStart,
        lineStart + FormData._crlf.length,
      );
      if (probe.needMore) return null;
      if (probe.match case final match?) return match;

      offset = lineStart + 1;
    }

    return null;
  }

  _BoundaryProbe _probeBoundaryAt(int lineStart, int markerStart) {
    final markerAvailable = _buffer.length - markerStart;
    if (markerAvailable < _boundaryMarker.length) {
      return const _BoundaryProbe.needMore();
    }

    if (!FormData._matches(_buffer, markerStart, _boundaryMarker)) {
      return const _BoundaryProbe.invalid();
    }

    final afterMarker = markerStart + _boundaryMarker.length;
    if (_buffer.length - afterMarker < 2) {
      return const _BoundaryProbe.needMore();
    }

    if (FormData._matches(_buffer, afterMarker, FormData._dashDash)) {
      final closingEnd = afterMarker + FormData._dashDash.length;
      switch (_probeBoundaryLineEnd(closingEnd)) {
        case _BoundaryLineEnd.needMore:
          return const _BoundaryProbe.needMore();
        case _BoundaryLineEnd.invalid:
          return const _BoundaryProbe.invalid();
        case _BoundaryLineEnd.valid:
          break;
      }

      return _BoundaryProbe.match(
        _BoundaryMatch(
          lineStart: lineStart,
          afterMarker: closingEnd,
          closing: true,
        ),
      );
    }

    if (FormData._matches(_buffer, afterMarker, FormData._crlf)) {
      return _BoundaryProbe.match(
        _BoundaryMatch(
          lineStart: lineStart,
          afterMarker: afterMarker,
          closing: false,
        ),
      );
    }

    return const _BoundaryProbe.invalid();
  }

  _BoundaryLineEnd _probeBoundaryLineEnd(int offset) {
    final available = _buffer.length - offset;
    if (available == 0) {
      return _streamDone ? _BoundaryLineEnd.valid : _BoundaryLineEnd.needMore;
    }

    if (available == 1) {
      if (_buffer[offset] == FormData._crlf.first && !_streamDone) {
        return _BoundaryLineEnd.needMore;
      }
      return _BoundaryLineEnd.invalid;
    }

    if (FormData._matches(_buffer, offset, FormData._crlf)) {
      return _BoundaryLineEnd.valid;
    }

    return _BoundaryLineEnd.invalid;
  }

  bool _couldMatchAt(int start, List<int> needle) {
    final available = _buffer.length - start;
    if (available <= 0) return false;

    final length = available < needle.length ? available : needle.length;
    for (var index = 0; index < length; index++) {
      if (_buffer[start + index] != needle[index]) {
        return false;
      }
    }
    return true;
  }

  void _consumeBoundary(_BoundaryMatch match) {
    final count = match.closing
        ? match.afterMarker
        : match.afterMarker + FormData._crlf.length;
    _consume(count);
    _state = match.closing
        ? _MultipartParseState.closed
        : _MultipartParseState.headers;
  }

  void _flushSafeContentPrefix() {
    final retain = _prefixedBoundaryMarker.length + FormData._dashDash.length;
    if (_buffer.length <= retain) return;

    final end = _buffer.length - retain;
    _addContentChunk(0, end);
    _consume(end);
  }

  void _discardSafePreamblePrefix() {
    final retain = _prefixedBoundaryMarker.length + FormData._dashDash.length;
    if (_buffer.length <= retain) return;
    _consume(_buffer.length - retain);
  }

  void _addContentChunk(int start, int end) {
    if (end <= start) return;
    _partChunks!.add(Uint8List.fromList(_buffer.sublist(start, end)));
  }

  void _consume(int count) {
    if (count <= 0) return;
    _buffer.removeRange(0, count);
  }
}

final class _BoundaryProbe {
  const _BoundaryProbe.match(this.match) : needMore = false;
  const _BoundaryProbe.needMore() : match = null, needMore = true;
  const _BoundaryProbe.invalid() : match = null, needMore = false;

  final _BoundaryMatch? match;
  final bool needMore;
}

final class _BoundaryMatch {
  const _BoundaryMatch({
    required this.lineStart,
    required this.afterMarker,
    required this.closing,
  });

  final int lineStart;
  final int afterMarker;
  final bool closing;
}

final class _ContentDisposition {
  const _ContentDisposition(this.name, this.filename);

  final String name;
  final String? filename;
}

final class _ParsedHeaderValue {
  const _ParsedHeaderValue(this.value, this.parameters);

  final String value;
  final Map<String, String> parameters;
}

final class _PartContentType {
  const _PartContentType(this.raw, this.mediaType);

  final String raw;
  final http_parser.MediaType mediaType;
}
