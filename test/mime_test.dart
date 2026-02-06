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
      expect(mime.toString(), 'application/json; charset=utf-8');
    });

    test('normalizes constructor values and keeps parameters unmodifiable', () {
      final mime = MimeType('Text', 'Plain', {'Charset': 'utf-8'});
      expect(mime.type, 'text');
      expect(mime.subtype, 'plain');
      expect(() => mime.parameters['x'] = '1', throwsUnsupportedError);
    });

    test('supports withParameter immutable updates', () {
      final original = MimeType.json;
      final next = original.withParameter('charset', 'utf-8');

      expect(original.parameters.containsKey('charset'), isFalse);
      expect(next.parameters['charset'], 'utf-8');
      expect(next.toString(), 'application/json; charset=utf-8');
    });

    test('uses value equality and stable hashCode', () {
      final a = MimeType.parse('application/json; charset=utf-8');
      final b = MimeType('application', 'json', {'charset': 'utf-8'});
      final c = MimeType('application', 'json');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == c, isFalse);
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
      expect(
        () => MimeType.fromBytes(<int>[1, 2, 3, 4]),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
