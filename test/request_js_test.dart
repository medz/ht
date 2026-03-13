@TestOn('browser')
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:ht/src/core/http_method.dart';
import 'package:ht/src/fetch/file.dart';
import 'package:ht/src/fetch/form_data.native.dart';
import 'package:ht/src/fetch/request.js.dart';
import 'package:ht/src/fetch/request.native.dart' as native;
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  group('Request (js)', () {
    test('accepts native web.Request host', () async {
      final upstream = web.Request(
        'https://example.com/upload?x=1'.toJS,
        web.RequestInit(
          method: 'POST',
          headers: {'content-type': 'text/plain'}.jsify()! as web.HeadersInit,
          body: 'hello world'.toJS,
          keepalive: true,
          redirect: 'manual',
          cache: 'reload',
          credentials: 'include',
          duplex: 'half',
          referrer: 'https://ref.example/path',
          referrerPolicy: 'origin',
        ),
      );

      final request = Request(upstream);

      expect(request.method, HttpMethod.post);
      expect(request.url, 'https://example.com/upload?x=1');
      expect(request.keepalive, isTrue);
      expect(request.cache, native.RequestCache.reload);
      expect(request.credentials, native.RequestCredentials.include);
      expect(request.redirect, native.RequestRedirect.manual);
      expect(request.referrer, 'about:client');
      expect(request.referrerPolicy, native.RequestReferrerPolicy.origin);
      expect(request.headers.get('content-type'), 'text/plain');
      expect(request.bodyUsed, isFalse);
      expect(await request.text(), 'hello world');
      expect(request.bodyUsed, isTrue);
    });

    test('clone tees a wrapped web.Request body', () async {
      final upstream = web.Request(
        'https://example.com/clone'.toJS,
        web.RequestInit(method: 'POST', body: 'cloned body'.toJS),
      );

      final request = Request(upstream);
      final clone = request.clone();

      expect(await request.text(), 'cloned body');
      expect(await clone.text(), 'cloned body');
    });

    test('reads bytes directly from web host', () async {
      final upstream = web.Request(
        'https://example.com/bytes'.toJS,
        web.RequestInit(method: 'POST', body: 'hello bytes'.toJS),
      );

      final request = Request(upstream);

      expect(await request.bytes(), Uint8List.fromList(utf8.encode('hello bytes')));
      expect(request.bodyUsed, isTrue);
    });

    test('reads blob directly from web host', () async {
      final upstream = web.Request(
        'https://example.com/blob'.toJS,
        web.RequestInit(
          method: 'POST',
          headers: {'content-type': 'text/plain'}.jsify()! as web.HeadersInit,
          body: 'hello blob'.toJS,
        ),
      );

      final request = Request(upstream);
      final blob = await request.blob();

      expect(blob.type, 'text/plain');
      expect(await blob.text(), 'hello blob');
      expect(request.bodyUsed, isTrue);
    });

    test('reads formData directly from web host', () async {
      final formData = web.FormData()
        ..append('a', '1'.toJS)
        ..append('a', '2'.toJS);
      final formRequest = Request(
        web.Request(
          'https://example.com/form'.toJS,
          web.RequestInit(method: 'POST', body: formData),
        ),
      );

      final parsed = await formRequest.formData();
      final values = parsed.getAll('a');
      expect(values, hasLength(2));
      expect((values[0] as TextMultipart).value, '1');
      expect((values[1] as TextMultipart).value, '2');
    });

    test('maps web.File formData entries to BlobMultipart', () async {
      final file = web.File(
        ['payload'.toJS].toJS,
        'payload.txt',
        web.FilePropertyBag(type: 'text/plain'),
      );
      final formData = web.FormData()..append('file', file);
      final request = Request(
        web.Request(
          'https://example.com/upload'.toJS,
          web.RequestInit(method: 'POST', body: formData),
        ),
      );

      final parsed = await request.formData();
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
