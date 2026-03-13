@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io' as io;

import 'package:ht/src/fetch/blob.io.dart' as io_blob;
import 'package:test/test.dart';

void main() {
  group('Blob (io)', () {
    test('accepts dart:io File parts lazily', () async {
      final tempDir = await io.Directory.systemTemp.createTemp('ht_blob_io_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final file = io.File('${tempDir.path}/payload.txt');
      await file.writeAsString('hello world');

      final blob = io_blob.Blob([file], 'text/plain');

      expect(blob.size, 11);
      expect(blob.type, 'text/plain');
      expect(await blob.text(), 'hello world');
    });

    test('slice reads the requested file range', () async {
      final tempDir = await io.Directory.systemTemp.createTemp('ht_blob_io_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final file = io.File('${tempDir.path}/payload.txt');
      await file.writeAsString('abcdef');

      final blob = io_blob.Blob([file], 'text/plain');
      final slice = blob.slice(1, 4);

      expect(slice.size, 3);
      expect(await slice.text(), 'bcd');
    });

    test('stream respects chunkSize', () async {
      final tempDir = await io.Directory.systemTemp.createTemp('ht_blob_io_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final file = io.File('${tempDir.path}/payload.txt');
      await file.writeAsString('hello');

      final blob = io_blob.Blob([file], 'text/plain');
      final chunks = await blob.stream(chunkSize: 2).map(utf8.decode).toList();

      expect(chunks, ['he', 'll', 'o']);
    });
  });
}
