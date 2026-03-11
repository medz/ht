import 'dart:convert';

import 'package:block/block.dart' as block;
import 'package:ht/ht.dart';
import 'package:test/test.dart';

void main() {
  group('Request', () {
    test('json request infers headers', () {
      final request = Request.json(Uri.parse('https://example.com'), {'x': 1});

      expect(request.method, 'POST');
      expect(
        request.headers.get('content-type'),
        'application/json; charset=utf-8',
      );
      expect(request.headers.get('content-length'), isNotNull);
    });

    test('search params request infers form encoding headers', () async {
      final params = URLSearchParams()
        ..append('a', '1')
        ..append('b', '2');

      final request = Request.searchParams(
        Uri.parse('https://example.com'),
        params,
      );

      expect(
        request.headers.get('content-type'),
        'application/x-www-form-urlencoded; charset=utf-8',
      );
      expect(await request.text(), 'a=1&b=2');
    });

    test('form-data request infers multipart headers', () async {
      final form = FormData()..append('name', 'alice');

      final request = Request.formData(Uri.parse('https://example.com'), form);

      expect(
        request.headers.get('content-type'),
        startsWith('multipart/form-data; boundary='),
      );
      expect(request.headers.get('content-length'), isNotNull);
      expect(await request.text(), contains('name="name"'));
    });

    test('accepts block body and infers content headers', () async {
      final body = block.Block(<Object>['hello'], type: 'text/custom');
      final request = Request(
        Uri.parse('https://example.com'),
        RequestInit(method: 'POST', body: body),
      );

      expect(request.headers.get('content-type'), 'text/custom');
      expect(request.headers.get('content-length'), '5');
      expect(await request.text(), 'hello');
    });

    test('cannot attach body to GET/HEAD/TRACE', () {
      expect(
        () => Request(
          Uri.parse('https://example.com'),
          RequestInit(method: 'GET', body: 'x'),
        ),
        throwsArgumentError,
      );
    });

    test('clone duplicates unread stream body', () async {
      final request = Request.stream(
        Uri.parse('https://example.com'),
        Stream<List<int>>.fromIterable(<List<int>>[
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
        'streamed',
      );

      expect(request.bodyUsed, isFalse);
      final bytes = await request.body!.expand((chunk) => chunk).toList();
      expect(utf8.decode(bytes), 'streamed');
      expect(request.bodyUsed, isTrue);
      await expectLater(request.text(), throwsStateError);
    });

    test('body can only be consumed once', () async {
      final request = Request.text(Uri.parse('https://example.com'), 'once');

      expect(await request.text(), 'once');
      await expectLater(request.text(), throwsStateError);
    });

    test('constructor clones headers input', () {
      final source = Headers({'x-id': '1'});
      final request = Request(
        Uri.parse('https://example.com'),
        RequestInit(method: 'POST', headers: source),
      );

      source.set('x-id', '2');
      request.headers.set('x-other', 'v');

      expect(request.headers.get('x-id'), '1');
      expect(source.has('x-other'), isFalse);
    });

    test('clone fails after body has been consumed', () async {
      final request = Request.text(Uri.parse('https://example.com'), 'x');
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
          RequestInit(method: 'POST', body: DateTime(2024)),
        ),
        throwsArgumentError,
      );
    });
  });

  group('Response', () {
    test('json response infers headers and ok status', () {
      final response = Response.json({'ok': true});

      expect(response.status, 200);
      expect(response.statusText, '');
      expect(response.ok, isTrue);
      expect(
        response.headers.get('content-type'),
        'application/json; charset=utf-8',
      );
      expect(response.headers.get('content-length'), isNotNull);
    });

    test('accepts block body and infers content headers', () async {
      final body = block.Block(<Object>['payload'], type: 'application/custom');
      final response = Response(body);

      expect(response.headers.get('content-type'), 'application/custom');
      expect(response.headers.get('content-length'), '7');
      expect(await response.text(), 'payload');
    });

    test('empty response defaults to 204 and no body', () async {
      final response = Response.empty();

      expect(response.status, HttpStatus.noContent);
      expect(response.statusText, '');
      expect(response.body, isNull);
      expect(await response.bytes(), isEmpty);
    });

    test('redirect response sets location and redirect metadata', () {
      final response = Response.redirect(Uri.parse('https://example.com/next'));
      expect(response.redirected, isFalse);
      expect(response.url, isNull);
      expect(response.headers.get('location'), 'https://example.com/next');
      expect(response.status, 302);
    });

    test('redirect factory rejects non-redirect status', () {
      expect(
        () => Response.redirect(Uri.parse('https://example.com'), 200),
        throwsArgumentError,
      );
    });

    test('constructor clones headers input', () {
      final source = Headers({'x-id': '1'});
      final response = Response.text('ok', ResponseInit(headers: source));

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

    test('blob type prefers explicit content-type header', () async {
      final response = Response(
        'hello',
        ResponseInit(headers: Headers({'content-type': 'application/custom'})),
      );

      final blob = await response.blob();
      expect(blob.type, 'application/custom');
      expect(await blob.text(), 'hello');
    });

    test('validates status range', () {
      expect(
        () => Response(null, ResponseInit(status: 99)),
        throwsArgumentError,
      );
      expect(
        () => Response(null, ResponseInit(status: 600)),
        throwsArgumentError,
      );
    });

    test('rejects body for null-body statuses', () {
      for (final status in const <int>[204, 205, 304]) {
        expect(
          () => Response('payload', ResponseInit(status: status)),
          throwsArgumentError,
          reason: 'status=$status',
        );
      }
    });
  });
}
