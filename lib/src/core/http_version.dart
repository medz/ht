/// HTTP protocol versions.
enum HttpVersion {
  http09(0, 9),
  http10(1, 0),
  http11(1, 1),
  http20(2, 0),
  http30(3, 0);

  const HttpVersion(this.major, this.minor);

  final int major;
  final int minor;

  /// Wire-format value, e.g. `HTTP/1.1`.
  String get value => 'HTTP/$major.$minor';

  /// Parses common wire or shorthand HTTP version strings.
  factory HttpVersion.parse(String input) {
    final normalized = input.trim().toUpperCase();
    return switch (normalized) {
      'HTTP/0.9' => HttpVersion.http09,
      'HTTP/1.0' => HttpVersion.http10,
      'HTTP/1.1' => HttpVersion.http11,
      'HTTP/2' || 'HTTP/2.0' || 'H2' => HttpVersion.http20,
      'HTTP/3' || 'HTTP/3.0' || 'H3' => HttpVersion.http30,
      _ => throw ArgumentError.value(
        input,
        'input',
        'Unsupported HTTP version string',
      ),
    };
  }

  @override
  String toString() => value;
}
