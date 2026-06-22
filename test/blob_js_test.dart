@TestOn('browser')
library;

import 'dart:js_interop';

import 'package:ht/src/_internal/web_fetch_utils.dart' as web_fetch;
import 'package:ht/src/fetch/blob.js.dart' as js;
import 'package:ht/src/fetch/file.dart' as fetch_file;
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

    test('normalizes MIME type inputs', () {
      expect(
        js.Blob(<Object>['x'], 'TEXT/PLAIN;Charset=UTF-8').type,
        'text/plain;charset=utf-8',
      );
      expect(js.Blob(<Object>['x'], 'NOT A MIME').type, 'not a mime');
      expect(js.Blob(<Object>['x'], 'text/π').type, isEmpty);
      expect(js.Blob(<Object>['x'], 'text/plain\nx').type, isEmpty);

      final blob = js.Blob(<Object>['payload'], 'text/plain');
      expect(blob.slice(0, 1).type, isEmpty);
      expect(blob.slice(0, 1, 'TEXT/HTML').type, 'text/html');
      expect(blob.slice(0, 1, 'text/π').type, isEmpty);

      expect(
        fetch_file.File(<Object>['x'], 'x.txt', type: 'TEXT/PLAIN').type,
        'text/plain',
      );
      expect(
        fetch_file.File(<Object>['x'], 'x.txt', type: 'text/π').type,
        isEmpty,
      );
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

    test(
      'preserves host blob MIME type when no override is provided',
      () async {
        final response = web.Response(
          'payload'.toJS,
          web.ResponseInit(
            headers: {'content-type': 'text/plain'}.jsify()! as web.HeadersInit,
          ),
        );

        final blob = await web_fetch.blobFromWebPromise(response.blob());

        expect(blob.type, 'text/plain');
        expect(await blob.text(), 'payload');
      },
    );
  });
}
