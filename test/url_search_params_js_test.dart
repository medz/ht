@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:ht/src/fetch/url_search_params.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  group('URLSearchParams (js)', () {
    test('accepts native web.URLSearchParams host', () {
      final upstream = web.URLSearchParams('?a=1&a=2&b=3'.toJS);
      final wrapped = URLSearchParams(upstream);

      expect(wrapped.get('a'), '1');
      expect(wrapped.getAll('a'), ['1', '2']);
      expect(wrapped.get('b'), '3');
      expect(wrapped.size, 3);
      expect(wrapped.toString(), 'a=1&a=2&b=3');
    });
  });
}
