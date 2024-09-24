/// A web API like [URLSearchParams] suitable for Dart.
extension type URLSearchParams._(List<(String, String)> _)
    implements Iterable<(String, String)> {
  /// Creates a new [URLSearchParams] object.
  factory URLSearchParams([Map<String, String>? init]) {
    final inner = URLSearchParams._([]);
    if (init != null && init.isNotEmpty) {
      for (final e in init.entries) {
        inner.append(e.key, e.value);
      }
    }

    return inner;
  }

  /// Append a new name-value pair to the query string.
  void append(String name, String value) {
    _.add((name, value));
  }

  /// If `value` is provided, removes all name-value pairs
  /// where name is `name` and value is `value`.
  ///
  /// If `value` is not provided, removes all name-value pairs whose name is `name`.
  void delete(String name, [String? value]) {
    if (value != null) {
      return _.removeWhere((e) => e.$1 == name && e.$2 == value);
    }

    _.removeWhere((e) => e.$1 == name);
  }

  /// Returns the value of the first name-value pair whose name is `name`. If there
  /// are no such pairs, `null` is returned.
  ///
  /// or `null` if there is no name-value pair with the given `name`.
  String? get(String name) {
    for (final e in _) {
      if (name == e.$1) return e.$2;
    }

    return null;
  }

  /// Returns the values of all name-value pairs whose name is `name`. If there are
  /// no such pairs, an empty array is returned.
  Iterable<String> getAll(String name) {
    return where((e) => e.$1 == name).map((e) => e.$2);
  }

  /// Checks if the `URLSearchParams` object contains key-value pair(s) based on `name` and an optional `value` argument.
  ///
  /// If `value` is provided, returns `true` when name-value pair with
  /// same `name` and `value` exists.
  ///
  /// If `value` is not provided, returns `true` if there is at least one name-value
  /// pair whose name is `name`.
  bool has(String name, [String? value]) {
    if (value == null) {
      return any((e) => e.$1 == name);
    }

    return any((e) => e.$1 == name && e.$2 == value);
  }

  /// Sets the value in the `URLSearchParams` object associated with `name` to `value`.
  /// If there are any pre-existing name-value pairs whose names are `name`,
  /// set the first such pair's value to `value` and remove all others. If not,
  /// append the name-value pair to the query string.
  void set(String name, String value) {
    delete(name);
    _.add(((name, value)));
  }

  /// Returns an [Iterable] over the names of each name-value pair.
  Iterable<String> keys() {
    return map((e) => e.$1).toSet();
  }

  /// Returns an [Iterable] over the values of each name-value pair.
  Iterable<String> values() {
    return map((e) => e.$2);
  }

  /// Sort all existing name-value pairs in-place by their names. Sorting is done
  /// with a [stable sorting algorithm](https://en.wikipedia.org/wiki/Sorting_algorithm#Stability), so relative order between name-value pairs
  /// with the same name is preserved.
  ///
  /// This method can be used, in particular, to increase cache hits.
  void sort() => _.sort();
}
