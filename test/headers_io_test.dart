@TestOn('vm')
library;

import 'dart:io';

import 'package:ht/src/fetch/headers.io.dart';
import 'package:test/test.dart';

void main() {
  group('Headers (io)', () {
    test('joins repeated values from dart:io HttpHeaders hosts', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final client = HttpClient();
      addTearDown(() async {
        client.close(force: true);
        await server.close(force: true);
      });

      final serverRequestFuture = server.first;
      final clientRequest = await client.get(
        InternetAddress.loopbackIPv4.host,
        server.port,
        '/headers',
      );
      clientRequest.headers
        ..add('x-multi', 'one')
        ..add('x-multi', 'two');

      final headers = Headers(clientRequest.headers);
      expect(headers.has('x-multi'), isTrue);
      expect(headers.get('x-multi'), 'one, two');
      expect(headers.get('missing'), isNull);

      final clientResponseFuture = clientRequest.close();
      final serverRequest = await serverRequestFuture;
      await serverRequest.response.close();
      final clientResponse = await clientResponseFuture;
      await clientResponse.drain<void>();
    });
  });
}
