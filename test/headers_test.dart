import 'package:ht/ht.dart';
import 'package:test/test.dart';

void main() {
  group('Headers', () {
    test('set/get is case-insensitive', () {
      final headers = Headers();
      headers.set('Content-Type', 'application/json');

      expect(headers.get('content-type'), 'application/json');
      expect(headers.has('CONTENT-TYPE'), isTrue);
    });

    test('append keeps multiple values', () {
      final headers = Headers();
      headers.append('accept', 'application/json');
      headers.append('accept', 'text/plain');

      expect(headers.getAll('accept'), ['application/json', 'text/plain']);
      expect(headers.get('accept'), 'application/json, text/plain');
    });

    test('set-cookie can be read with getSetCookie', () {
      final headers = Headers();
      headers.append('set-cookie', 'a=1');
      headers.append('set-cookie', 'b=2');

      expect(headers.get('set-cookie'), 'a=1');
      expect(headers.getSetCookie(), ['a=1', 'b=2']);
    });

    test('clone creates independent copy', () {
      final headers = Headers({'x-id': '1'});
      final clone = headers.clone();

      clone.set('x-id', '2');
      expect(headers.get('x-id'), '1');
      expect(clone.get('x-id'), '2');
    });

    test('rejects invalid names', () {
      final headers = Headers();
      expect(() => headers.set('bad name', 'x'), throwsArgumentError);
      expect(() => headers.set('x-test', 'line\nbreak'), throwsArgumentError);
    });
  });
}
