import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:block/block.dart' as block;
import 'package:ht/src/fetch/blob.dart' as platform_blob;
import 'package:ht/src/fetch/body.dart';
import 'package:ht/src/fetch/form_data.native.dart';
import 'package:ht/src/fetch/url_search_params.dart';
import 'package:test/test.dart';

Stream<Uint8List> expectNonNullableStream(Stream<Uint8List> stream) => stream;

final class _ThrowingReadBlob extends platform_blob.Blob {
  _ThrowingReadBlob(List<int> bytes, {String type = ''})
    : super(<Object>[Uint8List.fromList(bytes)], type);

  @override
  Future<Uint8List> arrayBuffer() {
    throw StateError('arrayBuffer should not be called');
  }

  @override
  Future<Uint8List> bytes() {
    throw StateError('bytes should not be called');
  }

  @override
  Future<String> text() {
    throw StateError('text should not be called');
  }

  @override
  Stream<Uint8List> stream({int chunkSize = 16 * 1024}) {
    throw StateError('stream should not be called');
  }
}

void main() {
  group('Body', () {
    test('string bodies decode as text and bytes', () async {
      final body = Body('hello');

      expect(await body.text(), 'hello');
      expect(body.bodyUsed, isTrue);
    });

    test('json decodes through text()', () async {
      final body = Body('{"ok":true}');

      expect(await body.json<Map<String, Object?>>(), {'ok': true});
    });

    test('URLSearchParams bodies serialize as form text', () async {
      final params = URLSearchParams()
        ..append('a', '1')
        ..append('b', '2');

      final body = Body(params);

      expect(await body.text(), 'a=1&b=2');
    });

    test('exposes body-derived content type', () {
      final params = URLSearchParams({'a': '1'});
      final formData = FormData()..append('a', Multipart.text('1'));

      expect(Body('hello').contentType, 'text/plain;charset=UTF-8');
      expect(
        Body(params).contentType,
        'application/x-www-form-urlencoded;charset=UTF-8',
      );
      expect(
        Body(block.Block(<Object>['x'], type: 'text/plain')).contentType,
        'text/plain',
      );
      expect(
        Body(formData).contentType,
        startsWith('multipart/form-data; boundary='),
      );
      expect(Body([1, 2, 3]).contentType, isNull);
    });

    test('extends platform Blob and implements Stream', () async {
      final body = Body('hello');

      expect(body, isA<platform_blob.Blob>());
      expect(body, isA<Stream<Uint8List>>());
      expect(body.type, 'text/plain;charset=utf-8');
      expect(body.size, 5);

      final slice = body.slice(1, 4);
      expect(await slice.text(), 'ell');
      expect(body.bodyUsed, isFalse);

      final chunks = await expectNonNullableStream(body).toList();
      expect(chunks.expand((chunk) => chunk).toList(), utf8.encode('hello'));
      expect(body.bodyUsed, isTrue);
    });

    test('normalizes ordinary init values through Blob snapshots', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final body = Body(bytes);

      bytes[0] = 9;

      expect(await body.bytes(), [1, 2, 3]);
    });

    test('uses Blob backing without calling source read methods', () async {
      final blob = _ThrowingReadBlob([
        1,
        2,
        3,
      ], type: 'application/octet-stream');
      final body = Body(blob);

      expect(body.contentType, 'application/octet-stream');
      expect(await body.bytes(), [1, 2, 3]);
    });

    test('exposes known byte size without consuming the body', () {
      final params = URLSearchParams({'a': '1', 'b': '2'});
      final formData = FormData()..append('a', Multipart.text('1'));
      final formBody = Body(formData);

      expect(Body().size, 0);
      expect(Body('hello').size, 5);
      expect(Body(Uint8List.fromList([1, 2, 3])).size, 3);
      expect(Body(Uint8List(2).buffer).size, 2);
      expect(Body([1, 2, 3, 4]).size, 4);
      expect(
        Body(block.Block(<Object>['payload'], type: 'text/plain')).size,
        7,
      );
      expect(Body(params).size, 7);
      expect(formBody.size, greaterThan(0));
      expect(formBody.bodyUsed, isFalse);
    });

    test('rejects size reads for arbitrary stream bodies', () {
      final body = Body(Stream<List<int>>.value(utf8.encode('stream')));

      expect(() => body.size, throwsUnsupportedError);
      expect(body.bodyUsed, isFalse);
    });

    test('validates stream chunk size before consumption starts', () async {
      final body = Body('hello');

      expect(() => body.stream(chunkSize: 0), throwsArgumentError);
      expect(body.bodyUsed, isFalse);

      final stream = body.stream(chunkSize: 2);

      expect(body.bodyUsed, isFalse);
      expect(await stream.map(utf8.decode).join(), 'hello');
      expect(body.bodyUsed, isTrue);
    });

    test('stream-backed bodies cannot be sliced', () {
      final body = Body(Stream<List<int>>.value(utf8.encode('stream')));

      expect(() => body.slice(0), throwsUnsupportedError);
      expect(body.bodyUsed, isFalse);
    });

    test('block bodies can be converted back to Blob', () async {
      final body = Body(block.Block(<Object>['payload'], type: 'text/plain'));
      final blob = await body.blob();

      expect(blob.type, 'text/plain');
      expect(await blob.text(), 'payload');
      expect(body.bodyUsed, isTrue);
    });

    test('list byte bodies decode as bytes', () async {
      final body = Body([1, 2, 3]);

      expect(await body.bytes(), [1, 2, 3]);
    });

    test('clone tees unread stream bodies', () async {
      final body = Body(
        Stream<List<int>>.fromIterable(<List<int>>[
          utf8.encode('hello '),
          utf8.encode('world'),
        ]),
      );

      final clone = body.clone();

      expect(await body.text(), 'hello world');
      expect(await clone.text(), 'hello world');
    });

    test('stream chunks are copied when consumed', () async {
      final controller = StreamController<List<int>>(sync: true);
      final chunk = Uint8List.fromList([1, 2, 3]);
      final body = Body(controller.stream);

      final bytes = body.bytes();
      controller.add(chunk);
      chunk[0] = 9;
      await controller.close();

      expect(await bytes, [1, 2, 3]);
    });

    test('copying a stream-backed body preserves independent reads', () async {
      final controller = StreamController<List<int>>();
      scheduleMicrotask(() async {
        controller
          ..add(utf8.encode('hello '))
          ..add(utf8.encode('copy'));
        await controller.close();
      });

      final body = Body(controller.stream);

      final copy = Body(body);

      expect(await body.text(), 'hello copy');
      expect(await copy.text(), 'hello copy');
    });

    test('blob consumes stream bodies and returns a Blob view', () async {
      final body = Body(
        Stream<List<int>>.fromIterable(<List<int>>[
          utf8.encode('hello '),
          utf8.encode('world'),
        ]),
      );

      final blob = await body.blob();

      expect(await blob.text(), 'hello world');
      expect(body.bodyUsed, isTrue);
    });

    test(
      'empty bodies return empty bytes and become used when consumed',
      () async {
        final body = Body();
        final stream = expectNonNullableStream(body);

        expect(body.bodyUsed, isFalse);
        expect(await stream.toList(), isEmpty);
        expect(body.bodyUsed, isTrue);

        final bytesBody = Body();
        expect(bytesBody.bodyUsed, isFalse);
        expect(await bytesBody.bytes(), isEmpty);
        expect(bytesBody.bodyUsed, isTrue);
      },
    );

    test('consumption is single-use', () async {
      final body = Body('once');

      expect(await body.text(), 'once');
      await expectLater(body.text(), throwsStateError);
    });

    test('clone fails after body has been consumed', () async {
      final body = Body('x');
      await body.text();

      expect(() => body.clone(), throwsStateError);
    });

    test('rejects unsupported body types', () {
      expect(() => Body(DateTime(2024)), throwsArgumentError);
    });
  });
}
