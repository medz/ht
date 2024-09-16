// A [String] or [File] that represents a single value from a set of `FormData` key-value pairs.
import 'package:ht/src/web/blob.dart';

import 'file.dart';

base class FormDataEntry<T> {
  const FormDataEntry(this.value);

  final T value;
}

final class StringFormDataEntry extends FormDataEntry<String> {
  const StringFormDataEntry(super.value);
}

final class FileFormDataEntry extends FormDataEntry<File> {
  const FileFormDataEntry(super.value);
}

/// Provides a way to easily construct a set of key/value pairs representing form fields and their values
extension type FormData._(List<(String, FormDataEntry)> _)
    implements Iterable<(String, FormDataEntry)> {
  factory FormData() => FormData._([]);

  /// Appends a new value onto an existing key inside a FormData object,
  /// or adds the key if it does not already exist.
  void append(String name, Object value, [String filename = 'blob']) {
    final FormDataEntry entry = switch (value) {
      File file => FileFormDataEntry(file),
      Blob blob => FileFormDataEntry(File.fromStream(blob.stream(), filename,
          size: blob.size, type: blob.type)),
      _ => StringFormDataEntry(value.toString()),
    };

    _.add((name, entry));
  }

  /// Set a new value for an existing key inside FormData,
  /// or add the new field if it does not already exist.
  void set(String name, Object value, [String filename = 'blob']) {
    delete(name);
    append(name, value, filename);
  }

  /// Returns the first value associated with a given key from within a `FormData` object.
  ///
  /// If you expect multiple values and want all of them, use the `getAll()` method instead.
  FormDataEntry? get(String name) {
    for (final (storedName, entry) in _) {
      if (name == storedName) return entry;
    }

    return null;
  }

  /// Returns all the values associated with a given key from within a `FormData` object.
  Iterable<FormDataEntry> getAll(String name) sync* {
    for (final (storedName, entry) in _) {
      if (name == storedName) {
        yield entry;
      }
    }
  }

  /// Returns a boolean stating whether a `FormData` object contains a certain key.
  bool has(String name) {
    return any((e) => e.$1 == name);
  }

  /// Deletes a key and its value(s) from a `FormData` object.
  void delete(String name) {
    _.removeWhere((e) => e.$1 == name);
  }

  /// Returns an [Iterable] allowing to go through all keys contained in this `FormData` object.
  Iterable<String> keys() {
    return map((e) => e.$1);
  }

  /// Returns an [Iterable] allowing to go through the `FormData` key/value pairs.
  Iterable<FormDataEntry> values() {
    return map((e) => e.$2);
  }
}
