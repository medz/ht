# ht

[![CI](https://github.com/medz/ht/actions/workflows/ci.yml/badge.svg)](https://github.com/medz/ht/actions/workflows/ci.yml)
[![pub package](https://img.shields.io/pub/v/ht?label=pub.dev)](https://pub.dev/packages/ht)
[![Dart SDK](https://img.shields.io/badge/Dart_SDK-%5E3.10.0-0175C2?logo=dart)](https://dart.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](./LICENSE)

`ht` stands for **HTTP Types**. It provides a fetch-first set of Dart HTTP abstractions.

This package focuses on the **type and semantics layer** only. It does not implement an HTTP client or server runtime.

## Features

- Fetch-style primitives: `Request`, `Response`, `Headers`, `URLSearchParams`, `Blob`, `File`, `FormData`
- Protocol helpers: `HttpMethod`, `HttpStatus`, `HttpVersion`, `MimeType`
- Consistent body-read semantics (single-consume), clone semantics, and header normalization
- Designed as a shared HTTP type layer for downstream client/server frameworks

## Installation

```bash
dart pub add ht
```

Or add it manually to `pubspec.yaml`:

```yaml
dependencies:
  ht: ^0.2.0
```

## Scope

- No HTTP client implementation
- No HTTP server implementation
- No routing or middleware framework

The goal is to provide stable and reusable HTTP types and behavior contracts.

## Core API

| Category | Types |
| --- | --- |
| Protocol | `HttpMethod`, `HttpStatus`, `HttpVersion`, `MimeType` |
| Message | `Request`, `Response`, `BodyMixin`, `BodyInit` |
| Header/URL | `Headers`, `URLSearchParams` |
| Binary/Form | `Blob`, `File`, `FormData` |

## Quick Example

```dart
import 'package:ht/ht.dart';

Future<void> main() async {
  final request = Request.json(
    Uri.parse('https://api.example.com/tasks'),
    method: HttpMethod.post.value,
    body: {'title': 'rewrite ht'},
  );

  final response = Response.json(
    {'ok': true},
    status: HttpStatus.created,
  );

  print(request.method); // POST
  print(request.headers.get('content-type')); // application/json; charset=utf-8
  print(await response.text());
}
```

## Body Semantics

`Request` and `Response` use a single-consume body model:

- After the first `text()` / `bytes()` / `json()` / `blob()` call (or stream read), `bodyUsed == true`
- Reading the same instance again throws `StateError`
- Use `clone()` when multiple reads are required

## FormData Example

```dart
import 'package:ht/ht.dart';

Future<void> main() async {
  final form = FormData()
    ..append('name', 'alice')
    ..append('avatar', Blob.text('binary'), filename: 'avatar.txt');

  final multipart = form.encodeMultipart();
  final bytes = await multipart.bytes();

  print(multipart.contentType);   // multipart/form-data; boundary=...
  print(multipart.contentLength); // body bytes length
  print(bytes.length);            // same as contentLength
}
```

## Block Interop

`Blob` implements `package:block` `Block`, and `BodyInit` accepts `Block`
values directly:

```dart
import 'package:block/block.dart' as block;
import 'package:ht/ht.dart';

Future<void> main() async {
  final body = block.Block(<Object>['hello'], type: 'text/plain');
  final request = Request(
    Uri.parse('https://example.com'),
    method: 'POST',
    body: body,
  );

  print(request.headers.get('content-type'));   // text/plain
  print(request.headers.get('content-length')); // 5
  print(await request.text());                  // hello
}
```

## Blob Slice Semantics

`Blob.slice(start, end)` now follows Web Blob semantics. Negative indexes are
interpreted from the end of the blob:

```dart
final blob = Blob.text('hello world');
final tail = blob.slice(-5);
print(await tail.text()); // world
```

## Development

```bash
dart pub get
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
dart run example/main.dart
```

## License

[MIT](./LICENSE)
