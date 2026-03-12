@JS()
library;

import 'dart:js_interop';

import 'url_search_params.native.dart' as native;
import '../_internal/web_utils.dart' as web;

class URLSearchParams
    with Iterable<MapEntry<String, String>>
    implements native.URLSearchParams {
  const URLSearchParams._(this._host);

  factory URLSearchParams([Object? init]) {
    final host = switch (init) {
      null => web.URLSearchParams(),
      final String source => web.URLSearchParams(source.toJS),
      URLSearchParams(:final _host) => web.URLSearchParams(_host),
      final native.URLSearchParams params => web.URLSearchParams.fromEntries(
        params,
      ),
      final Map<String, String> map => web.URLSearchParams.fromMap(map),
      final Iterable<MapEntry<String, String>> entries =>
        web.URLSearchParams.fromEntries(entries),
      _ => throw ArgumentError.value(
        init,
        'init',
        'Expected String, URLSearchParams, Map<String, String>, or entries',
      ),
    };

    return URLSearchParams._(host);
  }

  final web.URLSearchParams _host;

  @override
  Iterator<MapEntry<String, String>> get iterator => _entries().iterator;

  @override
  int get size => _host.size;

  Iterable<MapEntry<String, String>> _entries() sync* {
    final iterator = _host.entries();
    while (true) {
      final result = iterator.next();
      if (result.done) break;
      final [name, value] = (result.value as JSArray<JSString>).toDart;
      yield MapEntry(name.toDart, value.toDart);
    }
  }

  @override
  Iterable<MapEntry<String, String>> entries() => _entries();

  @override
  void append(String name, String value) => _host.append(name, value);

  @override
  void delete(String name, [String? value]) {
    if (value == null) {
      _host.delete(name);
      return;
    }

    _host.delete(name, value);
  }

  @override
  String? get(String name) => _host.get(name);

  @override
  List<String> getAll(String name) => _host
      .getAll(name)
      .toDart
      .map((value) => value.toDart)
      .toList(growable: false);

  @override
  bool has(String name, [String? value]) {
    if (value == null) {
      return _host.has(name);
    }

    return _host.has(name, value);
  }

  @override
  void set(String name, String value) => _host.set(name, value);

  @override
  void sort() => _host.sort();

  @override
  Iterable<String> keys() sync* {
    final iterator = _host.keys();
    while (true) {
      final result = iterator.next();
      if (result.done) break;
      yield (result.value as JSString).toDart;
    }
  }

  @override
  Iterable<String> values() sync* {
    final iterator = _host.values();
    while (true) {
      final result = iterator.next();
      if (result.done) break;
      yield (result.value as JSString).toDart;
    }
  }

  @override
  String toString() => _host.stringify();
}
