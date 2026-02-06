import 'package:ht/ht.dart';
import 'package:test/test.dart';

void main() {
  group('MimeType', () {
    test('parses and formats MIME values', () {
      final mime = MimeType.parse('application/json; charset=utf-8');
      expect(mime.type, 'application');
      expect(mime.subtype, 'json');
      expect(mime.parameters['charset'], 'utf-8');
      expect(mime.essence, 'application/json');
    });

    test('resolves extension and sniffs bytes', () {
      final byExtension = MimeType.fromExtension('json');
      expect(byExtension.essence, 'application/json');

      final byBytes = MimeType.fromBytes(
        <int>[137, 80, 78, 71, 13, 10, 26, 10],
      );
      expect(byBytes.essence, 'image/png');
    });

    test('throws for invalid input', () {
      expect(() => MimeType.parse('invalid'), throwsA(isA<FormatException>()));
      expect(
        () => MimeType.fromExtension('unknown-ext-foo'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
