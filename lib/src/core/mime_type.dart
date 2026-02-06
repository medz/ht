import 'dart:collection';

import 'package:http_parser/http_parser.dart' as http_parser;
import 'package:mime/mime.dart' as mime;

/// Thrown when a MIME type cannot be created from input.
final class MimeTypeFormatException implements FormatException {
  MimeTypeFormatException(this.message, [this.source]);

  @override
  final String message;

  @override
  final Object? source;

  @override
  int? get offset => null;

  @override
  String toString() => 'MimeTypeFormatException: $message';
}

/// Immutable MIME type value object.
final class MimeType {
  MimeType(
    String type,
    String subtype, [
    Map<String, String> parameters = const {},
  ])  : type = type.toLowerCase(),
        subtype = subtype.toLowerCase(),
        parameters = UnmodifiableMapView(Map<String, String>.from(parameters));

  factory MimeType.parse(String input) {
    try {
      final parsed = http_parser.MediaType.parse(input);
      return MimeType(parsed.type, parsed.subtype, parsed.parameters);
    } on FormatException catch (error) {
      throw MimeTypeFormatException(error.message, input);
    }
  }

  factory MimeType.fromExtension(String extension) {
    final normalized = extension.startsWith('.') ? extension : '.$extension';
    final found = _resolver.lookup('file$normalized');
    if (found == null) {
      throw MimeTypeFormatException(
          'Unknown file extension: $extension', extension);
    }

    return MimeType.parse(found);
  }

  factory MimeType.fromBytes(List<int> bytes) {
    final found = _resolver.lookup('', headerBytes: bytes);
    if (found == null) {
      throw MimeTypeFormatException('Could not detect MIME type from bytes');
    }

    return MimeType.parse(found);
  }

  static final mime.MimeTypeResolver _resolver = mime.MimeTypeResolver();

  static final MimeType any = MimeType('*', '*');
  static final MimeType text = MimeType('text', 'plain');
  static final MimeType html = MimeType('text', 'html');
  static final MimeType css = MimeType('text', 'css');
  static final MimeType javascript = MimeType('text', 'javascript');
  static final MimeType json = MimeType('application', 'json');
  static final MimeType xml = MimeType('application', 'xml');
  static final MimeType octetStream = MimeType('application', 'octet-stream');
  static final MimeType formUrlEncoded =
      MimeType('application', 'x-www-form-urlencoded');
  static final MimeType formData = MimeType('multipart', 'form-data');

  final String type;
  final String subtype;
  final Map<String, String> parameters;

  String get essence => '$type/$subtype';

  MimeType withParameter(String key, String value) {
    final next = Map<String, String>.from(parameters);
    next[key] = value;
    return MimeType(type, subtype, next);
  }

  @override
  String toString() {
    if (parameters.isEmpty) {
      return essence;
    }

    return http_parser.MediaType(type, subtype, parameters).toString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! MimeType) {
      return false;
    }

    if (type != other.type || subtype != other.subtype) {
      return false;
    }

    if (parameters.length != other.parameters.length) {
      return false;
    }

    for (final entry in parameters.entries) {
      if (other.parameters[entry.key] != entry.value) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode =>
      Object.hash(type, subtype, Object.hashAll(parameters.entries));
}
