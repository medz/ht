import 'dart:typed_data';

import 'package:ht/src/fetch/body.dart';
import 'package:ht/src/fetch/blob.dart';
import 'package:ht/src/fetch/form_data.native.dart';
import 'package:ht/src/fetch/headers.dart';
import 'package:test/test.dart';

void main() {
  group('FormData.parse (native)', () {
    test('parses application/x-www-form-urlencoded bodies', () async {
      final formData = await FormData.parse(
        Body('a=1&a=2&hello=world+x'),
        contentType: 'application/x-www-form-urlencoded',
      );

      expect(formData.get('a'), isA<TextMultipart>());
      expect((formData.get('a')! as TextMultipart).value, '1');
      expect(
        formData.getAll('a').map((value) => (value as TextMultipart).value),
        ['1', '2'],
      );
      expect((formData.get('hello')! as TextMultipart).value, 'world x');
    });

    test(
      'accepts content-type parameters when parsing urlencoded bodies',
      () async {
        final formData = await FormData.parse(
          Body('name=seven+du'),
          contentType: 'application/x-www-form-urlencoded; charset=utf-8',
        );

        expect((formData.get('name')! as TextMultipart).value, 'seven du');
      },
    );

    test('parses multipart/form-data text entries', () async {
      final encoded =
          (FormData()
                ..append('a', Multipart.text('1'))
                ..append('a', Multipart.text('2'))
                ..append('hello', Multipart.text('world')))
              .encodeMultipart(boundary: 'test-boundary');

      final formData = await FormData.parse(
        Body(encoded.stream),
        contentType: encoded.contentType,
      );

      expect(formData.get('a'), isA<TextMultipart>());
      expect((formData.get('a')! as TextMultipart).value, '1');
      expect(
        formData.getAll('a').map((value) => (value as TextMultipart).value),
        ['1', '2'],
      );
      expect((formData.get('hello')! as TextMultipart).value, 'world');
    });

    test('parses multipart/form-data blob entries', () async {
      final encoded =
          (FormData()
                ..append('title', Multipart.text('avatar'))
                ..append(
                  'file',
                  Multipart.blob(
                    Blob(<BlobPart>['binary'], 'text/plain;charset=utf-8'),
                    'a.txt',
                  ),
                ))
              .encodeMultipart(boundary: 'blob-boundary');

      final formData = await FormData.parse(
        Body(encoded.stream),
        contentType: encoded.contentType,
      );

      expect((formData.get('title')! as TextMultipart).value, 'avatar');

      final file = formData.get('file');
      expect(file, isA<BlobMultipart>());
      final blob = file! as BlobMultipart;
      expect(blob.filename, 'a.txt');
      expect(blob.type, 'text/plain;charset=utf-8');
      expect(await blob.text(), 'binary');
    });

    test('parses quoted multipart parameters containing semicolons', () async {
      const boundary = 'quoted-boundary';
      final body = Body(
        '--$boundary\r\n'
        'Content-Disposition: form-data; name="file"; filename="a;b.txt"\r\n'
        'Content-Type: text/plain\r\n'
        '\r\n'
        'payload\r\n'
        '--$boundary--\r\n',
      );

      final formData = await FormData.parse(
        body,
        contentType: 'multipart/form-data; boundary=$boundary',
      );

      final part = formData.get('file');
      expect(part, isA<BlobMultipart>());
      expect((part as BlobMultipart).filename, 'a;b.txt');
      expect(await part.text(), 'payload');
    });

    test(
      'does not unescape plain text CRLF sequences in quoted parameters',
      () async {
        const boundary = 'escaped-boundary';
        final body = Body(
          '--$boundary\r\n'
          'Content-Disposition: form-data; name="file"; filename="a\\nb.txt"\r\n'
          'Content-Type: text/plain\r\n'
          '\r\n'
          'payload\r\n'
          '--$boundary--\r\n',
        );

        final formData = await FormData.parse(
          body,
          contentType: 'multipart/form-data; boundary=$boundary',
        );

        final part = formData.get('file');
        expect(part, isA<BlobMultipart>());
        expect((part as BlobMultipart).filename, r'a\nb.txt');
        expect(await part.text(), 'payload');
      },
    );

    test(
      'preserves literal backslash-quote sequences in quoted parameters',
      () async {
        final encoded =
            (FormData()
                  ..append(
                    'file',
                    Multipart.blob(
                      Blob(<BlobPart>['payload'], 'text/plain'),
                      'a\\"b.txt',
                    ),
                  ))
                .encodeMultipart(boundary: 'quote-escape-boundary');

        final formData = await FormData.parse(
          Body(encoded.stream),
          contentType: encoded.contentType,
        );

        final part = formData.get('file');
        expect(part, isA<BlobMultipart>());
        expect((part as BlobMultipart).filename, 'a\\"b.txt');
        expect(await part.text(), 'payload');
      },
    );
  });

  group('FormData.encodeMultipart (native)', () {
    test('returns encoded multipart metadata and payload', () async {
      final encoded =
          (FormData()
                ..append('name', Multipart.text('alice'))
                ..append(
                  'avatar',
                  Multipart.blob(
                    Blob(<BlobPart>['binary'], 'text/plain;charset=utf-8'),
                    'a.txt',
                  ),
                ))
              .encodeMultipart(boundary: 'native-boundary');

      final headers = Headers();
      encoded.applyTo(headers);

      expect(
        headers.get('content-type'),
        'multipart/form-data; boundary=native-boundary',
      );
      expect(headers.get('content-length'), encoded.contentLength.toString());

      final bytes = await encoded.bytes();
      final fromStream = BytesBuilder(copy: false);
      await for (final chunk in encoded.stream) {
        fromStream.add(chunk);
      }

      expect(fromStream.takeBytes(), bytes);
    });
  });

  group('FormData mutation semantics (native)', () {
    test('set replaces the first matching entry in place', () {
      final formData = FormData()
        ..append('a', Multipart.text('1'))
        ..append('b', Multipart.text('2'))
        ..append('a', Multipart.text('3'))
        ..set('a', Multipart.text('x'));

      final entries = formData
          .entries()
          .map((entry) => (entry.key, (entry.value as TextMultipart).value))
          .toList();

      expect(entries, [('a', 'x'), ('b', '2')]);
    });
  });
}
