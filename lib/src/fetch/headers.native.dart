/// Constructor input accepted by headers implementations.
///
/// Supported forms are:
/// - `null`
/// - another [Headers]
/// - an `Iterable<MapEntry<String, String>>`
/// - a `Map<String, String>`
/// - a `Map<String, Iterable<String>>`
/// - an `Iterable<(String, String)>`
/// - an `Iterable<(String, Iterable<String>)>`
typedef HeadersInit = Object?;

class Headers with Iterable<MapEntry<String, String>> {
  const Headers._(this._host);

  factory Headers([HeadersInit? init]) {
    final headers = Headers._(<MapEntry<String, String>>[]);
    switch (init) {
      case null:
        return headers;
      case final Headers upstream:
        headers._host.addAll(upstream._host);
      case final Iterable<MapEntry<String, String>> entries:
        for (final MapEntry(:key, :value) in entries) {
          headers.append(key, value);
        }
      case final Map<String, String> map:
        for (final MapEntry(:key, :value) in map.entries) {
          headers.append(key, value);
        }
      case final Map<String, Iterable<String>> map:
        for (final MapEntry(:key, value: values) in map.entries) {
          for (final value in values) {
            headers.append(key, value);
          }
        }
      case final Iterable<Iterable<String>> pairs:
        for (final pair in pairs) {
          final values = pair.toList(growable: false);
          if (values.length != 2) {
            throw ArgumentError.value(
              pair,
              'init',
              'Header pairs must contain exactly two string items.',
            );
          }
          headers.append(values[0], values[1]);
        }
      case final Iterable<(String, String)> pairs:
        for (final (name, value) in pairs) {
          headers.append(name, value);
        }
      case final Iterable<(String, Iterable<String>)> pairs:
        for (final (name, values) in pairs) {
          for (final value in values) {
            headers.append(name, value);
          }
        }
      default:
        throw ArgumentError.value(init, 'init');
    }

    return headers;
  }

  static final _tokenPattern = RegExp(r"^[!#$%&'*+\-.^_`|~0-9A-Za-z]+$");

  final List<MapEntry<String, String>> _host;

  @override
  Iterator<MapEntry<String, String>> get iterator => _host.iterator;

  void append(String name, String value) {
    _host.add(
      MapEntry(
        _normalizeAndValidateName(name),
        _normalizeAndValidateValue(value),
      ),
    );
  }

  void delete(String name) {
    final normalizedName = _normalizeAndValidateName(name);
    _host.removeWhere((entry) => entry.key == normalizedName);
  }

  Iterable<MapEntry<String, String>> entries() => _host;

  String? get(String name) {
    final normalizedName = _normalizeAndValidateName(name);
    if (normalizedName == 'set-cookie') {
      return null;
    }

    final values = _host
        .where((entry) => entry.key == normalizedName)
        .map((entry) => entry.value);
    return values.isNotEmpty ? values.join(', ') : null;
  }

  void set(String name, String value) {
    final normalizedName = _normalizeAndValidateName(name);
    _host
      ..removeWhere((entry) => entry.key == normalizedName)
      ..add(MapEntry(normalizedName, _normalizeAndValidateValue(value)));
  }

  Iterable<String> getSetCookie() {
    return _host
        .where((entry) => entry.key == 'set-cookie')
        .map((entry) => entry.value);
  }

  bool has(String name) {
    final normalizedName = _normalizeAndValidateName(name);
    return _host.any((entry) => entry.key == normalizedName);
  }

  Iterable<String> keys() {
    final seen = <String>{};
    return _host.map((entry) => entry.key).where(seen.add);
  }

  Iterable<String> values() {
    return _host.map((entry) => entry.value);
  }

  static String _normalizeAndValidateName(String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty || !_tokenPattern.hasMatch(normalized)) {
      throw ArgumentError.value(name, 'name', 'Invalid header name');
    }

    return normalized;
  }

  static String _normalizeAndValidateValue(String value) {
    final normalized = value.trim();
    if (normalized.contains('\r') || normalized.contains('\n')) {
      throw ArgumentError.value(
        value,
        'value',
        'Header value must not contain CR/LF',
      );
    }

    return normalized;
  }
}
