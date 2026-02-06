import 'dart:convert';

import 'package:ht/ht.dart';
import 'package:test/test.dart';

void main() {
  group('Request', () {
    test('json request infers headers', () {
      final request = Request.json(
        Uri.parse('https://example.com'),
        body: {'x': 1},
      );

      expect(request.method, 'POST');
      expect(request.headers.get('content-type'),
          'application/json; charset=utf-8');
      expect(request.headers.get('content-length'), isNotNull);
    });

    test('cannot attach body to GET/HEAD/TRACE', () {
      expect(
        () =>
            Request(Uri.parse('https://example.com'), method: 'GET', body: 'x'),
        throwsArgumentError,
      );
    });

    test('supports clone before consumption', () async {
      final request = Request.stream(
        Uri.parse('https://example.com'),
        body: Stream<List<int>>.fromIterable(<List<int>>[
          utf8.encode('hello '),
          utf8.encode('world'),
        ]),
      );

      final clone = request.clone();
      expect(await request.text(), 'hello world');
      expect(await clone.text(), 'hello world');
    });

    test('body can only be consumed once', () async {
      final request = Request.text(
        Uri.parse('https://example.com'),
        body: 'once',
      );

      expect(await request.text(), 'once');
      await expectLater(request.text(), throwsStateError);
    });
  });

  group('Response', () {
    test('json response infers headers and ok status', () {
      final response = Response.json({'ok': true});

      expect(response.status, 200);
      expect(response.ok, isTrue);
      expect(response.headers.get('content-type'),
          'application/json; charset=utf-8');
      expect(response.headers.get('content-length'), isNotNull);
    });

    test('redirect response sets location and redirect metadata', () {
      final response = Response.redirect(Uri.parse('https://example.com/next'));
      expect(response.redirected, isTrue);
      expect(response.headers.get('location'), 'https://example.com/next');
      expect(response.status, 302);
    });

    test('clone duplicates unread body', () async {
      final response = Response.text('payload');
      final clone = response.clone();

      expect(await response.text(), 'payload');
      expect(await clone.text(), 'payload');
    });
  });
}
