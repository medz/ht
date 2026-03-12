@JS()
library;

import 'dart:js_interop';

import 'package:web/web.dart' as web;

extension type IteratorReturnResult(JSObject _) implements JSObject {
  external bool get done;
  external JSAny? get value;
}

extension type ArrayIterator(JSObject _) implements JSObject {
  external IteratorReturnResult next();
}

extension type Headers._(JSObject _) implements web.Headers {
  external factory Headers([web.HeadersInit init]);
  external ArrayIterator entries();
  external ArrayIterator keys();
  external ArrayIterator values();

  factory Headers.fromEntries(Iterable<MapEntry<String, String>> entries) {
    final headers = Headers();
    for (final MapEntry(key: name, :value) in entries) {
      headers.append(name, value);
    }
    return headers;
  }

  factory Headers.fromMap(Map<String, String> map) =>
      Headers.fromEntries(map.entries);

  factory Headers.fromMultiValueMap(Map<String, Iterable<String>> map) {
    final headers = Headers();
    for (final MapEntry(:key, value: values) in map.entries) {
      for (final value in values) {
        headers.append(key, value);
      }
    }
    return headers;
  }

  factory Headers.fromStringPairs(Iterable<Iterable<String>> pairs) {
    final headers = Headers();
    for (final kv in pairs) {
      if (kv.length != 2) {
        throw ArgumentError.value(
          kv,
          'pairs',
          'Header pairs must contain exactly two string items.',
        );
      }

      headers.append(kv.elementAt(0), kv.elementAt(1));
    }

    return headers;
  }

  factory Headers.fromRecordPairs(Iterable<(String, String)> pairs) {
    final headers = Headers();
    for (final (name, value) in pairs) {
      headers.append(name, value);
    }
    return headers;
  }

  factory Headers.fromRecordMultiPairs(
    Iterable<(String, Iterable<String>)> pairs,
  ) {
    final headers = Headers();
    for (final (name, values) in pairs) {
      for (final value in values) {
        headers.append(name, value);
      }
    }
    return headers;
  }
}

extension type Array<T extends JSAny?>._(JSAny _) {
  external static bool isArray(JSAny _);
}

extension type URLSearchParams._(JSObject _) implements web.URLSearchParams {
  external factory URLSearchParams([JSAny init]);

  external ArrayIterator entries();
  external ArrayIterator keys();
  external ArrayIterator values();

  @JS('toString')
  external String stringify();

  factory URLSearchParams.fromEntries(
    Iterable<MapEntry<String, String>> entries,
  ) {
    final params = URLSearchParams();
    for (final MapEntry(key: name, :value) in entries) {
      params.append(name, value);
    }
    return params;
  }

  factory URLSearchParams.fromMap(Map<String, String> map) =>
      URLSearchParams.fromEntries(map.entries);
}
