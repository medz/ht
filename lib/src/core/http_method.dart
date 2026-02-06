/// Standard HTTP methods used by both client and server side APIs.
enum HttpMethod {
  get('GET', allowsRequestBody: false),
  head('HEAD', allowsRequestBody: false),
  post('POST'),
  put('PUT'),
  patch('PATCH'),
  delete('DELETE'),
  options('OPTIONS'),
  connect('CONNECT'),
  trace('TRACE', allowsRequestBody: false);

  const HttpMethod(this.value, {this.allowsRequestBody = true});

  /// Upper-case wire value.
  final String value;

  /// Whether request bodies are normally allowed for this method.
  final bool allowsRequestBody;

  /// Parses a case-insensitive method string.
  factory HttpMethod.parse(String input) {
    final upper = input.trim().toUpperCase();
    for (final method in HttpMethod.values) {
      if (method.value == upper) {
        return method;
      }
    }

    throw ArgumentError.value(input, 'input', 'Unsupported HTTP method');
  }

  @override
  String toString() => value;
}
