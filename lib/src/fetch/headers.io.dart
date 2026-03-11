import 'dart:io';

import 'headers.native.dart' as native;

sealed class HeadersHost<T> {
  const HeadersHost(this.value);
  final T value;
}

final class HttpHeadersHost extends HeadersHost<HttpHeaders> {
  const HttpHeadersHost(super.value);
}

final class NativeHeadersHost extends HeadersHost<native.Headers> {
  const NativeHeadersHost(super.value);
}

class Headers
    with Iterable<MapEntry<String, String>>
    implements native.Headers {
  const Headers._(this._host);

  factory Headers([native.HeadersInit? init]) {
    final host = switch (init) {
      final Headers headers => headers._host,
      final HttpHeaders headers => HttpHeadersHost(headers),
      _ => NativeHeadersHost(native.Headers(init)),
    };

    return Headers._(host);
  }

  final HeadersHost _host;

  @override
  Iterator<MapEntry<String, String>> get iterator => entries().iterator;

  @override
  void append(String name, String value) {
    switch (_host) {
      case final HttpHeadersHost host:
        host.value.add(name, value);
      case final NativeHeadersHost host:
        host.value.append(name, value);
    }
  }

  @override
  void delete(String name) {
    switch (_host) {
      case final HttpHeadersHost host:
        host.value.removeAll(name);
      case final NativeHeadersHost host:
        host.value.delete(name);
    }
  }

  @override
  Iterable<MapEntry<String, String>> entries() sync* {
    switch (_host) {
      case final HttpHeadersHost host:
        final entries = <MapEntry<String, String>>[];
        host.value.forEach((name, values) {
          for (final value in values) {
            entries.add(MapEntry(name, value));
          }
        });
        yield* entries;
      case final NativeHeadersHost host:
        yield* host.value.entries();
    }
  }

  @override
  String? get(String name) {
    switch (_host) {
      case final HttpHeadersHost host:
        return name.toLowerCase() == 'set-cookie'
            ? null
            : host.value.value(name);
      case final NativeHeadersHost host:
        return host.value.get(name);
    }
  }

  @override
  void set(String name, String value) {
    switch (_host) {
      case final HttpHeadersHost host:
        host.value.set(name, value);
      case final NativeHeadersHost host:
        host.value.set(name, value);
    }
  }

  @override
  Iterable<String> getSetCookie() sync* {
    switch (_host) {
      case final HttpHeadersHost host:
        yield* host.value[HttpHeaders.setCookieHeader] ?? const <String>[];
      case final NativeHeadersHost host:
        yield* host.value.getSetCookie();
    }
  }

  @override
  bool has(String name) {
    switch (_host) {
      case final HttpHeadersHost host:
        return host.value.value(name) != null;
      case final NativeHeadersHost host:
        return host.value.has(name);
    }
  }

  @override
  Iterable<String> keys() sync* {
    switch (_host) {
      case final HttpHeadersHost host:
        final keys = <String>[];
        host.value.forEach((name, values) {
          keys.add(name);
        });
        yield* keys;
      case final NativeHeadersHost host:
        yield* host.value.keys();
    }
  }

  @override
  Iterable<String> values() sync* {
    switch (_host) {
      case final HttpHeadersHost host:
        final values = <String>[];
        host.value.forEach((name, entries) {
          values.addAll(entries);
        });
        yield* values;
      case final NativeHeadersHost host:
        yield* host.value.values();
    }
  }
}
