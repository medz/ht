import 'dart:convert';

import 'package:ht/src/fetch/blob.dart';
import 'package:ht/src/fetch/form_data.native.dart';
import 'package:ht/src/fetch/headers.dart';
import 'package:ht/src/fetch/response.native.dart';
import 'package:test/test.dart';

void main() {
  group('Response (native)', () {
    test('error factory creates an error response', () async {
      final response = Response.error();

      expect(response.type, ResponseType.error);
      expect(response.status, 0);
      expect(response.statusText, '');
      expect(response.ok, isFalse);
      expect(response.headers.entries(), isEmpty);
      expect(await response.text(), '');
    });

    test('defaults metadata for empty responses', () async {
      final response = Response();

      expect(response.status, 200);
      expect(response.statusText, '');
      expect(response.ok, isTrue);
      expect(response.headers.entries(), isEmpty);
      expect(response.body, isNull);
      expect(response.redirected, isFalse);
      expect(response.type, ResponseType.default_);
      expect(response.url, '');
      expect(response.bodyUsed, isFalse);
      expect(await response.text(), '');
      expect(await response.bytes(), isEmpty);
    });

    test('respects init status, statusText and headers', () async {
      final response = Response(
        'payload',
        ResponseInit(
          status: 201,
          statusText: 'Created',
          headers: Headers({'x-id': '1'}),
        ),
      );

      expect(response.status, 201);
      expect(response.statusText, 'Created');
      expect(response.ok, isTrue);
      expect(response.headers.get('x-id'), '1');
      expect(await response.text(), 'payload');
    });

    test('json factory encodes payload and sets content-type', () async {
      final response = Response.json({'ok': true});

      expect(response.status, 200);
      expect(response.ok, isTrue);
      expect(
        response.headers.get('content-type'),
        'application/json; charset=utf-8',
      );
      expect(await response.json<Map<String, Object?>>(), {'ok': true});
    });

    test('redirect factory sets location and validates status', () {
      final response = Response.redirect(Uri.parse('https://example.com/next'));

      expect(response.status, 302);
      expect(response.redirected, isFalse);
      expect(response.headers.get('location'), 'https://example.com/next');

      expect(
        () => Response.redirect(Uri.parse('https://example.com/next'), 200),
        throwsArgumentError,
      );
    });

    test('bytes, text, json and arrayBuffer delegate to body', () async {
      final textResponse = Response('{"ok":true}');
      expect(await textResponse.text(), '{"ok":true}');

      final bytesResponse = Response(utf8.encode('hello'));
      expect(utf8.decode(await bytesResponse.bytes()), 'hello');

      final arrayBufferResponse = Response(utf8.encode('hello'));
      expect(utf8.decode(await arrayBufferResponse.arrayBuffer()), 'hello');

      final jsonResponse = Response('{"ok":true}');
      expect(await jsonResponse.json<Map<String, Object?>>(), {'ok': true});

      final emptyResponse = Response();
      await expectLater(emptyResponse.json(), throwsFormatException);
    });

    test('blob prefers explicit content-type header', () async {
      final response = Response(
        'hello',
        ResponseInit(
          headers: Headers({'content-type': 'application/custom'}),
        ),
      );

      final blob = await response.blob();
      expect(blob.type, 'application/custom');
      expect(await blob.text(), 'hello');
    });

    test('formData parses application/x-www-form-urlencoded responses', () async {
      final response = Response(
        'a=1&a=2&hello=world+x',
        ResponseInit(
          headers: Headers({
            'content-type': 'application/x-www-form-urlencoded;charset=utf-8',
          }),
        ),
      );

      final formData = await response.formData();

      expect((formData.get('a')! as TextMultipart).value, '1');
      expect(
        formData.getAll('a').map((value) => (value as TextMultipart).value),
        ['1', '2'],
      );
      expect((formData.get('hello')! as TextMultipart).value, 'world x');
    });

    test('formData parses multipart responses', () async {
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
              .encodeMultipart(boundary: 'response-boundary');

      final headers = Headers()..set('content-type', encoded.contentType);
      final response = Response(
        encoded.stream,
        ResponseInit(
          headers: headers,
        ),
      );

      final formData = await response.formData();

      expect((formData.get('name')! as TextMultipart).value, 'alice');
      final avatar = formData.get('avatar');
      expect(avatar, isA<BlobMultipart>());
      final blob = avatar! as BlobMultipart;
      expect(blob.filename, 'a.txt');
      expect(blob.type, 'text/plain;charset=utf-8');
      expect(await blob.text(), 'binary');
    });

    test('clone duplicates unread stream bodies and metadata', () async {
      final response = Response(
        Stream<List<int>>.fromIterable(<List<int>>[
          utf8.encode('hello '),
          utf8.encode('world'),
        ]),
        ResponseInit(
          status: 202,
          statusText: 'Accepted',
          headers: Headers({'x-id': '1'}),
        ),
      );

      final clone = response.clone();

      expect(clone.status, 202);
      expect(clone.statusText, 'Accepted');
      expect(clone.headers.get('x-id'), '1');
      expect(await response.text(), 'hello world');
      expect(await clone.text(), 'hello world');
    });

    test('clone fails after body has been consumed', () async {
      final response = Response('used');

      expect(await response.text(), 'used');
      expect(() => response.clone(), throwsStateError);
    });
  });
}
