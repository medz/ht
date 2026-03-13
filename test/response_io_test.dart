import 'dart:io' as io;

import 'package:ht/src/fetch/response.io.dart';
import 'package:ht/src/fetch/response.native.dart' as native;
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
