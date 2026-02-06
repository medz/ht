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

      expect(headers.getAll('accept'), ['application/json', 'text/plain']);
      expect(headers.get('accept'), 'application/json, text/plain');
    });

    test('set-cookie can be read with getSetCookie', () {
      final headers = Headers()
        ..append('set-cookie', 'a=1')
        ..append('set-cookie', 'b=2');

      expect(headers.get('set-cookie'), 'a=1');
      expect(headers.getSetCookie(), ['a=1', 'b=2']);
    });

    test('clone creates independent copy', () {
      final headers = Headers({'x-id': '1'});
      final clone = headers.clone()..set('x-id', '2');

      expect(headers.get('x-id'), '1');
      expect(clone.get('x-id'), '2');
    });

    test('rejects invalid names', () {
      final headers = Headers();
      expect(() => headers.set('bad name', 'x'), throwsArgumentError);
      expect(() => headers.set('', 'x'), throwsArgumentError);
      expect(() => headers.set('x-test', 'line\nbreak'), throwsArgumentError);
    });

    test('supports construction from entries and iteration', () {
      final headers = Headers.fromEntries(<MapEntry<String, String>>[
        const MapEntry<String, String>('X-A', '1'),
        const MapEntry<String, String>('X-A', '2'),
        const MapEntry<String, String>('X-B', '3'),
      ]);

      expect(headers.getAll('x-a'), ['1', '2']);
      expect(headers.map((entry) => '${entry.key}:${entry.value}').toList(), [
        'x-a:1',
        'x-a:2',
        'x-b:3',
      ]);
    });

    test('names and toMap are normalized and deterministic', () {
      final headers = Headers()
        ..append('X-A', '1')
        ..append('x-a', '2')
        ..append('X-B', '3');

      expect(headers.names().toList(), ['x-a', 'x-b']);
      expect(headers.toMap(), {'x-a': '1, 2', 'x-b': '3'});
    });

    test('clear removes all values', () {
      final headers = Headers()
        ..append('x-a', '1')
        ..append('x-b', '2')
        ..clear();

      expect(headers.has('x-a'), isFalse);
      expect(headers.getAll('x-b'), isEmpty);
      expect(headers, isEmpty);
    });
  });
}
