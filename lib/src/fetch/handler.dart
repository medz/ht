import 'dart:async';

import 'request.dart';
import 'response.dart';

/// Fetch-style request handler signature.
typedef FetchHandler = FutureOr<Response> Function(Request request);

/// Fetch-style middleware signature.
typedef FetchMiddleware = FutureOr<Response> Function(
  Request request,
  FetchHandler next,
);

/// Builds a middleware pipeline around [handler].
FetchHandler composeFetchMiddleware(
  FetchHandler handler,
  Iterable<FetchMiddleware> middleware,
) {
  var pipeline = handler;
  final layers = middleware.toList(growable: false);

  for (final layer in layers.reversed) {
    final next = pipeline;
    pipeline = (request) => layer(request, next);
  }

  return pipeline;
}
