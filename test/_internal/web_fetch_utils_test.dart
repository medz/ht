@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:ht/src/_internal/web_fetch_utils.dart';
import 'package:ht/src/fetch/file.dart';
import 'package:ht/src/fetch/form_data.native.dart';
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  group('web_fetch_utils', () {
    test('preserves web.File lastModified when converting FormData hosts', () {
      const lastModified = 1_710_000_000_000;
      final host = web.FormData()
        ..append(
          'file',
          web.File(
            ['payload'.toJS].toJS,
            'payload.txt',
            web.FilePropertyBag(type: 'text/plain', lastModified: lastModified),
          ),
        );

      final formData = formDataFromWebHost(host);
      final part = formData.get('file');
      final file = part as File;

      expect(part, isA<BlobMultipart>());
      expect(part, isA<File>());
      expect(file.name, 'payload.txt');
      expect(file.lastModified, lastModified);
      expect(file.type, 'text/plain');
    });
  });
}
