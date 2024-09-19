import 'package:test/test.dart';
import 'package:ht/src/version.dart';

void main() {
  group('Version', () {
    test('should have correct string representations', () {
      expect(Version.http09.value, equals('HTTP/0.9'));
      expect(Version.http10.value, equals('HTTP/1.0'));
      expect(Version.http11.value, equals('HTTP/1.1'));
      expect(Version.http20.value, equals('HTTP/2.0'));
      expect(Version.http30.value, equals('HTTP/3.0'));
    });

    test('should parse valid version strings', () {
      expect(Version.parse('HTTP/0.9'), equals(Version.http09));
      expect(Version.parse('HTTP/1.0'), equals(Version.http10));
      expect(Version.parse('HTTP/1.1'), equals(Version.http11));
      expect(Version.parse('HTTP/2.0'), equals(Version.http20));
      expect(Version.parse('HTTP/3.0'), equals(Version.http30));
    });
  });

  group('Version.parse edge cases', () {
    test('should handle case-insensitive input', () {
      expect(Version.parse('http/1.1'), equals(Version.http11));
      expect(Version.parse('Http/2.0'), equals(Version.http20));
    });

    test('should handle partial version strings', () {
      expect(Version.parse('HTTP/1'), equals(Version.http11));
      expect(Version.parse('HTTP/2'), equals(Version.http20));
    });

    test('should throw ArgumentError for invalid versions', () {
      expect(() => Version.parse('HTTP/4.0'), throwsArgumentError);
      expect(() => Version.parse('Invalid'), throwsArgumentError);
    });
  });
}
