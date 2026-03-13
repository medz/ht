import 'package:block/block.dart' as block;
import 'package:ht/ht.dart';
import 'package:test/test.dart';

void main() {
  test('public API symbols are importable and usable', () async {
    const method = HttpMethod.post;
    const status = HttpStatus.ok;
    const version = HttpVersion.http11;
    final mime = MimeType.json;
    final requestInit = RequestInit(method: method);
    final responseInit = ResponseInit(status: status);

    final headers = Headers({'content-type': mime.toString()});
    final params = URLSearchParams('a=1');
    final blob = Blob(<Object>['hello'], 'text/plain;charset=utf-8');
    final file = File(<Object>[blob], 'hello.txt', type: 'text/plain');
    final form = FormData()..append('file', Multipart.blob(file));
    final multipart = form.encodeMultipart(boundary: 'api');
    final blockBody = block.Block(<Object>['block-body'], type: 'text/plain');

    final request = Request(
      RequestInput.uri(Uri.parse('https://example.com/upload')),
      RequestInit(method: requestInit.method, headers: headers, body: form),
    );

    final response = Response(blockBody, responseInit);

    final Object init = 'x';

    expect(method.toString(), 'POST');
    expect(version.value, 'HTTP/1.1');
    expect(mime.essence, 'application/json');
    expect(params.get('a'), '1');
    expect(await blob.text(), 'hello');
    expect(file.name, 'hello.txt');
    expect(requestInit.method, HttpMethod.post);
    expect(responseInit.status, 200);
    expect(request.headers.has('content-type'), isTrue);
    expect(await multipart.bytes(), isNotEmpty);
    expect(await response.text(), 'block-body');
    expect(response.ok, isTrue);
    expect(init, 'x');
  });
}
