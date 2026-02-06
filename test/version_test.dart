import 'package:ht/ht.dart';
import 'package:test/test.dart';

void main() {
  group('HttpVersion', () {
    test('prints wire values', () {
      expect(HttpVersion.http11.value, 'HTTP/1.1');
      expect(HttpVersion.http20.value, 'HTTP/2.0');
    });

    test('parses standard values', () {
      expect(HttpVersion.parse('HTTP/1.1'), HttpVersion.http11);
      expect(HttpVersion.parse('http/2.0'), HttpVersion.http20);
      expect(HttpVersion.parse('h3'), HttpVersion.http30);
    });

    test('throws for unsupported values', () {
      expect(() => HttpVersion.parse('HTTP/4.0'), throwsArgumentError);
    });
  });
}
