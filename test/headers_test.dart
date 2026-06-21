@TestOn('vm')
library;

import 'package:ht/ht.dart';
import 'package:test/test.dart';

void main() {
  group('Headers', () {
    test('set/get is case-insensitive', () {
      final headers = Headers()..set('Content-Type', 'application/json');

      expect(headers.get('content-type'), 'application/json');
      expect(headers.has('CONTENT-TYPE'), isTrue);
    });

    test('append keeps multiple values', () {
      final headers = Headers()
        ..append('accept', 'application/json')
        ..append('accept', 'text/plain');

      expect(
        headers
            .entries()
            .where((entry) => entry.key == 'accept')
            .map((entry) => entry.value),
        ['application/json, text/plain'],
      );
      expect(headers.get('accept'), 'application/json, text/plain');
    });

    test('set-cookie can be read with getSetCookie', () {
      final headers = Headers()
        ..append('set-cookie', 'a=1')
        ..append('set-cookie', 'b=2');

      expect(headers.get('set-cookie'), isNull);
      expect(headers.getSetCookie(), ['a=1', 'b=2']);
    });

    test('constructor from entries creates independent copy', () {
      final headers = Headers({'x-id': '1'});
      final copy = Headers(headers.entries())..set('x-id', '2');

      expect(headers.get('x-id'), '1');
      expect(copy.get('x-id'), '2');
    });

    test('rejects invalid names', () {
      final headers = Headers();
      expect(() => headers.set('bad name', 'x'), throwsArgumentError);
      expect(() => headers.set('', 'x'), throwsArgumentError);
      expect(() => headers.set('x-test', 'line\nbreak'), throwsArgumentError);
    });

    test('supports construction from entry iterables and iteration', () {
      final headers = Headers(<MapEntry<String, String>>[
        const MapEntry<String, String>('X-A', '1'),
        const MapEntry<String, String>('X-A', '2'),
        const MapEntry<String, String>('X-B', '3'),
      ]);

      expect(
        headers
            .entries()
            .where((entry) => entry.key == 'x-a')
            .map((entry) => entry.value),
        ['1, 2'],
      );
      expect(headers.map((entry) => '${entry.key}:${entry.value}').toList(), [
        'x-a:1, 2',
        'x-b:3',
      ]);
    });

    test('iteration sorts and combines according to Fetch semantics', () {
      final headers = Headers()
        ..append('X-B', 'b1')
        ..append('X-A', 'a1')
        ..append('x-a', 'a2')
        ..append('Set-Cookie', 's1=1')
        ..append('set-cookie', 's2=2');

      expect(headers.map((entry) => '${entry.key}:${entry.value}').toList(), [
        'set-cookie:s1=1',
        'set-cookie:s2=2',
        'x-a:a1, a2',
        'x-b:b1',
      ]);
      expect(headers.keys().toList(), [
        'set-cookie',
        'set-cookie',
        'x-a',
        'x-b',
      ]);
      expect(headers.values().toList(), ['s1=1', 's2=2', 'a1, a2', 'b1']);
    });

    test('delete removes all values', () {
      final headers = Headers()
        ..append('x-a', '1')
        ..append('x-b', '2')
        ..delete('x-b');

      expect(headers.has('x-a'), isTrue);
      expect(headers.get('x-b'), isNull);
      expect(headers.keys().toList(), ['x-a']);
    });
  });
}
