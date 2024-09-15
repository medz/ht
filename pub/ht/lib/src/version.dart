/// HTTP version
enum Version {
  http09('HTTP/0.9'),
  http10('HTTP/1.0'),
  http11('HTTP/1.1'),
  http20('HTTP/2.0'),
  http30('HTTP/3.0'),
  ;

  final String value;
  const Version(this.value);

  /// Lookup a http version from string.
  factory Version.fromString(String version) {
    return switch (version.toUpperCase()) {
      'HTTP/0.9' => Version.http09,
      'HTTP/1.0' => Version.http10,
      'HTTP/1.1' => Version.http11,
      String(startsWith: final s) when s('HTTP/1') => Version.http11,
      String(startsWith: final s) when s('HTTP/2') => Version.http20,
      _ => throw ArgumentError(), // TODO
    };
  }
}
