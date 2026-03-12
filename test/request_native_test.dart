import 'dart:convert';

import 'package:ht/src/core/http_method.dart';
import 'package:ht/src/fetch/blob.dart';
import 'package:ht/src/fetch/form_data.native.dart';
import 'package:ht/src/fetch/headers.dart';
import 'package:ht/src/fetch/request.native.dart';
import 'package:test/test.dart';

void main() {
  group('Request (native)', () {
    test('defaults metadata for string input', () {
      final request = Request(RequestInput.string('https://example.com'));

      expect(request.url, 'https://example.com');
      expect(request.method, HttpMethod.get);
      expect(request.headers.entries(), isEmpty);
      expect(request.body, isNull);
      expect(request.cache, RequestCache.default_);
      expect(request.credentials, RequestCredentials.sameOrigin);
      expect(request.destination, '');
      expect(request.duplex, RequestDuplex.half);
      expect(request.integrity, '');
      expect(request.isHistoryNavigation, isFalse);
      expect(request.keepalive, isFalse);
      expect(request.mode, RequestMode.cors);
      expect(request.redirect, RequestRedirect.follow);
      expect(request.referrer, 'about:client');
      expect(request.referrerPolicy, isNull);
    });

    test('inherits from input request and allows init overrides', () async {
      final upstream = Request(
        RequestInput.uri(Uri.parse('https://example.com/base')),
        RequestInit(
          method: HttpMethod.post,
          headers: Headers({'x-upstream': '1'}),
          body: 'payload',
          cache: RequestCache.reload,
          credentials: RequestCredentials.include,
          duplex: RequestDuplex.half,
          integrity: 'sha256-abc',
          keepalive: true,
          mode: RequestMode.sameOrigin,
          redirect: RequestRedirect.manual,
          referrer: 'https://referrer.example',
          referrerPolicy: RequestReferrerPolicy.origin,
        ),
      );

      final request = Request(
        RequestInput.request(upstream),
        RequestInit(
          method: HttpMethod.put,
          headers: Headers({'x-override': '2'}),
          cache: RequestCache.noStore,
          referrer: 'https://override.example',
        ),
      );

      expect(request.url, 'https://example.com/base');
      expect(request.method, HttpMethod.put);
      expect(request.headers.get('x-upstream'), isNull);
      expect(request.headers.get('x-override'), '2');
      expect(request.cache, RequestCache.noStore);
      expect(request.credentials, RequestCredentials.include);
      expect(request.duplex, RequestDuplex.half);
      expect(request.integrity, 'sha256-abc');
      expect(request.keepalive, isTrue);
      expect(request.mode, RequestMode.sameOrigin);
      expect(request.redirect, RequestRedirect.manual);
      expect(request.referrer, 'https://override.example');
      expect(request.referrerPolicy, RequestReferrerPolicy.origin);
      expect(await request.text(), 'payload');
    });

    test('bytes, text, json and arrayBuffer delegate to body', () async {
      final textRequest = Request(
        RequestInput.string('https://example.com/text'),
        RequestInit(
          method: HttpMethod.post,
          headers: Headers({'content-type': 'application/json'}),
          body: '{"ok":true}',
        ),
      );

      expect(await textRequest.text(), '{"ok":true}');

      final bytesRequest = Request(
        RequestInput.string('https://example.com/bytes'),
        RequestInit(body: utf8.encode('hello')),
      );
      expect(utf8.decode(await bytesRequest.bytes()), 'hello');

      final arrayBufferRequest = Request(
        RequestInput.string('https://example.com/array-buffer'),
        RequestInit(body: utf8.encode('hello')),
      );
      expect(utf8.decode(await arrayBufferRequest.arrayBuffer()), 'hello');

      final parsedRequest = Request(
        RequestInput.string('https://example.com/parsed'),
        RequestInit(body: '{"ok":true}'),
      );
      expect(await parsedRequest.json<Map<String, Object?>>(), {'ok': true});

      final emptyRequest = Request(RequestInput.string('https://example.com'));
      expect(await emptyRequest.text(), '');
      expect(await emptyRequest.bytes(), isEmpty);
      await expectLater(emptyRequest.json(), throwsFormatException);
    });

    test('blob prefers explicit content-type header', () async {
      final request = Request(
        RequestInput.string('https://example.com/blob'),
        RequestInit(
          headers: Headers({'content-type': 'application/custom'}),
          body: 'hello',
        ),
      );

      final blob = await request.blob();
      expect(blob.type, 'application/custom');
      expect(await blob.text(), 'hello');
    });

    test('formData parses application/x-www-form-urlencoded request bodies', () async {
      final request = Request(
        RequestInput.string('https://example.com/form'),
        RequestInit(
          method: HttpMethod.post,
          headers: Headers({
            'content-type': 'application/x-www-form-urlencoded;charset=utf-8',
          }),
          body: 'a=1&a=2&hello=world+x',
        ),
      );

      final formData = await request.formData();

      expect((formData.get('a')! as TextMultipart).value, '1');
      expect(
        formData.getAll('a').map((value) => (value as TextMultipart).value),
        ['1', '2'],
      );
      expect((formData.get('hello')! as TextMultipart).value, 'world x');
    });

    test('formData parses multipart request bodies', () async {
      final encoded =
          (FormData()
                ..append('name', Multipart.text('alice'))
                ..append(
                  'avatar',
                  Multipart.blob(
                    Blob(<BlobPart>['binary'], 'text/plain;charset=utf-8'),
                    'a.txt',
                  ),
                ))
              .encodeMultipart(boundary: 'request-boundary');

      final headers = Headers()..set('content-type', encoded.contentType);
      final request = Request(
        RequestInput.string('https://example.com/upload'),
        RequestInit(
          method: HttpMethod.post,
          headers: headers,
          body: encoded.stream,
        ),
      );

      final formData = await request.formData();

      expect((formData.get('name')! as TextMultipart).value, 'alice');
      final avatar = formData.get('avatar');
      expect(avatar, isA<BlobMultipart>());
      final blob = avatar! as BlobMultipart;
      expect(blob.filename, 'a.txt');
      expect(blob.type, 'text/plain;charset=utf-8');
      expect(await blob.text(), 'binary');
    });

    test('clone duplicates unread stream bodies and metadata', () async {
      final request = Request(
        RequestInput.string('https://example.com/clone'),
        RequestInit(
          method: HttpMethod.post,
          headers: Headers({'x-id': '1'}),
          body: Stream<List<int>>.fromIterable(<List<int>>[
            utf8.encode('hello '),
            utf8.encode('world'),
          ]),
          cache: RequestCache.noCache,
          credentials: RequestCredentials.include,
          keepalive: true,
          redirect: RequestRedirect.error,
          referrer: 'https://referrer.example',
        ),
      );

      final clone = request.clone();

      expect(clone.url, request.url);
      expect(clone.method, request.method);
      expect(clone.headers.get('x-id'), '1');
      expect(clone.cache, RequestCache.noCache);
      expect(clone.credentials, RequestCredentials.include);
      expect(clone.keepalive, isTrue);
      expect(clone.redirect, RequestRedirect.error);
      expect(clone.referrer, 'https://referrer.example');
      expect(await request.text(), 'hello world');
      expect(await clone.text(), 'hello world');
    });

    test('clone fails after body has been consumed', () async {
      final request = Request(
        RequestInput.string('https://example.com/clone'),
        RequestInit(body: 'used'),
      );

      expect(await request.text(), 'used');
      expect(() => request.clone(), throwsStateError);
    });
  });
}
