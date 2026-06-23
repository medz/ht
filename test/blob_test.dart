import 'dart:convert';
import 'dart:typed_data';

import 'package:ht/src/fetch/blob.dart' as platform_blob;
import 'package:test/test.dart';

void main() {
  group('Blob', () {
    test('snapshots byte parts at construction', () async {
      final typedBytes = Uint8List.fromList(utf8.encode('ab'));
      final bufferBytes = Uint8List.fromList(utf8.encode('cd'));
      final dataBytes = Uint8List.fromList(utf8.encode('-ef-'));
      final data = ByteData.sublistView(dataBytes, 1, 3);
      final listBytes = <int>[...utf8.encode('gh')];

      final blob = platform_blob.Blob(<platform_blob.BlobPart>[
        typedBytes,
        bufferBytes.buffer,
        data,
        listBytes,
      ]);

      typedBytes[0] = 'x'.codeUnitAt(0);
      bufferBytes[0] = 'y'.codeUnitAt(0);
      dataBytes[1] = 'z'.codeUnitAt(0);
      listBytes[0] = 'w'.codeUnitAt(0);

      expect(await blob.text(), 'abcdefgh');

      final singleBufferBytes = Uint8List.fromList(utf8.encode('ij'));
      final singleBufferBlob = platform_blob.Blob(<platform_blob.BlobPart>[
        singleBufferBytes.buffer,
      ]);
      singleBufferBytes[0] = 'x'.codeUnitAt(0);
      expect(await singleBufferBlob.text(), 'ij');

      final singleDataBytes = Uint8List.fromList(utf8.encode('-kl-'));
      final singleDataBlob = platform_blob.Blob(<platform_blob.BlobPart>[
        ByteData.sublistView(singleDataBytes, 1, 3),
      ]);
      singleDataBytes[1] = 'y'.codeUnitAt(0);
      expect(await singleDataBlob.text(), 'kl');
    });

    test('arrayBuffer and bytes return defensive copies', () async {
      final blob = platform_blob.Blob(<platform_blob.BlobPart>[
        Uint8List.fromList(utf8.encode('abc')),
      ]);

      final buffer = await blob.arrayBuffer();
      buffer[0] = 'x'.codeUnitAt(0);

      expect(await blob.text(), 'abc');

      final bytes = await blob.bytes();
      bytes[1] = 'y'.codeUnitAt(0);

      expect(await blob.text(), 'abc');
    });

    test('stream chunks do not expose mutable backing', () async {
      final blob = platform_blob.Blob(<platform_blob.BlobPart>[
        Uint8List.fromList(utf8.encode('abcd')),
      ]);

      expect(() => blob.stream(chunkSize: 0), throwsArgumentError);

      final chunks = await blob.stream(chunkSize: 2).toList();
      chunks.first[0] = 'x'.codeUnitAt(0);

      expect(await blob.text(), 'abcd');
      expect(
        await blob.stream(chunkSize: 2).map(utf8.decode).toList(),
        <String>['ab', 'cd'],
      );
    });

    test('Blob parts use Blob backing instead of read overrides', () async {
      final blob = platform_blob.Blob(<platform_blob.BlobPart>[
        _ReadOverridingBlob(),
      ]);

      expect(await blob.text(), 'base');
    });
  });
}

class _ReadOverridingBlob extends platform_blob.Blob {
  _ReadOverridingBlob() : super(<platform_blob.BlobPart>['base'], 'text/plain');

  @override
  Future<Uint8List> arrayBuffer() async {
    return Uint8List.fromList(utf8.encode('override'));
  }

  @override
  Stream<Uint8List> stream({int chunkSize = 16 * 1024}) {
    return Stream<Uint8List>.value(Uint8List.fromList(utf8.encode('override')));
  }

  @override
  Future<String> text() async => 'override';
}
