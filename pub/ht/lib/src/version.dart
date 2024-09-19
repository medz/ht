/// Represents HTTP protocol versions.
///
/// This enum provides constants for different HTTP versions and utilities
/// to work with version strings.
enum Version {
  /// HTTP/0.9 - The original HTTP as defined in 1991
  http09('HTTP/0.9'),

  /// HTTP/1.0 - First standardized version of HTTP, defined in 1996
  http10('HTTP/1.0'),

  /// HTTP/1.1 - Standardized version that introduced keep-alive connections, defined in 1997
  http11('HTTP/1.1'),

  /// HTTP/2.0 - Major revision of the HTTP protocol, introduced in 2015
  http20('HTTP/2.0'),

  /// HTTP/3.0 - The newest major version of HTTP, using QUIC instead of TCP
  http30('HTTP/3.0'),
  ;

  /// The string representation of the HTTP version
  final String value;

  /// Creates a new [Version] instance with the given [value]
  const Version(this.value);

  /// Parses a string representation of an HTTP version and returns the corresponding [Version].
  ///
  /// This method attempts to parse the given [version] string and
  /// return the corresponding [Version] enum value.
  ///
  /// Supports partial matches for HTTP/1.x and HTTP/2.x versions.
  ///
  /// Throws an [ArgumentError] if the version string is not recognized.
  ///
  /// Example:
  /// ```dart
  /// final v1 = Version.parse('HTTP/1.1'); // Returns Version.http11
  /// final v2 = Version.parse('HTTP/2');   // Returns Version.http20
  /// ```
  factory Version.parse(String version) {
    return switch (version.toUpperCase()) {
      'HTTP/0.9' => Version.http09,
      'HTTP/1.0' => Version.http10,
      'HTTP/1.1' => Version.http11,
      String(startsWith: final s) when s('HTTP/1') => Version.http11,
      String(startsWith: final s) when s('HTTP/2') => Version.http20,
      _ => throw ArgumentError('Unsupported HTTP version: $version'),
    };
  }
}
