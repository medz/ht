import '../core/http_version.dart';
import '../fetch/body.dart';
import '../fetch/headers.dart';
import '../fetch/request.dart';

/// Transport-level connection metadata for server requests.
final class ServerConnectionInfo {
  const ServerConnectionInfo({
    this.remoteAddress,
    this.remotePort,
    this.localAddress,
    this.localPort,
  });

  final String? remoteAddress;
  final int? remotePort;
  final String? localAddress;
  final int? localPort;
}

/// Server-side request abstraction.
class ServerRequest with BodyMixin {
  ServerRequest({
    required Uri url,
    String method = 'GET',
    Headers? headers,
    Object? body,
    this.version = HttpVersion.http11,
    Map<String, String>? pathParameters,
    Map<String, Object?>? attributes,
    this.connectionInfo,
  })  : request = Request(
          url,
          method: method,
          headers: headers,
          body: body,
        ),
        pathParameters = Map<String, String>.from(pathParameters ?? const {}),
        attributes = Map<String, Object?>.from(attributes ?? const {});

  ServerRequest.fromRequest(
    this.request, {
    this.version = HttpVersion.http11,
    Map<String, String>? pathParameters,
    Map<String, Object?>? attributes,
    this.connectionInfo,
  })  : pathParameters = Map<String, String>.from(pathParameters ?? const {}),
        attributes = Map<String, Object?>.from(attributes ?? const {});

  final Request request;
  final HttpVersion version;
  final ServerConnectionInfo? connectionInfo;
  final Map<String, String> pathParameters;
  final Map<String, Object?> attributes;

  Uri get url => request.url;

  String get method => request.method;

  Headers get headers => request.headers;

  bool get isSecure {
    final scheme = url.scheme.toLowerCase();
    return scheme == 'https' || scheme == 'wss';
  }

  Object? operator [](String key) => attributes[key];

  void operator []=(String key, Object? value) {
    attributes[key] = value;
  }

  @override
  BodyData get bodyData => request.bodyData;

  @override
  String? get bodyMimeTypeHint => request.headers.get('content-type');

  ServerRequest clone() {
    return ServerRequest.fromRequest(
      request.clone(),
      version: version,
      pathParameters: pathParameters,
      attributes: attributes,
      connectionInfo: connectionInfo,
    );
  }
}
