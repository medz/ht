import 'package:ht/ht.dart';
import 'package:test/test.dart';

void main() {
  group('HttpMethod', () {
    test('parses method strings case-insensitively', () {
      expect(HttpMethod.parse('get'), HttpMethod.get);
      expect(HttpMethod.parse('POST'), HttpMethod.post);
      expect(HttpMethod.parse('  patch  '), HttpMethod.patch);
    });

    test('validates unknown methods', () {
      expect(() => HttpMethod.parse('UNKNOWN'), throwsArgumentError);
    });

    test('reports body support', () {
      expect(HttpMethod.get.allowsRequestBody, isFalse);
      expect(HttpMethod.head.allowsRequestBody, isFalse);
      expect(HttpMethod.trace.allowsRequestBody, isFalse);
      expect(HttpMethod.post.allowsRequestBody, isTrue);
    });

    test('toString outputs wire value', () {
      expect(HttpMethod.delete.toString(), 'DELETE');
    });
  });
}
