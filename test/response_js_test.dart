@TestOn('browser')
library;

import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:ht/src/fetch/file.dart';
import 'package:ht/src/fetch/form_data.native.dart';
import 'package:ht/src/fetch/response.js.dart';
import 'package:ht/src/fetch/response.native.dart' as native;
import 'package:test/test.dart';
import 'package:web/web.dart' as web;

void main() {
  group('Response (js)', () {
    test('accepts native web.Response host', () async {
      final upstream = web.Response(
        'hello world'.toJS,
        web.ResponseInit(
          status: 201,
          statusText: 'Created',
          headers: {'content-type': 'text/plain'}.jsify()! as web.HeadersInit,
        ),
      );

      final response = Response(upstream);

      expect(response.status, 201);
      expect(response.statusText, 'Created');
      expect(response.ok, isTrue);
      expect(response.type, native.ResponseType.default_);
      expect(response.headers.get('content-type'), 'text/plain');
      expect(response.bodyUsed, isFalse);
      expect(await response.text(), 'hello world');
      expect(response.bodyUsed, isTrue);
    });

    test('sets default content-type for native construction body init', () {
      final response = Response('hello');

      expect(response.headers.get('content-type'), 'text/plain;charset=UTF-8');
    });

    test('clones wrapped responses without aliasing body state', () async {
      final upstream = Response(
        web.Response(
          'cloned response'.toJS,
          web.ResponseInit(
            status: 202,
            statusText: 'Accepted',
            headers: {'x-source': '1'}.jsify()! as web.HeadersInit,
          ),
        ),
      );
      final clone = Response(upstream);

      expect(clone.status, 202);
      expect(clone.statusText, 'Accepted');
      expect(clone.headers.get('x-source'), '1');
      expect(upstream.bodyUsed, isFalse);
      expect(clone.bodyUsed, isFalse);

      expect(await upstream.text(), 'cloned response');
      expect(upstream.bodyUsed, isTrue);
      expect(clone.bodyUsed, isFalse);
      expect(await clone.text(), 'cloned response');
      expect(clone.bodyUsed, isTrue);
    });

    test('applies init overrides when copying wrapped responses', () async {
      final upstream = Response(
        web.Response(
          'source body'.toJS,
          web.ResponseInit(
            status: 202,
            statusText: 'Accepted',
            headers: {'x-source': '1'}.jsify()! as web.HeadersInit,
          ),
        ),
      );

      final response = Response(
        upstream,
        native.ResponseInit(
          status: 201,
          statusText: 'Created',
          headers: {'x-init': '1'},
        ),
      );

      expect(response.status, 201);
      expect(response.statusText, 'Created');
      expect(response.headers.get('x-source'), isNull);
      expect(response.headers.get('x-init'), '1');
      expect(upstream.bodyUsed, isFalse);
      expect(await response.text(), 'source body');
      expect(upstream.bodyUsed, isFalse);
      expect(await upstream.text(), 'source body');
    });

    test('applies init overrides when copying native responses', () async {
      final upstream = native.Response(
        'native body',
        native.ResponseInit(
          status: 202,
          statusText: 'Accepted',
          headers: {'x-source': '1'},
        ),
      );

      final response = Response(
        upstream,
        native.ResponseInit(
          status: 201,
          statusText: 'Created',
          headers: {'x-init': '1'},
        ),
      );

      expect(response.status, 201);
      expect(response.statusText, 'Created');
      expect(response.headers.get('x-source'), isNull);
      expect(response.headers.get('x-init'), '1');
      expect(upstream.bodyUsed, isFalse);
      expect(await response.text(), 'native body');
      expect(upstream.bodyUsed, isFalse);
      expect(await upstream.text(), 'native body');
    });

    test(
      'preserves deleted body-derived content-type when copying responses',
      () async {
        final wrapped = Response('wrapped body');
        expect(wrapped.headers.get('content-type'), 'text/plain;charset=UTF-8');

        wrapped.headers.delete('content-type');
        final wrappedCopy = Response(
          wrapped,
          const native.ResponseInit(statusText: 'OK'),
        );

        expect(wrappedCopy.statusText, 'OK');
        expect(wrappedCopy.headers.get('content-type'), isNull);
        expect(wrapped.bodyUsed, isFalse);
        expect(await wrappedCopy.text(), 'wrapped body');
        expect(wrapped.bodyUsed, isFalse);
        expect(await wrapped.text(), 'wrapped body');

        final upstream = native.Response('native body');
        upstream.headers.delete('content-type');
        final nativeCopy = Response(
          upstream,
          const native.ResponseInit(statusText: 'OK'),
        );

        expect(nativeCopy.statusText, 'OK');
        expect(nativeCopy.headers.get('content-type'), isNull);
        expect(upstream.bodyUsed, isFalse);
        expect(await nativeCopy.text(), 'native body');
        expect(upstream.bodyUsed, isFalse);
        expect(await upstream.text(), 'native body');
      },
    );

    test('preserves web wrapper header mutations when copying', () async {
      final upstream = Response(
        web.Response(
          'web wrapped body'.toJS,
          web.ResponseInit(
            status: 202,
            statusText: 'Accepted',
            headers:
                {'content-type': 'text/plain', 'x-source': '1'}.jsify()!
                    as web.HeadersInit,
          ),
        ),
      );
      upstream.headers
        ..delete('content-type')
        ..set('x-source', '2');

      final response = Response(
        upstream,
        const native.ResponseInit(statusText: 'OK'),
      );

      expect(response.status, 202);
      expect(response.statusText, 'OK');
      expect(response.headers.get('content-type'), isNull);
      expect(response.headers.get('x-source'), '2');
      expect(upstream.bodyUsed, isFalse);
      expect(await response.text(), 'web wrapped body');
      expect(upstream.bodyUsed, isFalse);
      expect(await upstream.text(), 'web wrapped body');
    });

    test('applies init overrides when copying web responses', () async {
      final upstream = web.Response(
        'web body'.toJS,
        web.ResponseInit(
          status: 202,
          statusText: 'Accepted',
          headers: {'x-source': '1'}.jsify()! as web.HeadersInit,
        ),
      );

      final response = Response(
        upstream,
        native.ResponseInit(
          status: 201,
          statusText: 'Created',
          headers: {'x-init': '1'},
        ),
      );

      expect(response.status, 201);
      expect(response.statusText, 'Created');
      expect(response.headers.get('x-source'), isNull);
      expect(response.headers.get('x-init'), '1');
      expect(upstream.bodyUsed, isFalse);
      expect(await response.text(), 'web body');
      expect(upstream.bodyUsed, isFalse);
      expect(
        await upstream.text().toDart.then((text) => text.toDart),
        'web body',
      );
    });

    test('rejects copying consumed wrapped responses', () async {
      final upstream = Response('used body');

      expect(await upstream.text(), 'used body');
      expect(upstream.bodyUsed, isTrue);
      expect(() => Response(upstream), throwsStateError);
      expect(
        () => Response(upstream, const native.ResponseInit(status: 201)),
        throwsStateError,
      );
    });

    test('clone tees a wrapped web.Response body', () async {
      final upstream = web.Response('cloned body'.toJS);

      final response = Response(upstream);
      final clone = response.clone();

      expect(await response.text(), 'cloned body');
      expect(await clone.text(), 'cloned body');
    });

    test('reads bytes directly from web host', () async {
      final response = Response(web.Response('hello bytes'.toJS));

      expect(
        await response.bytes(),
        Uint8List.fromList(utf8.encode('hello bytes')),
      );
      expect(response.bodyUsed, isTrue);
    });

    test('reads blob directly from web host', () async {
      final response = Response(
        web.Response(
          'hello blob'.toJS,
          web.ResponseInit(
            headers: {'content-type': 'text/plain'}.jsify()! as web.HeadersInit,
          ),
        ),
      );

      final blob = await response.blob();

      expect(blob.type, 'text/plain');
      expect(await blob.text(), 'hello blob');
      expect(response.bodyUsed, isTrue);
    });

    test('supports MDN static factories', () async {
      final error = Response.error();
      expect(error.type, native.ResponseType.error);
      expect(error.status, 0);

      final redirect = Response.redirect(Uri.parse('https://example.com/next'));
      expect(redirect.status, 302);
      expect(redirect.headers.get('location'), 'https://example.com/next');

      final json = Response.json({'ok': true});
      expect(json.headers.get('content-type'), contains('application/json'));
      expect(await json.text(), '{"ok":true}');
    });

    test('enforces native constructor invariants', () {
      expect(
        () => Response(null, const native.ResponseInit(status: 199)),
        throwsRangeError,
      );
      expect(
        () => Response('payload', const native.ResponseInit(status: 204)),
        throwsArgumentError,
      );
    });

    test('reads formData directly from web host', () async {
      final formResponse = Response(
        web.Response(
          'a=1'.toJS,
          web.ResponseInit(
            headers:
                {'content-type': 'application/x-www-form-urlencoded'}.jsify()!
                    as web.HeadersInit,
          ),
        ),
      );

      final parsed = await formResponse.formData();
      expect((parsed.get('a') as TextMultipart).value, '1');
    });

    test('maps web.File formData entries to BlobMultipart', () async {
      final file = web.File(
        ['payload'.toJS].toJS,
        'payload.txt',
        web.FilePropertyBag(type: 'text/plain'),
      );
      final formData = web.FormData()..append('file', file);
      final response = Response(web.Response(formData));

      final parsed = await response.formData();
      final part = parsed.get('file');

      expect(part, isA<BlobMultipart>());
      expect(part, isA<File>());
      expect((part as BlobMultipart).filename, 'payload.txt');
      expect(part.name, 'payload.txt');
      expect(part.type, 'text/plain');
      expect(await part.text(), 'payload');
    });
  });
}
