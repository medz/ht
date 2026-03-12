import 'dart:js_interop';

import '../_internal/web_utils.dart' as web;
import 'headers.native.dart' as native;

class Headers
    with Iterable<MapEntry<String, String>>
    implements native.Headers {
  const Headers._(this.host);

  factory Headers([native.HeadersInit? init]) {
    final host = switch (init) {
      null => web.Headers(),
      Headers(:final host) => web.Headers(host),
      final Iterable<MapEntry<String, String>> entries =>
        web.Headers.fromEntries(entries),
      final Map<String, String> map => web.Headers.fromMap(map),
      final Map<String, Iterable<String>> map => web.Headers.fromMultiValueMap(
        map,
      ),
      final Iterable<Iterable<String>> pairs => web.Headers.fromStringPairs(
        pairs,
      ),
      final Iterable<(String, String)> pairs => web.Headers.fromRecordPairs(
        pairs,
      ),
      final Iterable<(String, Iterable<String>)> pairs =>
        web.Headers.fromRecordMultiPairs(pairs),
      _ => throw ArgumentError.value(init, 'init'),
    };

    return Headers._(host);
  }

  final web.Headers host;

  @override
  Iterator<MapEntry<String, String>> get iterator => entries().iterator;

  @override
  void append(String name, String value) => host.append(name, value);

  @override
  void delete(String name) => host.delete(name);

  @override
  Iterable<MapEntry<String, String>> entries() sync* {
    final iterator = host.entries();
    while (true) {
      final result = iterator.next();
      if (result.done) break;
      if (result.value == null ||
          result.value.isUndefinedOrNull ||
          web.Array.isArray(result.value!)) {
        continue;
      }
      final [name, value] = (result.value as JSArray<JSString>).toDart;
      yield MapEntry(name.toDart, value.toDart);
    }
  }

  @override
  String? get(String name) => host.get(name);

  @override
  void set(String name, String value) => host.set(name, value);

  @override
  Iterable<String> getSetCookie() sync* {
    for (final value in host.getSetCookie().toDart) {
      yield value.toDart;
    }
  }

  @override
  bool has(String name) => host.has(name);

  @override
  Iterable<String> keys() sync* {
    final iterator = host.keys();
    while (true) {
      final result = iterator.next();
      if (result.done) break;
      yield (result.value as JSString).toDart;
    }
  }

  @override
  Iterable<String> values() sync* {
    final iterator = host.values();
    while (true) {
      final result = iterator.next();
      if (result.done) break;
      yield (result.value as JSString).toDart;
    }
  }
}
