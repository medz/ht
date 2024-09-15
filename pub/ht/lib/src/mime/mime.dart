import 'package:mime/mime.dart' as mime;
import 'package:http_parser/http_parser.dart' as http_parser;

final class _ExtensionMediaType extends http_parser.MediaType {
  _ExtensionMediaType(super.type, super.subtype, [super.parameters]) : super();

  factory _ExtensionMediaType.parse(String str) {
    final http_parser.MediaType(:type, :subtype, :parameters) =
        http_parser.MediaType.parse(str);
    return _ExtensionMediaType(type, subtype, parameters);
  }

  @override
  int get hashCode => Object.hashAll(
      [MIME, type, subtype, ...parameters.keys, ...parameters.values]);

  @override
  bool operator ==(Object other) {
    return other is _ExtensionMediaType && other.hashCode == hashCode;
  }
}

/// MIME create fail exception.
class MimeCreateFailException implements Exception {
  const MimeCreateFailException._(this.message, [this.upstream]);

  /// Exception message.
  final String message;

  /// Upstream exception.
  final Exception? upstream;
}

/// An HTTP media type.
extension type const MIME._(_ExtensionMediaType _) {
  /// Global MIME resolver.
  static final resolver = mime.MimeTypeResolver();

  ///

  // Creates a new MIME type.
  factory MIME(String base, String sub, [Map<String, String>? params]) {
    return MIME._(_ExtensionMediaType(base, sub, params));
  }

  /// Creates a new [MIME] type from [String].
  factory MIME.fromString(String input) {
    try {
      return MIME._(_ExtensionMediaType.parse(input));
    } on FormatException catch (e) {
      throw MimeCreateFailException._(e.message, e);
    }
  }

  /// Creates a new [MIME] type from [bytes].
  factory MIME.fromBytes(Iterable<int> bytes) {
    final safeBytes =
        bytes.take(resolver.magicNumbersMaxLength).toList(growable: false);
    final type = resolver.lookup('', headerBytes: safeBytes);
    if (type == null) {
      throw MimeCreateFailException._('Could not sniff the MIME-type');
    }

    return MIME.fromString(type);
  }

  /// Creates a new [MIME] type from [extension].
  factory MIME.fromExtension(String extension) {
    final type = resolver.lookup('HT/_internal/test.$extension');
    if (type == null) {
      throw MimeCreateFailException._('Not found MIME-type for "$extension"');
    }

    return MIME.fromString(type);
  }

  /// The primary identifier of the [MIME].
  String get base => _.type;

  /// The secondary identifier of the [MIME].
  String get sub => _.subtype;

  /// Returns the essence [MIME] type string.
  String get essence => _.mimeType;

  /// Returns the [MIME] params.
  Map<String, String> get params => _.parameters;
}
