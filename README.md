# ht

`ht` means **HTTP Types**. It provides shared, framework-agnostic, fetch-first HTTP abstractions:

- Fetch primitives (`Request`, `Response`, `Headers`, `URLSearchParams`, `Blob`, `File`, `FormData`)
- Common protocol types (`HttpMethod`, `HttpStatus`, `HttpVersion`, `MimeType`)

## Example

```dart
import 'package:ht/ht.dart';

void main() async {
  final request = Request.json(
    Uri.parse('https://api.example.com/tasks'),
    method: HttpMethod.post.value,
    body: {'title': 'rewrite ht'},
  );

  final response = Response.json(
    {'ok': true},
    status: HttpStatus.created,
  );

  print(request.headers.get('content-type'));
  print(await response.text());
}
```

## Notes

- `body` follows one-time consumption semantics (`bodyUsed` becomes `true` after reading).
- `clone()` is supported for unread request/response bodies.
- `FormData.encodeMultipart()` is available for adapters that need raw multipart payloads.
