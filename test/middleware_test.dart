import 'package:ht/ht.dart';
import 'package:test/test.dart';

void main() {
  group('Fetch middleware', () {
    test('composeFetchMiddleware executes in order', () async {
      final app = composeFetchMiddleware(
        (request) async => Response.text('ok'),
        <FetchMiddleware>[
          (request, next) async {
            final response = await next(request);
            response.headers.set('x-trace-id', 'trace-1');
            return response;
          },
        ],
      );

      final response = await app(Request(Uri.parse('http://localhost')));
      expect(response.headers.get('x-trace-id'), 'trace-1');
      expect(await response.text(), 'ok');
    });

    test('middleware can short-circuit downstream handler', () async {
      final app = composeFetchMiddleware(
        (request) => Response.text('downstream'),
        <FetchMiddleware>[
          (request, next) {
            if (request.url.path == '/health') {
              return Response.text('healthy');
            }
            return next(request);
          },
        ],
      );

      final healthResponse =
          await app(Request(Uri.parse('http://localhost/health')));
      final normalResponse =
          await app(Request(Uri.parse('http://localhost/api')));

      expect(await healthResponse.text(), 'healthy');
      expect(await normalResponse.text(), 'downstream');
    });
  });
}
