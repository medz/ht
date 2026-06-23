import 'dart:async';
import 'dart:typed_data';

import 'package:block/block.dart' as block;
import 'package:ht/ht.dart';
import 'package:test/test.dart';

final class _RequestBody extends Body {
  _RequestBody(super.init, {required this.replayable});

  final bool replayable;

  @override
  _RequestBody clone() {
    return _RequestBody(this, replayable: replayable);
  }
}

void main() {
  test('public API symbols are importable and usable', () async {
    const method = 'POST';
    const protocolMethod = HttpMethod.post;
    const status = HttpStatus.ok;
    const version = HttpVersion.http11;
    final mime = MimeType.json;
    final requestInit = RequestInit(
      method: method,
      priority: RequestPriority.high,
    );
    final responseInit = ResponseInit(status: status);

    final headers = Headers({'content-type': mime.toString()});
    final params = URLSearchParams('a=1');
    final blob = Blob(<Object>['hello'], 'text/plain;charset=utf-8');
    final file = File(<Object>[blob], 'hello.txt', type: 'text/plain');
    final form = FormData()..append('file', Multipart.blob(file));
    final multipart = form.encodeMultipart(boundary: 'api');
    final body = Body('public');
    final requestBody = _RequestBody(
      Stream<List<int>>.fromIterable(<List<int>>[
        Uint8List.fromList(<int>[119, 114, 97, 112]),
      ]),
      replayable: true,
    );
    final requestBodyClone = requestBody.clone();
    final requestBodyForRequest = _RequestBody(
      'request-body',
      replayable: false,
    );
    final responseBody = _RequestBody('response-body', replayable: true);
    final blockBody = block.Block(<Object>['block-body'], type: 'text/plain');

    final request = Request(
      Uri.parse('https://example.com/upload'),
      RequestInit(method: requestInit.method, headers: headers, body: form),
    );

    final response = Response(blockBody, responseInit);
    final requestWithSubclassBody = Request(
      Uri.parse('https://example.com/subclass'),
      RequestInit(method: method, body: requestBodyForRequest),
    );
    final responseWithSubclassBody = Response(responseBody);

    final Object init = 'x';

    expect(protocolMethod.toString(), 'POST');
    expect(version.value, 'HTTP/1.1');
    expect(mime.essence, 'application/json');
    expect(params.get('a'), '1');
    expect(await blob.text(), 'hello');
    expect(file.name, 'hello.txt');
    expect(requestInit.method, 'POST');
    expect(requestInit.priority, RequestPriority.high);
    expect(responseInit.status, 200);
    expect(body, isA<Blob>());
    expect(body, isA<Stream<Uint8List>>());
    expect(body.size, 6);
    expect(requestBody, isA<Body>());
    expect(requestBodyClone, isA<_RequestBody>());
    expect(requestBodyClone.replayable, isTrue);
    expect(await requestBody.text(), 'wrap');
    expect(await requestBodyClone.text(), 'wrap');
    expect(requestWithSubclassBody.body, isA<_RequestBody>());
    expect((requestWithSubclassBody.body! as _RequestBody).replayable, isFalse);
    expect(await requestWithSubclassBody.text(), 'request-body');
    expect(request.headers.has('content-type'), isTrue);
    expect(await multipart.bytes(), isNotEmpty);
    expect(await response.text(), 'block-body');
    expect(responseWithSubclassBody.body, isA<_RequestBody>());
    expect((responseWithSubclassBody.body! as _RequestBody).replayable, isTrue);
    expect(await responseWithSubclassBody.text(), 'response-body');
    expect(response.ok, isTrue);
    expect(init, 'x');
  });
}
