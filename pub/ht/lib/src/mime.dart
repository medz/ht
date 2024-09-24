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
      [MimeType, type, subtype, ...parameters.keys, ...parameters.values]);

  @override
  bool operator ==(Object other) {
    return other is _ExtensionMediaType && other.hashCode == hashCode;
  }
}

/// MIME-Type create fail exception.
class MimeTypeCreateFailException implements Exception {
  const MimeTypeCreateFailException._(this.message, [this.upstream]);

  /// Exception message.
  final String message;

  /// Upstream exception.
  final Exception? upstream;
}

/// An HTTP media type.
extension type const MimeType._(_ExtensionMediaType _) implements Object {
  /// Global MIME-type resolver.
  static final resolver = mime.MimeTypeResolver();

  // Creates a new [MimeType].
  factory MimeType(String base, String sub, [Map<String, String>? params]) {
    return MimeType._(_ExtensionMediaType(base, sub, params));
  }

  /// Creates a new [MimeType] from [String].
  factory MimeType.parse(String input) {
    try {
      return MimeType._(_ExtensionMediaType.parse(input));
    } on FormatException catch (e) {
      throw MimeTypeCreateFailException._(e.message, e);
    }
  }

  /// Creates a new [MimeType] from [bytes].
  factory MimeType.bytes(Iterable<int> bytes) {
    final safeBytes =
        bytes.take(resolver.magicNumbersMaxLength).toList(growable: false);
    final type = resolver.lookup('', headerBytes: safeBytes);
    if (type == null) {
      throw MimeTypeCreateFailException._('Could not sniff the MIME-type');
    }

    return MimeType.parse(type);
  }

  /// Creates a new [MimeType] from [extension].
  factory MimeType.fromExtension(String extension) {
    final type = resolver.lookup('HT/_internal/test.$extension');
    if (type == null) {
      throw MimeTypeCreateFailException._(
          'Not found MIME-type for "$extension"');
    }

    return MimeType.parse(type);
  }

  // Commons
  static final any = MimeType('*', '*');
  static final javascript = MimeType('text', 'javascript');
  static final css = MimeType('text', 'css');
  static final html = MimeType('text', 'html');
  static final plain = MimeType('text', 'plain');
  static final xml = MimeType('application', 'xml');
  static final rss = MimeType('application', 'rss+xml');
  static final atom = MimeType('application', 'atom+xml');
  static final json = MimeType('application', 'json');
  static final sse = MimeType('text', 'event-stream');
  static final byteStream = MimeType('application', 'octet-stream');
  static final form = MimeType('application', 'x-www-form-urlencoded');
  static final formData = MimeType('multipart', 'form-data');
  static final wasm = MimeType('application', 'wasm');

  // Images
  static final bmp = MimeType('image', 'bmp');
  static final jpeg = MimeType('image', 'jpeg');
  static final png = MimeType('image', 'png');
  static final svg = MimeType('image', 'svg+xml');
  static final webp = MimeType('image', 'webp');
  static final ico = MimeType('image', 'x-icon');

  // Audio
  static final midi = MimeType('audio', 'midi');
  static final mp3 = MimeType('audio', 'mpeg');
  static final ogg = MimeType('audio', 'ogg');
  static final opus = MimeType('audio', 'opus');
  static final m4a = MimeType('audio', 'mp4');

  // ---------------------- Video ----------------------//
  static final mp4 = MimeType('video', 'mp4');
  static final mpeg = MimeType('video', 'mpeg');
  static final webm = MimeType('video', 'webm');
  static final avi = MimeType('video', 'x-msvideo');

  // ---------------------- Fonts ----------------------//
  static final otf = MimeType('font', 'otf');
  static final ttf = MimeType('font', 'ttf');
  static final woff = MimeType('font', 'woff');
  static final woff2 = MimeType('font', 'woff2');

  // ---------------------- Archives ----------------------//
  static final zip = MimeType('application', 'zip');
  static final x7z = MimeType('application', 'x-7z-compressed');
}

/// Extension to provide properties for the [MimeType] class.
extension MimeTypeProperties on MimeType {
  /// Retrieves the primary type of the MIME.
  String get base => _.type;

  /// Retrieves the subtype of the MIME.
  String get sub => _.subtype;

  /// Returns the full MIME type string.
  String get essence => _.mimeType;

  /// Returns the parameters associated with the MIME type.
  Map<String, String> get params => _.parameters;
}
