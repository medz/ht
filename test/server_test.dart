import 'package:ht/ht.dart';
import 'package:test/test.dart';

void main() {
  group('ServerRequest', () {
    test('wraps request with server metadata', () async {
      final request = ServerRequest(
        url: Uri.parse('https://example.com/users/1'),
        method: 'POST',
        body: 'hello',
        pathParameters: {'id': '1'},
      );

      expect(request.method, 'POST');
      expect(request.pathParameters['id'], '1');
      expect(request.isSecure, isTrue);
      expect(await request.text(), 'hello');
    });
  });

  group('Server middleware', () {
    test('composeMiddleware executes in order', () async {
      final handler = composeMiddleware(
        (request) async {
          final id = request['traceId'];
          return ServerResponse(
              body: 'ok', headers: Headers({'x-trace-id': '$id'}));
        },
        <ServerMiddleware>[
          (request, next) {
            request['traceId'] = 'trace-1';
            return next(request);
          },
        ],
      );

      final response =
          await handler(ServerRequest(url: Uri.parse('http://localhost')));
      expect(response.headers.get('x-trace-id'), 'trace-1');
      expect(await response.text(), 'ok');
    });
  });
}
