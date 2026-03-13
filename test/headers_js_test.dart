@TestOn('browser')
library;

import 'package:ht/src/fetch/headers.js.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  group('Headers (js)', () {
    test('iterates entries from a native web.Headers host', () {
      final headers = Headers(
        web.Headers()
          ..append('x-a', '1')
          ..append('x-b', '2'),
      );

      expect(
        headers
            .entries()
            .map((entry) => '${entry.key}:${entry.value}')
            .toList(),
        ['x-a:1', 'x-b:2'],
      );
    });

    test('does not expose set-cookie through get()', () {
      final headers = Headers(
        web.Headers()
          ..append('set-cookie', 'a=1')
          ..append('set-cookie', 'b=2'),
      );

      expect(headers.get('set-cookie'), isNull);
      expect(headers.getSetCookie(), ['a=1', 'b=2']);
    });

    test('does not expose set-cookie through get() with padded names', () {
      final headers = Headers(
        web.Headers()
          ..append('set-cookie', 'a=1')
          ..append('set-cookie', 'b=2'),
      );

      expect(headers.get(' set-cookie '), isNull);
      expect(headers.getSetCookie(), ['a=1', 'b=2']);
    });
  });
}
