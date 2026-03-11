@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:ht/src/fetch/blob.js.dart' as js;
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  group('Blob (js)', () {
    test('accepts native web.Blob parts', () async {
      final part = web.Blob(
        ['hello '.toJS].toJS,
        web.BlobPropertyBag(type: 'text/plain'),
      );

      final blob = js.Blob([part, 'world'], 'text/plain');

      expect(blob.type, 'text/plain');
      expect(await blob.text(), 'hello world');
    });

    test('accepts native web.File parts', () async {
      final part = web.File(
        ['payload'.toJS].toJS,
        'payload.txt',
        web.FilePropertyBag(type: 'text/plain'),
      );

      final blob = js.Blob([part], 'text/plain');

      expect(blob.size, 7);
      expect(await blob.text(), 'payload');
    });
  });
}
