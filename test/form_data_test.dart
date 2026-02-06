import 'dart:convert';

import 'package:ht/ht.dart';
import 'package:test/test.dart';

void main() {
  group('Blob/File/FormData', () {
    test('blob supports text and slice', () async {
      final blob = Blob.text('hello world');
      expect(blob.size, 11);
      expect(await blob.text(), 'hello world');

      final slice = blob.slice(6);
      expect(await slice.text(), 'world');
    });

    test('file stores metadata', () {
      final file = File(<Object>['abc'], 'a.txt', type: 'text/plain');
      expect(file.name, 'a.txt');
      expect(file.type, 'text/plain');
    });

    test('form-data normalizes values and encodes multipart', () {
      final form = FormData();
      form.append('name', 'alice');
      form.append('avatar', Blob.text('binary'), filename: 'a.txt');

      final avatar = form.get('avatar');
      expect(avatar, isA<File>());

      final encoded = form.encodeMultipart(boundary: 'test-boundary');
      final bodyText = utf8.decode(encoded.bytes);

      expect(
          encoded.contentType, 'multipart/form-data; boundary=test-boundary');
      expect(bodyText, contains('name="name"'));
      expect(bodyText, contains('name="avatar"; filename="a.txt"'));
      expect(bodyText, contains('alice'));
      expect(bodyText, contains('binary'));
    });
  });
}
