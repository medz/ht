@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:ht/src/fetch/response.js.dart';
import 'package:ht/src/fetch/response.native.dart' as native;
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  group('Response (js)', () {
    test('accepts native web.Response host', () async {
      final upstream = web.Response(
        'hello world'.toJS,
        web.ResponseInit(
          status: 201,
          statusText: 'Created',
          headers: {'content-type': 'text/plain'}.jsify()! as web.HeadersInit,
        ),
      );

      final response = Response(upstream);

      expect(response.status, 201);
      expect(response.statusText, 'Created');
      expect(response.ok, isTrue);
      expect(response.type, native.ResponseType.default_);
      expect(response.headers.get('content-type'), 'text/plain');
      expect(response.bodyUsed, isFalse);
      expect(await response.text(), 'hello world');
      expect(response.bodyUsed, isTrue);
    });

    test('clone tees a wrapped web.Response body', () async {
      final upstream = web.Response('cloned body'.toJS);

      final response = Response(upstream);
      final clone = response.clone();

      expect(await response.text(), 'cloned body');
      expect(await clone.text(), 'cloned body');
    });

    test('supports MDN static factories', () async {
      final error = Response.error();
      expect(error.type, native.ResponseType.error);
      expect(error.status, 0);

      final redirect = Response.redirect(Uri.parse('https://example.com/next'));
      expect(redirect.status, 302);
      expect(redirect.headers.get('location'), 'https://example.com/next');

      final json = Response.json({'ok': true});
      expect(json.headers.get('content-type'), contains('application/json'));
      expect(await json.text(), '{"ok":true}');
    });
  });
}
