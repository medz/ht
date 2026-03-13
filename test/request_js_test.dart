@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:ht/src/core/http_method.dart';
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
  });
}
