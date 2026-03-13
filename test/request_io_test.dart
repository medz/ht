@TestOn('vm')
library;

import 'dart:io';

import 'package:ht/src/core/http_method.dart';
import 'package:ht/src/fetch/request.io.dart' as io_request;
import 'package:ht/src/fetch/request.native.dart' as native;
import 'package:test/test.dart';

void main() {
  group('Request (io)', () {
    test('caches body for wrapped native requests', () {
      final request = io_request.Request(
        native.Request(
          'https://example.com',
          native.RequestInit(body: 'payload'),
        ),
      );

      expect(identical(request.body, request.body), isTrue);
    });

    test('applies init overrides when cloning from wrapped requests', () async {
      final upstream = io_request.Request(
        native.Request(
          'https://example.com/base',
          native.RequestInit(
            method: HttpMethod.post,
            headers: {'x-upstream': '1'},
            body: 'payload',
            cache: native.RequestCache.reload,
          ),
        ),
      );

      final request = io_request.Request(
        upstream,
        native.RequestInit(
          method: HttpMethod.put,
          headers: {'x-override': '2'},
          cache: native.RequestCache.noStore,
        ),
      );

      expect(request.url, 'https://example.com/base');
      expect(request.method, HttpMethod.put);
      expect(request.headers.get('x-upstream'), isNull);
      expect(request.headers.get('x-override'), '2');
      expect(request.cache, native.RequestCache.noStore);
      expect(await request.text(), 'payload');
    });

    test('wraps HttpRequest without copying headers or body eagerly', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      final port = server.port;

      final requestFuture = server.first;

      final client = HttpClient();
      addTearDown(client.close);

      final clientRequest = await client.post(
        InternetAddress.loopbackIPv4.host,
        port,
        '/upload?q=1',
      );
      clientRequest.headers.set('content-type', 'text/plain;charset=utf-8');
      clientRequest.headers.add('x-id', '1');
      clientRequest.write('hello world');
      final clientResponseFuture = clientRequest.close();

      final httpRequest = await requestFuture;
      final request = io_request.Request(httpRequest);

      expect(request.method, HttpMethod.post);
      expect(request.url, 'http://127.0.0.1:$port/upload?q=1');
      expect(request.keepalive, isTrue);
      expect(request.cache, native.RequestCache.default_);
      expect(request.headers.get('content-type'), 'text/plain;charset=utf-8');
      expect(request.headers.get('x-id'), '1');
      expect(request.bodyUsed, isFalse);
      expect(await request.text(), 'hello world');
      expect(request.bodyUsed, isTrue);

      httpRequest.response
        ..statusCode = HttpStatus.noContent
        ..close();

      final clientResponse = await clientResponseFuture;
      await clientResponse.drain<void>();
    });

    test('clone tees HttpRequest body streams', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      final port = server.port;

      final requestFuture = server.first;

      final client = HttpClient();
      addTearDown(client.close);

      final clientRequest = await client.post(
        InternetAddress.loopbackIPv4.host,
        port,
        '/clone',
      );
      clientRequest.write('hello world');
      final clientResponseFuture = clientRequest.close();

      final httpRequest = await requestFuture;
      final request = io_request.Request(httpRequest);
      final clone = request.clone();

      expect(await request.text(), 'hello world');
      expect(await clone.text(), 'hello world');

      httpRequest.response
        ..statusCode = HttpStatus.noContent
        ..close();

      final clientResponse = await clientResponseFuture;
      await clientResponse.drain<void>();
    });
  });
}
