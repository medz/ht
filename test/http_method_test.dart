import 'package:ht/ht.dart';
import 'package:test/test.dart';

void main() {
  group('HttpMethod', () {
    test('parses method strings', () {
      expect(HttpMethod.parse('get'), HttpMethod.get);
      expect(HttpMethod.parse('POST'), HttpMethod.post);
    });

    test('validates unknown methods', () {
      expect(() => HttpMethod.parse('UNKNOWN'), throwsArgumentError);
    });

    test('reports body support', () {
      expect(HttpMethod.get.allowsRequestBody, isFalse);
      expect(HttpMethod.post.allowsRequestBody, isTrue);
    });
  });
}
