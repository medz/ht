import 'dart:collection';

/// Query parameter collection compatible with the MDN URLSearchParams model.
class URLSearchParams extends IterableBase<MapEntry<String, String>> {
  URLSearchParams([Object? init]) {
    if (init == null) {
      return;
    }

    if (init is String) {
      _parse(init);
      return;
    }

    if (init is URLSearchParams) {
      _entries.addAll(
        init._entries.map((entry) => MapEntry(entry.key, entry.value)),
      );
      return;
    }

    if (init is Map<String, String>) {
      for (final entry in init.entries) {
        append(entry.key, entry.value);
      }
      return;
    }

    if (init is Iterable<MapEntry<String, String>>) {
      for (final entry in init) {
        append(entry.key, entry.value);
      }
      return;
    }

    throw ArgumentError.value(
      init,
      'init',
      'Expected String, URLSearchParams, Map<String, String>, or entries',
    );
  }

  final _entries = <MapEntry<String, String>>[];

  void append(String name, String value) {
    _entries.add(MapEntry<String, String>(name, value));
  }

  void delete(String name, [String? value]) {
    if (value == null) {
      _entries.removeWhere((entry) => entry.key == name);
      return;
    }

    _entries.removeWhere((entry) => entry.key == name && entry.value == value);
  }

  String? get(String name) {
    for (final entry in _entries) {
      if (entry.key == name) {
        return entry.value;
      }
    }
    return null;
  }

  List<String> getAll(String name) {
    return List<String>.unmodifiable(
      _entries.where((entry) => entry.key == name).map((entry) => entry.value),
    );
  }

  bool has(String name, [String? value]) {
    if (value == null) {
      return _entries.any((entry) => entry.key == name);
    }

    return _entries.any((entry) => entry.key == name && entry.value == value);
  }

  void set(String name, String value) {
    delete(name);
    append(name, value);
  }

  void sort() {
    _entries.sort((a, b) => a.key.compareTo(b.key));
  }

  URLSearchParams clone() => URLSearchParams(this);

  @override
  Iterator<MapEntry<String, String>> get iterator =>
      List<MapEntry<String, String>>.unmodifiable(_entries).iterator;

  @override
  String toString() {
    return _entries
        .map((entry) => '${_encode(entry.key)}=${_encode(entry.value)}')
        .join('&');
  }

  void _parse(String input) {
    final source = input.startsWith('?') ? input.substring(1) : input;
    if (source.isEmpty) {
      return;
    }

    for (final part in source.split('&')) {
      if (part.isEmpty) {
        continue;
      }

      final index = part.indexOf('=');
      if (index == -1) {
        append(_decode(part), '');
      } else {
        append(
          _decode(part.substring(0, index)),
          _decode(part.substring(index + 1)),
        );
      }
    }
  }

  static String _decode(String value) {
    return Uri.decodeQueryComponent(value.replaceAll('+', ' '));
  }

  static String _encode(String value) {
    return Uri.encodeQueryComponent(value).replaceAll('%20', '+');
  }
}
