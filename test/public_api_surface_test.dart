import 'package:ht/ht.dart';
import 'package:test/test.dart';

void main() {
  test('public API symbols are importable and usable', () async {
    const method = HttpMethod.post;
    const status = HttpStatus.ok;
    const version = HttpVersion.http11;
    final mime = MimeType.json;

    final headers = Headers({'content-type': mime.toString()});
    final params = URLSearchParams('a=1');
    final blob = Blob.text('hello');
    final file = File(<Object>[blob], 'hello.txt', type: 'text/plain');
    final form = FormData()..append('file', file);

    final request = Request.formData(
      Uri.parse('https://example.com/upload'),
      method: method.value,
      headers: headers,
      body: form,
    );

    final response = Response.bytes(<int>[1, 2, 3], status: status);

    final BodyInit init = 'x';

    expect(method.toString(), 'POST');
    expect(version.value, 'HTTP/1.1');
    expect(mime.essence, 'application/json');
    expect(params.get('a'), '1');
    expect(await blob.text(), 'hello');
    expect(file.name, 'hello.txt');
    expect(request.headers.has('content-type'), isTrue);
    expect(response.ok, isTrue);
    expect(init, 'x');
  });
}
