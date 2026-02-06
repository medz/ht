import 'dart:async';

import 'server_request.dart';
import 'server_response.dart';

/// Application handler signature.
typedef ServerHandler = FutureOr<ServerResponse> Function(
    ServerRequest request);

/// Middleware wrapper signature.
typedef ServerMiddleware = FutureOr<ServerResponse> Function(
  ServerRequest request,
  ServerHandler next,
);

/// Builds a middleware pipeline around [handler].
ServerHandler composeMiddleware(
  ServerHandler handler,
  Iterable<ServerMiddleware> middleware,
) {
  var pipeline = handler;
  final layers = middleware.toList(growable: false);

  for (final layer in layers.reversed) {
    final next = pipeline;
    pipeline = (request) => layer(request, next);
  }

  return pipeline;
}
