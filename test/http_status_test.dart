import 'package:ht/ht.dart';
import 'package:test/test.dart';

void main() {
  group('HttpStatus', () {
    test('returns reason phrases for known and unknown values', () {
      expect(HttpStatus.reasonPhrase(200), 'OK');
      expect(HttpStatus.reasonPhrase(204), 'No Content');
      expect(HttpStatus.reasonPhrase(499), '');
    });

    test('categorizes status classes with boundaries', () {
      expect(HttpStatus.isInformational(100), isTrue);
      expect(HttpStatus.isInformational(199), isTrue);
      expect(HttpStatus.isInformational(200), isFalse);

      expect(HttpStatus.isSuccess(200), isTrue);
      expect(HttpStatus.isSuccess(299), isTrue);
      expect(HttpStatus.isSuccess(300), isFalse);

      expect(HttpStatus.isRedirection(300), isTrue);
      expect(HttpStatus.isRedirection(399), isTrue);
      expect(HttpStatus.isRedirection(400), isFalse);

      expect(HttpStatus.isClientError(400), isTrue);
      expect(HttpStatus.isClientError(499), isTrue);
      expect(HttpStatus.isClientError(500), isFalse);

      expect(HttpStatus.isServerError(500), isTrue);
      expect(HttpStatus.isServerError(599), isTrue);
      expect(HttpStatus.isServerError(600), isFalse);
    });

    test('validates allowed status-code range', () {
      expect(() => HttpStatus.validate(99), throwsArgumentError);
      expect(() => HttpStatus.validate(600), throwsArgumentError);
      expect(() => HttpStatus.validate(100), returnsNormally);
      expect(() => HttpStatus.validate(599), returnsNormally);
    });
  });
}
