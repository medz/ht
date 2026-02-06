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
  });
}
