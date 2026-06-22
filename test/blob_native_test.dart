@TestOn('vm')
library;

import 'package:ht/src/fetch/blob.native.dart' as native;
import 'package:test/test.dart';

void main() {
  group('Blob (native)', () {
    test('normalizes MIME type inputs', () {
      expect(
        native.Blob(<native.BlobPart>['x'], 'TEXT/PLAIN;Charset=UTF-8').type,
        'text/plain;charset=utf-8',
      );
      expect(
        native.Blob(<native.BlobPart>['x'], 'NOT A MIME').type,
        'not a mime',
      );
      expect(native.Blob(<native.BlobPart>['x'], 'text/π').type, isEmpty);
      expect(
        native.Blob(<native.BlobPart>['x'], 'text/plain\nx').type,
        isEmpty,
      );
    });

    test('normalizes slice content type inputs', () {
      final blob = native.Blob(<native.BlobPart>['payload'], 'text/plain');

      expect(blob.slice(0, 1).type, isEmpty);
      expect(blob.slice(0, 1, 'TEXT/HTML').type, 'text/html');
      expect(blob.slice(0, 1, 'text/π').type, isEmpty);
      expect(blob.slice(0, 1, 'text/plain\nx').type, isEmpty);
    });
  });
}
