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

    test('search params request infers form encoding headers', () async {
      final params = URLSearchParams();
      params.append('a', '1');
      params.append('b', '2');

      final request = Request.searchParams(
        Uri.parse('https://example.com'),
        body: params,
      );

      expect(request.headers.get('content-type'),
          'application/x-www-form-urlencoded; charset=utf-8');
      expect(await request.text(), 'a=1&b=2');
    });

    test('form-data request infers multipart headers', () async {
      final form = FormData();
      form.append('name', 'alice');

      final request = Request.formData(
        Uri.parse('https://example.com'),
        body: form,
      );

      expect(request.headers.get('content-type'),
          startsWith('multipart/form-data; boundary='));
      expect(request.headers.get('content-length'), isNotNull);
      expect(await request.text(), contains('name="name"'));
    });

    test('cannot attach body to GET/HEAD/TRACE', () {
      expect(
        () =>
            Request(Uri.parse('https://example.com'), method: 'GET', body: 'x'),
        throwsArgumentError,
      );
    });

    test('clone duplicates unread stream body', () async {
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

    test('body stream marks bodyUsed and is single-consume', () async {
      final request = Request.text(
        Uri.parse('https://example.com'),
        body: 'streamed',
      );

      expect(request.bodyUsed, isFalse);
      final bytes = await request.body!.expand((chunk) => chunk).toList();
      expect(utf8.decode(bytes), 'streamed');
      expect(request.bodyUsed, isTrue);
      await expectLater(request.text(), throwsStateError);
    });

    test('body can only be consumed once', () async {
      final request = Request.text(
        Uri.parse('https://example.com'),
        body: 'once',
      );

      expect(await request.text(), 'once');
      await expectLater(request.text(), throwsStateError);
    });

    test('constructor clones headers input', () {
      final source = Headers({'x-id': '1'});
      final request = Request(
        Uri.parse('https://example.com'),
        method: 'POST',
        headers: source,
      );

      source.set('x-id', '2');
      request.headers.set('x-other', 'v');

      expect(request.headers.get('x-id'), '1');
      expect(source.has('x-other'), isFalse);
    });

    test('copyWith clones body when omitted and can replace body', () async {
      final request = Request.text(
        Uri.parse('https://example.com'),
        body: 'payload',
      );

      final copied = request.copyWith(method: 'PUT');
      final replaced = request.copyWith(method: 'PATCH', body: 'next');

      expect(copied.method, 'PUT');
      expect(replaced.method, 'PATCH');
      expect(await request.text(), 'payload');
      expect(await copied.text(), 'payload');
      expect(await replaced.text(), 'next');
    });

    test('copyWith without body fails after body has been consumed', () async {
      final request = Request.text(
        Uri.parse('https://example.com'),
        body: 'x',
      );
      await request.text();

      expect(() => request.copyWith(method: 'PUT'), throwsStateError);
    });

    test('clone fails after body has been consumed', () async {
      final request = Request.text(
        Uri.parse('https://example.com'),
        body: 'x',
      );
      await request.text();

      expect(() => request.clone(), throwsStateError);
    });

    test('request with no body exposes null stream and empty bytes', () async {
      final request = Request(Uri.parse('https://example.com'));
      expect(request.body, isNull);
      expect(request.bodyUsed, isFalse);
      expect(await request.bytes(), isEmpty);
      expect(request.bodyUsed, isTrue);
    });

    test('rejects unsupported body types', () {
      expect(
        () => Request(
          Uri.parse('https://example.com'),
          method: 'POST',
          body: DateTime(2024),
        ),
        throwsArgumentError,
      );
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

    test('empty response defaults to 204 and no body', () async {
      final response = Response.empty();

      expect(response.status, HttpStatus.noContent);
      expect(response.statusText, 'No Content');
      expect(response.body, isNull);
      expect(await response.bytes(), isEmpty);
    });

    test('redirect response sets location and redirect metadata', () {
      final response = Response.redirect(Uri.parse('https://example.com/next'));
      expect(response.redirected, isTrue);
      expect(response.headers.get('location'), 'https://example.com/next');
      expect(response.status, 302);
    });

    test('redirect factory rejects non-redirect status', () {
      expect(
        () => Response.redirect(Uri.parse('https://example.com'), status: 200),
        throwsArgumentError,
      );
    });

    test('constructor clones headers input', () {
      final source = Headers({'x-id': '1'});
      final response = Response.text('ok', headers: source);

      source.set('x-id', '2');
      response.headers.set('x-other', 'v');

      expect(response.headers.get('x-id'), '1');
      expect(source.has('x-other'), isFalse);
    });

    test('clone duplicates unread body', () async {
      final response = Response.text('payload');
      final clone = response.clone();

      expect(await response.text(), 'payload');
      expect(await clone.text(), 'payload');
    });

    test('copyWith clones body when omitted and supports body override',
        () async {
      final response = Response.text('payload', status: 200);
      final copied = response.copyWith(status: 201);
      final replaced = response.copyWith(body: 'other');
      final emptied = response.copyWith(body: null);

      expect(copied.status, 201);
      expect(await response.text(), 'payload');
      expect(await copied.text(), 'payload');
      expect(await replaced.text(), 'other');
      expect(await emptied.bytes(), isEmpty);
    });

    test('copyWith without body fails after body has been consumed', () async {
      final response = Response.text('x');
      await response.text();

      expect(() => response.copyWith(status: 201), throwsStateError);
    });

    test('blob type prefers explicit content-type header', () async {
      final response = Response(
        body: 'hello',
        headers: Headers({'content-type': 'application/custom'}),
      );

      final blob = await response.blob();
      expect(blob.type, 'application/custom');
      expect(await blob.text(), 'hello');
    });

    test('validates status range', () {
      expect(() => Response(status: 99), throwsArgumentError);
      expect(() => Response(status: 600), throwsArgumentError);
    });
  });
}
