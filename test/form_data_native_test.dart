import 'package:ht/src/fetch/body.dart';
import 'package:ht/src/fetch/blob.dart';
import 'package:ht/src/fetch/form_data.dart' as legacy;
import 'package:ht/src/fetch/form_data.native.dart';
import 'package:test/test.dart';

void main() {
  group('FormData.parse (native)', () {
    test('parses application/x-www-form-urlencoded bodies', () async {
      final formData = await FormData.parse(
        Body('a=1&a=2&hello=world+x'),
        contentType: 'application/x-www-form-urlencoded',
      );

      expect(formData.get('a'), isA<TextMultipartBody>());
      expect((formData.get('a')! as TextMultipartBody).value, '1');
      expect(
        formData.getAll('a').map((value) => (value as TextMultipartBody).value),
        ['1', '2'],
      );
      expect((formData.get('hello')! as TextMultipartBody).value, 'world x');
    });

    test(
      'accepts content-type parameters when parsing urlencoded bodies',
      () async {
        final formData = await FormData.parse(
          Body('name=seven+du'),
          contentType: 'application/x-www-form-urlencoded; charset=utf-8',
        );

        expect((formData.get('name')! as TextMultipartBody).value, 'seven du');
      },
    );

    test('parses multipart/form-data text entries', () async {
      final encoded =
          (legacy.FormData()
                ..append('a', '1')
                ..append('a', '2')
                ..append('hello', 'world'))
              .encodeMultipart(boundary: 'test-boundary');

      final formData = await FormData.parse(
        Body(encoded.stream),
        contentType: encoded.contentType,
      );

      expect(formData.get('a'), isA<TextMultipartBody>());
      expect((formData.get('a')! as TextMultipartBody).value, '1');
      expect(
        formData.getAll('a').map((value) => (value as TextMultipartBody).value),
        ['1', '2'],
      );
      expect((formData.get('hello')! as TextMultipartBody).value, 'world');
    });

    test('parses multipart/form-data blob entries', () async {
      final encoded =
          (legacy.FormData()
                ..append('title', 'avatar')
                ..append(
                  'file',
                  Blob(<BlobPart>['binary'], 'text/plain;charset=utf-8'),
                  filename: 'a.txt',
                ))
              .encodeMultipart(boundary: 'blob-boundary');

      final formData = await FormData.parse(
        Body(encoded.stream),
        contentType: encoded.contentType,
      );

      expect((formData.get('title')! as TextMultipartBody).value, 'avatar');

      final file = formData.get('file');
      expect(file, isA<BlobMultipartBody>());
      final blob = file! as BlobMultipartBody;
      expect(blob.filename, 'a.txt');
      expect(blob.type, 'text/plain;charset=utf-8');
      expect(await blob.text(), 'binary');
    });
  });
}
