@TestOn('vm')
library;

import 'dart:io';

import 'package:ht/src/fetch/headers.io.dart';
import 'package:test/test.dart';

void main() {
  group('Headers (io)', () {
    test('constructor from Headers creates independent copy', () {
      final original = Headers({'x-test': '1'});
      final copy = Headers(original)..set('x-test', '2');

      expect(original.get('x-test'), '1');
      expect(copy.get('x-test'), '2');
    });

    test('combines iteration from dart:io HttpHeaders hosts', () async {
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
        ..add('x-b', 'b1')
        ..add('X-A', 'a1')
        ..add('x-a', 'a2')
        ..add('x-multi', 'one')
        ..add('x-multi', 'two')
        ..add(HttpHeaders.setCookieHeader, 's1=1')
        ..add(HttpHeaders.setCookieHeader, 's2=2');

      final headers = Headers(clientRequest.headers);
      expect(headers.has('x-multi'), isTrue);
      expect(headers.get('x-multi'), 'one, two');
      expect(headers.get('missing'), isNull);
      expect(headers.getSetCookie(), ['s1=1', 's2=2']);
      final testedNames = {'set-cookie', 'x-a', 'x-b', 'x-multi'};
      final testedEntries = headers
          .where((entry) => testedNames.contains(entry.key))
          .toList();
      expect(testedEntries.map((entry) => '${entry.key}:${entry.value}'), [
        'set-cookie:s1=1',
        'set-cookie:s2=2',
        'x-a:a1, a2',
        'x-b:b1',
        'x-multi:one, two',
      ]);
      expect(headers.keys().where(testedNames.contains).toList(), [
        'set-cookie',
        'set-cookie',
        'x-a',
        'x-b',
        'x-multi',
      ]);
      expect(
        headers.values().toList(),
        containsAllInOrder(['s1=1', 's2=2', 'a1, a2', 'b1', 'one, two']),
      );

      final clientResponseFuture = clientRequest.close();
      final serverRequest = await serverRequestFuture;
      await serverRequest.response.close();
      final clientResponse = await clientResponseFuture;
      await clientResponse.drain<void>();
    });
  });
}
