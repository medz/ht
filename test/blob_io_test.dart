@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io' as io;

import 'package:ht/src/fetch/body.dart';
import 'package:ht/src/fetch/blob.io.dart' as io_blob;
import 'package:ht/src/fetch/file.dart' as fetch_file;
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

    test('normalizes MIME type inputs', () {
      expect(
        io_blob.Blob(<Object>['x'], 'TEXT/PLAIN;Charset=UTF-8').type,
        'text/plain;charset=utf-8',
      );
      expect(io_blob.Blob(<Object>['x'], 'NOT A MIME').type, 'not a mime');
      expect(io_blob.Blob(<Object>['x'], 'text/π').type, isEmpty);
      expect(io_blob.Blob(<Object>['x'], 'text/plain\nx').type, isEmpty);

      final blob = io_blob.Blob(<Object>['payload'], 'text/plain');
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

    test(
      'works as a BodyInit value after wrapping dart:io File parts',
      () async {
        final tempDir = await io.Directory.systemTemp.createTemp('ht_blob_io_');
        addTearDown(() async {
          if (await tempDir.exists()) {
            await tempDir.delete(recursive: true);
          }
        });

        final file = io.File('${tempDir.path}/payload.txt');
        await file.writeAsString('hello body');

        final body = Body(io_blob.Blob([file], 'text/plain'));

        expect(await body.text(), 'hello body');
      },
    );

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

    test('captures file length at construction time', () async {
      final tempDir = await io.Directory.systemTemp.createTemp('ht_blob_io_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final file = io.File('${tempDir.path}/payload.txt');
      await file.writeAsString('hello');

      final blob = io_blob.Blob([file], 'text/plain');

      await file.writeAsString('hello world');

      expect(blob.size, 5);
      expect(await blob.text(), 'hello');
    });
  });
}
