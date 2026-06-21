import 'dart:convert';
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

    test('parses quoted multipart boundary values', () async {
      const boundary = 'quoted-boundary';
      final formData = await FormData.parse(
        _bodyBytes([
          '--$boundary\r\n'
              'Content-Disposition: form-data; name="field"\r\n'
              '\r\n'
              'value\r\n'
              '--$boundary--\r\n',
        ]),
        contentType: 'multipart/form-data; boundary="$boundary"',
      );

      expect((formData.get('field')! as TextMultipart).value, 'value');
    });

    test('rejects duplicate content-type boundary parameters', () async {
      const boundary = 'duplicate-boundary';

      await expectLater(
        FormData.parse(
          _bodyBytes(['--$boundary--\r\n']),
          contentType:
              'multipart/form-data; boundary=$boundary; boundary=other',
        ),
        throwsFormatException,
      );
    });

    test('rejects malformed multipart boundary separators', () async {
      const boundary = 'malformed-boundary';

      await expectLater(
        FormData.parse(
          _bodyBytes([
            '--$boundary\n'
                'Content-Disposition: form-data; name="field"\r\n'
                '\r\n'
                'value\r\n'
                '--$boundary--\r\n',
          ]),
          contentType: 'multipart/form-data; boundary=$boundary',
        ),
        throwsFormatException,
      );
    });

    test('rejects multipart parts without content-disposition', () async {
      const boundary = 'missing-disposition-boundary';

      await expectLater(
        FormData.parse(
          _bodyBytes([
            '--$boundary\r\n'
                'Content-Type: text/plain\r\n'
                '\r\n'
                'value\r\n'
                '--$boundary--\r\n',
          ]),
          contentType: 'multipart/form-data; boundary=$boundary',
        ),
        throwsFormatException,
      );
    });

    test('rejects duplicate multipart part headers', () async {
      const boundary = 'duplicate-header-boundary';

      await expectLater(
        FormData.parse(
          _bodyBytes([
            '--$boundary\r\n'
                'Content-Disposition: form-data; name="a"\r\n'
                'Content-Disposition: form-data; name="b"\r\n'
                '\r\n'
                'value\r\n'
                '--$boundary--\r\n',
          ]),
          contentType: 'multipart/form-data; boundary=$boundary',
        ),
        throwsFormatException,
      );
    });

    test('rejects duplicate content-disposition parameters', () async {
      const boundary = 'duplicate-parameter-boundary';

      await expectLater(
        FormData.parse(
          _bodyBytes([
            '--$boundary\r\n'
                'Content-Disposition: form-data; name="a"; name="b"\r\n'
                '\r\n'
                'value\r\n'
                '--$boundary--\r\n',
          ]),
          contentType: 'multipart/form-data; boundary=$boundary',
        ),
        throwsFormatException,
      );
    });

    test('decodes text parts with explicit charset parameters', () async {
      const boundary = 'charset-boundary';
      final formData = await FormData.parse(
        _bodyBytes([
          '--$boundary\r\n'
              'Content-Disposition: form-data; name="title"\r\n'
              'Content-Type: text/plain; charset=iso-8859-1\r\n'
              '\r\n',
          [0x63, 0x61, 0x66, 0xe9],
          '\r\n--$boundary--\r\n',
        ]),
        contentType: 'multipart/form-data; boundary=$boundary',
      );

      expect((formData.get('title')! as TextMultipart).value, 'caf\u00e9');
    });

    test('keeps boundary-like bytes inside binary payloads', () async {
      const boundary = 'binary-boundary';
      final formData = await FormData.parse(
        _bodyBytes([
          '--$boundary\r\n'
              'Content-Disposition: form-data; name="file"; filename="a.bin"\r\n'
              'Content-Type: application/octet-stream\r\n'
              '\r\n'
              'before\r\n'
              '--$boundary-not-a-delimiter\r\n'
              'after\r\n'
              '--$boundary--\r\n',
        ]),
        contentType: 'multipart/form-data; boundary=$boundary',
      );

      final file = formData.get('file')! as BlobMultipart;
      expect(
        await file.text(),
        'before\r\n--$boundary-not-a-delimiter\r\nafter',
      );
    });

    test('keeps closing-boundary-like bytes inside binary payloads', () async {
      const boundary = 'closing-like-boundary';
      final formData = await FormData.parse(
        _bodyBytes([
          '--$boundary\r\n'
              'Content-Disposition: form-data; name="file"; filename="a.bin"\r\n'
              'Content-Type: application/octet-stream\r\n'
              '\r\n'
              'before\r\n'
              '--$boundary--not-a-delimiter\r\n'
              'after\r\n'
              '--$boundary--\r\n',
        ]),
        contentType: 'multipart/form-data; boundary=$boundary',
      );

      final file = formData.get('file')! as BlobMultipart;
      expect(
        await file.text(),
        'before\r\n--$boundary--not-a-delimiter\r\nafter',
      );
    });

    test('parses multipart bodies across stream chunk boundaries', () async {
      const boundary = 'stream-boundary';
      final formData = await FormData.parse(
        _bodyChunks([
          '--str',
          'eam-boundary\r',
          '\nContent-Dis',
          'position: form-data; name="field"\r\n\r\nhe',
          'llo\r',
          '\n--stream-bou',
          'ndary\r\nContent-Disposition: form-data; '
              'name="file"; filename="a.txt"\r\n'
              'Content-Type: text/plain\r\n'
              '\r\npay',
          'load\r\n--stream-bound',
          'ary--',
          '\r\n',
        ]),
        contentType: 'multipart/form-data; boundary=$boundary',
      );

      expect((formData.get('field')! as TextMultipart).value, 'hello');

      final file = formData.get('file')! as BlobMultipart;
      expect(file.filename, 'a.txt');
      expect(file.type, 'text/plain');
      expect(await file.text(), 'payload');
    });

    test('parses closing boundaries split after trailing CR', () async {
      const boundary = 'split-closing-boundary';
      final formData = await FormData.parse(
        _bodyChunks([
          '--$boundary\r\n'
              'Content-Disposition: form-data; name="file"; filename="a.txt"\r\n'
              'Content-Type: text/plain\r\n'
              '\r\npayload\r\n--$boundary--\r',
          '\n',
        ]),
        contentType: 'multipart/form-data; boundary=$boundary',
      );

      final file = formData.get('file')! as BlobMultipart;
      expect(await file.text(), 'payload');
    });

    test('parses RFC 5987 filename star parameters', () async {
      const boundary = 'filename-star-boundary';
      final formData = await FormData.parse(
        _bodyBytes([
          '--$boundary\r\n'
              "Content-Disposition: form-data; name=\"file\"; filename*=UTF-8''caf%C3%A9.txt\r\n"
              'Content-Type: text/plain\r\n'
              '\r\n'
              'payload\r\n'
              '--$boundary--\r\n',
        ]),
        contentType: 'multipart/form-data; boundary=$boundary',
      );

      final file = formData.get('file')! as BlobMultipart;
      expect(file.filename, 'caf\u00e9.txt');
      expect(await file.text(), 'payload');
    });

    test('prefers filename star over filename fallback', () async {
      const boundary = 'filename-priority-boundary';
      final formData = await FormData.parse(
        _bodyBytes([
          '--$boundary\r\n'
              'Content-Disposition: form-data; name="file"; '
              'filename="fallback.txt"; filename*=UTF-8\'\'%E2%82%ACrates.txt\r\n'
              'Content-Type: text/plain\r\n'
              '\r\n'
              'payload\r\n'
              '--$boundary--\r\n',
        ]),
        contentType: 'multipart/form-data; boundary=$boundary',
      );

      expect(
        (formData.get('file')! as BlobMultipart).filename,
        '\u20acrates.txt',
      );
    });

    test('rejects multipart parts without form-data disposition', () async {
      const boundary = 'invalid-disposition-boundary';

      await expectLater(
        FormData.parse(
          _bodyBytes([
            '--$boundary\r\n'
                'Content-Disposition: attachment; name="file"; filename="a.txt"\r\n'
                '\r\n'
                'payload\r\n'
                '--$boundary--\r\n',
          ]),
          contentType: 'multipart/form-data; boundary=$boundary',
        ),
        throwsFormatException,
      );
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
            (FormData()..append(
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
    test('generates a default multipart boundary', () async {
      final encoded = (FormData()..append('name', const Multipart.text('ht')))
          .encodeMultipart();

      expect(encoded.boundary, startsWith('----ht-'));
      expect(encoded.boundary, matches(RegExp(r'^----ht-[a-z0-9]+$')));
      expect(
        encoded.contentType,
        'multipart/form-data; boundary=${encoded.boundary}',
      );

      final bytes = await encoded.bytes();
      expect(bytes.length, encoded.contentLength);

      final parsed = await FormData.parse(
        Body(encoded.stream),
        contentType: encoded.contentType,
      );
      expect((parsed.get('name')! as TextMultipart).value, 'ht');
    });

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

Body _bodyBytes(List<Object> parts) {
  final builder = BytesBuilder(copy: false);
  for (final part in parts) {
    switch (part) {
      case final String value:
        builder.add(ascii.encode(value));
      case final List<int> value:
        builder.add(value);
      default:
        throw ArgumentError.value(part, 'parts', 'Unsupported test body part.');
    }
  }
  return Body(builder.takeBytes());
}

Body _bodyChunks(List<String> chunks) {
  return Body(Stream<List<int>>.fromIterable(chunks.map(ascii.encode)));
}
