import 'dart:collection';

/// A mutable, case-insensitive HTTP headers collection.
class Headers extends IterableBase<MapEntry<String, String>> {
  Headers([Map<String, String>? init]) {
    if (init == null) {
      return;
    }

    for (final entry in init.entries) {
      set(entry.key, entry.value);
    }
  }

  Headers.from(Headers other) {
    _entries.addAll(other._entries.map((entry) => entry.copy()));
  }

  factory Headers.fromEntries(Iterable<MapEntry<String, String>> entries) {
    final headers = Headers();
    for (final entry in entries) {
      headers.append(entry.key, entry.value);
    }
    return headers;
  }

  static final _tokenPattern = RegExp(r"^[!#$%&'*+\-.^_`|~0-9A-Za-z]+$");

  final _entries = <_HeaderEntry>[];

  /// Adds a header value.
  void append(String name, Object value) {
    final normalizedName = _normalizeAndValidateName(name);
    final normalizedValue = _normalizeAndValidateValue(value);
    _entries.add(
      _HeaderEntry(
        originalName: name.trim(),
        normalizedName: normalizedName,
        value: normalizedValue,
      ),
    );
  }

  /// Replaces all values for [name] with [value].
  void set(String name, Object value) {
    delete(name);
    append(name, value);
  }

  /// Deletes all values by [name].
  void delete(String name) {
    final normalizedName = _normalizeAndValidateName(name);
    _entries.removeWhere((entry) => entry.normalizedName == normalizedName);
  }

  /// Returns a merged value for [name].
  ///
  /// For `set-cookie`, this returns the first cookie. Use [getSetCookie]
  /// to retrieve all cookie values.
  String? get(String name) {
    final values = getAll(name);
    if (values.isEmpty) {
      return null;
    }

    final normalizedName = _normalizeAndValidateName(name);
    if (normalizedName == 'set-cookie') {
      return values.first;
    }

    return values.join(', ');
  }

  /// Returns all values by [name], preserving insertion order.
  List<String> getAll(String name) {
    final normalizedName = _normalizeAndValidateName(name);
    return List<String>.unmodifiable(
      _entries
          .where((entry) => entry.normalizedName == normalizedName)
          .map((entry) => entry.value),
    );
  }

  /// Returns all `set-cookie` values.
  List<String> getSetCookie() => getAll('set-cookie');

  /// Returns whether [name] exists.
  bool has(String name) {
    final normalizedName = _normalizeAndValidateName(name);
    return _entries.any((entry) => entry.normalizedName == normalizedName);
  }

  /// Removes all headers.
  void clear() => _entries.clear();

  /// Creates a deep copy of this header collection.
  Headers clone() => Headers.from(this);

  /// Returns normalized header names in insertion order (without duplicates).
  Iterable<String> names() sync* {
    final seen = <String>{};
    for (final entry in _entries) {
      if (seen.add(entry.normalizedName)) {
        yield entry.normalizedName;
      }
    }
  }

  /// Returns a map representation where duplicate values are merged by `, `.
  Map<String, String> toMap() {
    final result = <String, String>{};
    for (final name in names()) {
      result[name] = get(name)!;
    }
    return Map<String, String>.unmodifiable(result);
  }

  @override
  Iterator<MapEntry<String, String>> get iterator => _entries
      .map(
        (entry) => MapEntry<String, String>(entry.normalizedName, entry.value),
      )
      .iterator;

  static String _normalizeAndValidateName(String name) {
    final normalized = name.trim().toLowerCase();
    if (normalized.isEmpty || !_tokenPattern.hasMatch(normalized)) {
      throw ArgumentError.value(name, 'name', 'Invalid header name');
    }
    return normalized;
  }

  static String _normalizeAndValidateValue(Object value) {
    final normalized = value.toString().trim();
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

final class _HeaderEntry {
  const _HeaderEntry({
    required this.originalName,
    required this.normalizedName,
    required this.value,
  });

  final String originalName;
  final String normalizedName;
  final String value;

  _HeaderEntry copy() => _HeaderEntry(
    originalName: originalName,
    normalizedName: normalizedName,
    value: value,
  );
}
