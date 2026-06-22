@TestOn('vm')
library;

import 'dart:io';

import 'package:ht/src/fetch/request.io.dart' as io_request;
import 'package:ht/src/fetch/request.native.dart' as native;
import 'package:ht/src/fetch/url_search_params.dart';
import 'package:test/test.dart';

void main() {
  group('Request (io)', () {
    test('caches body for wrapped native requests', () {
      final request = io_request.Request(
        native.Request(
          'https://example.com',
          native.RequestInit(method: 'POST', body: 'payload'),
        ),
      );

      expect(identical(request.body, request.body), isTrue);
    });

    test('sets default content-type for native construction body init', () {
      final textRequest = io_request.Request(
        'https://example.com/text',
        native.RequestInit(method: 'POST', body: 'hello'),
      );
      expect(
        textRequest.headers.get('content-type'),
        'text/plain;charset=UTF-8',
      );

      final paramsRequest = io_request.Request(
        'https://example.com/form',
        native.RequestInit(method: 'POST', body: URLSearchParams({'a': '1'})),
      );
      expect(
        paramsRequest.headers.get('content-type'),
        'application/x-www-form-urlencoded;charset=UTF-8',
      );
    });

    test('copies raw HttpHeaders before appending body content-type', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      final port = server.port;

      final requestFuture = server.first;

      final client = HttpClient();
      addTearDown(client.close);

      final clientRequest = await client.post(
        InternetAddress.loopbackIPv4.host,
        port,
        '/headers-copy',
      );
      final clientResponseFuture = clientRequest.close();

      final httpRequest = await requestFuture;
      final request = native.Request(
        'https://example.com/text',
        native.RequestInit(
          method: 'POST',
          headers: httpRequest.headers,
          body: 'hello',
        ),
      );

      expect(request.headers.get('content-type'), 'text/plain;charset=UTF-8');
      expect(httpRequest.headers[HttpHeaders.contentTypeHeader], isNull);

      httpRequest.response
        ..statusCode = HttpStatus.noContent
        ..close();

      final clientResponse = await clientResponseFuture;
      await clientResponse.drain<void>();
    });

    test('clone preserves deleted body-derived content-type', () async {
      final request = io_request.Request(
        'https://example.com/clone',
        native.RequestInit(method: 'POST', body: 'hello'),
      );
      expect(request.headers.get('content-type'), 'text/plain;charset=UTF-8');

      request.headers.delete('content-type');
      final clone = request.clone();

      expect(request.headers.get('content-type'), isNull);
      expect(clone.headers.get('content-type'), isNull);
      expect(await request.text(), 'hello');
      expect(await clone.text(), 'hello');
    });

    test('init override preserves deleted body-derived content-type', () async {
      final request = io_request.Request(
        'https://example.com/rebuild',
        native.RequestInit(method: 'POST', body: 'hello'),
      );
      request.headers.delete('content-type');

      final rebuilt = io_request.Request(
        request,
        native.RequestInit(cache: native.RequestCache.noStore),
      );

      expect(rebuilt.cache, native.RequestCache.noStore);
      expect(request.headers.get('content-type'), isNull);
      expect(rebuilt.headers.get('content-type'), isNull);
      expect(await request.text(), 'hello');
      expect(await rebuilt.text(), 'hello');
    });

    test('applies init overrides when cloning from wrapped requests', () async {
      final upstream = io_request.Request(
        native.Request(
          'https://example.com/base',
          native.RequestInit(
            method: 'POST',
            headers: {'x-upstream': '1'},
            body: 'payload',
            cache: native.RequestCache.reload,
            priority: native.RequestPriority.high,
          ),
        ),
      );

      final request = io_request.Request(
        upstream,
        native.RequestInit(
          method: 'PUT',
          headers: {'x-override': '2'},
          cache: native.RequestCache.noStore,
          priority: native.RequestPriority.low,
        ),
      );

      expect(request.url, 'https://example.com/base');
      expect(request.method, 'PUT');
      expect(request.headers.get('x-upstream'), isNull);
      expect(request.headers.get('x-override'), '2');
      expect(request.cache, native.RequestCache.noStore);
      expect(request.priority, native.RequestPriority.low);
      expect(await request.text(), 'payload');
    });

    test('preserves native request priority through clone', () {
      final request = io_request.Request(
        'https://example.com/priority',
        native.RequestInit(priority: native.RequestPriority.high),
      );
      final clone = request.clone();

      expect(request.priority, native.RequestPriority.high);
      expect(clone.priority, native.RequestPriority.high);
    });

    test('clones wrapped requests without init by teeing the body', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(server.close);
      final port = server.port;

      final requestFuture = server.first;

      final client = HttpClient();
      addTearDown(client.close);

      final clientRequest = await client.post(
        InternetAddress.loopbackIPv4.host,
        port,
        '/upstream-clone',
      );
      clientRequest.write('hello world');
      final clientResponseFuture = clientRequest.close();

      final httpRequest = await requestFuture;
      final upstream = io_request.Request(httpRequest);
      final clone = io_request.Request(upstream);

      expect(upstream.bodyUsed, isFalse);
      expect(clone.bodyUsed, isFalse);
      expect(await upstream.text(), 'hello world');
      expect(upstream.bodyUsed, isTrue);
      expect(clone.bodyUsed, isFalse);
      expect(await clone.text(), 'hello world');
      expect(clone.bodyUsed, isTrue);

      httpRequest.response
        ..statusCode = HttpStatus.noContent
        ..close();

      final clientResponse = await clientResponseFuture;
      await clientResponse.drain<void>();
    });

    test(
      'clones wrapped GET requests without forwarding empty host body',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(server.close);
        final port = server.port;

        final requestFuture = server.first;

        final client = HttpClient();
        addTearDown(client.close);

        final clientRequest = await client.get(
          InternetAddress.loopbackIPv4.host,
          port,
          '/bodyless-clone',
        );
        final clientResponseFuture = clientRequest.close();

        final httpRequest = await requestFuture;
        final upstream = io_request.Request(httpRequest);
        final clone = io_request.Request(upstream);

        expect(clone.method, 'GET');
        expect(clone.body, isNull);
        expect(await clone.text(), '');

        httpRequest.response
          ..statusCode = HttpStatus.noContent
          ..close();

        final clientResponse = await clientResponseFuture;
        await clientResponse.drain<void>();
      },
    );

    test(
      'rebuilds wrapped GET requests with lowercase method override',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(server.close);
        final port = server.port;

        final requestFuture = server.first;

        final client = HttpClient();
        addTearDown(client.close);

        final clientRequest = await client.get(
          InternetAddress.loopbackIPv4.host,
          port,
          '/bodyless-override',
        );
        final clientResponseFuture = clientRequest.close();

        final httpRequest = await requestFuture;
        final upstream = io_request.Request(httpRequest);
        final rebuilt = io_request.Request(
          upstream,
          native.RequestInit(method: 'get'),
        );

        expect(rebuilt.method, 'GET');
        expect(rebuilt.body, isNull);
        expect(await rebuilt.text(), '');

        httpRequest.response
          ..statusCode = HttpStatus.noContent
          ..close();

        final clientResponse = await clientResponseFuture;
        await clientResponse.drain<void>();
      },
    );

    test(
      'rejects overriding wrapped bodyful requests to bodyless methods',
      () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(server.close);
        final port = server.port;

        final requestFuture = server.first;

        final client = HttpClient();
        addTearDown(client.close);

        final clientRequest = await client.post(
          InternetAddress.loopbackIPv4.host,
          port,
          '/bodyful-override',
        );
        clientRequest.write('payload');
        final clientResponseFuture = clientRequest.close();

        final httpRequest = await requestFuture;
        final upstream = io_request.Request(httpRequest);

        expect(
          () => io_request.Request(upstream, native.RequestInit(method: 'GET')),
          throwsArgumentError,
        );

        expect(upstream.bodyUsed, isFalse);
        expect(await upstream.text(), 'payload');

        httpRequest.response
          ..statusCode = HttpStatus.noContent
          ..close();

        final clientResponse = await clientResponseFuture;
        await clientResponse.drain<void>();
      },
    );

    test(
      'rebuilds consumed wrapped requests when init provides a replacement body',
      () async {
        final upstream = io_request.Request(
          native.Request(
            'https://example.com/base',
            native.RequestInit(
              method: 'POST',
              headers: {'x-upstream': '1'},
              body: 'payload',
            ),
          ),
        );

        expect(await upstream.text(), 'payload');
        expect(upstream.bodyUsed, isTrue);

        final rebuilt = io_request.Request(
          upstream,
          native.RequestInit(body: 'replacement', headers: {'x-override': '2'}),
        );

        expect(rebuilt.url, 'https://example.com/base');
        expect(rebuilt.method, 'POST');
        expect(rebuilt.headers.get('x-upstream'), isNull);
        expect(rebuilt.headers.get('x-override'), '2');
        expect(rebuilt.bodyUsed, isFalse);
        expect(await rebuilt.text(), 'replacement');
        expect(rebuilt.bodyUsed, isTrue);
      },
    );

    test('rejects native construction bodies for bodyless methods', () {
      expect(
        () => io_request.Request(
          'https://example.com',
          native.RequestInit(method: 'HEAD', body: 'payload'),
        ),
        throwsArgumentError,
      );
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

      expect(request.method, 'POST');
      expect(request.url, 'http://127.0.0.1:$port/upload?q=1');
      expect(request.keepalive, isTrue);
      expect(request.cache, native.RequestCache.default_);
      expect(request.priority, native.RequestPriority.auto);
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
