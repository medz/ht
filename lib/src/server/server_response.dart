import '../core/http_status.dart';
import '../core/http_version.dart';
import '../fetch/body.dart';
import '../fetch/headers.dart';
import '../fetch/response.dart';

/// Server-side response abstraction.
class ServerResponse with BodyMixin {
  ServerResponse({
    Object? body,
    int status = HttpStatus.ok,
    String? statusText,
    Headers? headers,
    Uri? url,
    bool redirected = false,
    this.version = HttpVersion.http11,
    this.closeConnection = false,
    Map<String, Object?>? attributes,
  })  : response = Response(
          body: body,
          status: status,
          statusText: statusText,
          headers: headers,
          url: url,
          redirected: redirected,
        ),
        attributes = Map<String, Object?>.from(attributes ?? const {});

  ServerResponse.fromResponse(
    this.response, {
    this.version = HttpVersion.http11,
    this.closeConnection = false,
    Map<String, Object?>? attributes,
  }) : attributes = Map<String, Object?>.from(attributes ?? const {});

  final Response response;
  final HttpVersion version;
  final bool closeConnection;
  final Map<String, Object?> attributes;

  int get status => response.status;

  String get statusText => response.statusText;

  Headers get headers => response.headers;

  Uri? get url => response.url;

  bool get redirected => response.redirected;

  bool get ok => response.ok;

  Object? operator [](String key) => attributes[key];

  void operator []=(String key, Object? value) {
    attributes[key] = value;
  }

  @override
  BodyData get bodyData => response.bodyData;

  @override
  String? get bodyMimeTypeHint => response.headers.get('content-type');

  ServerResponse clone() {
    return ServerResponse.fromResponse(
      response.clone(),
      version: version,
      closeConnection: closeConnection,
      attributes: attributes,
    );
  }
}
