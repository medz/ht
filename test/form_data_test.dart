import 'dart:convert';
import 'dart:typed_data';

import 'package:ht/ht.dart';
import 'package:test/test.dart';

void main() {
  group('Blob', () {
    test('supports text, bytes and slice', () async {
      final blob = Blob.text('hello world');
      expect(blob.size, 11);
      expect(await blob.text(), 'hello world');

      final slice = blob.slice(6);
      expect(await slice.text(), 'world');
    });

    test('concatenates mixed part types', () async {
      final blob = Blob(<Object>[
        'ab',
        Uint8List.fromList(<int>[99]),
        Uint8List.fromList(<int>[100]).buffer,
        Blob.text('ef'),
      ], ' TEXT/PLAIN ');

      expect(await blob.text(), 'abcdef');
      expect(blob.type, 'text/plain');
    });

    test('streams with chunk size', () async {
      final blob = Blob.text('hello');
      final chunks = await blob
          .stream(chunkSize: 2)
          .map((chunk) => utf8.decode(chunk))
          .toList();
      expect(chunks, ['he', 'll', 'o']);
    });

    test('rejects invalid types and chunk size', () async {
      expect(
        () => Blob.text('x', type: 'text/plain\nfoo'),
        throwsArgumentError,
      );
      await expectLater(
        Blob.text('x').stream(chunkSize: 0).toList(),
        throwsArgumentError,
      );
    });

    test('rejects unsupported part types', () {
      expect(() => Blob(<Object>[DateTime(2024)]), throwsArgumentError);
    });
  });

  group('File', () {
    test('stores metadata', () {
      final file = File(<Object>['abc'], 'a.txt', type: 'text/plain');
      expect(file.name, 'a.txt');
      expect(file.type, 'text/plain');
      expect(file.lastModified, greaterThan(0));
    });
  });

  group('FormData', () {
    test('normalizes values and encodes multipart', () {
      final form = FormData()
        ..append('name', 'alice')
        ..append('avatar', Blob.text('binary'), filename: 'a.txt');

      final avatar = form.get('avatar');
      expect(avatar, isA<File>());

      final encoded = form.encodeMultipart(boundary: 'test-boundary');
      final bodyText = utf8.decode(encoded.bytes);

      expect(
        encoded.contentType,
        'multipart/form-data; boundary=test-boundary',
      );
      expect(encoded.contentLength, encoded.bytes.length);
      expect(bodyText, contains('name="name"'));
      expect(bodyText, contains('name="avatar"; filename="a.txt"'));
      expect(bodyText, contains('alice'));
      expect(bodyText, contains('binary'));
      expect(bodyText.endsWith('--test-boundary--\r\n'), isTrue);
    });

    test('set and delete provide deterministic mutations', () {
      final form = FormData()
        ..append('a', '1')
        ..append('a', '2')
        ..set('a', '3');

      expect(form.getAll('a'), ['3']);
      expect(form.has('a'), isTrue);

      form.delete('a');
      expect(form.has('a'), isFalse);
      expect(form.get('a'), isNull);
    });

    test('normalizes blob and scalar values', () {
      final form = FormData()
        ..append('count', 42)
        ..append('payload', Blob.text('x'))
        ..append('avatar', File(<Object>['a'], 'old.txt'), filename: 'new.txt');

      expect(form.get('count'), '42');

      final payload = form.get('payload')! as File;
      expect(payload.name, 'blob');

      final avatar = form.get('avatar')! as File;
      expect(avatar.name, 'new.txt');
    });

    test('clone is independent for entry mutations', () {
      final form = FormData()..append('a', '1');

      final clone = form.clone()..set('a', '2');

      expect(form.get('a'), '1');
      expect(clone.get('a'), '2');
    });

    test('escapes multipart header values', () {
      final form = FormData()
        ..append('na"me', Blob.text('x'), filename: 'fi\r\nle.txt');

      final encoded = form.encodeMultipart(boundary: 'b');
      final text = utf8.decode(encoded.bytes);

      expect(text, contains('name="na\\"me"'));
      expect(text, contains('filename="fi\\r\\nle.txt"'));
    });
  });
}
