import 'package:ht/ht.dart';
import 'package:test/test.dart';

void main() {
  group('URLSearchParams', () {
    test('parses and serializes query strings', () {
      final params = URLSearchParams('?a=1&a=2&hello=world+x');
      expect(params.get('a'), '1');
      expect(params.getAll('a'), ['1', '2']);
      expect(params.get('hello'), 'world x');
      expect(params.toString(), 'a=1&a=2&hello=world+x');
    });

    test('set and delete mutate entries', () {
      final params = URLSearchParams();
      params.append('a', '1');
      params.append('a', '2');
      params.set('a', '3');

      expect(params.getAll('a'), ['3']);

      params.delete('a');
      expect(params.has('a'), isFalse);
    });

    test('sort orders by key', () {
      final params = URLSearchParams('z=1&a=2');
      params.sort();
      expect(params.toString(), 'a=2&z=1');
    });

    test('supports map and entry-list construction', () {
      final byMap = URLSearchParams({'a': '1', 'b': '2'});
      expect(byMap.toString(), 'a=1&b=2');

      final byEntries = URLSearchParams(
        <MapEntry<String, String>>[
          const MapEntry<String, String>('x', '1'),
          const MapEntry<String, String>('x', '2'),
        ],
      );
      expect(byEntries.getAll('x'), ['1', '2']);
    });

    test('supports selective delete and has(name, value)', () {
      final params = URLSearchParams('a=1&a=2&a=3');
      expect(params.has('a', '2'), isTrue);

      params.delete('a', '2');
      expect(params.getAll('a'), ['1', '3']);
      expect(params.has('a', '2'), isFalse);
    });

    test('clone is independent', () {
      final params = URLSearchParams('a=1');
      final clone = params.clone();
      clone.set('a', '2');

      expect(params.get('a'), '1');
      expect(clone.get('a'), '2');
    });

    test('handles key without equal-sign', () {
      final params = URLSearchParams('a&b=1&&c=');
      expect(params.get('a'), '');
      expect(params.get('b'), '1');
      expect(params.get('c'), '');
      expect(params.toString(), 'a=&b=1&c=');
    });

    test('rejects unsupported initializer', () {
      expect(() => URLSearchParams(42), throwsArgumentError);
    });
  });
}
