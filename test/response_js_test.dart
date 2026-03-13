@TestOn('browser')
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:ht/src/fetch/file.dart';
import 'package:ht/src/fetch/form_data.native.dart';
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

    test('reads bytes directly from web host', () async {
      final response = Response(web.Response('hello bytes'.toJS));

      expect(
        await response.bytes(),
        Uint8List.fromList(utf8.encode('hello bytes')),
      );
      expect(response.bodyUsed, isTrue);
    });

    test('reads blob directly from web host', () async {
      final response = Response(
        web.Response(
          'hello blob'.toJS,
          web.ResponseInit(
            headers: {'content-type': 'text/plain'}.jsify()! as web.HeadersInit,
          ),
        ),
      );

      final blob = await response.blob();

      expect(blob.type, 'text/plain');
      expect(await blob.text(), 'hello blob');
      expect(response.bodyUsed, isTrue);
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

    test('reads formData directly from web host', () async {
      final formResponse = Response(
        web.Response(
          'a=1'.toJS,
          web.ResponseInit(
            headers: {
              'content-type': 'application/x-www-form-urlencoded',
            }.jsify()! as web.HeadersInit,
          ),
        ),
      );

      final parsed = await formResponse.formData();
      expect((parsed.get('a') as TextMultipart).value, '1');
    });

    test('maps web.File formData entries to BlobMultipart', () async {
      final file = web.File(
        ['payload'.toJS].toJS,
        'payload.txt',
        web.FilePropertyBag(type: 'text/plain'),
      );
      final formData = web.FormData()..append('file', file);
      final response = Response(web.Response(formData));

      final parsed = await response.formData();
      final part = parsed.get('file');

      expect(part, isA<BlobMultipart>());
      expect(part, isA<File>());
      expect((part as BlobMultipart).filename, 'payload.txt');
      expect(part.name, 'payload.txt');
      expect(part.type, 'text/plain');
      expect(await part.text(), 'payload');
    });
  });
}
