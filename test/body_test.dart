import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:block/block.dart' as block;
import 'package:ht/src/fetch/body.dart';
import 'package:ht/src/fetch/form_data.native.dart';
import 'package:ht/src/fetch/url_search_params.dart';
import 'package:test/test.dart';

Stream<Uint8List> expectNonNullableStream(Stream<Uint8List> stream) => stream;

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
        final stream = expectNonNullableStream(body.stream);

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
