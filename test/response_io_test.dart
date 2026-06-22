@TestOn('vm')
library;

import 'dart:io' as io;

import 'package:ht/src/fetch/response.io.dart';
import 'package:ht/src/fetch/response.native.dart' as native;
import 'package:ht/src/fetch/url_search_params.dart';
import 'package:test/test.dart';

void main() {
  group('Response (io)', () {
    test('preserves native error clone semantics', () {
      final response = Response(native.Response.error());

      expect(() => response.clone(), returnsNormally);

      final clone = response.clone();
      expect(clone.type, native.ResponseType.error);
      expect(clone.status, 0);
      expect(clone.ok, isFalse);
    });

    test('sets default content-type for native construction body init', () {
      final textResponse = Response('hello');
      expect(
        textResponse.headers.get('content-type'),
        'text/plain;charset=UTF-8',
      );

      final paramsResponse = Response(URLSearchParams({'a': '1'}));
      expect(
        paramsResponse.headers.get('content-type'),
        'application/x-www-form-urlencoded;charset=UTF-8',
      );
    });

    test('clones wrapped responses without aliasing body state', () async {
      final upstream = Response(
        native.Response(
          'cloned response',
          native.ResponseInit(
            status: 202,
            statusText: 'Accepted',
            headers: {'x-source': '1'},
          ),
        ),
      );
      final clone = Response(upstream);

      expect(clone.status, 202);
      expect(clone.statusText, 'Accepted');
      expect(clone.headers.get('x-source'), '1');
      expect(upstream.bodyUsed, isFalse);
      expect(clone.bodyUsed, isFalse);

      expect(await upstream.text(), 'cloned response');
      expect(upstream.bodyUsed, isTrue);
      expect(clone.bodyUsed, isFalse);
      expect(await clone.text(), 'cloned response');
      expect(clone.bodyUsed, isTrue);
    });

    test('applies init overrides when copying wrapped responses', () async {
      final upstream = Response(
        native.Response(
          'source body',
          native.ResponseInit(
            status: 202,
            statusText: 'Accepted',
            headers: {'x-source': '1'},
          ),
        ),
      );

      final response = Response(
        upstream,
        native.ResponseInit(
          status: 201,
          statusText: 'Created',
          headers: {'x-init': '1'},
        ),
      );

      expect(response.status, io.HttpStatus.created);
      expect(response.statusText, 'Created');
      expect(response.headers.get('x-source'), isNull);
      expect(response.headers.get('x-init'), '1');
      expect(upstream.bodyUsed, isFalse);
      expect(await response.text(), 'source body');
      expect(upstream.bodyUsed, isFalse);
      expect(await upstream.text(), 'source body');
    });

    test('applies init overrides when copying native responses', () async {
      final upstream = native.Response(
        'native body',
        native.ResponseInit(
          status: 202,
          statusText: 'Accepted',
          headers: {'x-source': '1'},
        ),
      );

      final response = Response(
        upstream,
        native.ResponseInit(
          status: 201,
          statusText: 'Created',
          headers: {'x-init': '1'},
        ),
      );

      expect(response.status, io.HttpStatus.created);
      expect(response.statusText, 'Created');
      expect(response.headers.get('x-source'), isNull);
      expect(response.headers.get('x-init'), '1');
      expect(upstream.bodyUsed, isFalse);
      expect(await response.text(), 'native body');
      expect(upstream.bodyUsed, isFalse);
      expect(await upstream.text(), 'native body');
    });

    test(
      'preserves deleted body-derived content-type when copying responses',
      () async {
        final wrapped = Response('wrapped body');
        expect(wrapped.headers.get('content-type'), 'text/plain;charset=UTF-8');

        wrapped.headers.delete('content-type');
        final wrappedCopy = Response(
          wrapped,
          const native.ResponseInit(statusText: 'OK'),
        );

        expect(wrappedCopy.statusText, 'OK');
        expect(wrappedCopy.headers.get('content-type'), isNull);
        expect(wrapped.bodyUsed, isFalse);
        expect(await wrappedCopy.text(), 'wrapped body');
        expect(wrapped.bodyUsed, isFalse);
        expect(await wrapped.text(), 'wrapped body');

        final upstream = native.Response('native body');
        upstream.headers.delete('content-type');
        final nativeCopy = Response(
          upstream,
          const native.ResponseInit(statusText: 'OK'),
        );

        expect(nativeCopy.statusText, 'OK');
        expect(nativeCopy.headers.get('content-type'), isNull);
        expect(upstream.bodyUsed, isFalse);
        expect(await nativeCopy.text(), 'native body');
        expect(upstream.bodyUsed, isFalse);
        expect(await upstream.text(), 'native body');
      },
    );

    test('rejects copying consumed wrapped responses', () async {
      final upstream = Response('used body');

      expect(await upstream.text(), 'used body');
      expect(upstream.bodyUsed, isTrue);
      expect(() => Response(upstream), throwsStateError);
      expect(
        () => Response(upstream, const native.ResponseInit(status: 201)),
        throwsStateError,
      );
    });

    test(
      'copies null-body HttpClientResponse wrappers with init overrides',
      () async {
        final server = await io.HttpServer.bind(
          io.InternetAddress.loopbackIPv4,
          0,
        );
        addTearDown(server.close);

        server.listen((request) {
          request.response
            ..statusCode = io.HttpStatus.noContent
            ..close();
        });

        final client = io.HttpClient();
        addTearDown(client.close);

        final httpRequest = await client.getUrl(
          Uri.parse('http://${server.address.host}:${server.port}/empty'),
        );
        final httpResponse = await httpRequest.close();

        final upstream = Response(httpResponse);

        final response = Response(
          upstream,
          native.ResponseInit(
            statusText: 'No Content',
            headers: {'x-init': '1'},
          ),
        );

        expect(response.status, io.HttpStatus.noContent);
        expect(response.statusText, 'No Content');
        expect(response.headers.get('x-source'), isNull);
        expect(response.headers.get('x-init'), '1');
        expect(response.body, isNull);
        expect(await response.text(), '');
      },
    );

    test('copies raw HttpHeaders before appending body content-type', () async {
      final server = await io.HttpServer.bind(
        io.InternetAddress.loopbackIPv4,
        0,
      );
      addTearDown(server.close);

      server.listen((request) {
        request.response.headers.contentType = null;
        request.response
          ..statusCode = io.HttpStatus.noContent
          ..close();
      });

      final client = io.HttpClient();
      addTearDown(client.close);

      final httpRequest = await client.getUrl(
        Uri.parse('http://${server.address.host}:${server.port}/'),
      );
      final httpResponse = await httpRequest.close();

      final response = native.Response(
        'hello',
        native.ResponseInit(headers: httpResponse.headers),
      );

      expect(response.headers.get('content-type'), 'text/plain;charset=UTF-8');
      expect(httpResponse.headers[io.HttpHeaders.contentTypeHeader], isNull);

      await httpResponse.drain<void>();
    });

    test('enforces native constructor invariants', () {
      expect(
        () => Response(null, const native.ResponseInit(status: 199)),
        throwsRangeError,
      );
      expect(
        () => Response(
          'payload',
          const native.ResponseInit(status: io.HttpStatus.noContent),
        ),
        throwsArgumentError,
      );
    });

    test(
      'wraps HttpClientResponse without copying headers or body eagerly',
      () async {
        final server = await io.HttpServer.bind(
          io.InternetAddress.loopbackIPv4,
          0,
        );

        addTearDown(server.close);

        server.listen((request) {
          request.response.statusCode = io.HttpStatus.created;
          request.response.headers.set('content-type', 'text/plain');
          request.response.headers.set('x-test', 'response-io');
          request.response.write('hello response');
          request.response.close();
        });

        final client = io.HttpClient();
        addTearDown(client.close);

        final httpRequest = await client.getUrl(
          Uri.parse('http://${server.address.host}:${server.port}/'),
        );
        final httpResponse = await httpRequest.close();

        final response = Response(httpResponse);

        expect(response.status, io.HttpStatus.created);
        expect(response.ok, isTrue);
        expect(response.type, native.ResponseType.default_);
        expect(response.redirected, isFalse);
        expect(response.headers.get('content-type'), 'text/plain');
        expect(response.headers.get('x-test'), 'response-io');
        expect(response.bodyUsed, isFalse);
        expect(await response.text(), 'hello response');
        expect(response.bodyUsed, isTrue);
      },
    );

    test('marks redirected when HttpClient followed redirects', () async {
      final server = await io.HttpServer.bind(
        io.InternetAddress.loopbackIPv4,
        0,
      );

      addTearDown(server.close);

      server.listen((request) {
        if (request.uri.path == '/redirect') {
          request.response.statusCode = io.HttpStatus.found;
          request.response.headers.set(io.HttpHeaders.locationHeader, '/final');
          request.response.close();
          return;
        }

        request.response.write('ok');
        request.response.close();
      });

      final client = io.HttpClient();
      addTearDown(client.close);

      final httpRequest = await client.getUrl(
        Uri.parse('http://${server.address.host}:${server.port}/redirect'),
      );
      final httpResponse = await httpRequest.close();

      final response = Response(httpResponse);

      expect(response.redirected, isTrue);
      expect(await response.text(), 'ok');
    });

    test('clones null-body HttpClientResponse statuses without body', () async {
      final server = await io.HttpServer.bind(
        io.InternetAddress.loopbackIPv4,
        0,
      );

      addTearDown(server.close);

      server.listen((request) {
        request.response
          ..statusCode = io.HttpStatus.noContent
          ..close();
      });

      final client = io.HttpClient();
      addTearDown(client.close);

      final httpRequest = await client.getUrl(
        Uri.parse('http://${server.address.host}:${server.port}/empty'),
      );
      final httpResponse = await httpRequest.close();

      final response = Response(httpResponse);
      final clone = response.clone();

      expect(clone.status, io.HttpStatus.noContent);
      expect(clone.body, isNull);
      expect(await clone.text(), '');
    });

    test('clone tees HttpClientResponse body streams', () async {
      final server = await io.HttpServer.bind(
        io.InternetAddress.loopbackIPv4,
        0,
      );

      addTearDown(server.close);

      server.listen((request) {
        request.response.write('cloned response');
        request.response.close();
      });

      final client = io.HttpClient();
      addTearDown(client.close);

      final httpRequest = await client.getUrl(
        Uri.parse('http://${server.address.host}:${server.port}/'),
      );
      final httpResponse = await httpRequest.close();

      final response = Response(httpResponse);
      final clone = response.clone();

      expect(await response.text(), 'cloned response');
      expect(await clone.text(), 'cloned response');
    });
  });
}
