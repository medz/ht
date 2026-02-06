import 'package:ht/ht.dart';
import 'package:test/test.dart';

void main() {
  group('HttpStatus', () {
    test('returns reason phrase', () {
      expect(HttpStatus.reasonPhrase(200), 'OK');
      expect(HttpStatus.reasonPhrase(499), '');
    });

    test('categorizes status codes', () {
      expect(HttpStatus.isSuccess(204), isTrue);
      expect(HttpStatus.isClientError(404), isTrue);
      expect(HttpStatus.isServerError(503), isTrue);
    });

    test('validates range', () {
      expect(() => HttpStatus.validate(99), throwsArgumentError);
      expect(() => HttpStatus.validate(600), throwsArgumentError);
      expect(() => HttpStatus.validate(200), returnsNormally);
    });
  });
}
