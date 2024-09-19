import 'package:test/test.dart';
import 'package:ht/src/mime.dart';

void main() {
  group('MimeType', () {
    group('Construction and Parsing', () {
      test('should create MimeType with base and sub', () {
        final mime = MimeType('text', 'plain');
        expect(mime.base, equals('text'));
        expect(mime.sub, equals('plain'));
        expect(mime.essence, equals('text/plain'));
      });

      test('should create MimeType with base, sub, and parameters', () {
        final mime = MimeType('text', 'plain', {'charset': 'utf-8'});
        expect(mime.base, equals('text'));
        expect(mime.sub, equals('plain'));
        expect(mime.essence, equals('text/plain'));
        expect(mime.params, equals({'charset': 'utf-8'}));
      });

      test('should parse MimeType from string', () {
        final mime = MimeType.parse('application/json');
        expect(mime.base, equals('application'));
        expect(mime.sub, equals('json'));
        expect(mime.essence, equals('application/json'));
      });

      test('should parse MimeType with parameters', () {
        final mime = MimeType.parse('application/json; charset=utf-8');
        expect(mime.base, equals('application'));
        expect(mime.sub, equals('json'));
        expect(mime.essence, equals('application/json'));
        expect(mime.params, equals({'charset': 'utf-8'}));
      });

      test('should throw MimeTypeCreateFailException for invalid input', () {
        expect(() => MimeType.parse('invalid'),
            throwsA(isA<MimeTypeCreateFailException>()));
      });

      test('should throw MimeTypeCreateFailException for empty string', () {
        expect(() => MimeType.parse(''),
            throwsA(isA<MimeTypeCreateFailException>()));
      });
    });

    group('Factory Methods', () {
      test('should create MimeType from bytes', () {
        final pngBytes = [137, 80, 78, 71, 13, 10, 26, 10]; // PNG magic numbers
        final mime = MimeType.bytes(pngBytes);
        expect(mime.base, equals('image'));
        expect(mime.sub, equals('png'));
      });

      test('should throw MimeTypeCreateFailException for unrecognized bytes',
          () {
        expect(() => MimeType.bytes([0, 1, 2, 3]),
            throwsA(isA<MimeTypeCreateFailException>()));
      });

      test('should create MimeType from extension', () {
        final mime = MimeType.fromExtension('json');
        expect(mime.base, equals('application'));
        expect(mime.sub, equals('json'));
      });

      test('should throw MimeTypeCreateFailException for unknown extension',
          () {
        expect(() => MimeType.fromExtension('unknown'),
            throwsA(isA<MimeTypeCreateFailException>()));
      });
    });

    group('Predefined Types', () {
      test('should have correct predefined MIME types', () {
        expect(MimeType.any.essence, equals('*/*'));
        expect(MimeType.javascript.essence, equals('text/javascript'));
        expect(MimeType.css.essence, equals('text/css'));
        expect(MimeType.html.essence, equals('text/html'));
        expect(MimeType.plain.essence, equals('text/plain'));
        expect(MimeType.xml.essence, equals('application/xml'));
        expect(MimeType.json.essence, equals('application/json'));
        expect(MimeType.byteStream.essence, equals('application/octet-stream'));
        expect(
            MimeType.form.essence, equals('application/x-www-form-urlencoded'));
        expect(MimeType.formData.essence, equals('multipart/form-data'));
        expect(MimeType.jpeg.essence, equals('image/jpeg'));
        expect(MimeType.png.essence, equals('image/png'));
        expect(MimeType.mp3.essence, equals('audio/mpeg'));
        expect(MimeType.mp4.essence, equals('video/mp4'));
        expect(MimeType.woff.essence, equals('font/woff'));
        expect(MimeType.zip.essence, equals('application/zip'));
      });
    });

    group('Properties', () {
      test('should access MIME type properties', () {
        final mime = MimeType('application', 'json', {'charset': 'utf-8'});
        expect(mime.base, equals('application'));
        expect(mime.sub, equals('json'));
        expect(mime.essence, equals('application/json'));
        expect(mime.params, equals({'charset': 'utf-8'}));
      });
    });
  });
}
